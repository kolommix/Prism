import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../library/application/library_providers.dart';
import '../data/import_repository.dart';
import '../data/network_check.dart';
import '../../../l10n/l10n.dart';
import '../../library/domain/track.dart';
import '../domain/external_track.dart';
import '../domain/matching.dart';
import '../domain/online_error.dart';
import '../services/music_service_module.dart';
import '../services/youtube/youtube_module.dart';
import 'import_file_check.dart';
import 'online_providers.dart';

/// Where imported songs are saved: real files, real library songs.
final importDownloadDirProvider = Provider<Directory>(
  (ref) => Directory(p.join(ref.watch(onlineHubProvider).cache.dir.parent.path, 'imported_music')),
);

/// The service that can save audio, null while it is off.
final importDownloadModuleProvider = Provider<MusicServiceModule?>((ref) {
  ref.watch(onlineRevisionProvider);
  final m = ref.watch(onlineHubProvider).module(OnlineService.youtube);
  return m != null && m.features.contains(ModuleFeature.stream) ? m : null;
});

class ImportDownload {
  const ImportDownload({required this.jobId, required this.done, this.failed = 0, this.current, this.running = true, this.message});
  final int jobId;
  final int done;
  final int failed;
  final String? current;
  final bool running;
  final String? message;
}

/// Turns found songs into files inside Prism. Works through a job's songs in
/// the background, also while matching still finds more. Every found song is
/// saved right away (nothing waits for a check); a wrong one can still be
/// fixed afterwards, which saves the new pick.
class ImportDownloader extends Notifier<ImportDownload?> {
  static const workers = 2;

  /// After this many failures in a row the service is refusing: stop and say so.
  static const giveUpAfter = 4;

  final _failed = <int>{};
  final _claimed = <int>{};
  final _again = <int>{};
  bool _stop = false;
  bool _stoppedByUser = false;
  int _busyJob = -1;

  /// After the service refused or the connection dropped, saving goes on by
  /// itself later (longer each time), nobody has to press Retry.
  Timer? _retryTimer;
  final _attempts = <int, int>{};

  /// While stopped because YouTube can't be reached: a VPN switched on (or
  /// any other change of the connection) starts saving again at once.
  NetworkWatch? _watching;
  NetworkWatch get _watch => _watching ??= ref.read(networkWatchFactoryProvider)();

  @override
  ImportDownload? build() {
    ref.onDispose(() {
      _retryTimer?.cancel();
      _watching?.stop();
    });
    return null;
  }

  void stop() {
    _stop = true;
    _stoppedByUser = true;
    _retryTimer?.cancel();
    _watching?.stop();
  }

  /// Downloads whatever this job has waiting. Safe to call often.
  void poke(int jobId) {
    if (_busyJob != -1) {
      _again.add(jobId);
      return;
    }
    unawaited(_run(jobId));
  }

  /// Tries the songs that failed before as well.
  void retry(int jobId) {
    _retryTimer?.cancel();
    _watching?.stop();
    _failed.clear();
    poke(jobId);
  }

  Future<void> _run(int jobId) async {
    _busyJob = jobId;
    _stop = false;
    _stoppedByUser = false;
    final repo = ref.read(importRepositoryProvider);
    await _dropUnfinished();
    var done = 0, failed = 0, inARow = 0;
    String? message;
    Object? lastError;

    Future<void> worker() async {
      while (!_stop) {
        final module = ref.read(importDownloadModuleProvider);
        if (module == null) return;
        final waiting = await repo.downloadableItems(jobId);
        final item = waiting.where((i) => !_failed.contains(i.id) && !_claimed.contains(i.id)).firstOrNull;
        if (item == null) return;
        _claimed.add(item.id);
        state = ImportDownload(jobId: jobId, done: done, failed: failed, current: item.wanted.title);
        try {
          await _downloadOne(repo, module, item);
          done++;
          inARow = 0;
          await repo.writePlaylist(jobId, finish: false);
        } on Object catch (e) {
          _failed.add(item.id);
          failed++;
          lastError = e;
          message = describeOnlineError(e);
          // A blocked song is about that song; only service trouble counts
          // towards stopping.
          final blocked = e is OnlineException && e.kind == OnlineErrorKind.notFound;
          if (!blocked && ++inARow >= giveUpAfter) _stop = true;
          // YouTube doesn't answer from here at all (blocked on this
          // network, no VPN): the next songs would only time out too.
          if (!_stop && e is OnlineException && e.kind == OnlineErrorKind.offline) {
            final service = e.service ?? OnlineService.youtube;
            if (!await ref.read(networkCheckProvider).reachable(service, saving: true)) _stop = true;
          }
        } finally {
          _claimed.remove(item.id);
        }
      }
    }

    var serviceTrouble = false;
    try {
      await Future.wait([for (var i = 0; i < workers; i++) worker()]);
      serviceTrouble = _stop && !_stoppedByUser;
      if (lastError case final OnlineException e) {
        // "Offline" only when the internet really is gone.
        message = (await ref.read(networkCheckProvider).explain(e)).message;
      }
    } finally {
      _busyJob = -1;
      if (serviceTrouble) {
        final attempt = _attempts[jobId] ?? 0;
        _attempts[jobId] = attempt + 1;
        final wait = importRetryDelay(attempt);
        final unreachable = lastError is OnlineException && (lastError as OnlineException).kind == OnlineErrorKind.offline;
        message = '${message ?? ''} ${l10n.importRetryIn(wait.inMinutes)}${unreachable ? ' ${l10n.importResumesOnNetworkChange}' : ''}'.trim();
        _retryTimer?.cancel();
        _retryTimer = Timer(wait, () => retry(jobId));
        if (unreachable) {
          _watch.start(() {
            _attempts.remove(jobId);
            retry(jobId);
          });
        }
      } else if (failed == 0) {
        _attempts.remove(jobId);
      }
      state = ImportDownload(jobId: jobId, done: done, failed: failed, running: false, message: failed > 0 ? message : null);
    }
    if (_again.isNotEmpty && !_stoppedByUser) {
      final next = _again.first;
      _again.remove(next);
      poke(next);
    }
  }

  Future<void> _downloadOne(ImportRepository repo, MusicServiceModule module, ImportItem item) async {
    final remote = item.track!;
    final id = youtubeIdOf(remote);
    if (id == null) throw OnlineException(OnlineErrorKind.unsupported, service: OnlineService.youtube);
    final w = item.wanted;
    final title = w.title.trim().isEmpty ? remote.title : w.title.trim();
    final artist = w.artist.trim().isEmpty ? remote.artist : w.artist.trim();

    final dir = ref.read(importDownloadDirProvider);
    await dir.create(recursive: true);
    final expected = remote.durationMs > 0 ? remote.durationMs : w.durationMs;
    var saved = await _existing(dir, id, expected);
    if (saved == null) {
      try {
        saved = await _save(module, remote, dir, artist, title);
      } on OnlineException catch (e) {
        if (e.kind != OnlineErrorKind.notFound) rethrow;
        // YouTube blocks saving some uploads; another upload of the same
        // song often works.
        saved = await _fromAnotherUpload(module, w, id, dir, artist, title) ?? (throw e);
      }
    }
    final (file, audio) = saved;
    final trackId = await ref.read(libraryRepositoryProvider).addDownloadedFile(
          file,
          title: title,
          artist: artist,
          album: w.album,
          // The length of what was really saved, when it was measured.
          durationMs: audio.durationMs > 0 ? audio.durationMs : expected,
          artwork: w.artworkUrl ?? remote.artworkPath,
        );
    await repo.relinkItem(item.id, trackId);
  }

  /// Saves one upload and checks the file. A broken file is thrown away and
  /// counts as a blocked upload, so the next upload of the song gets a turn.
  Future<(File, SavedAudio)> _save(MusicServiceModule module, Track remote, Directory dir, String artist, String title) async {
    final base = p.join(dir.path, importFileName(artist, title, youtubeIdOf(remote)!));
    final ext = await module.download(remote, base);
    final file = File('$base.$ext');
    final audio = await ref.read(importFileCheckProvider).check(file, expectedMs: remote.durationMs);
    if (!audio.ok) {
      debugPrint('Prism import: ${file.path} refused (${audio.reason})');
      await _delete(file);
      throw OnlineException(OnlineErrorKind.notFound, service: OnlineService.youtube, message: l10n.importSavedFileBroken);
    }
    return (file, audio);
  }

  static Future<void> _delete(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } on FileSystemException {
      // In use: the next start cleans it up.
    }
  }

  /// How many other uploads are tried before a song counts as blocked.
  static const otherUploads = 3;

  Future<(File, SavedAudio)?> _fromAnotherUpload(
    MusicServiceModule module,
    ExternalTrack wanted,
    String blockedId,
    Directory dir,
    String artist,
    String title,
  ) async {
    final found = await module.search(MatchScorer.queryFor(wanted), limit: 10);
    final scored = [
      for (final t in found)
        if (youtubeIdOf(t) case final id? when id != blockedId) (t, MatchScorer.score(wanted, t).value),
    ]
      ..removeWhere((x) => x.$2 < MatchScorer.acceptThreshold)
      ..sort((a, b) => b.$2.compareTo(a.$2));
    for (final (t, _) in scored.take(otherUploads)) {
      try {
        return await _save(module, t, dir, artist, title);
      } on OnlineException catch (e) {
        if (e.kind != OnlineErrorKind.notFound) rethrow;
      }
    }
    return null;
  }

  /// Leftovers of downloads that were cut off (app closed, old bug).
  Future<void> _dropUnfinished() async {
    final dir = ref.read(importDownloadDirProvider);
    if (!await dir.exists()) return;
    await for (final e in dir.list()) {
      if (e is File && _unfinished(e.path)) {
        try {
          await e.delete();
        } on FileSystemException {
          // In use: next time.
        }
      }
    }
  }

  /// What a finished save can be. Anything else with the id in its name is
  /// a leftover of a cut-off one (`.part`, yt-dlp's `.ytdl` and `.part-Frag`).
  static const savedExtensions = {'.m4a', '.mp4', '.webm', '.opus', '.ogg', '.mp3'};

  static bool _unfinished(String path) {
    final name = p.basename(path).toLowerCase();
    return name.endsWith('.part') || name.endsWith('.ytdl') || name.contains('.part-frag') || name.endsWith('.temp');
  }

  /// Already saved by an earlier import, and whole. A broken copy (older
  /// versions kept those) is removed so it gets saved again.
  Future<(File, SavedAudio)?> _existing(Directory dir, String id, int expectedMs) async {
    await for (final e in dir.list()) {
      final name = p.basename(e.path);
      if (e is File && name.contains('[$id].') && savedExtensions.contains(p.extension(name).toLowerCase())) {
        final audio = await ref.read(importFileCheckProvider).check(e, expectedMs: expectedMs);
        if (audio.ok) return (e, audio);
        await _delete(e);
      }
    }
    return null;
  }
}

final importDownloaderProvider = NotifierProvider<ImportDownloader, ImportDownload?>(ImportDownloader.new);

/// "Artist - Title [id]", safe on Windows and Android, without the extension.
String importFileName(String artist, String title, String id) {
  final name = '${artist.isEmpty ? '' : '$artist - '}$title'
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final short = name.length > 120 ? name.substring(0, 120).trim() : name;
  return '$short [$id]';
}

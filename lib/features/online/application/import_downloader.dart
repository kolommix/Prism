import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../library/application/library_providers.dart';
import '../data/import_repository.dart';
import '../domain/external_track.dart';
import '../domain/online_error.dart';
import '../services/music_service_module.dart';
import '../services/youtube/youtube_module.dart';
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
/// the background, also while matching still finds more. Sure matches go right
/// away; uncertain ones wait until they are accepted in Review.
class ImportDownloader extends Notifier<ImportDownload?> {
  static const workers = 2;

  /// After this many failures in a row the service is refusing: stop and say so.
  static const giveUpAfter = 4;

  final _failed = <int>{};
  final _claimed = <int>{};
  final _again = <int>{};
  bool _stop = false;
  int _busyJob = -1;

  @override
  ImportDownload? build() => null;

  void stop() => _stop = true;

  /// Downloads whatever this job has waiting. Safe to call often.
  void poke(int jobId) {
    if (_busyJob == jobId) {
      _again.add(jobId);
      return;
    }
    if (_busyJob != -1) {
      _again.add(jobId);
      return;
    }
    unawaited(_run(jobId));
  }

  /// Tries the songs that failed before as well.
  void retry(int jobId) {
    _failed.clear();
    poke(jobId);
  }

  Future<void> _run(int jobId) async {
    _busyJob = jobId;
    _stop = false;
    final repo = ref.read(importRepositoryProvider);
    var done = 0, failed = 0, inARow = 0;
    String? message;

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
          inARow++;
          message = describeOnlineError(e);
          if (inARow >= giveUpAfter) _stop = true;
        } finally {
          _claimed.remove(item.id);
        }
      }
    }

    try {
      await Future.wait([for (var i = 0; i < workers; i++) worker()]);
    } finally {
      _busyJob = -1;
      state = ImportDownload(jobId: jobId, done: done, failed: failed, running: false, message: failed > 0 ? message : null);
    }
    if (_again.isNotEmpty && !_stop) {
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
    var file = await _existing(dir, id);
    if (file == null) {
      final base = p.join(dir.path, importFileName(artist, title, id));
      final ext = await module.download(remote, base);
      file = File('$base.$ext');
    }
    final trackId = await ref.read(libraryRepositoryProvider).addDownloadedFile(
          file,
          title: title,
          artist: artist,
          album: w.album,
          durationMs: remote.durationMs > 0 ? remote.durationMs : w.durationMs,
          artwork: w.artworkUrl ?? remote.artworkPath,
        );
    await repo.relinkItem(item.id, trackId);
  }

  /// Already saved by an earlier import.
  Future<File?> _existing(Directory dir, String id) async {
    await for (final e in dir.list()) {
      if (e is File && !e.path.endsWith('.part') && p.basename(e.path).contains('[$id].')) return e;
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

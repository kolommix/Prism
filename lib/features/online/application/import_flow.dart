import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../playlists/domain/playlist_share.dart';
import '../data/import_repository.dart';
import '../domain/external_track.dart';
import '../domain/import_intake.dart';
import '../domain/import_parsers.dart';
import '../domain/link_parser.dart';
import '../domain/online_error.dart';
import '../services/link_only/link_modules.dart';
import 'import_downloader.dart';
import 'online_providers.dart';

/// Everything an import does between "here is a link or file" and "the songs
/// are arriving". There is no preview step: tracks go in as they are found, and
/// the uncertain ones wait in the Review list.
class ImportFlow {
  ImportFlow(this._ref);
  final Ref _ref;

  Future<void> _running = Future<void>.value();

  /// Reads what a link points to. Throws [OnlineException].
  Future<List<ImportedList>> readLink(ParsedLink link) async {
    var target = link;
    if (link.kind == LinkKind.shortLink && link.service != OnlineService.deezer) {
      final full = parseMusicLink((await followRedirects(link.url)).toString());
      if (full == null || full.kind == LinkKind.shortLink) {
        throw OnlineException(OnlineErrorKind.notFound, service: link.service);
      }
      target = full;
    }
    final list = await _ref.read(onlineHubProvider).linkReader(target.service).openLink(target);
    // The same link always gets the same address, so doing it twice re-syncs.
    return [
      ImportedList(
        name: list.name,
        origin: list.origin,
        tracks: list.tracks,
        sourceUrl: target.kind == LinkKind.shortLink ? list.sourceUrl : target.canonicalUrl,
      ),
    ];
  }

  /// Reads a playlist file (CSV, JSON, M3U, .liner).
  List<ImportedList> readFile(String name, String text) => parseImportFile(name, text);

  /// Reads a piece of text: a shared playlist, a link or a file path.
  Future<List<ImportedList>> readText(String text) async {
    switch (classifyImportText(text)) {
      case SharedPlaylistInput(:final text):
        return [decodeSharedPlaylist(text)];
      case ServiceLinkInput(:final link):
        return readLink(link);
      case FileInput(:final path):
        return readFile(path, decodeImportBytes(await File(path).readAsBytes()));
      case UnknownInput():
        throw ImportFormatException(l10n.notALinkPrismCanRead);
    }
  }

  /// Starts importing; matching goes on in the background. A list imported
  /// before is synced instead of copied. Returns the job ids.
  Future<List<int>> start(List<ImportedList> lists) async {
    final repo = _ref.read(importRepositoryProvider);
    final ids = <int>[];
    for (final list in lists) {
      final earlier = await repo.jobForSource(list.sourceUrl);
      if (earlier != null) {
        await repo.resync(earlier.id, list);
        ids.add(earlier.id);
      } else {
        ids.add(await repo.createJob(list));
      }
    }
    _runInBackground(ids);
    return ids;
  }

  void _runInBackground(List<int> ids) {
    final runner = _ref.read(importRunnerProvider.notifier);
    _running = _running.then((_) async {
      for (final id in ids) {
        await runner.run(id);
      }
    }).catchError((Object _) {});
    unawaited(_running);
  }

  /// One tap: reads the source again, adds what's new, drops what's gone.
  Future<void> resync(ImportJob job) async {
    final repo = _ref.read(importRepositoryProvider);
    final source = job.sourceUrl;
    if (source == null) throw OnlineException(OnlineErrorKind.unsupported);
    final List<ImportedList> lists;
    if (parseMusicLink(source) case final link?) {
      lists = await readLink(link);
    } else {
      lists = await _reread(source);
    }
    final fresh = lists.where((l) => l.sourceUrl == source).firstOrNull ?? lists.first;
    await repo.resync(job.id, fresh);
    _runInBackground([job.id]);
  }

  /// A file source is the path, plus "#name" for one list of several.
  Future<List<ImportedList>> _reread(String source) async {
    final hash = source.lastIndexOf('#');
    final path = hash > 0 && !File(source).existsSync() ? source.substring(0, hash) : source;
    final file = File(path);
    if (!await file.exists()) throw ImportFormatException(l10n.importErrorFileGone(path));
    return readFile(path, decodeImportBytes(await file.readAsBytes()));
  }

  /// Looks again for the songs nothing was found for (say, YouTube was just
  /// turned on). Songs the user marked "no match" stay as they are.
  Future<void> retryUnmatched(int jobId) async {
    await _ref.read(importRepositoryProvider).requeueUnmatched(jobId);
    _runInBackground([jobId]);
  }

  /// Carries on with everything unfinished: songs still to find and songs still
  /// to save. After the download switch goes on, and at every start with it on.
  Future<void> resumeAll() async {
    final jobs = await _ref.read(importRepositoryProvider).watchJobs().first;
    final waiting = [for (final j in jobs) if (j.pending > 0) j.id];
    if (waiting.isNotEmpty) _runInBackground(waiting);
    if (_ref.read(onlineHubProvider).flags.importDownload) {
      for (final j in jobs) {
        _ref.read(importDownloaderProvider.notifier).poke(j.id);
      }
    }
  }

  /// True when [job] can be read again from where it came from.
  static bool canResync(ImportJob job) {
    final s = job.sourceUrl;
    if (s == null || s.isEmpty) return false;
    return parseMusicLink(s) != null || job.origin == OnlineService.file;
  }
}

final importFlowProvider = Provider<ImportFlow>(ImportFlow.new);

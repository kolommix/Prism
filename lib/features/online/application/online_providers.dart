import '../../../core/diagnostics/error_log.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/track.dart';
import '../../player/application/player_providers.dart';
import '../data/import_repository.dart';
import '../data/network_check.dart';
import '../data/remote_track_store.dart';
import '../data/stream_cache.dart';
import '../domain/external_track.dart';
import '../domain/online_error.dart';
import '../services/music_service_module.dart';
import 'import_downloader.dart';
import 'match_service.dart';
import 'online_hub.dart';
import '../../../l10n/l10n.dart';

final onlineHubProvider = Provider<OnlineHub>((ref) => throw UnimplementedError('override in bootstrap'));

/// Re-emits whenever modules / flags / accounts change.
final onlineRevisionProvider = StreamProvider<int>((ref) {
  final hub = ref.watch(onlineHubProvider);
  return hub.revisions;
});

final streamCacheProvider = Provider<StreamCache>((ref) => ref.watch(onlineHubProvider).cache);

final remoteTrackStoreProvider = Provider<RemoteTrackStore>((ref) => RemoteTrackStore(ref.watch(appDatabaseProvider)));

final importRepositoryProvider = Provider<ImportRepository>((ref) => ImportRepository(ref.watch(appDatabaseProvider)));

final matchServiceProvider = Provider<MatchService>((ref) {
  final hub = ref.watch(onlineHubProvider);
  final repo = ref.watch(libraryRepositoryProvider);
  return MatchService(
    localSearch: (q) => repo.search(q, limit: 40),
    localByUri: repo.trackByUri,
    playable: () => hub.playable,
  );
});

/// Account of a service (null = not connected). Errors are kept per service.
final accountProvider = FutureProvider.family<AccountInfo?, OnlineService>((ref, s) async {
  ref.watch(onlineRevisionProvider);
  final m = ref.watch(onlineHubProvider).module(s);
  if (m == null || !m.features.contains(ModuleFeature.login)) return null;
  return m.account();
});

final importJobsProvider = StreamProvider<List<ImportJob>>((ref) => ref.watch(importRepositoryProvider).watchJobs());

final importJobProvider = StreamProvider.family<ImportJob?, int>(
  (ref, id) => ref.watch(importRepositoryProvider).watchJob(id),
);

/// Songs waiting for a yes or no, across all imports.
final importReviewProvider = StreamProvider<List<ImportItem>>((ref) => ref.watch(importRepositoryProvider).watchReview());

final importItemsProvider = StreamProvider.family<List<ImportItem>, int>(
  (ref, id) => ref.watch(importRepositoryProvider).watchItems(id),
);

/// Online part of the unified search: one entry per searchable service.
final onlineSearchProvider = FutureProvider.autoDispose.family<List<Track>, ({OnlineService service, String query})>((
  ref,
  key,
) async {
  ref.watch(onlineRevisionProvider);
  final q = key.query.trim();
  if (q.length < 2) return const [];
  // Debounce: typing fast must not burn API quota.
  var cancelled = false;
  ref.onDispose(() => cancelled = true);
  await Future<void>.delayed(const Duration(milliseconds: 450));
  if (cancelled) return const [];
  final m = ref.read(onlineHubProvider).module(key.service);
  if (m == null) throw OnlineException(OnlineErrorKind.disabled, service: key.service);
  return m.search(q, limit: 15);
});

/// Saves remote tracks (gives them ids) and plays them.
Future<void> playTracksAnywhere(WidgetRef ref, List<Track> tracks, {int startIndex = 0}) async {
  final saved = await ref.read(remoteTrackStoreProvider).ensureAll(tracks);
  await ref.read(playerControllerProvider).playTracks(saved, startIndex: startIndex);
}

// --------------------------------------------------------------- matching

/// How long an import waits before it tries again by itself after a service
/// refused or the connection dropped: longer every time, at most 30 minutes.
Duration importRetryDelay(int attempt) => Duration(minutes: const [2, 5, 10, 20, 30][attempt.clamp(0, 4)]);

class ImportRun {
  const ImportRun({required this.jobId, required this.done, required this.total, this.running = true});
  final int jobId;
  final int done;
  final int total;
  final bool running;
}

/// Runs matching for one import job at a time. Progress is saved per song,
/// so pausing, closing the app or losing the connection never loses work:
/// "Resume" continues with the songs still pending.
class ImportRunner extends Notifier<ImportRun?> {
  bool _stop = false;

  /// Two songs at a time: while one waits for an answer the next search is
  /// already queued. The YouTube extractor spaces its own searches, so this
  /// doesn't make them come faster than YouTube accepts.
  static const workers = 2;

  /// Tries of one song after a dropped connection before the import pauses.
  static const transientRetries = 2;
  static Duration transientWait = const Duration(seconds: 3);

  /// One timer per paused import: another import starting must not cancel
  /// the retry of this one (it used to, and the paused one never came back).
  final _retries = <int, Timer>{};
  final _attempts = <int, int>{};

  /// The import running now (set before anything is awaited) and the ones
  /// waiting for their turn.
  int? _current;
  final _queued = <int>[];

  /// While paused because a service can't be reached: a VPN switched on (or
  /// any other change of the connection) starts these imports again at once.
  final _waitingForNetwork = <int>{};
  NetworkWatch? _watching;
  NetworkWatch get _watch => _watching ??= ref.read(networkWatchFactoryProvider)();

  @override
  ImportRun? build() {
    ref.onDispose(() {
      for (final t in _retries.values) {
        t.cancel();
      }
      _watching?.stop();
    });
    return null;
  }

  bool isRunning(int jobId) => state?.jobId == jobId && state!.running;

  /// Stops the import running now (the next waiting one starts).
  void pause() {
    _stop = true;
    final id = _current;
    if (id != null) _retries.remove(id)?.cancel();
  }

  void _watchNetwork(int jobId) {
    _waitingForNetwork.add(jobId);
    _watch.start(() {
      final ids = List.of(_waitingForNetwork);
      _waitingForNetwork.clear();
      _watching?.stop();
      for (final id in ids) {
        _attempts.remove(id);
        unawaited(run(id));
      }
    });
  }

  Future<void> run(int jobId) async {
    _retries.remove(jobId)?.cancel();
    if (_waitingForNetwork.remove(jobId) && _waitingForNetwork.isEmpty) _watching?.stop();
    if (_current != null) {
      // Another import is matching: this one goes next, nothing is paused.
      if (_current != jobId && !_queued.contains(jobId)) _queued.add(jobId);
      return;
    }
    _current = jobId;
    try {
      await _run(jobId);
    } finally {
      _current = null;
      if (_queued.isNotEmpty) unawaited(run(_queued.removeAt(0)));
    }
  }

  Future<void> _run(int jobId) async {
    final repo = ref.read(importRepositoryProvider);
    final matcher = ref.read(matchServiceProvider);
    final store = ref.read(remoteTrackStoreProvider);
    _stop = false;
    await repo.setState(jobId, ImportJobState.matching);
    final queue = await repo.pendingItems(jobId);
    final total = queue.length;
    var done = 0;
    String? pauseMessage;
    var unreachable = false;
    final retries = <int, int>{};
    state = ImportRun(jobId: jobId, done: 0, total: total);

    Future<void> worker() async {
      while (queue.isNotEmpty && !_stop) {
        final item = queue.removeAt(0);
        try {
          final r = await matcher.match(item.wanted);
          final t = r.track == null ? null : await store.ensure(r.track!);
          await repo.saveMatch(item.id, trackId: t?.id, confidence: r.score.value, source: r.source, note: r.note, wanted: r.wanted);
          if (t != null && ref.read(onlineHubProvider).flags.importDownload) {
            ref.read(importDownloaderProvider.notifier).poke(jobId);
          }
        } on OnlineException catch (e) {
          final wait = e.retryAfter;
          final n = retries[item.id] = (retries[item.id] ?? 0) + 1;
          if (e.kind == OnlineErrorKind.rateLimited && wait != null && wait <= const Duration(seconds: 60) && n <= 3) {
            queue.insert(0, item);
            await Future<void>.delayed(wait);
            continue;
          }
          // One slow answer or dropped connection is common on a weak or
          // filtered network: try the song again a little later before the
          // whole import pauses.
          //
          // Unless the service doesn't answer from here at all (blocked on
          // this network, no VPN): then waiting for more timeouts only
          // keeps the user in the dark for minutes. Say so right away.
          final service = e.service;
          final blockedHere = e.kind == OnlineErrorKind.offline && service != null && !await ref.read(networkCheckProvider).reachable(service);
          if (!blockedHere && e.isTransient && n <= transientRetries && !_stop) {
            queue.insert(0, item);
            await Future<void>.delayed(transientWait * n);
            continue;
          }
          // Offline / rate limited / server down: stop, keep the song pending.
          queue.insert(0, item);
          unreachable = e.kind == OnlineErrorKind.offline;
          pauseMessage = (await ref.read(networkCheckProvider).explain(e)).message;
          ErrorLog.instance.failed('import paused', pauseMessage!, details: '${e.kind.name} · ${e.service?.name ?? '-'} · ${e.message}');
          _stop = true;
          break;
        } on Object catch (e, st) {
          // Unexpected – don't block the rest of the import on one song.
          ErrorLog.instance.record(e, st, where: 'import match', message: '${item.wanted.artist} - ${item.wanted.title}: $e');
          await repo.saveMatch(item.id, trackId: null, confidence: 0, note: l10n.error(e));
        }
        done++;
        state = ImportRun(jobId: jobId, done: done, total: total);
      }
    }

    // Songs reach the playlist as they are found, not at the end.
    var writing = false;
    final writer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (writing) return;
      writing = true;
      try {
        await repo.writePlaylist(jobId, finish: false);
      } on Object {
        // The final write below reports nothing either: the job page shows state.
      } finally {
        writing = false;
      }
    });
    try {
      await Future.wait([for (var i = 0; i < workers; i++) worker()]);
    } finally {
      writer.cancel();
    }
    while (writing) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    final left = (await repo.pendingItems(jobId)).length;
    final saved = await repo.writePlaylist(jobId, finish: false);
    if (left == 0 && saved != null) {
      await repo.writePlaylist(jobId);
    } else {
      await repo.setState(
        jobId,
        left == 0 ? ImportJobState.review : ImportJobState.paused,
        message: left == 0
            ? null
            : pauseMessage == null
            ? l10n.pausedSongsLeft(left)
            : '$pauseMessage ${l10n.importRetryIn(importRetryDelay(_attempts[jobId] ?? 0).inMinutes)}${unreachable ? ' ${l10n.importResumesOnNetworkChange}' : ''}',
      );
    }
    // A service said wait: go on by itself later, nobody has to press Resume.
    if (left > 0 && pauseMessage != null) {
      final attempt = _attempts[jobId] ?? 0;
      _attempts[jobId] = attempt + 1;
      _retries[jobId] = Timer(importRetryDelay(attempt), () => unawaited(run(jobId)));
      if (unreachable) _watchNetwork(jobId);
    } else if (left == 0) {
      _attempts.remove(jobId);
    }
    state = ImportRun(jobId: jobId, done: done, total: total, running: false);
    if (ref.read(onlineHubProvider).flags.importDownload) ref.read(importDownloaderProvider.notifier).poke(jobId);
  }
}

final importRunnerProvider = NotifierProvider<ImportRunner, ImportRun?>(ImportRunner.new);

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/track.dart';
import '../../player/application/player_providers.dart';
import '../data/import_repository.dart';
import '../data/remote_track_store.dart';
import '../data/stream_cache.dart';
import '../domain/external_track.dart';
import '../domain/online_error.dart';
import '../services/music_service_module.dart';
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

  /// How many songs are matched in parallel (keeps services happy).
  static const workers = 2;

  @override
  ImportRun? build() => null;

  bool isRunning(int jobId) => state?.jobId == jobId && state!.running;

  void pause() => _stop = true;

  Future<void> run(int jobId) async {
    if (state?.running ?? false) {
      if (state!.jobId == jobId) return;
      pause();
      while (state?.running ?? false) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    final repo = ref.read(importRepositoryProvider);
    final matcher = ref.read(matchServiceProvider);
    final store = ref.read(remoteTrackStoreProvider);
    _stop = false;
    await repo.setState(jobId, ImportJobState.matching);
    final queue = await repo.pendingItems(jobId);
    final total = queue.length;
    var done = 0;
    String? pauseMessage;
    final retries = <int, int>{};
    state = ImportRun(jobId: jobId, done: 0, total: total);

    Future<void> worker() async {
      while (queue.isNotEmpty && !_stop) {
        final item = queue.removeAt(0);
        try {
          final r = await matcher.match(item.wanted);
          final t = r.track == null ? null : await store.ensure(r.track!);
          await repo.saveMatch(item.id, trackId: t?.id, confidence: r.score.value, source: r.source, note: r.note);
        } on OnlineException catch (e) {
          final wait = e.retryAfter;
          final n = retries[item.id] = (retries[item.id] ?? 0) + 1;
          if (e.kind == OnlineErrorKind.rateLimited && wait != null && wait <= const Duration(seconds: 60) && n <= 3) {
            queue.insert(0, item);
            await Future<void>.delayed(wait);
            continue;
          }
          // Offline / rate limited / server down: stop, keep the song pending.
          pauseMessage = e.message;
          _stop = true;
          break;
        } on Object catch (e) {
          // Unexpected – don't block the rest of the import on one song.
          await repo.saveMatch(item.id, trackId: null, confidence: 0, note: l10n.error(e));
        }
        done++;
        state = ImportRun(jobId: jobId, done: done, total: total);
        // Be gentle with the services between searches.
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }

    await Future.wait([for (var i = 0; i < workers; i++) worker()]);
    final left = (await repo.pendingItems(jobId)).length;
    await repo.setState(
      jobId,
      left == 0 ? ImportJobState.review : ImportJobState.paused,
      message: left == 0 ? null : (pauseMessage ?? l10n.pausedSongsLeft(left)),
    );
    state = ImportRun(jobId: jobId, done: done, total: total, running: false);
  }
}

final importRunnerProvider = NotifierProvider<ImportRunner, ImportRun?>(ImportRunner.new);

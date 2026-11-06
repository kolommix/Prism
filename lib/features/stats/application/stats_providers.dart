import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/track.dart';
import '../../player/application/player_providers.dart';
import '../data/stats_repository.dart';
import '../domain/deep_stats.dart';
import '../domain/listen_accumulator.dart';
import '../domain/listening_stats.dart';
import '../domain/smart_playlist.dart';
import '../../../l10n/l10n.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) => StatsRepository(ref.watch(appDatabaseProvider)));

final smartPlaylistsProvider =
    StreamProvider<List<SmartPlaylist>>((ref) => ref.watch(statsRepositoryProvider).watchSmartPlaylists());

final smartTracksProvider = StreamProvider.family<List<Track>, SmartPlaylist>(
  (ref, p) => ref.watch(statsRepositoryProvider).watchSmartTracks(p),
);

/// Periods on the stats screen.
enum StatsPeriod {
  week,
  month,
  year,
  allTime;

  String get label => switch (this) {
        StatsPeriod.week => l10n.week,
        StatsPeriod.month => l10n.month,
        StatsPeriod.year => l10n.year,
        StatsPeriod.allTime => l10n.allTime,
      };
  /// Start of the period containing [now]; the week starts on Monday.
  DateTime startOf(DateTime now) => switch (this) {
        StatsPeriod.week => DateTime(now.year, now.month, now.day - (now.weekday - 1)),
        StatsPeriod.month => DateTime(now.year, now.month),
        StatsPeriod.year => DateTime(now.year),
        StatsPeriod.allTime => DateTime(2000),
      };

  /// Start of the period just before; null when there is none.
  DateTime? previousStart(DateTime now) => switch (this) {
        StatsPeriod.week => startOf(now).subtract(const Duration(days: 7)),
        StatsPeriod.month => DateTime(now.year, now.month - 1),
        StatsPeriod.year => DateTime(now.year - 1),
        StatsPeriod.allTime => null,
      };
}

final statsProvider = FutureProvider.family<ListeningStats, StatsPeriod>((ref, period) {
  ref.watch(_playCountProvider); // refresh when new plays are recorded
  final now = DateTime.now();
  return ref.watch(statsRepositoryProvider).stats(period.startOf(now), now.add(const Duration(minutes: 1)));
});

/// The whole history, once per change of the play count.
final allPlaysProvider = FutureProvider<List<PlayRecord>>((ref) {
  ref.watch(_playCountProvider);
  return ref.watch(statsRepositoryProvider).plays(DateTime(2000), DateTime.now().add(const Duration(minutes: 1)));
});

/// The Overview, Top and History tabs for one period.
final deepStatsProvider = FutureProvider.family<DeepStats, StatsPeriod>((ref, period) async {
  final all = await ref.watch(allPlaysProvider.future);
  final now = DateTime.now();
  return computeDeepStats(
    all,
    from: period.startOf(now),
    to: now.add(const Duration(minutes: 1)),
    now: now,
    previousFrom: period.previousStart(now),
  );
});

/// Day -> listening over the whole history, for the calendar.
final allDaysProvider = FutureProvider<Map<DateTime, Duration>>((ref) async {
  final all = await ref.watch(allPlaysProvider.future);
  final out = <DateTime, Duration>{};
  for (final r in all) {
    final l = r.playedAt.toLocal();
    final d = DateTime(l.year, l.month, l.day);
    out[d] = (out[d] ?? Duration.zero) + r.listened;
  }
  return out;
});

/// Numbers about the library itself.
final libraryStatsProvider = FutureProvider<LibraryStats>((ref) async {
  final repo = ref.watch(libraryRepositoryProvider);
  final tracks = await repo.watchTracks().first;
  final plays = await ref.watch(allPlaysProvider.future);
  final favorites = await repo.watchFavoriteIds().first;
  return computeLibraryStats(tracks, playedIds: {for (final p in plays) p.track.id}, favoriteIds: favorites);
});

final _playCountProvider = StreamProvider<int>((ref) => ref.watch(statsRepositoryProvider).watchPlayCount());

/// Records plays: listens to the current track and playing state and writes
/// a row once a listen qualifies (≥ 30 s or half the track).
final playRecorderProvider = Provider<void>((ref) {
  final repo = ref.watch(statsRepositoryProvider);
  final player = ref.watch(playerControllerProvider);
  final acc = ListenAccumulator();
  void save((int, DateTime, Duration)? done) {
    if (done != null) unawaited(repo.recordPlay(done.$1, done.$2, done.$3));
  }

  final cur = player.current;
  acc.setTrack(cur?.id, cur?.duration ?? Duration.zero, DateTime.now());
  var lastId = cur?.id;
  var lastPos = Duration.zero;
  final subs = [
    player.queueStream.listen((q) {
      final t = q.current;
      if (t?.id == lastId) return;
      lastId = t?.id;
      save(acc.setTrack(t?.id, t?.duration ?? Duration.zero, DateTime.now()));
    }),
    player.stateStream.listen((s) {
      // Position jumped back to the start of the same track (repeat-one).
      if (s.playing && lastPos > const Duration(seconds: 10) && s.position < const Duration(seconds: 2)) {
        save(acc.restart(DateTime.now()));
      }
      lastPos = s.position;
      acc.update(playing: s.playing, now: DateTime.now());
    }),
  ];
  ref.onDispose(() {
    save(acc.flush(DateTime.now()));
    for (final s in subs) {
      s.cancel();
    }
  });
});

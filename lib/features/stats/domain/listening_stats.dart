import 'dart:math' as math;

import '../../library/domain/track.dart';

/// One recorded listen joined with its track.
class PlayRecord {
  const PlayRecord(this.track, this.playedAt, this.listened);
  final Track track;
  final DateTime playedAt;
  final Duration listened;
}

class Ranked<T> {
  const Ranked(this.item, this.plays, this.listened);
  final T item;
  final int plays;
  final Duration listened;
}

/// Everything the "Wrapped" screen shows for one period.
class ListeningStats {
  const ListeningStats({
    required this.from,
    required this.to,
    required this.plays,
    required this.listened,
    required this.topTracks,
    required this.topArtists,
    required this.topGenres,
    required this.byHour,
    required this.activeDays,
    required this.longestStreakDays,
    required this.distinctTracks,
  });

  final DateTime from, to;
  final int plays;
  final Duration listened;
  final List<Ranked<Track>> topTracks;
  final List<Ranked<String>> topArtists;
  final List<Ranked<String>> topGenres;

  /// Plays per hour of day (0..23).
  final List<int> byHour;
  final int activeDays;
  final int longestStreakDays;
  final int distinctTracks;

  bool get isEmpty => plays == 0;

  /// Hour with the most plays.
  int get peakHour => byHour.isEmpty ? 0 : byHour.indexOf(byHour.reduce(math.max));
}

/// Pure aggregation (unit tested). [records] may be in any order.
ListeningStats computeStats(List<PlayRecord> records, {required DateTime from, required DateTime to, int top = 5}) {
  final tracks = <int, (Track, int, Duration)>{};
  final artists = <String, (int, Duration)>{};
  final genres = <String, (int, Duration)>{};
  final byHour = List.filled(24, 0);
  final days = <DateTime>{};
  var listened = Duration.zero;

  for (final r in records) {
    listened += r.listened;
    final t = tracks[r.track.id];
    tracks[r.track.id] = (r.track, (t?.$2 ?? 0) + 1, (t?.$3 ?? Duration.zero) + r.listened);
    final artist = r.track.displayArtist;
    final a = artists[artist];
    artists[artist] = ((a?.$1 ?? 0) + 1, (a?.$2 ?? Duration.zero) + r.listened);
    if (r.track.genre.trim().isNotEmpty) {
      final genre = r.track.genre.trim();
      final g = genres[genre];
      genres[genre] = ((g?.$1 ?? 0) + 1, (g?.$2 ?? Duration.zero) + r.listened);
    }
    final local = r.playedAt.toLocal();
    byHour[local.hour]++;
    days.add(DateTime(local.year, local.month, local.day));
  }

  int cmp(int playsA, Duration lA, int playsB, Duration lB) =>
      playsB != playsA ? playsB.compareTo(playsA) : lB.compareTo(lA);

  final topTracks = tracks.values.map((e) => Ranked(e.$1, e.$2, e.$3)).toList()
    ..sort((a, b) => cmp(a.plays, a.listened, b.plays, b.listened));
  final topArtists = artists.entries.map((e) => Ranked(e.key, e.value.$1, e.value.$2)).toList()
    ..sort((a, b) => cmp(a.plays, a.listened, b.plays, b.listened));
  final topGenres = genres.entries.map((e) => Ranked(e.key, e.value.$1, e.value.$2)).toList()
    ..sort((a, b) => cmp(a.plays, a.listened, b.plays, b.listened));

  // Longest run of consecutive calendar days with at least one play.
  final sortedDays = days.toList()..sort();
  var longest = sortedDays.isEmpty ? 0 : 1, run = 1;
  for (var i = 1; i < sortedDays.length; i++) {
    final gap = DateTime.utc(sortedDays[i].year, sortedDays[i].month, sortedDays[i].day)
        .difference(DateTime.utc(sortedDays[i - 1].year, sortedDays[i - 1].month, sortedDays[i - 1].day))
        .inDays;
    run = gap == 1 ? run + 1 : 1;
    longest = math.max(longest, run);
  }

  return ListeningStats(
    from: from,
    to: to,
    plays: records.length,
    listened: listened,
    topTracks: topTracks.take(top).toList(),
    topArtists: topArtists.take(top).toList(),
    topGenres: topGenres.take(top).toList(),
    byHour: byHour,
    activeDays: days.length,
    longestStreakDays: longest,
    distinctTracks: tracks.length,
  );
}

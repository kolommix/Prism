import 'dart:math' as math;

import '../../library/domain/track.dart';
import 'listening_stats.dart';
import '../../../l10n/l10n.dart';

/// Parts of the day, in the order they are shown.
enum DayPart {
  morning,
  afternoon,
  evening,
  night;

  String get label => switch (this) {
        DayPart.morning => l10n.morning,
        DayPart.afternoon => l10n.afternoon,
        DayPart.evening => l10n.evening,
        DayPart.night => l10n.night,
      };

  String get hours => switch (this) {
        DayPart.morning => l10n.x5To12,
        DayPart.afternoon => l10n.x12To18,
        DayPart.evening => l10n.x18To23,
        DayPart.night => l10n.x23To5,
      };
  static DayPart of(int hour) => switch (hour) {
        >= 5 && < 12 => morning,
        >= 12 && < 18 => afternoon,
        >= 18 && < 23 => evening,
        _ => night,
      };
}

/// One bar on the activity chart: a day, or a month for long periods.
class ActivityBar {
  const ActivityBar(this.start, this.listened, this.plays);
  final DateTime start;
  final Duration listened;
  final int plays;
}

/// A stretch of listening without a long break.
class ListeningSession {
  const ListeningSession(this.start, this.end, this.listened, this.plays);
  final DateTime start, end;
  final Duration listened;
  final int plays;
}

/// Everything on the Overview, Top and History tabs for one period.
class DeepStats {
  const DeepStats({
    required this.base,
    required this.previousListened,
    required this.previousPlays,
    required this.topTracks,
    required this.topArtists,
    required this.topAlbums,
    required this.newSongs,
    required this.newSongPlays,
    required this.newArtists,
    required this.currentStreak,
    required this.activity,
    required this.byMonth,
    required this.weekHour,
    required this.dayParts,
    required this.weekendShare,
    required this.sessions,
    required this.longestSession,
    required this.biggestDay,
    required this.onRepeat,
    required this.completion,
    required this.decades,
    required this.topArtistShare,
    required this.oneHitWonders,
    required this.recent,
  });

  final ListeningStats base;

  /// The same length of time just before this period (null: nothing to compare).
  final Duration? previousListened;
  final int? previousPlays;

  final List<Ranked<Track>> topTracks;
  final List<Ranked<String>> topArtists;

  /// Album name, artist.
  final List<Ranked<(String, String)>> topAlbums;

  /// First ever played in this period.
  final int newSongs;

  /// Plays in the period of songs first heard in the period. The rest of the
  /// plays are repeats of songs you already knew.
  final int newSongPlays;
  final int newArtists;

  /// Days in a row up to today (or yesterday: today isn't over yet).
  final int currentStreak;

  /// Chart bars, oldest first, with empty days included.
  final List<ActivityBar> activity;

  /// Whole-history calendar is drawn from this: day -> listening.
  final Map<DateTime, Duration> byMonth;

  /// Minutes per weekday (0 = Monday) × hour: `[day * 24 + hour]`.
  final List<double> weekHour;
  final Map<DayPart, Duration> dayParts;

  /// 0..1 of listening time on Saturdays and Sundays.
  final double weekendShare;
  final int sessions;
  final ListeningSession? longestSession;

  /// The day with the most listening.
  final (DateTime, Duration)? biggestDay;

  /// The song played most in one single day: (track, day, times).
  final (Track, DateTime, int)? onRepeat;

  /// 0..1 how much of a song you hear on average (songs with a known length).
  final double? completion;

  /// Decade (1990, 2000…) -> listening.
  final Map<int, Duration> decades;

  /// 0..1 of plays that went to the top artist.
  final double topArtistShare;

  /// Songs played exactly once in this period.
  final int oneHitWonders;

  /// Newest first, at most 100.
  final List<PlayRecord> recent;

  Duration get averagePerActiveDay =>
      base.activeDays == 0 ? Duration.zero : Duration(seconds: base.listened.inSeconds ~/ base.activeDays);

  Duration get averageSession => sessions == 0 ? Duration.zero : Duration(seconds: base.listened.inSeconds ~/ sessions);

  /// Change vs the period before, e.g. +0.25. Null when there's no comparison.
  double? get listenedChange {
    final p = previousListened;
    if (p == null || p == Duration.zero) return null;
    return (base.listened.inSeconds - p.inSeconds) / p.inSeconds;
  }

  double? get playsChange {
    final p = previousPlays;
    if (p == null || p == 0) return null;
    return (base.plays - p) / p;
  }
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// A new listening session starts after this much silence.
const sessionGap = Duration(minutes: 30);

/// Pure aggregation (unit tested). [all] is the whole play history, in any
/// order; the period is `[from, to)`. [previousFrom] null = no comparison.
DeepStats computeDeepStats(
  List<PlayRecord> all, {
  required DateTime from,
  required DateTime to,
  required DateTime now,
  DateTime? previousFrom,
  int top = 50,
}) {
  final sorted = [...all]..sort((a, b) => a.playedAt.compareTo(b.playedAt));
  final inPeriod = [
    for (final r in sorted)
      if (!r.playedAt.isBefore(from) && r.playedAt.isBefore(to)) r,
  ];
  final base = computeStats(inPeriod, from: from, to: to, top: top);

  // Compare with the same length of time just before.
  Duration? previousListened;
  int? previousPlays;
  if (previousFrom != null) {
    var listened = Duration.zero, plays = 0;
    for (final r in sorted) {
      if (!r.playedAt.isBefore(previousFrom) && r.playedAt.isBefore(from)) {
        listened += r.listened;
        plays++;
      }
    }
    previousListened = listened;
    previousPlays = plays;
  }

  // First listens ever.
  final seenTracks = <int>{}, seenArtists = <String>{};
  final newIds = <int>{};
  var newSongs = 0, newArtists = 0, newSongPlays = 0;
  for (final r in sorted) {
    if (!r.playedAt.isBefore(to)) break;
    final inside = !r.playedAt.isBefore(from);
    if (seenTracks.add(r.track.id) && inside) {
      newSongs++;
      newIds.add(r.track.id);
    }
    if (inside && newIds.contains(r.track.id)) newSongPlays++;
    if (seenArtists.add(r.track.displayArtist) && inside) newArtists++;
  }

  // Current streak counts back from today over the whole history.
  final allDays = {for (final r in sorted) _day(r.playedAt.toLocal())};
  var streak = 0;
  var cursor = _day(now);
  if (!allDays.contains(cursor)) cursor = _day(cursor.subtract(const Duration(hours: 12)));
  while (allDays.contains(cursor)) {
    streak++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }

  // Albums, per day, per week × hour, day parts, weekend, decades, sessions…
  final albums = <(String, String), (int, Duration)>{};
  final perDay = <DateTime, (int, Duration)>{};
  final weekHour = List<double>.filled(7 * 24, 0);
  final parts = {for (final p in DayPart.values) p: Duration.zero};
  final decades = <int, Duration>{};
  final perTrack = <int, int>{};
  final perTrackDay = <(int, DateTime), int>{};
  final tracksById = <int, Track>{};
  var weekend = Duration.zero;
  double heardShare = 0;
  var heardCount = 0;
  final sessions = <ListeningSession>[];
  DateTime? sStart, sEnd;
  var sListened = Duration.zero, sPlays = 0;

  void closeSession() {
    if (sStart != null) sessions.add(ListeningSession(sStart!, sEnd!, sListened, sPlays));
    sStart = null;
    sListened = Duration.zero;
    sPlays = 0;
  }

  for (final r in inPeriod) {
    final local = r.playedAt.toLocal();
    final t = r.track;
    tracksById[t.id] = t;
    if (t.album.isNotEmpty) {
      final key = (t.album, t.displayArtist);
      final a = albums[key];
      albums[key] = ((a?.$1 ?? 0) + 1, (a?.$2 ?? Duration.zero) + r.listened);
    }
    final d = _day(local);
    final p = perDay[d];
    perDay[d] = ((p?.$1 ?? 0) + 1, (p?.$2 ?? Duration.zero) + r.listened);
    weekHour[(local.weekday - 1) * 24 + local.hour] += r.listened.inSeconds / 60;
    final part = DayPart.of(local.hour);
    parts[part] = parts[part]! + r.listened;
    if (local.weekday >= DateTime.saturday) weekend += r.listened;
    final year = t.year;
    if (year != null && year > 1000) {
      final decade = year ~/ 10 * 10;
      decades[decade] = (decades[decade] ?? Duration.zero) + r.listened;
    }
    perTrack[t.id] = (perTrack[t.id] ?? 0) + 1;
    final td = (t.id, d);
    perTrackDay[td] = (perTrackDay[td] ?? 0) + 1;
    if (t.durationMs > 0) {
      heardShare += math.min(1.0, r.listened.inMilliseconds / t.durationMs);
      heardCount++;
    }
    // playedAt is when the listen was recorded, about when it ended.
    final began = r.playedAt.subtract(r.listened);
    if (sEnd != null && began.difference(sEnd) > sessionGap) closeSession();
    sStart ??= began;
    sEnd = r.playedAt;
    sListened += r.listened;
    sPlays++;
  }
  closeSession();

  ListeningSession? longest;
  for (final s in sessions) {
    if (longest == null || s.listened > longest.listened) longest = s;
  }

  (DateTime, Duration)? biggest;
  perDay.forEach((d, v) {
    if (biggest == null || v.$2 > biggest!.$2) biggest = (d, v.$2);
  });

  (Track, DateTime, int)? repeat;
  perTrackDay.forEach((k, n) {
    if (n >= 2 && (repeat == null || n > repeat!.$3)) repeat = (tracksById[k.$1]!, k.$2, n);
  });

  final topAlbums = albums.entries.map((e) => Ranked(e.key, e.value.$1, e.value.$2)).toList()
    ..sort((a, b) => b.plays != a.plays ? b.plays.compareTo(a.plays) : b.listened.compareTo(a.listened));

  return DeepStats(
    base: base,
    previousListened: previousListened,
    previousPlays: previousPlays,
    topTracks: base.topTracks,
    topArtists: base.topArtists,
    topAlbums: topAlbums.take(top).toList(),
    newSongs: newSongs,
    newSongPlays: newSongPlays,
    newArtists: newArtists,
    currentStreak: streak,
    activity: _activityBars(perDay, from: from, to: to, now: now, firstPlay: inPeriod.firstOrNull?.playedAt.toLocal()),
    byMonth: {for (final e in perDay.entries) e.key: e.value.$2},
    weekHour: weekHour,
    dayParts: parts,
    weekendShare: base.listened == Duration.zero ? 0 : weekend.inSeconds / base.listened.inSeconds,
    sessions: sessions.length,
    longestSession: longest,
    biggestDay: biggest,
    onRepeat: repeat,
    completion: heardCount == 0 ? null : heardShare / heardCount,
    decades: decades,
    topArtistShare: base.plays == 0 || base.topArtists.isEmpty ? 0 : base.topArtists.first.plays / base.plays,
    oneHitWonders: perTrack.values.where((n) => n == 1).length,
    recent: [for (final r in inPeriod.reversed.take(100)) r],
  );
}

/// Days for up to two months, months beyond that.
List<ActivityBar> _activityBars(
  Map<DateTime, (int, Duration)> perDay, {
  required DateTime from,
  required DateTime to,
  required DateTime now,
  DateTime? firstPlay,
}) {
  if (firstPlay == null) return const [];
  final last = _day(to.isAfter(now) ? now : to);
  // "All time" starts in the year 2000: begin at the first listen instead.
  final first = from.year <= 2000 ? _day(firstPlay) : _day(from);
  final days = DateTime.utc(last.year, last.month, last.day).difference(DateTime.utc(first.year, first.month, first.day)).inDays;
  if (days <= 62) {
    return [
      for (var i = 0; i <= days; i++)
        () {
          final d = DateTime(first.year, first.month, first.day + i);
          final v = perDay[d];
          return ActivityBar(d, v?.$2 ?? Duration.zero, v?.$1 ?? 0);
        }(),
    ];
  }
  final months = <DateTime, (int, Duration)>{};
  perDay.forEach((d, v) {
    final m = DateTime(d.year, d.month);
    final old = months[m];
    months[m] = ((old?.$1 ?? 0) + v.$1, (old?.$2 ?? Duration.zero) + v.$2);
  });
  final out = <ActivityBar>[];
  var m = DateTime(first.year, first.month);
  final end = DateTime(last.year, last.month);
  while (!m.isAfter(end)) {
    final v = months[m];
    out.add(ActivityBar(m, v?.$2 ?? Duration.zero, v?.$1 ?? 0));
    m = DateTime(m.year, m.month + 1);
  }
  return out;
}

/// The library itself, not the listening.
class LibraryStats {
  const LibraryStats({
    required this.songs,
    required this.artists,
    required this.albums,
    required this.totalLength,
    required this.favorites,
    required this.neverPlayed,
    required this.formats,
    required this.decades,
    required this.genres,
    required this.longest,
    required this.shortest,
    required this.withCover,
    required this.withTags,
  });

  final int songs, artists, albums, favorites, neverPlayed, withCover, withTags;
  final Duration totalLength;

  /// File type -> songs, most first.
  final List<MapEntry<String, int>> formats;

  /// Decade -> songs, oldest first.
  final List<MapEntry<int, int>> decades;

  /// Genre -> songs, most first.
  final List<MapEntry<String, int>> genres;
  final Track? longest, shortest;

  Duration get averageLength => songs == 0 ? Duration.zero : Duration(seconds: totalLength.inSeconds ~/ songs);
}

LibraryStats computeLibraryStats(List<Track> tracks, {required Set<int> playedIds, required Set<int> favoriteIds}) {
  final artists = <String>{}, albums = <String>{};
  final formats = <String, int>{};
  final decades = <int, int>{};
  final genres = <String, int>{};
  var total = Duration.zero;
  Track? longest, shortest;
  var never = 0, covers = 0, tagged = 0;
  for (final t in tracks) {
    artists.add(t.displayArtist);
    if (t.album.isNotEmpty) albums.add('${t.album}|${t.displayArtist}');
    final dot = t.uri.lastIndexOf('.');
    final ext = dot >= 0 && t.uri.length - dot <= 6 ? t.uri.substring(dot + 1).toLowerCase() : 'other';
    formats[ext] = (formats[ext] ?? 0) + 1;
    final y = t.year;
    if (y != null && y > 1000) decades[y ~/ 10 * 10] = (decades[y ~/ 10 * 10] ?? 0) + 1;
    final g = t.genre.trim();
    if (g.isNotEmpty) genres[g] = (genres[g] ?? 0) + 1;
    total += t.duration;
    if (t.durationMs > 0) {
      if (longest == null || t.durationMs > longest.durationMs) longest = t;
      if (shortest == null || t.durationMs < shortest.durationMs) shortest = t;
    }
    if (!playedIds.contains(t.id)) never++;
    if (t.artworkPath != null) covers++;
    if (t.artist.isNotEmpty && t.album.isNotEmpty) tagged++;
  }
  List<MapEntry<String, int>> byCount(Map<String, int> m) =>
      m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return LibraryStats(
    songs: tracks.length,
    artists: artists.length,
    albums: albums.length,
    totalLength: total,
    favorites: favoriteIds.length,
    neverPlayed: never,
    formats: byCount(formats),
    decades: decades.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    genres: byCount(genres),
    longest: longest,
    shortest: shortest,
    withCover: covers,
    withTags: tagged,
  );
}

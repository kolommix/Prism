import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/smooth_scroll.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/artwork.dart';
import '../../library/presentation/widgets/library_widgets.dart';
import '../../player/application/player_providers.dart';
import '../application/stats_providers.dart';
import '../domain/deep_stats.dart';
import '../domain/listening_stats.dart';
import 'stats_charts.dart';
import '../../../l10n/l10n.dart';

String longTime(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h == 0) return l10n.minutesValue(m);
  return m == 0 ? l10n.hoursValue(h) : l10n.hoursMinutesValue(h, m);
}

String _shortDate(DateTime d) => dateShort(d);

String _ago(DateTime t, DateTime now) {
  final d = now.difference(t);
  if (d.inMinutes < 1) return l10n.justNow;
  if (d.inMinutes < 60) return l10n.minAgo(d.inMinutes);
  if (d.inHours < 24) return l10n.hAgo(d.inHours);
  final hm = timeShort(t);
  if (d.inDays < 7) return '${weekdayShort(t.weekday)} $hm';
  return '${_shortDate(t)} $hm';
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.note});

  final String title;
  final String? note;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(note!, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.note, this.change});

  final String label;
  final String value;
  final String? note;

  /// e.g. +0.25; shown as "+25 %" with an arrow.
  final double? change;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final c = change;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 18,
            child: c != null
                ? Row(
                    children: [
                      Icon(c >= 0 ? Icons.north_east_rounded : Icons.south_east_rounded, size: 13, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          l10n.vsBefore(c >= 0 ? '+' : '', (c * 100).round()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  )
                : (note == null
                    ? null
                    : Text(note!, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
          ),
        ],
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) {
          final perRow = c.maxWidth >= 860 ? 4 : (c.maxWidth >= 520 ? 3 : 2);
          final w = (c.maxWidth - 10 * (perRow - 1)) / perRow;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [for (final x in children) SizedBox(width: w, child: x)],
          );
        },
      );
}

/// Overview tab: the numbers, when and how you listen.
class StatsOverview extends ConsumerWidget {
  const StatsOverview({super.key, required this.stats, required this.period});

  final DeepStats stats;
  final StatsPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = stats;
    final b = s.base;
    final now = DateTime.now();
    final bars = s.activity;
    final byDayChart = bars.length <= 62 && (bars.length < 2 || bars[1].start.day != 1 || bars[0].start.day != 1);
    final maxParts = s.dayParts.values.fold<int>(1, (m, d) => math.max(m, d.inSeconds));
    final maxDecade = s.decades.values.fold<int>(1, (m, d) => math.max(m, d.inSeconds));
    final decades = s.decades.entries.toList()..sort((x, y) => x.key.compareTo(y.key));
    final repeat = s.onRepeat;
    return SmoothListView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset(context)),
      children: [
        _Section(
          title: l10n.atAGlance,
          child: _Tiles(
            children: [
              _Tile(label: l10n.listeningTime, value: longTime(b.listened), change: s.listenedChange),
              _Tile(label: l10n.plays, value: '${b.plays}', change: s.playsChange),
              _Tile(label: l10n.differentSongs, value: '${b.distinctTracks}', note: l10n.playedOnlyOnce(s.oneHitWonders)),
              _Tile(label: l10n.newToYou, value: '${s.newSongs}', note: l10n.nNewArtists(s.newArtists)),
              _Tile(label: l10n.daysWithMusic, value: '${b.activeDays}', note: l10n.aboutADay(longTime(s.averagePerActiveDay))),
              _Tile(label: l10n.currentStreak, value: l10n.nDays(s.currentStreak), note: l10n.best(b.longestStreakDays)),
              _Tile(label: l10n.sessions, value: '${s.sessions}', note: l10n.aboutEach(longTime(s.averageSession))),
              _Tile(
                label: l10n.youHearOfASong,
                value: s.completion == null ? '–' : '${(s.completion! * 100).round()} %',
                note: l10n.onAverage,
              ),
            ],
          ),
        ),
        if (bars.isNotEmpty)
          _Section(
            title: byDayChart ? l10n.minutesPerDay : l10n.minutesPerMonth,
            child: BarChart(
              values: [for (final a in bars) a.listened.inSeconds / 60],
              tooltip: (i) {
                final a = bars[i];
                final when = byDayChart ? _shortDate(a.start) : monthYear(a.start);
                return l10n.min(when, a.listened.inMinutes);
              },
              axisLabel: (i) {
                final a = bars[i].start;
                if (byDayChart) {
                  final every = math.max(1, (bars.length / 6).ceil());
                  return i % every == 0 ? _shortDate(a) : null;
                }
                final every = math.max(1, (bars.length / 8).ceil());
                return i % every == 0 ? monthShort(a.month) : null;
              },
            ),
          ),
        _Section(
          title: l10n.yourWeek,
          note: l10n.darkerMeansMoreMinutesHoverFor,
          child: WeekHourHeatmap(minutes: s.weekHour),
        ),
        _Section(
          title: l10n.last6Months,
          child: Consumer(
            builder: (context, ref, _) => CalendarHeatmap(
              byDay: ref.watch(allDaysProvider).value ?? s.byMonth,
              today: DateTime(now.year, now.month, now.day),
            ),
          ),
        ),
        if (s.base.plays > 0)
          _Section(
            title: l10n.statsNewVsRepeat,
            note: l10n.statsNewVsRepeatNote(s.newSongs),
            child: ShareBars(
              rows: [
                (l10n.statsNewPlays, s.newSongPlays / s.base.plays, l10n.nPlays(s.newSongPlays)),
                (l10n.statsRepeatPlays, (s.base.plays - s.newSongPlays) / s.base.plays, l10n.nPlays(s.base.plays - s.newSongPlays)),
              ],
            ),
          ),
        LayoutBuilder(
          builder: (context, c) {
            final parts = _Section(
              title: l10n.timeOfDay,
              note: l10n.ofYourListeningIsOnWeekends((s.weekendShare * 100).round()),
              child: ShareBars(
                rows: [
                  for (final p in DayPart.values)
                    (p.label, s.dayParts[p]!.inSeconds / maxParts, longTime(s.dayParts[p]!)),
                ],
              ),
            );
            final era = _Section(
              title: l10n.musicByDecade,
              note: decades.isEmpty ? l10n.songsNeedAYearTagFor : l10n.howOldIsWhatYouPlay,
              child: decades.isEmpty
                  ? const SizedBox.shrink()
                  : ShareBars(
                      rows: [
                        for (final e in decades) (l10n.decade(e.key), e.value.inSeconds / maxDecade, longTime(e.value)),
                      ],
                    ),
            );
            if (c.maxWidth < 700) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [parts, era]);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: parts),
                const SizedBox(width: 32),
                Expanded(child: era),
              ],
            );
          },
        ),
        _Section(
          title: l10n.records,
          child: _Tiles(
            children: [
              if (s.longestSession != null)
                _Tile(
                  label: l10n.longestSession,
                  value: longTime(s.longestSession!.listened),
                  note: l10n.nSongsOnDate(s.longestSession!.plays, _shortDate(s.longestSession!.start)),
                ),
              if (s.biggestDay != null)
                _Tile(label: l10n.biggestDay, value: longTime(s.biggestDay!.$2), note: _shortDate(s.biggestDay!.$1)),
              if (repeat != null)
                _Tile(label: l10n.onRepeat(repeat.$1.title), value: l10n.nTimes(repeat.$3), note: l10n.xOn2(_shortDate(repeat.$2))),
              if (b.topArtists.isNotEmpty)
                _Tile(
                  label: l10n.loyalTo(b.topArtists.first.item),
                  value: '${(s.topArtistShare * 100).round()} %',
                  note: l10n.ofYourPlays,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Top tab: songs, artists, albums and genres, each long enough to explore.
class StatsTop extends ConsumerWidget {
  const StatsTop({super.key, required this.stats});

  final DeepStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = stats;
    final player = ref.read(playerControllerProvider);
    final tracks = [for (final r in s.topTracks.take(20)) r.item];
    Widget rank(int i) => SizedBox(
          width: 26,
          child: Text(
            '${i + 1}',
            textAlign: TextAlign.right,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        );
    String playsAndTime(int plays, Duration d) => '${l10n.nPlays(plays)} · ${longTime(d)}';
    return SmoothListView(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomInset(context)),
      children: [
        _listTitle(context, l10n.topSongs),
        for (final (i, r) in s.topTracks.take(20).indexed)
          ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [rank(i), const SizedBox(width: 10), Artwork(path: r.item.artworkPath, size: 42, seed: r.item.album)],
            ),
            title: Text(r.item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${r.item.displayArtist} · ${playsAndTime(r.plays, r.listened)}', maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => player.playTracks(tracks, startIndex: i),
          ),
        _listTitle(context, l10n.topArtists),
        for (final (i, r) in s.topArtists.take(15).indexed)
          ListTile(
            leading: Row(mainAxisSize: MainAxisSize.min, children: [rank(i)]),
            title: Text(r.item, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(playsAndTime(r.plays, r.listened)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.go(Routes.artist(r.item)),
          ),
        if (s.topAlbums.isNotEmpty) _listTitle(context, l10n.topAlbums),
        for (final (i, r) in s.topAlbums.take(15).indexed)
          ListTile(
            leading: Row(mainAxisSize: MainAxisSize.min, children: [rank(i)]),
            title: Text(r.item.$1, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text('${r.item.$2} · ${playsAndTime(r.plays, r.listened)}', maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.go(Routes.album(r.item.$1, r.item.$2)),
          ),
        if (s.base.topGenres.isNotEmpty) _listTitle(context, l10n.topGenres),
        for (final (i, r) in s.base.topGenres.take(10).indexed)
          ListTile(
            leading: Row(mainAxisSize: MainAxisSize.min, children: [rank(i)]),
            title: Text(r.item, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(playsAndTime(r.plays, r.listened)),
          ),
      ],
    );
  }

  Widget _listTitle(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
        child: Text(t, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      );
}

/// History tab: the last 100 listens.
class StatsHistory extends ConsumerWidget {
  const StatsHistory({super.key, required this.recent});

  final List<PlayRecord> recent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final scheme = Theme.of(context).colorScheme;
    final player = ref.read(playerControllerProvider);
    if (recent.isEmpty) return Center(child: Text(l10n.nothingHereYet));
    return SmoothListView(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomInset(context)),
      children: [
        for (final r in recent)
          ListTile(
            leading: Artwork(path: r.track.artworkPath, size: 42, seed: r.track.album),
            title: Text(r.track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(r.track.displayArtist, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_ago(r.playedAt.toLocal(), now), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                Text(longTime(r.listened), style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
            ),
            onTap: () => player.playTracks([r.track]),
          ),
      ],
    );
  }
}

/// Library tab: what you own, whatever you listened to.
class StatsLibrary extends ConsumerWidget {
  const StatsLibrary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(libraryStatsProvider);
    return stats.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (s) {
        final maxDecade = s.decades.fold<int>(1, (m, e) => math.max(m, e.value));
        final maxGenre = s.genres.fold<int>(1, (m, e) => math.max(m, e.value));
        final maxFormat = s.formats.fold<int>(1, (m, e) => math.max(m, e.value));
        String percent(int part) => s.songs == 0 ? '–' : '${(part / s.songs * 100).round()} %';
        final days = s.totalLength.inHours / 24;
        return SmoothListView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset(context)),
          children: [
            _Section(
              title: l10n.yourLibrary,
              child: _Tiles(
                children: [
                  _Tile(label: l10n.songs, value: '${s.songs}'),
                  _Tile(
                    label: l10n.totalLength,
                    value: longTime(s.totalLength),
                    note: days >= 1 ? l10n.daysNonstop(fmtNum(days, 1)) : null,
                  ),
                  _Tile(label: l10n.artists, value: '${s.artists}'),
                  _Tile(label: l10n.albums, value: '${s.albums}'),
                  _Tile(label: l10n.averageSong, value: longTime(s.averageLength)),
                  _Tile(label: l10n.favorites, value: '${s.favorites}', note: percent(s.favorites)),
                  _Tile(label: l10n.neverPlayed, value: '${s.neverPlayed}', note: percent(s.neverPlayed)),
                  _Tile(label: l10n.withACover, value: percent(s.withCover), note: l10n.fullyTagged(s.withTags)),
                ],
              ),
            ),
            if (s.longest != null)
              _Section(
                title: l10n.extremes,
                child: _Tiles(
                  children: [
                    _Tile(label: l10n.longest(s.longest!.title), value: longTime(s.longest!.duration), note: s.longest!.displayArtist),
                    _Tile(
                      label: l10n.shortest(s.shortest!.title),
                      value: l10n.secondsValue(s.shortest!.duration.inSeconds),
                      note: s.shortest!.displayArtist,
                    ),
                  ],
                ),
              ),
            if (s.formats.isNotEmpty)
              _Section(
                title: l10n.fileTypes,
                child: ShareBars(
                  rows: [for (final e in s.formats.take(8)) (e.key.toUpperCase(), e.value / maxFormat, '${e.value}')],
                ),
              ),
            if (s.genres.isNotEmpty)
              _Section(
                title: l10n.genres,
                child: ShareBars(rows: [for (final e in s.genres.take(12)) (e.key, e.value / maxGenre, '${e.value}')]),
              ),
            if (s.decades.isNotEmpty)
              _Section(
                title: l10n.decades,
                child: ShareBars(rows: [for (final e in s.decades) (l10n.decade(e.key), e.value / maxDecade, '${e.value}')]),
              ),
          ],
        );
      },
    );
  }
}

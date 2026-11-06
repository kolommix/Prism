import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/spring_button.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/widgets/artwork.dart';
import '../application/stats_providers.dart';
import '../domain/deep_stats.dart';
import '../domain/listening_stats.dart';
import 'stats_overview.dart';
import '../../../l10n/l10n.dart';

/// Listening stats: Overview, Top, History, Library and the Wrapped cards,
/// for one period (a week to all time).
class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 5, vsync: this);
  StatsPeriod _period = StatsPeriod.month;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 560;
    final picker = SegmentedButton<StatsPeriod>(
      segments: [for (final p in StatsPeriod.values) ButtonSegment(value: p, label: Text(p.label))],
      selected: {_period},
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      onSelectionChanged: (s) => setState(() => _period = s.first),
    );
    final deep = ref.watch(deepStatsProvider(_period));
    Widget withData(Widget Function(DeepStats) view) => deep.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (d) => d.base.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      l10n.noListensYetInThisPeriod,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : view(d),
        );
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.yourListening),
        actions: [
          if (!narrow) picker,
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(narrow ? 92 : 46),
          child: Column(
            children: [
              if (narrow) Padding(padding: const EdgeInsets.only(bottom: 6), child: picker),
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: l10n.overview),
                  Tab(text: l10n.xTop),
                  Tab(text: l10n.history),
                  Tab(text: l10n.xLibrary),
                  Tab(text: l10n.wrapped),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          withData((d) => StatsOverview(stats: d, period: _period)),
          withData((d) => StatsTop(stats: d)),
          withData((d) => StatsHistory(recent: d.recent)),
          const StatsLibrary(),
          WrappedCards(period: _period),
        ],
      ),
    );
  }
}

/// "Wrapped"-style cards to swipe through.
class WrappedCards extends ConsumerStatefulWidget {
  const WrappedCards({super.key, required this.period});

  final StatsPeriod period;

  @override
  ConsumerState<WrappedCards> createState() => _WrappedCardsState();
}

class _WrappedCardsState extends ConsumerState<WrappedCards> {
  final _pages = PageController(viewportFraction: 0.86);
  int _page = 0;

  /// Story mode: the cards turn by themselves.
  Timer? _story;
  static const _storyCardTime = Duration(seconds: 6);
  final _cardKeys = <int, GlobalKey>{};
  bool _saving = false;

  StatsPeriod get _period => widget.period;

  @override
  void didUpdateWidget(WrappedCards old) {
    super.didUpdateWidget(old);
    if (old.period != widget.period) {
      _page = 0;
      if (_pages.hasClients) _pages.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _story?.cancel();
    _pages.dispose();
    super.dispose();
  }

  void _toggleStory(int count) {
    if (_story != null) {
      setState(() {
        _story?.cancel();
        _story = null;
      });
      return;
    }
    setState(() {
      _story = Timer.periodic(_storyCardTime, (_) {
        if (!mounted) return;
        if (_page >= count - 1) {
          _toggleStory(count);
        } else {
          _go(1, count);
        }
      });
    });
  }

  /// The card on screen as a picture.
  Future<void> _saveImage() async {
    final key = _cardKeys[_page];
    final box = key?.currentContext?.findRenderObject();
    if (box is! RenderRepaintBoundary || _saving) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _saving = true);
    try {
      final image = await box.toImage(pixelRatio: 2.5);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;
      final saved = await FilePicker.saveFile(
        dialogTitle: l10n.statsSaveImage,
        fileName: 'prism-wrapped-${_period.name}-${_page + 1}.png',
        bytes: data.buffer.asUint8List(),
      );
      if (saved != null) messenger?.showSnackBar(SnackBar(content: Text(l10n.statsImageSaved)));
    } on Object catch (e) {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.exportFailed(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _go(int delta, int count) {
    final target = (_page + delta).clamp(0, count - 1);
    _pages.animateToPage(target, duration: context.motion.d(PrismMotion.long), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider(_period));
    return stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) {
          if (s.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(l10n.noListensYetInThisPeriod,
                    textAlign: TextAlign.center),
              ),
            );
          }
          final cards = _cards(s);
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.arrowRight): () => _go(1, cards.length),
              const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _go(-1, cards.length),
            },
            child: Focus(
              autofocus: true,
              child: Column(children: [
                Expanded(
                  child: ScrollConfiguration(
                    // Let mouse drags swipe the cards on desktop too.
                    behavior: ScrollConfiguration.of(context).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: cards.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, i) => AnimatedBuilder(
                        animation: _pages,
                        builder: (context, child) {
                          // Neighbouring cards shrink and fade a little.
                          final page = _pages.hasClients && _pages.position.haveDimensions ? _pages.page ?? 0 : 0.0;
                          final d = (page - i).abs().clamp(0.0, 1.0);
                          return Opacity(opacity: 1 - d * 0.4, child: Transform.scale(scale: 1 - d * 0.08, child: child));
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          child: RepaintBoundary(
                            key: _cardKeys.putIfAbsent(i, GlobalKey.new),
                            child: _Card(index: i, active: i == _page, child: cards[i]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, top: 4),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SpringIconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () => _go(-1, cards.length)),
                    for (var i = 0; i < cards.length; i++)
                      AnimatedContainer(
                        duration: context.motion.d(PrismMotion.short),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: i == _page ? 1 : 0.3),
                        ),
                      ),
                    SpringIconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () => _go(1, cards.length)),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: _story == null ? l10n.statsStoryPlay : l10n.pause,
                      icon: Icon(_story == null ? Icons.play_circle_outline_rounded : Icons.pause_circle_outline_rounded),
                      onPressed: () => _toggleStory(cards.length),
                    ),
                    IconButton(
                      tooltip: l10n.statsSaveImage,
                      icon: const Icon(Icons.image_outlined),
                      onPressed: _saving ? null : _saveImage,
                    ),
                  ]),
                ),
              ]),
            ),
          );
        },
      );
  }

  List<Widget> _cards(ListeningStats s) {
    final minutes = s.listened.inMinutes;
    final top = s.topTracks.firstOrNull;
    final hour = s.peakHour;
    final deep = ref.watch(deepStatsProvider(_period)).value;
    final hourLabel = switch (hour) {
      >= 5 && < 12 => l10n.aMorningListener,
      >= 12 && < 18 => l10n.anAfternoonListener,
      >= 18 && < 23 => l10n.anEveningListener,
      _ => l10n.aNightOwl,
    };
    return [
      _Hero(
        kicker: switch (_period) {
          StatsPeriod.week => l10n.thisWeekYouListenedFor,
          StatsPeriod.month => l10n.thisMonthYouListenedFor,
          StatsPeriod.year => l10n.thisYearYouListenedFor,
          StatsPeriod.allTime => l10n.inTotalYouListenedFor,
        },
        value: minutes,
        unit: l10n.statsMinutesUnit(minutes),
        footer: '${l10n.nPlays(s.plays)} · ${l10n.nDifferentSongs(s.distinctTracks)} · ${l10n.nDays(s.activeDays)}',
      ),
      if (top != null)
        _TopSong(track: top),
      if ((deep?.newSongs ?? 0) > 0)
        _Hero(
          kicker: l10n.statsWrappedNew,
          value: deep!.newSongs,
          unit: l10n.statsNewSongsUnit(deep.newSongs),
          footer: deep.newArtists > 0 ? l10n.nNewArtists(deep.newArtists) : l10n.statsNewPlays,
        ),
      _RankList(title: l10n.topArtists, items: [for (final a in s.topArtists) (a.item, a.plays)]),
      if (s.topGenres.isNotEmpty) _RankList(title: l10n.topGenres, items: [for (final g in s.topGenres) (g.item, g.plays)]),
      _Clock(byHour: s.byHour, label: l10n.youAreMostPlaysAround00(hourLabel, hour.toString().padLeft(2, '0'))),
      _Hero(
        kicker: l10n.longestListeningStreak,
        value: s.longestStreakDays,
        unit: l10n.statsDaysInARow(s.longestStreakDays),
        footer: l10n.daysInARowWithAt,
      ),
    ];
  }
}

/// Card frame: a dark sleeve (the same in every theme, so the white type
/// always reads), slides in when active.
class _Card extends StatelessWidget {
  const _Card({required this.index, required this.active, required this.child});
  final int index;
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: const Color(0xFF151517),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: AnimatedSlide(
        offset: active ? Offset.zero : const Offset(0, 0.04),
        duration: context.motion.d(PrismMotion.long),
        curve: PrismMotion.curve,
        child: AnimatedOpacity(
          opacity: active ? 1 : 0.6,
          duration: context.motion.d(PrismMotion.long),
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: Colors.white),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Stack(children: [
                Positioned.fill(child: child),
                // Says where a shared picture came from.
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Text('Prism', style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Big animated number.
class _Hero extends StatelessWidget {
  const _Hero({required this.kicker, required this.value, required this.unit, required this.footer});
  final String kicker;
  final int value;
  final String unit;
  final String footer;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(kicker, style: text.titleLarge?.copyWith(color: Colors.white70), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.toDouble()),
        duration: context.motion.d(const Duration(milliseconds: 1400)),
        curve: Curves.easeOutExpo,
        builder: (context, v, _) => Text(
          v.round().toString(),
          style: text.displayLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 96),
        ),
      ),
      Text(unit, style: text.headlineSmall?.copyWith(color: Colors.white)),
      const SizedBox(height: 24),
      Text(footer, style: text.bodyLarge?.copyWith(color: Colors.white70), textAlign: TextAlign.center),
    ]);
  }
}

class _TopSong extends StatelessWidget {
  const _TopSong({required this.track});
  final Ranked track;

  @override
  Widget build(BuildContext context) {
    final t = track.item;
    final text = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, c) => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(l10n.yourTopSong, style: text.titleLarge?.copyWith(color: Colors.white70)),
        const SizedBox(height: 20),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.6, end: 1),
          duration: context.motion.d(const Duration(milliseconds: 900)),
          curve: PrismMotion.curve,
          builder: (context, s, child) => Transform.scale(scale: s, child: child),
          child: Artwork(
            path: t.artworkPath,
            size: math.min(260, c.maxHeight * 0.45),
            borderRadius: BorderRadius.circular(context.shape.radius * 1.2),
            seed: t.album,
          ),
        ),
        const SizedBox(height: 20),
        Text(t.title,
            style: text.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        Text(t.displayArtist, style: text.titleMedium?.copyWith(color: Colors.white70)),
        const SizedBox(height: 12),
        Text('${l10n.nPlays(track.plays)} · ${l10n.minutesValue(track.listened.inMinutes)}', style: text.bodyLarge?.copyWith(color: Colors.white)),
      ]),
    );
  }
}

/// Ranked list with bars that grow in.
class _RankList extends StatelessWidget {
  const _RankList({required this.title, required this.items});
  final String title;
  final List<(String, int)> items;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final max = items.isEmpty ? 1 : items.map((e) => e.$2).reduce(math.max);
    return Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: text.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      const SizedBox(height: 24),
      for (final (i, (name, plays)) in items.indexed)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            SizedBox(width: 36, child: Text('${i + 1}', style: text.headlineSmall?.copyWith(color: Colors.white70))),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: text.titleMedium?.copyWith(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: plays / max),
                  duration: context.motion.d(Duration(milliseconds: 700 + i * 150)),
                  curve: Curves.easeOutCubic,
                  builder: (context, f, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: f.clamp(0.02, 1),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 12),
            Text('$plays', style: text.titleMedium?.copyWith(color: Colors.white)),
          ]),
        ),
    ]);
  }
}

/// Plays per hour of the day.
class _Clock extends StatelessWidget {
  const _Clock({required this.byHour, required this.label});
  final List<int> byHour;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final max = math.max(1, byHour.reduce(math.max));
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(l10n.whenYouListen, style: text.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      const SizedBox(height: 24),
      SizedBox(
        height: 180,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var h = 0; h < 24; h++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: byHour[h] / max),
                  duration: context.motion.d(Duration(milliseconds: 500 + h * 30)),
                  curve: PrismMotion.curve,
                  builder: (context, f, _) => Container(
                    height: 4 + 170 * f.clamp(0.0, 1.2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35 + 0.6 * (byHour[h] / max)),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (final h in const ['00', '06', '12', '18', '23'])
          Text(h, style: text.labelSmall?.copyWith(color: Colors.white70)),
      ]),
      const SizedBox(height: 24),
      Text(label, style: text.titleMedium?.copyWith(color: Colors.white), textAlign: TextAlign.center),
    ]);
  }
}

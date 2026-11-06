import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/prism_theme_extensions.dart';
import '../../../l10n/l10n.dart';
import '../../player/application/player_providers.dart';
import '../../player/engine/playback_engine.dart';
import '../../player/presentation/widgets/live_position.dart';
import '../../settings/application/settings_controller.dart';
import '../application/lyrics_providers.dart';
import '../domain/lrc.dart';

/// Lyrics of the current song. Synced lyrics get a karaoke wipe on the current
/// line, follow playback smoothly and can be tapped to seek.
class LyricsView extends ConsumerWidget {
  const LyricsView({super.key, this.textAlign = TextAlign.center, this.large = false});
  final TextAlign textAlign;

  /// Bigger lines (full-screen view).
  final bool large;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lyrics = ref.watch(currentLyricsProvider);
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return AnimatedSwitcher(
      duration: context.motion.d(PrismMotion.medium),
      child: lyrics.when(
        loading: () => const Center(key: ValueKey('loading'), child: CircularProgressIndicator()),
        error: (e, _) => Center(key: const ValueKey('error'), child: Text(l10n.lyricsError(e))),
        data: (l) {
          if (l == null) {
            final online = ref.watch(settingsProvider.select((s) => s.onlineLyrics));
            return Center(
              key: const ValueKey('none'),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  (online ? l10n.noLyricsPlain : l10n.noLyricsHint),
                  textAlign: TextAlign.center,
                  style: text.bodyMedium?.copyWith(color: muted),
                ),
              ),
            );
          }
          if (!l.synced) {
            return SingleChildScrollView(
              key: ValueKey('plain${l.hashCode}'),
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Text(l10n.notSynced(l.source), style: text.labelSmall?.copyWith(color: muted)),
                const SizedBox(height: 12),
                SelectableText(l.plain ?? '', textAlign: textAlign, style: text.titleMedium?.copyWith(height: 1.6)),
              ]),
            );
          }
          return _SyncedLyrics(key: ValueKey(l), lyrics: l, textAlign: textAlign, large: large);
        },
      ),
    );
  }
}

class _SyncedLyrics extends ConsumerStatefulWidget {
  const _SyncedLyrics({super.key, required this.lyrics, required this.textAlign, this.large = false});
  final Lyrics lyrics;
  final TextAlign textAlign;
  final bool large;

  @override
  ConsumerState<_SyncedLyrics> createState() => _SyncedLyricsState();
}

class _SyncedLyricsState extends ConsumerState<_SyncedLyrics> with TickerProviderStateMixin {
  late final LivePosition _pos = LivePosition(this);
  late List<GlobalKey> _keys = _makeKeys();
  final _scroll = ScrollController();

  /// Song position as the lyrics see it: position + this track's offset.
  final _lyricTime = ValueNotifier<Duration>(Duration.zero);
  int _index = -1;
  Duration _offset = Duration.zero;
  DateTime _userScrolledAt = DateTime.fromMillisecondsSinceEpoch(0);

  // Critically damped spring towards the current line: smooth from any
  // distance, no overshoot, and a new target mid-way just bends the motion.
  late final Ticker _springTicker = createTicker(_springTick);
  double? _target;
  double _velocity = 0;
  Duration _lastSpring = Duration.zero;

  List<GlobalKey> _makeKeys() => List.generate(widget.lyrics.lines.length, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _pos.addListener(_onPosition);
    ref.listenManual(engineStateProvider, (_, s) {
      final v = s.value;
      if (v != null) _sync(v);
    }, fireImmediately: true);
    ref.listenManual(tuningProvider, (_, _) {
      final v = ref.read(engineStateProvider).value;
      if (v != null) _sync(v);
    });
    ref.listenManual(currentLyricsOffsetProvider, (_, o) {
      _offset = o.value ?? Duration.zero;
      _onPosition();
    }, fireImmediately: true);
  }

  void _sync(EngineState s) => _pos.sync(s, speed: ref.read(tuningProvider).value?.speed ?? 1);

  @override
  void didUpdateWidget(_SyncedLyrics old) {
    super.didUpdateWidget(old);
    if (old.lyrics != widget.lyrics) _keys = _makeKeys();
  }

  @override
  void dispose() {
    _springTicker.dispose();
    _pos.dispose();
    _lyricTime.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onPosition() {
    final t = _pos.value + _offset;
    _lyricTime.value = t;
    final i = widget.lyrics.indexAt(t);
    if (i == _index) return;
    setState(() => _index = i);
    _follow(i);
  }

  bool get _userScrolling => DateTime.now().difference(_userScrolledAt) < const Duration(seconds: 4);

  /// Sets the spring's target to line [i]. It has to wait for layout: scale and
  /// size of the lines settle during the rebuild.
  void _follow(int i) {
    if (_userScrolling) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final reduce = context.motion.reduceMotion;
      final target = i < 0 ? 0.0 : _offsetOf(i);
      if (target == null) return;
      if (reduce) {
        _scroll.jumpTo(target);
        return;
      }
      _target = target;
      if (!_springTicker.isActive) {
        _lastSpring = Duration.zero;
        _springTicker.start();
      }
    });
  }

  double? _offsetOf(int i) {
    final box = _keys[i].currentContext?.findRenderObject();
    if (box == null || !box.attached) return null;
    final reveal = RenderAbstractViewport.of(box).getOffsetToReveal(box, 0.38).offset;
    final p = _scroll.position;
    return reveal.clamp(p.minScrollExtent, p.maxScrollExtent);
  }

  void _springTick(Duration elapsed) {
    final target = _target;
    if (target == null || !_scroll.hasClients || _userScrolling) {
      _velocity = 0;
      _springTicker.stop();
      return;
    }
    final dt = _lastSpring == Duration.zero ? 1 / 120 : math.min(0.05, (elapsed - _lastSpring).inMicroseconds / 1e6);
    _lastSpring = elapsed;
    final next = stepSpring(_scroll.offset, _velocity, target, dt);
    _velocity = next.$2;
    if ((next.$1 - target).abs() < 0.3 && _velocity.abs() < 2) {
      _scroll.jumpTo(target);
      _velocity = 0;
      _springTicker.stop();
      return;
    }
    _scroll.jumpTo(next.$1);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final style = (widget.large ? text.displaySmall : text.headlineSmall)
        ?.copyWith(fontWeight: FontWeight.w600, height: 1.25, letterSpacing: widget.large ? -0.5 : null);
    final lines = widget.lyrics.lines;
    final alignment = switch (widget.textAlign) {
      TextAlign.left || TextAlign.start => Alignment.centerLeft,
      _ => Alignment.center,
    };
    return Stack(children: [
      NotificationListener<UserScrollNotification>(
        onNotification: (n) {
          if (n.direction != ScrollDirection.idle) _userScrolledAt = DateTime.now();
          return false;
        },
        // A plain column, not a lazy list: every line's place is known, so a
        // seek to anywhere can scroll to it.
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(vertical: 160, horizontal: 24),
          child: Column(
            crossAxisAlignment: widget.textAlign == TextAlign.center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < lines.length; i++)
                _LineRow(
                  key: _keys[i],
                  line: lines[i].text.isEmpty ? '♪' : lines[i].text,
                  current: i == _index,
                  past: i < _index,
                  alignment: alignment,
                  textAlign: widget.textAlign,
                  style: style,
                  scheme: scheme,
                  time: i == _index ? _lyricTime : null,
                  sung: (t) => widget.lyrics.sungAt(i, t),
                  onTap: () {
                    _userScrolledAt = DateTime.fromMillisecondsSinceEpoch(0);
                    final at = lines[i].time - _offset;
                    ref.read(playerControllerProvider).seek(at < Duration.zero ? Duration.zero : at);
                  },
                ),
            ],
          ),
        ),
      ),
      Positioned(
        right: 4,
        top: 4,
        child: IconButton(
          tooltip: l10n.lyricsOffsetTitle,
          icon: Icon(Icons.tune_rounded, size: 18, color: _offset == Duration.zero ? scheme.onSurfaceVariant : context.look.led),
          onPressed: () => showLyricsOffsetSheet(context, ref),
        ),
      ),
    ]);
  }
}

/// One step of a critically damped spring: (position, velocity) after [dt].
(double, double) stepSpring(double x, double v, double target, double dt, {double omega = 11}) {
  // Exact solution, so the motion doesn't depend on the frame rate.
  final d = x - target;
  final c = v + omega * d;
  final e = math.exp(-omega * dt);
  return (target + (d + c * dt) * e, (c - omega * (d + c * dt)) * e);
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    super.key,
    required this.line,
    required this.current,
    required this.past,
    required this.alignment,
    required this.textAlign,
    required this.style,
    required this.scheme,
    required this.time,
    required this.sung,
    required this.onTap,
  });

  final String line;
  final bool current, past;
  final Alignment alignment;
  final TextAlign textAlign;
  final TextStyle? style;
  final ColorScheme scheme;

  /// Only the current line listens to the clock.
  final ValueNotifier<Duration>? time;
  final double Function(Duration) sung;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dim = scheme.onSurface.withValues(alpha: past ? 0.35 : 0.5);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: AnimatedScale(
          scale: current ? 1 : 0.9,
          alignment: alignment,
          duration: context.motion.d(PrismMotion.medium),
          curve: Curves.easeOutCubic,
          child: time == null
              ? Text(line, textAlign: textAlign, style: style?.copyWith(color: dim))
              : KaraokeLine(
                  text: line,
                  textAlign: textAlign,
                  style: style,
                  sung: scheme.primary,
                  rest: scheme.onSurface.withValues(alpha: 0.55),
                  time: time!,
                  progress: sung,
                ),
        ),
      ),
    );
  }
}

/// The current line: dim text with the sung characters painted over it, moving
/// smoothly across each character, also over wrapped lines. Repaints on its own
/// layer, nothing else in the list is touched per frame.
class KaraokeLine extends StatelessWidget {
  const KaraokeLine({
    super.key,
    required this.text,
    required this.textAlign,
    required this.style,
    required this.sung,
    required this.rest,
    required this.time,
    required this.progress,
  });

  final String text;
  final TextAlign textAlign;
  final TextStyle? style;
  final Color sung, rest;
  final ValueNotifier<Duration> time;
  final double Function(Duration) progress;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          foregroundPainter: _KaraokePainter(
            text: text,
            textAlign: textAlign,
            style: (style ?? const TextStyle()).copyWith(color: sung),
            scaler: MediaQuery.textScalerOf(context),
            time: time,
            progress: progress,
          ),
          child: Text(text, textAlign: textAlign, style: style?.copyWith(color: rest)),
        ),
      );
}

class _KaraokePainter extends CustomPainter {
  _KaraokePainter({
    required this.text,
    required this.textAlign,
    required this.style,
    required this.scaler,
    required this.time,
    required this.progress,
  }) : super(repaint: time);

  final String text;
  final TextAlign textAlign;
  final TextStyle style;
  final TextScaler scaler;
  final ValueNotifier<Duration> time;
  final double Function(Duration) progress;

  TextPainter? _painter;
  double _width = -1;

  @override
  void paint(Canvas canvas, Size size) {
    if (_painter == null || _width != size.width) {
      _painter?.dispose();
      _painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textAlign: textAlign,
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout(minWidth: size.width, maxWidth: size.width);
      _width = size.width;
    }
    final p = _painter!;
    final chars = text.length * progress(time.value).clamp(0.0, 1.0);
    final whole = chars.floor();
    if (chars <= 0) return;
    final clip = Path();
    if (whole > 0) {
      for (final b in p.getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: whole))) {
        clip.addRect(b.toRect().inflate(1));
      }
    }
    if (whole < text.length) {
      final boxes = p.getBoxesForSelection(TextSelection(baseOffset: whole, extentOffset: whole + 1));
      if (boxes.isNotEmpty) {
        final r = boxes.first.toRect();
        clip.addRect(Rect.fromLTRB(r.left, r.top, r.left + r.width * (chars - whole), r.bottom).inflate(0.5));
      }
    }
    canvas.save();
    canvas.clipPath(clip);
    p.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_KaraokePainter old) => old.text != text || old.style != style || old.textAlign != textAlign;
}

/// Moves this song's lyrics earlier or later, saved per song.
Future<void> showLyricsOffsetSheet(BuildContext context, WidgetRef ref) {
  final track = ref.read(currentTrackProvider);
  if (track == null) return Future.value();
  final repo = ref.read(lyricsRepositoryProvider);
  var value = (ref.read(currentLyricsOffsetProvider).value ?? Duration.zero).inMilliseconds.toDouble();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheet) {
        final text = Theme.of(context).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.lyricsOffsetTitle, style: text.titleMedium),
              const SizedBox(height: 4),
              Text(l10n.lyricsOffsetHint, style: text.bodySmall),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: Slider(
                    value: value.clamp(-5000, 5000),
                    min: -5000,
                    max: 5000,
                    divisions: 200,
                    onChanged: (v) {
                      setSheet(() => value = v);
                      ref.read(lyricsOffsetLiveProvider.notifier).preview(Duration(milliseconds: v.round()));
                    },
                    onChangeEnd: (v) async {
                      await repo.setOffset(track.id, v.round());
                      ref.invalidate(currentLyricsOffsetProvider);
                    },
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    l10n.secondsValue('${value > 0 ? '+' : ''}${fmtNum(value / 1000, 2)}'),
                    textAlign: TextAlign.end,
                    style: text.labelMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ),
              ]),
              TextButton(
                onPressed: value == 0
                    ? null
                    : () async {
                        setSheet(() => value = 0);
                        ref.read(lyricsOffsetLiveProvider.notifier).preview(Duration.zero);
                        await repo.setOffset(track.id, 0);
                        ref.invalidate(currentLyricsOffsetProvider);
                      },
                child: Text(l10n.reset2),
              ),
            ]),
          ),
        );
      },
    ),
  );
}

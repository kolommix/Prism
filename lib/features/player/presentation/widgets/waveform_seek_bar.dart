import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/prism_theme_extensions.dart';
import '../../../../core/widgets/led_dot.dart';
import '../../../settings/application/settings_controller.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../visualizer/domain/spectrum.dart';
import '../../../visualizer/presentation/visualizer.dart';
import '../../application/player_providers.dart';
import '../../domain/seek_bar_style.dart';
import 'seek_bar_painters.dart';

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

/// Seek bar in one of the [SeekBarStyle]s (Settings, or right-click the bar).
///
/// * The bar heights are a deterministic pseudo-waveform derived from the
///   track id (decoding real peaks would need a full decode of the file; the
///   painters take any `List<double>` so real peaks can be plugged in later).
/// * Position is interpolated between the engine's ~4 Hz updates: every frame
///   on the big bars, once per pixel on small ones, 30 fps for styles that
///   move on their own.
/// * Drag or tap to seek; [compact] draws a thin classic bar instead.
/// The seek bar part of the settings.
extension SeekBarLookOf on AppSettings {
  SeekBarLook get seekBarLook => SeekBarLook(
        color: seekBarColor,
        size: seekBarSize,
        density: seekBarDensity,
        thickness: seekBarThickness,
        dim: seekBarDim,
        react: seekBarReact,
        head: seekBarHead,
        times: seekBarTimes,
      );
}

class WaveformSeekBar extends ConsumerStatefulWidget {
  const WaveformSeekBar({
    super.key,
    this.height = 56,
    this.compact = false,
    this.showTimes = true,
    this.inlineTimes = false,
  });

  final double height;
  final bool compact;
  final bool showTimes;

  /// Elapsed and total time left and right of the bar (player bar).
  final bool inlineTimes;

  @override
  ConsumerState<WaveformSeekBar> createState() => _WaveformSeekBarState();
}

class _WaveformSeekBarState extends ConsumerState<WaveformSeekBar> with TickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);

  /// Pointer position over the bar (0..1) and how far the hover look is in.
  final _hover = ValueNotifier<double?>(null);
  late final AnimationController _hoverAnim = AnimationController(vsync: this);

  /// 0 paused .. 1 playing: the Ribbon flattens, Live settles.
  late final AnimationController _playAnim = AnimationController(vsync: this);
  bool? _animatedPlaying;
  final _clock = Stopwatch()..start();

  SeekBarStyle _style = SeekBarStyle.waveform;
  Spectrum? _spectrum;
  final _raw = Float32List(256);
  Float32List _levels = Float32List(0);
  int _levelsAt = 0;

  bool _liveSetting = true;

  /// The song's spectrum is needed: the Live style, or every style with the setting on.
  bool get _wantsBands => (_style == SeekBarStyle.live && !widget.compact) || _liveSetting;

  /// Moves on its own while playing, so it gets a frame per screen refresh.
  bool get _moves => context.motion.decorative && (_wantsBands || (_style.animated && !widget.compact));
  bool _mouseInside = false;

  void _hoverIn() {
    _hoverAnim.duration = context.motion.d(PrismMotion.short);
    unawaited(_hoverAnim.forward());
  }

  void _hoverOut() {
    _hoverAnim.duration = context.motion.d(PrismMotion.medium);
    unawaited(_hoverAnim.reverse().whenComplete(() {
      if (mounted && !_mouseInside && _dragValue == null) _hover.value = null;
    }));
  }
  final _progress = ValueNotifier<double>(0);
  final _pulse = ValueNotifier<double>(0);

  /// Whole seconds shown in the time labels (they rebuild once a second,
  /// not every frame like the bar).
  final _seconds = ValueNotifier<int>(0);

  Duration _basePos = Duration.zero;
  DateTime _baseAt = DateTime.now();
  Duration _duration = Duration.zero;
  bool _playing = false;
  double? _dragValue;
  int? _trackId;
  List<double> _peaks = const [];

  /// Last seek: the engine keeps reporting the old position for a moment,
  /// which made the bar jump back after a tap or drag.
  Duration? _seekTarget;
  DateTime _seekAt = DateTime(0);

  /// Small bars (player bar, mini player) only need a new frame when the
  /// playhead has moved by a pixel: a timer at that pace instead of a
  /// per-frame ticker (a running ticker re-renders the whole window 60x/s).
  Timer? _timer;
  Duration _timerEvery = Duration.zero;
  double _barPixels = 300;

  /// Only the big waveform (full player) animates every frame: its bars
  /// near the playhead breathe.
  bool get _perFrame => !widget.compact && widget.height >= 40 && context.motion.decorative;

  void _syncPlayAnim() {
    if (_animatedPlaying == _playing) return;
    final first = _animatedPlaying == null;
    _animatedPlaying = _playing;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (first) {
        _playAnim.value = _playing ? 1 : 0;
      } else {
        _playAnim.duration = context.motion.d(PrismMotion.long);
        unawaited(_playAnim.animateTo(_playing ? 1 : 0, curve: PrismMotion.curve));
      }
    });
  }

  /// Runs only while playing; when paused the bar is updated once and no
  /// frames are requested at all.
  void _syncTicker() {
    final perFrame = _playing && (_perFrame || _moves);
    if (perFrame && !_ticker.isActive) {
      _ticker.start();
    } else if (!perFrame && _ticker.isActive) {
      _ticker.stop();
    }
    if (_playing && !perFrame) {
      final ms = _duration.inMilliseconds / math.max(1.0, _barPixels);
      final every = Duration(milliseconds: ms.isFinite ? ms.clamp(16, 250).round() : 250);
      if (_timer == null || every != _timerEvery) {
        _timer?.cancel();
        _timerEvery = every;
        _timer = Timer.periodic(every, (_) => _onTick(Duration.zero));
      }
    } else {
      _timer?.cancel();
      _timer = null;
    }
    if (!_playing) {
      // After this build (listeners must not be notified during build).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onTick(Duration.zero);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ticker.dispose();
    _hoverAnim.dispose();
    _playAnim.dispose();
    _hover.dispose();
    _progress.dispose();
    _pulse.dispose();
    _seconds.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_dragValue != null) return;
    var pos = _basePos;
    if (_playing) pos += DateTime.now().difference(_baseAt);
    final total = _duration.inMilliseconds;
    _setProgress(total <= 0 ? 0 : (pos.inMilliseconds / total).clamp(0.0, 1.0));
    if (_playing && (_perFrame || _moves)) _pulse.value = _clock.elapsedMilliseconds / 1000.0;
    if (_wantsBands && _moves) _updateLevels(pos);
  }

  /// Live spectrum: fast rise, slow fall, like a real analyser.
  void _updateLevels(Duration pos) {
    final s = _spectrum;
    if (s == null || s.bands == 0 || s.frames == 0) {
      if (_levels.isNotEmpty) _levels = Float32List(0);
      return;
    }
    if (_levels.length != math.min(s.bands, _raw.length)) _levels = Float32List(math.min(s.bands, _raw.length));
    s.sample(pos, _raw);
    // By time, not by frame: the same at 60 or 120 fps.
    final now = _clock.elapsedMicroseconds;
    final frames = math.min(0.1, (now - _levelsAt) / 1e6) * 60;
    _levelsAt = now;
    final keep = math.pow(0.82, frames).toDouble();
    for (var i = 0; i < _levels.length; i++) {
      final v = _raw[i];
      _levels[i] = v > _levels[i] ? v : _levels[i] * keep + v * (1 - keep);
    }
  }

  Future<void> _pickStyle(Offset global) async {
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final picked = await showMenu<SeekBarStyle>(
      context: context,
      position: RelativeRect.fromRect(global & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        for (final s in SeekBarStyle.values)
          PopupMenuItem(
            value: s,
            child: Row(
              children: [
                Expanded(child: Text(s.label)),
                const SizedBox(width: 24),
                LedDot(on: s == _style),
              ],
            ),
          ),
      ],
    );
    if (picked != null) ref.read(settingsProvider.notifier).update((x) => x.copyWith(seekBarStyle: picked.name));
  }

  void _setProgress(double p) {
    _progress.value = p;
    _seconds.value = (_duration.inMilliseconds * p) ~/ 1000;
  }

  static List<double> _fakePeaks(int seed, int count) {
    final r = math.Random(seed);
    var v = 0.5;
    return List.generate(count, (i) {
      // Random walk + slow envelope looks surprisingly like real music.
      v = (v + (r.nextDouble() - 0.5) * 0.5).clamp(0.15, 1.0);
      final envelope = 0.55 + 0.45 * math.sin(i / count * math.pi);
      return (v * envelope).clamp(0.12, 1.0);
    });
  }

  void _seekTo(double fraction) {
    final target = Duration(milliseconds: (_duration.inMilliseconds * fraction).round());
    ref.read(playerControllerProvider).seek(target);
    _basePos = target;
    _baseAt = DateTime.now();
    _seekTarget = target;
    _seekAt = _baseAt;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(engineStateProvider).value;
    final track = ref.watch(currentTrackProvider);
    _style = SeekBarStyle.parse(ref.watch(settingsProvider.select((s) => s.seekBarStyle)));
    _liveSetting = ref.watch(settingsProvider.select((s) => s.liveSeekBar));
    final look = ref.watch(settingsProvider.select((s) => s.seekBarLook));
    _spectrum = _wantsBands && context.motion.decorative && track != null && track.sourceId == 'local'
        ? ref.watch(spectrumProvider(track)).value
        : null;
    if (state != null) {
      final target = _seekTarget;
      final stale = target != null &&
          DateTime.now().difference(_seekAt) < const Duration(milliseconds: 1500) &&
          (state.position - target).abs() > const Duration(milliseconds: 900);
      if (!stale) {
        _seekTarget = null;
        _basePos = state.position;
        _baseAt = DateTime.now();
      }
      _playing = state.playing;
      _duration = state.duration ?? track?.duration ?? Duration.zero;
    }
    if (track?.id != _trackId) {
      _trackId = track?.id;
      _peaks = _fakePeaks(track?.id ?? 0, _peaks.isEmpty ? 72 : _peaks.length);
    }
    _syncTicker();
    _syncPlayAnim();

    final scheme = Theme.of(context).colorScheme;
    final ink = look.color == null ? scheme.primary : Color(look.color!);
    final dim = scheme.onSurface.withValues(alpha: look.dim);
    // The player bar has a fixed height: the bar can't grow past what fits there.
    final barHeight = widget.inlineTimes ? math.min(widget.height * look.size, 34.0) : widget.height * look.size;
    final timeStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontFeatures: const [FontFeature.tabularFigures()],
        );
    final bar = LayoutBuilder(
      builder: (context, c) {
        _barPixels = c.maxWidth * MediaQuery.devicePixelRatioOf(context);
        // About one bar per 6 px: a wide bar gets a denser, finer waveform.
        final count = (c.maxWidth / 6 * look.density).clamp(20, 320).round();
        if (count != _peaks.length) _peaks = _fakePeaks(_trackId ?? 0, count);
        double fractionAt(Offset local) => (local.dx / c.maxWidth).clamp(0.0, 1.0);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (d) => _seekTo(fractionAt(d.localPosition)),
          onSecondaryTapUp: widget.compact ? null : (d) => _pickStyle(d.globalPosition),
          onHorizontalDragStart: (d) {
            setState(() => _dragValue = fractionAt(d.localPosition));
            _hoverIn();
          },
          onHorizontalDragUpdate: (d) {
            _dragValue = fractionAt(d.localPosition);
            _hover.value = _dragValue;
            _setProgress(_dragValue!);
          },
          onHorizontalDragEnd: (_) {
            final v = _dragValue;
            setState(() => _dragValue = null);
            if (v != null) _seekTo(v);
            if (!_mouseInside) _hoverOut();
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (e) {
              _mouseInside = true;
              _hover.value = fractionAt(e.localPosition);
              _hoverIn();
            },
            onHover: (e) => _hover.value = fractionAt(e.localPosition),
            onExit: (_) {
              _mouseInside = false;
              if (_dragValue == null) _hoverOut();
            },
            child: SizedBox(
              height: widget.compact ? 18 : barHeight,
              width: double.infinity,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: widget.compact
                      ? _LinePainter(
                          progress: _progress,
                          pulse: _pulse,
                          levels: () => _liveSetting && _playing ? _levels : null,
                          active: ink,
                          inactive: dim,
                          thickness: look.thickness,
                        )
                      : seekPainterFor(
                          _style,
                          SeekPaintData(
                            progress: _progress,
                            pulse: _pulse,
                            hover: _hover,
                            hoverT: _hoverAnim,
                            playT: _playAnim,
                            peaks: _peaks,
                            levels: _levels,
                            live: _liveSetting && context.motion.decorative,
                            look: look,
                            duration: _duration,
                            ink: ink,
                            dim: dim,
                            led: context.look.led,
                            bubble: scheme.inverseSurface,
                            bubbleText: (timeStyle ?? const TextStyle()).copyWith(
                              color: scheme.onInverseSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!look.times) return bar;
    if (widget.inlineTimes) {
      // Player bar: elapsed | waveform | total, all on one line.
      return Row(
        children: [
          SizedBox(
            width: 44,
            child: ValueListenableBuilder<int>(
              valueListenable: _seconds,
              builder: (context, s, _) =>
                  Text(formatDuration(Duration(seconds: s)), textAlign: TextAlign.right, style: timeStyle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: bar),
          const SizedBox(width: 10),
          SizedBox(width: 44, child: Text(formatDuration(_duration), style: timeStyle)),
        ],
      );
    }
    if (!widget.showTimes) return bar;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        bar,
        const SizedBox(height: 4),
        ValueListenableBuilder<int>(
          valueListenable: _seconds,
          builder: (context, s, _) {
            final pos = Duration(seconds: s);
            return Row(
              children: [
                Text(formatDuration(pos), style: timeStyle),
                const Spacer(),
                Text('-${formatDuration(_duration - pos)}', style: timeStyle),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// The thin bar of the mini players; it thickens with the bass when live.
class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.progress,
    required this.pulse,
    required this.levels,
    required this.active,
    required this.inactive,
    this.thickness = 1,
  })
      : super(repaint: Listenable.merge([progress, pulse]));

  final ValueNotifier<double> progress;
  final ValueNotifier<double> pulse;
  final Float32List? Function() levels;
  final Color active, inactive;
  final double thickness;

  double get _bass {
    final l = levels();
    if (l == null || l.isEmpty) return 0;
    final n = math.max(1, l.length ~/ 8);
    var sum = 0.0;
    for (var i = 0; i < n; i++) {
      sum += l[i];
    }
    return ((sum / n - 0.45) / 0.55).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final bass = _bass;
    final paint = Paint()
      ..strokeWidth = 4 * thickness
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(2, y), Offset(size.width - 2, y), paint..color = inactive);
    final x = 2 + (size.width - 4) * progress.value;
    canvas.drawLine(Offset(2, y), Offset(x, y), paint
      ..color = active
      ..strokeWidth = (4 + 3 * bass) * thickness);
    canvas.drawCircle(Offset(x, y), 5 + 2.5 * bass, Paint()..color = active);
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.active != active || old.inactive != inactive || old.thickness != thickness;
}

/// A small working sample of a style, for the picker in Settings.
class SeekBarStylePreview extends StatefulWidget {
  const SeekBarStylePreview({
    super.key,
    required this.style,
    this.height = 30,
    this.live = false,
    this.look = const SeekBarLook(),
  });

  final SeekBarLook look;

  final SeekBarStyle style;
  final double height;
  final bool live;

  @override
  State<SeekBarStylePreview> createState() => _SeekBarStylePreviewState();
}

class _SeekBarStylePreviewState extends State<SeekBarStylePreview> {
  static final _peaksByCount = <int, List<double>>{};
  static List<double> _peaksFor(int n) => _peaksByCount.putIfAbsent(n, () {
        final r = math.Random(7);
        var v = 0.5;
        return List<double>.generate(n, (i) {
          v = (v + (r.nextDouble() - 0.5) * 0.5).clamp(0.15, 1.0);
          return (v * (0.55 + 0.45 * math.sin(i / n * math.pi))).clamp(0.12, 1.0);
        });
      });

  final _progress = ValueNotifier<double>(0.42);
  final _pulse = ValueNotifier<double>(0);
  final _hover = ValueNotifier<double?>(null);
  Timer? _timer;
  final _clock = Stopwatch()..start();
  static final _noBands = Float32List(0);

  void _sync() {
    _timer?.cancel();
    _timer = null;
    if (widget.style.animated || widget.live) {
      _timer = Timer.periodic(const Duration(milliseconds: 33), (_) => _pulse.value = _clock.elapsedMilliseconds / 1000.0);
    }
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(SeekBarStylePreview old) {
    super.didUpdateWidget(old);
    if (old.style != widget.style || old.live != widget.live) _sync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progress.dispose();
    _pulse.dispose();
    _hover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final decorative = context.motion.decorative;
    final look = widget.look;
    return RepaintBoundary(
      child: SizedBox(
        height: widget.height * look.size,
        width: double.infinity,
        child: CustomPaint(
          painter: seekPainterFor(
            widget.style,
            SeekPaintData(
              progress: _progress,
              pulse: _pulse,
              hover: _hover,
              hoverT: kAlwaysDismissedAnimation,
              playT: decorative ? kAlwaysCompleteAnimation : kAlwaysDismissedAnimation,
              peaks: _peaksFor((90 * look.density).round()),
              levels: _noBands,
              live: widget.live && decorative,
              look: look,
              duration: const Duration(minutes: 3),
              ink: look.color == null ? scheme.primary : Color(look.color!),
              dim: scheme.onSurface.withValues(alpha: look.dim),
              led: context.look.led,
              bubble: scheme.inverseSurface,
              bubbleText: const TextStyle(),
            ),
          ),
        ),
      ),
    );
  }
}

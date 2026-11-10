import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/prism_theme_extensions.dart';
import '../../desktop/application/desktop_extras.dart';
import '../../player/application/player_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../../../core/motion/busy_pc.dart';
import '../../visualizer/domain/spectrum.dart';
import '../../visualizer/presentation/visualizer.dart';
import '../application/background_input.dart';
import '../domain/background_config.dart';
import 'background_effects.dart';

/// Runs one [BackgroundEffect].
///
/// Moves once per screen refresh, every step by the real time passed: that is
/// what makes it flow (a timer beats against the screen and judders). It can be
/// capped in Settings. Only the top full-window instance runs (the shell's stops
/// while a full player covers it), and it also stops when the window is hidden,
/// in mini mode, when motion is reduced and (optional) while the music is paused.
class LiveBackground extends ConsumerStatefulWidget {
  const LiveBackground({super.key, required this.style, required this.params, this.preview = false, this.fps, this.still = false});

  /// One frame only (the cards that aren't selected in the picker).
  final bool still;

  final BackgroundStyle style;
  final BgParams params;

  /// A small sample in the settings: no music, only local clicks.
  final bool preview;
  final int? fps;

  @override
  ConsumerState<LiveBackground> createState() => _LiveBackgroundState();
}

class _LiveBackgroundState extends ConsumerState<LiveBackground> with SingleTickerProviderStateMixin {
  static final _windowStack = <_LiveBackgroundState>[];

  BackgroundEffect? _effect;
  final _repaint = ValueNotifier<int>(0);
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastStep = Duration.zero;
  StreamSubscription<BackgroundBurst>? _bursts;
  AppLifecycleListener? _life;
  bool _windowVisible = true;

  final _raw = Float32List(256);
  Duration _basePos = Duration.zero;
  DateTime _baseAt = DateTime.now();
  bool _playing = false;
  double _speed = 1;
  double _bass = 0;
  Spectrum? _spectrum;

  bool get _isTop => widget.preview || (_windowStack.isNotEmpty && identical(_windowStack.last, this));

  @override
  void initState() {
    super.initState();
    if (!widget.preview) _windowStack.add(this);
    _life = AppLifecycleListener(
      onStateChange: (s) {
        final visible = s != AppLifecycleState.hidden && s != AppLifecycleState.paused && s != AppLifecycleState.detached;
        if (visible != _windowVisible) {
          _windowVisible = visible;
          _syncTimer();
        }
      },
    );
    _bursts = ref.read(backgroundInputProvider).bursts.listen(_onBurst);
    _create();
  }

  void _onBurst(BackgroundBurst b) {
    final effect = _effect;
    final box = context.findRenderObject();
    if (effect == null || box is! RenderBox || !box.hasSize || !_isTop) return;
    final local = box.globalToLocal(b.at);
    if (widget.preview && !(Offset.zero & box.size).contains(local)) return;
    effect.burst(local, b.strength * math.max(0.3, widget.params.mouse));
    _ensureFrame();
  }

  BackgroundConfig get _config => ref.read(settingsProvider).background;

  /// What makes a new effect necessary besides the style.
  String _sourceKey(BackgroundConfig c) => '${c.gradientPreset}|${c.imagePath}|${c.videoDir}|${c.batterySaver}';
  late String _source = _sourceKey(_config);

  void _create() {
    final old = _effect;
    final effect = BackgroundEffect.create(widget.style, widget.params.sanitized(), Colors.white, Colors.white, config: _config);
    _effect = effect;
    old?.dispose();
    unawaited(effect.prepare().then((_) {
      if (mounted && identical(_effect, effect)) {
        // A moment in, so a still frame isn't an empty one.
        if (widget.still && !effect.isStatic) effect.step(1.2);
        _repaint.value++;
      }
    }));
  }

  @override
  void didUpdateWidget(LiveBackground old) {
    super.didUpdateWidget(old);
    final source = _sourceKey(_config);
    if (old.style != widget.style || source != _source) {
      _source = source;
      _create();
      return;
    }
    if (old.params != widget.params) {
      final effect = _effect;
      if (effect == null) return;
      final glyphsChanged = old.params.glyphs != widget.params.glyphs || old.params.customGlyphs != widget.params.customGlyphs;
      effect.params = widget.params.sanitized();
      if (old.params.density != widget.params.density || old.params.size != widget.params.size) {
        if (effect.size != Size.zero) effect.resize(effect.size);
      }
      if (glyphsChanged) {
        unawaited(effect.prepare().then((_) {
          if (mounted) _repaint.value++;
        }));
      }
      _repaint.value++;
    }
  }

  /// One step while stopped (paused music, reduced motion) after a click.
  void _ensureFrame() {
    if (!_ticker.isActive) SchedulerBinding.instance.scheduleFrameCallback((_) => _step(1 / 60));
  }

  bool get _shouldRun {
    final cfg = ref.read(settingsProvider).background;
    if (!mounted || !_isTop || !_windowVisible || widget.still) return false;
    if (!context.motion.decorative) return false;
    if (ref.read(miniModeProvider)) return false;
    if (!widget.preview && cfg.onlyWhilePlaying && !_playing) return false;
    // A still picture only needs frames to follow the mouse.
    if ((_effect?.isStatic ?? false) && (widget.preview || !cfg.parallax)) return false;
    return true;
  }

  void _syncTimer() {
    final run = _shouldRun;
    if (run && !_ticker.isActive) {
      _lastStep = Duration.zero;
      unawaited(_ticker.start());
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration now) {
    var cap = widget.fps ?? ref.read(settingsProvider).background.effectiveFrameRate;
    // A busy PC: 30 frames a second at most (see BusyMeter).
    if (!widget.preview && ref.read(busyPcProvider) && (cap <= 0 || cap > 30)) cap = 30;
    final passed = now - _lastStep;
    // A little early is fine: frames are never exactly on the mark.
    if (cap > 0 && passed.inMicroseconds < 1000000 ~/ cap - 2000) return;
    _lastStep = now;
    _step(math.min(0.1, passed.inMicroseconds / 1e6));
  }

  void _step(double dt) {
    final effect = _effect;
    if (effect == null || !mounted) return;
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      final global = ref.read(backgroundInputProvider).pointer;
      final local = global == null ? null : box.globalToLocal(global);
      effect.pointer = widget.preview && local != null && !(Offset.zero & box.size).contains(local) ? null : local;
    }
    _updateParallax(dt);
    _updateBass(effect, dt);
    effect.step(dt);
    _repaint.value++;
  }

  /// Follows the mouse softly, by real time. Touch screens have no pointer to
  /// follow, so nothing moves there.
  void _updateParallax(double dt) {
    final cfg = ref.read(settingsProvider).background;
    final box = context.findRenderObject();
    var want = Offset.zero;
    if (cfg.parallax && !widget.preview && box is RenderBox && box.hasSize) {
      final global = ref.read(backgroundInputProvider).pointer;
      if (global != null) {
        final c = box.size.center(Offset.zero);
        final d = box.globalToLocal(global) - c;
        want = Offset(d.dx / c.dx, d.dy / c.dy) * -_parallaxReach;
      }
    }
    _parallax.value = Offset.lerp(_parallax.value, want, 1 - math.exp(-dt * 5))!;
  }

  static const _parallaxReach = 14.0;
  final _parallax = ValueNotifier<Offset>(Offset.zero);

  void _updateBass(BackgroundEffect effect, double dt) {
    final s = _spectrum;
    final strength = effect.params.music;
    if (s == null || widget.preview || strength <= 0 || !_playing || s.bands == 0 || s.frames == 0) {
      _bass *= math.pow(0.9, dt * 30);
    } else {
      final elapsed = DateTime.now().difference(_baseAt);
      s.sample(_basePos + elapsed * _speed, _raw);
      final lows = math.max(1, s.bands ~/ 8);
      var sum = 0.0;
      for (var i = 0; i < lows; i++) {
        sum += _raw[i];
      }
      final b = ((sum / lows - 0.45) / 0.55).clamp(0.0, 1.0);
      // Rises quickly but not in one frame: the whole picture doesn't jump.
      final toward = b > _bass ? 1 - math.pow(0.55, dt * 30) : 1 - math.pow(0.86, dt * 30);
      _bass += (b - _bass) * toward;
    }
    effect.bass = _bass * strength;
  }

  @override
  void dispose() {
    final wasTop = _isTop;
    _windowStack.remove(this);
    _ticker.dispose();
    _bursts?.cancel();
    _life?.dispose();
    _effect?.dispose();
    _repaint.dispose();
    _parallax.dispose();
    // The one underneath takes over.
    if (wasTop && _windowStack.isNotEmpty) {
      final below = _windowStack.last;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (below.mounted) below._syncTimer();
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = widget.params;
    final mono = context.look.monochrome;
    final color = p.followTheme ? (mono ? scheme.onSurface : scheme.primary) : Color(p.color);
    final accent = p.followTheme ? (mono ? scheme.onSurface : scheme.tertiary) : Color(p.accent);
    final effect = _effect;
    if (effect != null) {
      effect.color = color;
      effect.accent = accent;
    }

    if (!widget.preview) {
      final st = ref.watch(engineStateProvider).value;
      if (st != null) {
        _basePos = st.position;
        _baseAt = DateTime.now();
        _playing = st.playing;
      }
      _speed = ref.watch(tuningProvider.select((t) => t.value?.speed ?? 1));
      final track = ref.watch(currentTrackProvider);
      final wantsSpectrum = p.music > 0 && track != null && track.sourceId == 'local' && context.motion.decorative;
      _spectrum = wantsSpectrum ? ref.watch(spectrumProvider(track)).value : null;
      ref.watch(miniModeProvider);
      ref.watch(settingsProvider.select((s) => s.background.onlyWhilePlaying));
    }
    final bg = ref.watch(settingsProvider.select((s) => (s.background.softness, s.background.dim, s.background.batterySaver, s.background.parallax)));
    ref.watch(settingsProvider.select((s) => _sourceKey(s.background)));
    final soft = widget.preview || bg.$3 ? 0.0 : bg.$1;
    final dim = widget.preview ? 0.0 : bg.$2;
    // Pictures take far more blur than small moving dots before it shows.
    final blurReach = widget.style == BackgroundStyle.image || widget.style == BackgroundStyle.video || widget.style == BackgroundStyle.gradient ? 26.0 : 3.5;
    final strength = widget.preview ? 1.0 : ref.watch(settingsProvider.select((s) => s.background.strength));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncTimer();
    });

    return RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        willChange: true,
        painter: _EffectPainter(
          effect,
          _repaint,
          blur: soft.clamp(0.0, 1.0) * blurReach,
          strength: strength.clamp(0.1, 1.0),
          dim: dim.clamp(0.0, 0.9),
          parallax: bg.$4 && !widget.preview ? _parallax : null,
        ),
      ),
    );
  }
}

class _EffectPainter extends CustomPainter {
  _EffectPainter(this.effect, Listenable repaint, {required this.blur, required this.strength, this.dim = 0, this.parallax}) : super(repaint: repaint);

  final double dim;
  final ValueNotifier<Offset>? parallax;

  final BackgroundEffect? effect;

  /// Out of focus and dimmed, the way things far behind look.
  final double blur;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final e = effect;
    if (e == null || size.isEmpty) return;
    if (e.size != size) e.resize(size);
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(rect);
    canvas.saveLayer(
      rect,
      Paint()
        ..color = Color.fromRGBO(0, 0, 0, strength)
        ..imageFilter = blur > 0.05 ? ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur, tileMode: TileMode.decal) : null,
    );
    final shift = parallax?.value;
    if (shift != null) {
      // A little larger than the window, so the edges never show when it moves.
      final c = size.center(Offset.zero);
      canvas.translate(c.dx + shift.dx, c.dy + shift.dy);
      canvas.scale(1.04);
      canvas.translate(-c.dx, -c.dy);
    }
    e.paint(canvas);
    canvas.restore();
    if (dim > 0) canvas.drawRect(rect, Paint()..color = Color.fromRGBO(0, 0, 0, dim));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EffectPainter old) => !identical(old.effect, effect) || old.blur != blur || old.strength != strength || old.dim != dim || old.parallax != parallax;
}

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/beat_detector.dart';
import '../domain/spectrum.dart';
import '../../../l10n/l10n.dart';

/// Visualizer looks. Each one is drawn in one ink color (the theme's text or
/// primary color); the amber LED color only marks peaks, like the hold
/// lights on a real spectrum analyser.
enum VisualizerStyle {
  bars(Icons.bar_chart_rounded),
  mirror(Icons.align_vertical_center_rounded),
  radial(Icons.blur_circular_rounded),
  wave(Icons.waves_rounded),
  meters(Icons.speed_rounded),
  waterfall(Icons.waterfall_chart_rounded),
  matrix(Icons.grid_on_rounded),
  ribbon(Icons.gesture_rounded),
  particles(Icons.scatter_plot_rounded),
  glow(Icons.blur_on_rounded);

  const VisualizerStyle(this.icon);
  final IconData icon;

  String get label => switch (this) {
        VisualizerStyle.bars => l10n.bars,
        VisualizerStyle.mirror => l10n.mirror,
        VisualizerStyle.radial => l10n.radial,
        VisualizerStyle.wave => l10n.wave,
        VisualizerStyle.meters => l10n.vuMeters,
        VisualizerStyle.waterfall => l10n.waterfall,
        VisualizerStyle.matrix => l10n.ledMatrix,
        VisualizerStyle.ribbon => l10n.vizRibbon,
        VisualizerStyle.particles => l10n.vizParticles,
        VisualizerStyle.glow => l10n.vizGlow,
      };

  static VisualizerStyle parse(String s) => values.asNameMap()[s] ?? bars;
}

/// Draws one frame of a [Spectrum] at [position] in [style].
///
/// Smoothing state (fast attack / slow decay levels, falling peak marks,
/// needle ballistics, beats, particles) lives in small per-source buffers so a
/// rebuilt painter continues where the last one stopped.
class VisualizerPainter extends CustomPainter {
  VisualizerPainter({
    required this.spectrum,
    required this.position,
    required this.style,
    required this.ink,
    required this.led,
    required this.reduce,
    this.sensitivity = 1,
    this.lowPower = false,
    this.shader,
    required Listenable repaint,
  }) : super(repaint: repaint);

  final BandSource spectrum;
  final double sensitivity;
  final bool lowPower;

  /// The glow style's program; null falls back to a plain painted glow.
  final ui.FragmentProgram? shader;
  final ValueNotifier<Duration> position;
  final VisualizerStyle style;
  final Color ink;
  final Color led;
  final bool reduce;

  static final _state = <BandSource, _VizState>{};
  static final _raw = Float32List(256);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final n = spectrum.bands;
    final s = _state.putIfAbsent(spectrum, () => _VizState(n));
    if (_state.length > 4) _state.remove(_state.keys.first);
    spectrum.sample(position.value, _raw);
    for (var i = 0; i < n; i++) {
      _raw[i] = applySensitivity(_raw[i], sensitivity);
    }
    // Smoothing goes by time, not by frame: the same at 60 or 120 fps.
    final dt = math.min(0.1, s.clock.elapsedMicroseconds / 1e6);
    final frames = dt * 60;
    s.clock
      ..reset()
      ..start();
    s.frames = frames;
    if (reduce) {
      s.level.setRange(0, n, _raw);
    } else {
      smoothLevels(s.level, _raw, math.max(dt, 1 / 240));
    }
    // Bass, mids and highs, then beats from the bass.
    final third = math.max(1, n ~/ 3), lows = math.max(1, n ~/ 8);
    var bass = 0.0, mid = 0.0, high = 0.0;
    for (var i = 0; i < n; i++) {
      if (i < lows) bass += s.level[i];
      if (i >= lows && i < 2 * third) mid += s.level[i];
      if (i >= 2 * third) high += s.level[i];
    }
    s.bass = bass / lows;
    s.mid = mid / math.max(1, 2 * third - lows);
    s.high = high / math.max(1, n - 2 * third);
    s.time += dt;
    s.beat.update(s.bass, dt);
    for (var i = 0; i < n; i++) {
      final v = _raw[i];
      // Peak marks hold, then fall at a steady speed.
      s.peak[i] = v >= s.peak[i] ? v : math.max(v, s.peak[i] - 0.012 * frames);
    }
    switch (style) {
      case VisualizerStyle.bars:
        _bars(canvas, size, s, mirrored: false);
      case VisualizerStyle.mirror:
        _bars(canvas, size, s, mirrored: true);
      case VisualizerStyle.radial:
        _radial(canvas, size, s.level);
      case VisualizerStyle.wave:
        _wave(canvas, size, s.level);
      case VisualizerStyle.meters:
        _meters(canvas, size, s);
      case VisualizerStyle.waterfall:
        _waterfall(canvas, size);
      case VisualizerStyle.matrix:
        _matrix(canvas, size, s);
      case VisualizerStyle.ribbon:
        _ribbon(canvas, size, s);
      case VisualizerStyle.particles:
        _particles(canvas, size, s, dt);
      case VisualizerStyle.glow:
        _glow(canvas, size, s);
    }
  }

  void _bars(Canvas canvas, Size size, _VizState s, {required bool mirrored}) {
    final v = s.level;
    final n = v.length;
    final slot = size.width / n;
    final w = math.max(2.0, slot * 0.6);
    final paint = Paint()
      ..color = ink
      ..strokeWidth = w
      ..strokeCap = StrokeCap.butt;
    final base = mirrored ? size.height / 2 : size.height;
    final scale = mirrored ? size.height * 0.48 : size.height * 0.94;
    final cap = Paint()..color = led;
    for (var i = 0; i < n; i++) {
      final x = i * slot + slot / 2;
      final h = math.max(2.0, v[i] * scale);
      // Taller bars are brighter: one ink, a tone shift by level.
      paint.color = ink.withValues(alpha: 0.35 + 0.65 * v[i]);
      canvas.drawLine(Offset(x, base), Offset(x, base - h), paint);
      if (mirrored) {
        canvas.drawLine(Offset(x, base), Offset(x, base + h), paint);
      } else {
        final py = base - math.max(2.0, s.peak[i] * scale) - 3;
        canvas.drawRect(Rect.fromLTWH(x - w / 2, py, w, 2), cap);
      }
    }
  }

  void _radial(Canvas canvas, Size size, Float32List v) {
    final c = size.center(Offset.zero);
    final r0 = size.shortestSide * 0.22;
    final n = v.length;
    final paint = Paint()
      ..strokeWidth = math.max(2, 2 * math.pi * r0 / (n * 2) * 0.6)
      ..strokeCap = StrokeCap.round;
    // Mirror the bands around the circle for symmetry.
    for (var k = 0; k < n * 2; k++) {
      final i = k < n ? k : 2 * n - 1 - k;
      final a = -math.pi / 2 + k / (n * 2) * 2 * math.pi;
      final len = 4 + v[i] * size.shortestSide * 0.26;
      final dir = Offset(math.cos(a), math.sin(a));
      paint.color = ink.withValues(alpha: 0.35 + 0.65 * v[i]);
      canvas.drawLine(c + dir * r0, c + dir * (r0 + len), paint);
    }
    final avg = v.fold(0.0, (s, x) => s + x) / n;
    canvas.drawCircle(
      c,
      r0 * 0.8,
      Paint()
        ..color = ink.withValues(alpha: 0.12 + avg * 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(c, 4 + avg * 6, Paint()..color = led);
  }

  void _wave(Canvas canvas, Size size, Float32List v) {
    final n = v.length;
    final mid = size.height * 0.62;
    Path build(double scale) {
      final path = Path()..moveTo(0, mid);
      for (var i = 0; i < n; i++) {
        final x = i / (n - 1) * size.width;
        final y = mid - v[i] * size.height * 0.55 * scale;
        final px = (i - 0.5) / (n - 1) * size.width;
        i == 0 ? path.lineTo(x, y) : path.quadraticBezierTo(px, y, x, y);
      }
      return path;
    }

    final top = build(1);
    final fill = Path.from(top)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = ink.withValues(alpha: 0.12));
    canvas.drawPath(
      top,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    canvas.drawPath(
      build(0.6),
      Paint()
        ..color = ink.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  /// Two analog VU meters (lows and highs) with needle ballistics.
  void _meters(Canvas canvas, Size size, _VizState s) {
    final n = s.level.length;
    double avg(int from, int to) {
      var sum = 0.0;
      for (var i = from; i < to; i++) {
        sum += s.level[i];
      }
      return sum / math.max(1, to - from);
    }

    final targets = [avg(0, n ~/ 3), avg(n ~/ 3, n)];
    final labels = [l10n.low, l10n.high];
    final gap = size.width * 0.06;
    final w = math.min((size.width - gap) / 2, size.height * 1.5);
    final left = (size.width - (w * 2 + gap)) / 2;
    for (var m = 0; m < 2; m++) {
      // A real needle has inertia: it eases towards the level.
      final t = targets[m].clamp(0.0, 1.0);
      s.needle[m] = reduce ? t : s.needle[m] + (t - s.needle[m]) * (1 - math.pow(0.82, s.frames));
      final rect = Rect.fromLTWH(left + m * (w + gap), (size.height - w * 0.62) / 2, w, w * 0.62);
      _meter(canvas, rect, s.needle[m], labels[m]);
    }
  }

  void _meter(Canvas canvas, Rect r, double value, String label) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(12)),
      Paint()
        ..color = ink.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final pivot = Offset(r.center.dx, r.bottom - r.height * 0.12);
    final radius = r.height * 0.72;
    const sweep = 1.6; // radians, centered on straight up
    double angle(double v) => -math.pi / 2 - sweep / 2 + sweep * v;
    final tick = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k <= 20; k++) {
      final v = k / 20;
      final a = angle(v);
      final major = k % 5 == 0;
      final dir = Offset(math.cos(a), math.sin(a));
      // The last quarter of the scale is the "hot" zone, in LED color.
      tick.color = v > 0.75 ? led : ink.withValues(alpha: major ? 0.7 : 0.35);
      canvas.drawLine(pivot + dir * (radius - (major ? 12 : 7)), pivot + dir * radius, tick);
    }
    final a = angle(value);
    canvas.drawLine(
      pivot,
      pivot + Offset(math.cos(a), math.sin(a)) * (radius + 2),
      Paint()
        ..color = ink
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(pivot, 4, Paint()..color = ink);
    final tp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(color: ink.withValues(alpha: 0.6), fontSize: 12)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(r.left + 12, r.top + 10));
    tp.dispose();
  }

  /// The last ~3 seconds as a scrolling heat map: newest at the top,
  /// low frequencies on the left.
  void _waterfall(Canvas canvas, Size size) {
    const rows = 40;
    const step = Duration(milliseconds: 75);
    final n = spectrum.bands;
    final cw = size.width / n, ch = size.height / rows;
    final cell = Paint();
    final now = position.value;
    for (var r = 0; r < rows; r++) {
      final t = now - step * r;
      if (t.isNegative) break;
      spectrum.sample(t, _raw);
      final fade = 1 - r / rows;
      for (var i = 0; i < n; i++) {
        final v = _raw[i];
        if (v < 0.08) continue;
        cell.color = ink.withValues(alpha: (v * v * fade).clamp(0.0, 1.0));
        canvas.drawRect(Rect.fromLTWH(i * cw, r * ch, cw + 0.5, ch + 0.5), cell);
      }
    }
  }

  /// An LED bar-graph: lit dots up to the level, the peak dot in LED color.
  void _matrix(Canvas canvas, Size size, _VizState s) {
    const rows = 14;
    final cols = math.min(24, s.level.length);
    final per = s.level.length / cols;
    final cw = size.width / cols, rh = size.height / rows;
    final r = math.min(cw, rh) * 0.32;
    final off = Paint()..color = ink.withValues(alpha: 0.07);
    final on = Paint()..color = ink;
    final hot = Paint()..color = led;
    for (var c = 0; c < cols; c++) {
      var level = 0.0, peak = 0.0;
      for (var i = (c * per).floor(); i < ((c + 1) * per).floor(); i++) {
        level = math.max(level, s.level[i]);
        peak = math.max(peak, s.peak[i]);
      }
      final lit = (level * rows).round();
      final peakRow = (peak * rows).round().clamp(0, rows) - 1;
      for (var k = 0; k < rows; k++) {
        final center = Offset(c * cw + cw / 2, size.height - k * rh - rh / 2);
        canvas.drawCircle(center, r, k == peakRow && k >= lit ? hot : (k < lit ? on : off));
      }
    }
  }

  /// A flowing band: real band levels drive a sum of sines, drawn as one
  /// triangle strip, so it costs one draw call however wide the screen is.
  void _ribbon(Canvas canvas, Size size, _VizState s) {
    final n = s.level.length;
    final points = lowPower ? 64 : 160;
    final pos = Float32List(points * 4);
    final colors = Int32List(points * 2);
    final mid = size.height / 2;
    final amp = size.height * 0.42;
    const voices = 8;
    final top = ink.withValues(alpha: 0.9).toARGB32();
    final edge = ink.withValues(alpha: 0.12).toARGB32();
    for (var p = 0; p < points; p++) {
      final u = p / (points - 1);
      var y = 0.0;
      for (var v = 0; v < voices; v++) {
        final level = s.level[(v * n / voices).floor()];
        final freq = 1.0 + v * 1.7;
        y += level * math.sin(2 * math.pi * freq * u + s.time * (1.4 + v * 0.55) + v);
      }
      y = y / voices * 2.2;
      // Pinched at the ends so it doesn't look cut off.
      final envelope = math.sin(math.pi * u);
      final cy = mid + y * amp * envelope;
      final half = (2 + (6 + 26 * s.bass + 10 * s.beat.pulse) * envelope) / 2;
      final x = u * size.width;
      pos[p * 4] = x;
      pos[p * 4 + 1] = cy - half;
      pos[p * 4 + 2] = x;
      pos[p * 4 + 3] = cy + half;
      colors[p * 2] = top;
      colors[p * 2 + 1] = edge;
    }
    final vertices = ui.Vertices.raw(ui.VertexMode.triangleStrip, pos, colors: colors);
    canvas.drawVertices(vertices, BlendMode.srcOver, Paint());
    vertices.dispose();
  }

  /// Bass hits throw particles out from the middle. One batched draw.
  void _particles(Canvas canvas, Size size, _VizState s, double dt) {
    final count = lowPower ? 90 : 260;
    final p = s.particles(count);
    final c = size.center(Offset.zero);
    final reach = size.shortestSide * 0.6;
    final burst = s.beat.pulse > 0.92 ? (lowPower ? 10 : 26) : 0;
    var spawned = 0;
    final rnd = s.random;
    final drag = math.exp(-dt * 1.4);
    final fade = dt * (0.5 + s.mid * 0.3);
    final live = <double>[];
    final hot = <double>[];
    for (var i = 0; i < count; i++) {
      final o = i * 5;
      var life = p[o + 4];
      if (life <= 0) {
        // Always a few drifting, more on a beat.
        if (spawned < burst || rnd.nextDouble() < dt * (2 + 10 * s.bass)) {
          final a = rnd.nextDouble() * 2 * math.pi;
          final strength = (spawned < burst ? 0.6 + s.bass : 0.12 + 0.3 * s.mid) * (0.5 + rnd.nextDouble());
          p[o] = math.cos(a) * 0.04;
          p[o + 1] = math.sin(a) * 0.04;
          p[o + 2] = math.cos(a) * strength;
          p[o + 3] = math.sin(a) * strength;
          p[o + 4] = 1;
          life = 1;
          spawned++;
        } else {
          continue;
        }
      }
      p[o] += p[o + 2] * dt;
      p[o + 1] += p[o + 3] * dt;
      p[o + 2] *= drag;
      p[o + 3] *= drag;
      life -= fade;
      p[o + 4] = life;
      final x = c.dx + p[o] * reach, y = c.dy + p[o + 1] * reach;
      if (life > 0.72) {
        hot..add(x)..add(y);
      } else if (life > 0) {
        live..add(x)..add(y);
      }
    }
    final dot = 2.0 + 3 * s.bass;
    if (live.isNotEmpty) {
      canvas.drawRawPoints(ui.PointMode.points, Float32List.fromList(live), Paint()
        ..color = ink.withValues(alpha: 0.55)
        ..strokeWidth = dot
        ..strokeCap = StrokeCap.round);
    }
    if (hot.isNotEmpty) {
      canvas.drawRawPoints(ui.PointMode.points, Float32List.fromList(hot), Paint()
        ..color = led
        ..strokeWidth = dot + 1
        ..strokeCap = StrokeCap.round);
    }
    // The core swells with the bass.
    canvas.drawCircle(c, size.shortestSide * (0.03 + 0.05 * s.bass + 0.03 * s.beat.pulse), Paint()..color = ink.withValues(alpha: 0.85));
  }

  void _glow(Canvas canvas, Size size, _VizState s) {
    final program = shader;
    if (program == null) {
      // No shaders here: the same idea with a plain gradient.
      final c = size.center(Offset.zero);
      final r = size.shortestSide * (0.3 + 0.25 * s.bass + 0.08 * s.beat.pulse);
      canvas.drawCircle(c, r, Paint()
        ..shader = ui.Gradient.radial(c, r, [ink.withValues(alpha: 0.8), ink.withValues(alpha: 0)]));
      return;
    }
    final f = s.fragment ??= program.fragmentShader();
    var u = 0;
    void put(double v) => f.setFloat(u++, v);
    put(size.width);
    put(size.height);
    put(s.time % 1000);
    put(s.bass);
    put(s.mid);
    put(s.high);
    put(s.beat.pulse);
    put(ink.r);
    put(ink.g);
    put(ink.b);
    put(1);
    put(led.r);
    put(led.g);
    put(led.b);
    put(1);
    canvas.drawRect(Offset.zero & size, Paint()..shader = f);
  }

  @override
  bool shouldRepaint(VisualizerPainter old) =>
      old.spectrum != spectrum ||
      old.style != style ||
      old.ink != ink ||
      old.led != led ||
      old.reduce != reduce ||
      old.sensitivity != sensitivity ||
      old.lowPower != lowPower ||
      old.shader != shader;
}

class _VizState {
  final clock = Stopwatch()..start();
  double frames = 1;
  _VizState(int bands)
      : level = Float32List(bands),
        peak = Float32List(bands);
  final Float32List level;
  final Float32List peak;
  final needle = Float32List(2);
  final beat = BeatDetector();
  final random = math.Random(7);
  double bass = 0, mid = 0, high = 0, time = 0;
  ui.FragmentShader? fragment;
  Float32List? _particles;

  /// x, y, velocity x, velocity y, life per particle.
  Float32List particles(int count) {
    final p = _particles;
    if (p != null && p.length == count * 5) return p;
    return _particles = Float32List(count * 5);
  }
}

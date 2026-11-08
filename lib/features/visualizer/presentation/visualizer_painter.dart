import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../domain/beat_detector.dart';
import '../domain/spectrum.dart';
import '../../../l10n/l10n.dart';

/// Visualizer looks. Each one is drawn in one ink color (the theme's text or
/// primary color); the amber LED color only marks peaks, like the hold
/// lights on a real spectrum analyser.
enum VisualizerStyle {
  bars(Icons.bar_chart_rounded),
  wave(Icons.waves_rounded),
  radial(Icons.blur_circular_rounded);

  const VisualizerStyle(this.icon);
  final IconData icon;

  String get label => switch (this) {
        VisualizerStyle.bars => l10n.bars,
        VisualizerStyle.wave => l10n.wave,
        VisualizerStyle.radial => l10n.vizRing,
      };

  /// Styles that were removed fall back to bars.
  static VisualizerStyle parse(String s) => values.asNameMap()[s] ?? bars;
}

/// Draws one frame of a [BandSource] at [position] in [style].
///
/// Smoothing state (fast attack / slow decay levels, falling peak marks,
/// beats) lives in small per-source buffers so a rebuilt painter continues
/// where the last one stopped. Everything moves by real time, not by frame.
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
    required Listenable repaint,
  }) : super(repaint: repaint);

  final BandSource spectrum;
  final double sensitivity;
  final bool lowPower;
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
    if (n == 0) return;
    final s = _state.putIfAbsent(spectrum, () => _VizState(n));
    if (_state.length > 4) _state.remove(_state.keys.first);
    spectrum.sample(position.value, _raw);
    for (var i = 0; i < n; i++) {
      _raw[i] = applySensitivity(_raw[i], sensitivity);
    }
    final dt = math.min(0.1, s.clock.elapsedMicroseconds / 1e6);
    s.clock
      ..reset()
      ..start();
    if (reduce) {
      s.level.setRange(0, n, _raw);
    } else {
      smoothLevels(s.level, _raw, math.max(dt, 1 / 240), attack: 0.025, decay: 0.22);
    }
    final lows = math.max(1, n ~/ 8);
    var bass = 0.0;
    for (var i = 0; i < lows; i++) {
      bass += s.level[i];
    }
    s.bass = bass / lows;
    s.beat.update(s.bass, dt);
    // Peak marks hold for a moment, then fall at a steady speed.
    for (var i = 0; i < n; i++) {
      final v = s.level[i];
      if (v >= s.peak[i]) {
        s.peak[i] = v;
        s.hold[i] = 0.35;
      } else if (s.hold[i] > 0) {
        s.hold[i] -= dt;
      } else {
        s.peak[i] = math.max(v, s.peak[i] - 0.9 * dt);
      }
    }
    switch (style) {
      case VisualizerStyle.bars:
        _bars(canvas, size, s);
      case VisualizerStyle.wave:
        _wave(canvas, size, s);
      case VisualizerStyle.radial:
        _ring(canvas, size, s);
    }
  }

  /// [count] values from [v] (any length), each the max of its share, so a
  /// short hit in one band is never averaged away.
  static Float32List _resample(Float32List v, int count, Float32List out) {
    final n = v.length;
    for (var c = 0; c < count; c++) {
      final a = c * n / count, b = (c + 1) * n / count;
      var m = 0.0;
      for (var i = a.floor(); i < math.max(a.floor() + 1, b.ceil()) && i < n; i++) {
        m = math.max(m, v[i]);
      }
      out[c] = m;
    }
    return out;
  }

  /// Neighbours blend a little, so curves stay smooth instead of spiky.
  static void _soften(Float32List v, int count) {
    var prev = v[0];
    for (var i = 0; i < count; i++) {
      final cur = v[i];
      final next = i + 1 < count ? v[i + 1] : cur;
      v[i] = cur * 0.6 + (prev + next) * 0.2;
      prev = cur;
    }
  }

  /// Analyser bars with rounded tops and falling peak marks.
  void _bars(Canvas canvas, Size size, _VizState s) {
    final count = (size.width / (lowPower ? 14 : 10)).floor().clamp(16, s.level.length);
    final v = _resample(s.level, count, s.a);
    final p = _resample(s.peak, count, s.b);
    final slot = size.width / count;
    final w = math.max(2.0, slot * 0.62);
    final radius = Radius.circular(math.min(w / 2, 4));
    final floor = size.height - 2;
    final scale = size.height * 0.86;
    final paint = Paint();
    final cap = Paint()..color = led;
    for (var i = 0; i < count; i++) {
      final x = i * slot + (slot - w) / 2;
      final h = math.max(w * 0.5, v[i] * scale);
      // Taller bars are brighter: one ink, a tone shift by level.
      paint.color = ink.withValues(alpha: 0.28 + 0.72 * v[i]);
      canvas.drawRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(x, floor - h, w, h), topLeft: radius, topRight: radius),
        paint,
      );
      if (p[i] > 0.04) {
        final py = floor - math.max(w * 0.5, p[i] * scale) - 5;
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, py, w, 2.5), const Radius.circular(1.25)), cap);
      }
    }
  }

  /// A smooth shape mirrored both ways: bass in the middle, highs at the
  /// edges, opening up and down from the center line.
  void _wave(Canvas canvas, Size size, _VizState s) {
    final half = lowPower ? 24 : 40;
    final v = _resample(s.level, half, s.a);
    _soften(v, half);
    _soften(v, half);
    final mid = size.height / 2;
    final amp = size.height * 0.44;
    final cx = size.width / 2;
    // Bass in the middle, both sides out to the highs.
    final xs = Float32List(half * 2), ys = Float32List(half * 2);
    for (var k = 0; k < half * 2; k++) {
      final i = k < half ? half - 1 - k : k - half;
      final u = (i + 0.5) / half;
      xs[k] = k < half ? cx - u * cx : cx + u * cx;
      // Pinched at the ends so it doesn't look cut off.
      ys[k] = v[i] * amp * math.sin(math.pi / 2 * (1 - u * 0.92)) + 1;
    }
    Path outline(double sign, double scale) {
      final path = Path()..moveTo(0, mid);
      _spline(path, xs, ys, mid, sign, scale);
      path.lineTo(size.width, mid);
      return path;
    }

    final top = outline(-1, 1), bottom = outline(1, 1);
    final body = Path()
      ..addPath(top, Offset.zero)
      ..addPath(bottom, Offset.zero);
    // The halves never overlap (one above the line, one below): two fills.
    final fill = Paint()..color = ink.withValues(alpha: 0.10 + 0.10 * s.beat.pulse);
    canvas
      ..drawPath(Path.from(top)..close(), fill)
      ..drawPath(Path.from(bottom)..close(), fill);
    canvas.drawPath(
      body,
      Paint()
        ..color = ink.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    // A quieter inner line for depth.
    canvas.drawPath(
      outline(-1, 0.55)..addPath(outline(1, 0.55), Offset.zero),
      Paint()
        ..color = ink.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  /// Catmull-Rom through the points (x, mid + sign * y * scale).
  static void _spline(Path path, Float32List xs, Float32List ys, double mid, double sign, double scale) {
    final n = xs.length;
    Offset at(int i) {
      final k = i.clamp(0, n - 1);
      return Offset(xs[k], mid + sign * ys[k] * scale);
    }

    path.lineTo(at(0).dx, at(0).dy);
    for (var i = 0; i < n - 1; i++) {
      final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
      final c1 = p1 + (p2 - p0) / 6, c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
  }

  /// A ring that breathes: a smooth closed outline around a circle that
  /// swells on the beat.
  void _ring(Canvas canvas, Size size, _VizState s) {
    final half = lowPower ? 24 : 40;
    final v = _resample(s.level, half, s.a);
    _soften(v, half);
    final c = size.center(Offset.zero);
    final r0 = size.shortestSide * (0.24 + 0.025 * s.beat.pulse);
    final reach = size.shortestSide * 0.2;
    // Mirrored left/right: bass at the top and bottom meet smoothly.
    final count = half * 2;
    final pts = <Offset>[
      for (var k = 0; k < count; k++)
        () {
          final i = k < half ? k : count - 1 - k;
          final a = -math.pi / 2 + (k + 0.5) / count * 2 * math.pi;
          final r = r0 + 2 + v[i] * reach;
          return c + Offset(math.cos(a), math.sin(a)) * r;
        }(),
    ];
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 0; i < count; i++) {
      final p0 = pts[(i - 1 + count) % count], p1 = pts[i], p2 = pts[(i + 1) % count], p3 = pts[(i + 2) % count];
      final c1 = p1 + (p2 - p0) / 6, c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = ink.withValues(alpha: 0.12));
    canvas.drawPath(
      path,
      Paint()
        ..color = ink.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      c,
      r0,
      Paint()
        ..color = ink.withValues(alpha: 0.25 + 0.35 * s.beat.pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(VisualizerPainter old) =>
      old.spectrum != spectrum ||
      old.style != style ||
      old.ink != ink ||
      old.led != led ||
      old.reduce != reduce ||
      old.sensitivity != sensitivity ||
      old.lowPower != lowPower;
}

class _VizState {
  _VizState(int bands)
      : level = Float32List(bands),
        peak = Float32List(bands),
        hold = Float32List(bands);
  final clock = Stopwatch()..start();
  final Float32List level;
  final Float32List peak;

  /// Seconds a peak mark still waits before it falls.
  final Float32List hold;
  final beat = BeatDetector();
  double bass = 0;

  /// Scratch buffers for resampled values.
  final a = Float32List(256);
  final b = Float32List(256);
}

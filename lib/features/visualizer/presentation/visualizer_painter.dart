import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/beat_detector.dart';
import '../domain/spectrum.dart';

/// Live state of the visualizer: smoothed band levels, falling peak marks,
/// beats, the rings they send out and how far the disc has turned.
///
/// Fed from the playback ticker (before the frame is drawn), so the painter
/// and the spinning cover read the same numbers. Everything moves by real
/// time, never per frame: the same at 60 and 120 Hz.
class VizAnalyser extends ChangeNotifier {
  static const _rippleLife = 1.5;
  static const _maxRipples = 5;

  Float32List level = Float32List(0);
  Float32List peak = Float32List(0);
  Float32List _hold = Float32List(0);
  final _raw = Float32List(256);
  final beat = BeatDetector();
  final _clock = Stopwatch()..start();

  /// Ages (seconds) of the rings sent out by beats; negative = unused.
  final ripples = Float32List(_maxRipples)..fillRange(0, _maxRipples, -1);
  int _nextRipple = 0;

  /// How far the disc has turned, radians.
  double spin = 0;

  /// Overall loudness, smoothed (0..1).
  double energy = 0;

  double get pulse => beat.pulse;
  static double get rippleLife => _rippleLife;

  /// One step: samples [source] at [position] and moves everything on by
  /// the real time since the last step. [still] = reduced motion: raw
  /// levels, no spin, no rings.
  void update(BandSource source, Duration position, {double sensitivity = 1, bool still = false}) {
    final n = math.min(source.bands, _raw.length);
    if (n == 0) return;
    if (level.length != n) {
      level = Float32List(n);
      peak = Float32List(n);
      _hold = Float32List(n);
      beat.reset();
    }
    final dt = math.min(0.1, _clock.elapsedMicroseconds / 1e6);
    _clock
      ..reset()
      ..start();
    source.sample(position, _raw);
    for (var i = 0; i < n; i++) {
      _raw[i] = applySensitivity(_raw[i], sensitivity);
    }
    if (still) {
      level.setRange(0, n, _raw);
    } else {
      smoothLevels(level, _raw, math.max(dt, 1 / 240), attack: 0.02, decay: 0.2);
    }
    final lows = math.max(1, n ~/ 8);
    var bass = 0.0, all = 0.0;
    for (var i = 0; i < n; i++) {
      if (i < lows) bass += level[i];
      all += level[i];
    }
    final hit = beat.update(bass / lows, dt);
    energy += (all / n - energy) * (1 - math.exp(-dt / 0.25));
    // Peak marks hold for a moment, then fall at a steady speed.
    for (var i = 0; i < n; i++) {
      final v = level[i];
      if (v >= peak[i]) {
        peak[i] = v;
        _hold[i] = 0.4;
      } else if (_hold[i] > 0) {
        _hold[i] -= dt;
      } else {
        peak[i] = math.max(v, peak[i] - 0.8 * dt);
      }
    }
    if (still) {
      ripples.fillRange(0, _maxRipples, -1);
    } else {
      for (var i = 0; i < _maxRipples; i++) {
        if (ripples[i] >= 0) ripples[i] = ripples[i] + dt > _rippleLife ? -1 : ripples[i] + dt;
      }
      if (hit) {
        ripples[_nextRipple] = 0;
        _nextRipple = (_nextRipple + 1) % _maxRipples;
      }
      // About one turn every 30 s, with a little push on each beat.
      spin = (spin + dt * (0.2 + 1.4 * beat.pulse * beat.pulse)) % (2 * math.pi);
    }
    notifyListeners();
  }
}

/// The visualizer, in one ink color (the theme's primary): a radial spectrum
/// around the cover disc, mirrored left and right so the bass meets at the
/// top, a soft filled contour through the bar tips, amber peak dots (like
/// the hold lights on a real analyser) and thin rings that ripple out on
/// each beat. The cover itself is a widget on top (see `Visualizer`).
class VisualizerPainter extends CustomPainter {
  VisualizerPainter({
    required this.viz,
    required this.ink,
    required this.led,
    this.lowPower = false,
  }) : super(repaint: viz);

  final VizAnalyser viz;
  final Color ink;
  final Color led;
  final bool lowPower;

  /// The cover disc's radius, as a share of the shorter side.
  static const coverShare = 0.27;

  final _a = Float32List(128);
  final _b = Float32List(128);

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

  /// Neighbours blend a little, so the contour stays smooth.
  static void _soften(Float32List v, int count) {
    var prev = v[0];
    for (var i = 0; i < count; i++) {
      final cur = v[i];
      final next = i + 1 < count ? v[i + 1] : cur;
      v[i] = cur * 0.6 + (prev + next) * 0.2;
      prev = cur;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || viz.level.isEmpty) return;
    final half = lowPower ? 36 : 64;
    final count = half * 2;
    final v = _resample(viz.level, half, _a);
    final p = _resample(viz.peak, half, _b);
    final pulse = viz.pulse;
    final c = size.center(Offset.zero);
    final short = size.shortestSide;
    final cover = short * coverShare * (1 + 0.04 * pulse);
    final r0 = cover + math.max(6, short * 0.02);
    final edge = short / 2 - 8;
    final reach = math.max(8.0, (edge - r0 - 10) * (0.88 + 0.12 * pulse));
    final slot = 2 * math.pi * r0 / count;
    final w = (slot * 0.5).clamp(1.5, 5.0);

    // Rings from the beats: born at the disc, they fade as they spread.
    final ring = Paint()..style = PaintingStyle.stroke;
    for (final age in viz.ripples) {
      if (age < 0) continue;
      final t = age / VizAnalyser.rippleLife;
      final eased = 1 - math.pow(1 - t, 3).toDouble();
      ring
        ..color = ink.withValues(alpha: 0.32 * (1 - t) * (1 - t))
        ..strokeWidth = 0.6 + 1.6 * (1 - t);
      canvas.drawCircle(c, r0 + (edge - r0) * eased, ring);
    }

    double angle(int k) => -math.pi / 2 + (k + 0.5) / count * 2 * math.pi;
    int band(int k) => k < half ? k : count - 1 - k;

    // Soft body: the area between the disc and a smooth contour through the
    // bar tips (the bars' values blended with their neighbours).
    final soft = Float32List.fromList(v.sublist(0, half));
    _soften(soft, half);
    _soften(soft, half);
    final tips = <Offset>[
      for (var k = 0; k < count; k++)
        c + Offset(math.cos(angle(k)), math.sin(angle(k))) * (r0 + 3 + soft[band(k)] * reach * 1.04),
    ];
    final contour = Path()..moveTo(tips[0].dx, tips[0].dy);
    for (var i = 0; i < count; i++) {
      final p0 = tips[(i - 1 + count) % count], p1 = tips[i], p2 = tips[(i + 1) % count], p3 = tips[(i + 2) % count];
      final c1 = p1 + (p2 - p0) / 6, c2 = p2 - (p3 - p1) / 6;
      contour.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    contour.close();
    final body = Path.from(contour)
      ..addOval(Rect.fromCircle(center: c, radius: cover))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(body, Paint()..color = ink.withValues(alpha: 0.06 + 0.05 * viz.energy + 0.05 * pulse));
    canvas.drawPath(
      contour,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = ink.withValues(alpha: 0.22 + 0.2 * pulse),
    );

    // The bars: brighter as they grow, round ends.
    final bar = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w;
    final dots = Float32List(count * 2);
    var nDots = 0;
    for (var k = 0; k < count; k++) {
      final a = angle(k);
      final dir = Offset(math.cos(a), math.sin(a));
      final i = band(k);
      final len = 2 + v[i] * reach;
      bar.color = ink.withValues(alpha: 0.3 + 0.7 * v[i]);
      canvas.drawLine(c + dir * r0, c + dir * (r0 + len), bar);
      if (p[i] > 0.06) {
        final at = c + dir * (r0 + 2 + p[i] * reach + w + 3);
        dots[nDots++] = at.dx;
        dots[nDots++] = at.dy;
      }
    }
    if (nDots > 0) {
      canvas.drawRawPoints(
        ui.PointMode.points,
        Float32List.sublistView(dots, 0, nDots),
        Paint()
          ..color = led
          ..strokeCap = StrokeCap.round
          ..strokeWidth = w + 0.5,
      );
    }

    // A thin rim around the disc that lights up on the beat.
    canvas.drawCircle(
      c,
      cover + 1.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = ink.withValues(alpha: 0.3 + 0.5 * pulse),
    );
  }

  @override
  bool shouldRepaint(VisualizerPainter old) =>
      old.viz != viz || old.ink != ink || old.led != led || old.lowPower != lowPower;
}

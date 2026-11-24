import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'background_effects.dart';

/// A spiral galaxy in 3D, the camera slowly circling and tilting over it.
///
/// Stars sit in a thin disk (two arms, a haze between them, a round bulge),
/// each with its own temperature: blue-white young stars in the arms, warm
/// old ones in the bulge. Dark dust lanes follow the inner edge of the arms,
/// pink star-forming knots sit along them. Nearer stars are bigger and
/// brighter. The music runs through the disk: low notes light the middle,
/// high notes the rim, so the spectrum shows as rings breathing outwards; the
/// core flares with the bass, stars twinkle with the treble. The mouse pulls
/// stars like a small black hole; a click pushes a ring out.
///
/// One `drawRawAtlas` batch per layer (dust, stars, knots, core), nothing
/// allocated per frame.
class GalaxyEffect extends BackgroundEffect {
  GalaxyEffect(super.params, super.color, super.accent);

  ui.Image? _atlas;
  final _batch = SpriteBatch();

  int _n = 0;
  // Per star: radius 0..1, angle, height above the disk, temperature 0..1
  // (0 warm, 1 blue), twinkle seed, size.
  Float32List _r = Float32List(0), _th = Float32List(0), _h = Float32List(0), _temp = Float32List(0);
  Float32List _tw = Float32List(0), _sz = Float32List(0);
  int _knots = 0, _dust = 0;
  Float32List _kr = Float32List(0), _kth = Float32List(0), _dr = Float32List(0), _dth = Float32List(0);
  // Far background stars: x, y (0..1), brightness.
  Float32List _bg = Float32List(0);

  static const _cStar = [0.0, 0.0, 16.0, 16.0];
  static const _cGlow = [16.0, 0.0, 80.0, 64.0];

  static double _gauss(math.Random r) => math.sqrt(-2 * math.log(1 - r.nextDouble())) * math.cos(2 * math.pi * r.nextDouble());

  @override
  Future<void> prepare() async {
    _atlas = await renderSprites(80, 64, (c) {
      const s = Offset(8, 8);
      c.drawCircle(
        s,
        8,
        Paint()
          ..shader = ui.Gradient.radial(s, 8, const [Color(0xFFFFFFFF), Color(0xCCFFFFFF), Color(0x22FFFFFF), Color(0x00FFFFFF)],
              const [0, 0.22, 0.55, 1]),
      );
      const g = Offset(48, 32);
      c.drawCircle(
        g,
        32,
        Paint()
          ..shader = ui.Gradient.radial(g, 32, const [Color(0xFFFFFFFF), Color(0x55FFFFFF), Color(0x11FFFFFF), Color(0x00FFFFFF)],
              const [0, 0.3, 0.65, 1]),
      );
    });
  }

  @override
  void resize(Size s) {
    size = s;
    final area = (s.width * s.height / (1280 * 720)).clamp(0.3, 3.0);
    final n = (9000 * params.density * area * (lowDetail ? 0.45 : 1)).round().clamp(1000, 24000);
    if (n == _n) return;
    _n = n;
    final rnd = math.Random(21);
    _r = Float32List(n);
    _th = Float32List(n);
    _h = Float32List(n);
    _temp = Float32List(n);
    _tw = Float32List(n);
    _sz = Float32List(n);
    for (var i = 0; i < n; i++) {
      final pick = rnd.nextDouble();
      double r, th, h, temp;
      if (pick < 0.18) {
        // Bulge: round, dense, warm, a little thick.
        r = (_gauss(rnd).abs() * 0.09).clamp(0.0, 0.35);
        th = rnd.nextDouble() * 2 * math.pi;
        h = _gauss(rnd) * 0.05 * (1 - r * 2).clamp(0.2, 1.0);
        temp = 0.1 + rnd.nextDouble() * 0.25;
      } else if (pick < 0.8) {
        // Two logarithmic arms, looser further out.
        r = 0.08 + 0.92 * math.pow(rnd.nextDouble(), 0.85).toDouble();
        final arm = rnd.nextBool() ? 0.0 : math.pi;
        th = arm + math.log(r / 0.08) * 2.1 + _gauss(rnd) * (0.15 + 0.24 * r);
        h = _gauss(rnd) * 0.012;
        temp = 0.55 + rnd.nextDouble() * 0.45;
      } else {
        // Thin haze of older stars between the arms.
        r = 0.05 + 0.95 * math.sqrt(rnd.nextDouble());
        th = rnd.nextDouble() * 2 * math.pi;
        h = _gauss(rnd) * 0.02;
        temp = 0.25 + rnd.nextDouble() * 0.4;
      }
      _r[i] = r;
      _th[i] = th;
      _h[i] = h;
      _temp[i] = temp;
      _tw[i] = rnd.nextDouble();
      _sz[i] = 0.6 + math.pow(rnd.nextDouble(), 6).toDouble() * 1.6;
    }
    // Star-forming knots and dust along the arms.
    _knots = lowDetail ? 30 : 70;
    _dust = lowDetail ? 60 : 140;
    _kr = Float32List(_knots);
    _kth = Float32List(_knots);
    for (var i = 0; i < _knots; i++) {
      final r = 0.2 + 0.75 * rnd.nextDouble();
      _kr[i] = r;
      _kth[i] = (rnd.nextBool() ? 0.0 : math.pi) + math.log(r / 0.08) * 2.1 + _gauss(rnd) * 0.08;
    }
    _dr = Float32List(_dust);
    _dth = Float32List(_dust);
    for (var i = 0; i < _dust; i++) {
      final r = 0.12 + 0.75 * rnd.nextDouble();
      _dr[i] = r;
      // A little behind the arm: the inner edge.
      _dth[i] = (rnd.nextBool() ? 0.0 : math.pi) + math.log(r / 0.08) * 2.1 - 0.28 + _gauss(rnd) * 0.06;
    }
    final bgN = lowDetail ? 120 : 260;
    _bg = Float32List(bgN * 3);
    for (var i = 0; i < bgN; i++) {
      _bg[i * 3] = rnd.nextDouble();
      _bg[i * 3 + 1] = rnd.nextDouble();
      _bg[i * 3 + 2] = rnd.nextDouble();
    }
  }

  // Camera, set at the start of every frame.
  double _cx = 0, _cy = 0, _scale = 1, _tiltSin = 0, _tiltCos = 1, _yaw = 0, _cam = 3;

  /// Galaxy coordinates (radius, angle, height) to the screen. Returns the
  /// depth factor (bigger = nearer), the position in [_px], [_py].
  double _project(double r, double th, double h) {
    final a = th - _yaw;
    final x = r * math.cos(a);
    final y = r * math.sin(a);
    // Tilt around the x axis.
    final y2 = y * _tiltCos - h * _tiltSin;
    final z2 = y * _tiltSin + h * _tiltCos;
    final k = _cam / (_cam + z2);
    _px = _cx + x * _scale * k;
    _py = _cy + y2 * _scale * k;
    return k;
  }

  double _px = 0, _py = 0;

  @override
  void paint(Canvas canvas) {
    final atlas = _atlas;
    if (atlas == null || _n == 0 || size.isEmpty) return;
    final bright = params.brightness;
    _cx = size.width / 2;
    _cy = size.height / 2;
    _scale = math.min(size.width * 0.8, size.height * 1.5) * 0.46 * (1 + bass * 0.04);
    // Slow circling and nodding, so the 3D shows.
    _yaw = time * 0.045 * params.speed;
    final tilt = 1.05 + 0.18 * math.sin(time * 0.05 * params.speed);
    _tiltSin = math.sin(tilt);
    _tiltCos = math.cos(tilt);
    _cam = 3.4;
    final p = pointer;
    final pull = p != null && params.mouse > 0 ? params.mouse : 0.0;
    final treble = levelAt(0.85);
    final warm = Color.lerp(const Color(0xFFFFC98A), accent, 0.35)!;
    final blue = Color.lerp(const Color(0xFFB9D4FF), color, 0.45)!;

    // Far stars, a little parallax with the turn.
    for (var i = 0; i < _bg.length ~/ 3; i++) {
      final x = (_bg[i * 3] * size.width + time * 2) % size.width;
      final y = _bg[i * 3 + 1] * size.height;
      final b = _bg[i * 3 + 2];
      _batch.add(0.35 + b * 0.25, x, y, 0, _cStar[0], _cStar[1], _cStar[2], _cStar[3], mixArgb(blue, warm, b, (0.15 + 0.3 * b) * bright));
    }

    _batch.flush(canvas, atlas);

    // Core glow behind the stars.
    _project(0, 0, 0);
    final core = (_scale / 64) * (0.55 + bass * 0.35);
    _batch.add(core * 1.8, _px, _py, 0, _cGlow[0], _cGlow[1], _cGlow[2], _cGlow[3], mixArgb(warm, warm, 0, (0.22 + bass * 0.25) * bright));
    _batch.add(core * 0.8, _px, _py, 0, _cGlow[0], _cGlow[1], _cGlow[2], _cGlow[3],
        mixArgb(warm, const Color(0xFFFFFFFF), 0.5, (0.45 + bass * 0.35) * bright));

    // Stars.
    final size1 = params.size;
    for (var i = 0; i < _n; i++) {
      final r = _r[i];
      final k = _project(r, _th[i], _h[i]);
      var x = _px, y = _py;
      if (pull > 0) {
        final dx = p!.dx - x, dy = p.dy - y;
        final d2 = dx * dx + dy * dy + 400;
        final f = math.min(0.6, 2600 * pull / d2);
        x += dx * f;
        y += dy * f;
      }
      for (final w in waves) {
        final dx = x - w.at.dx, dy = y - w.at.dy;
        final d = math.sqrt(dx * dx + dy * dy);
        final off = (d - w.radius).abs();
        if (off < 80 && d > 0.01) {
          final f = (1 - off / 80) * w.power * 18;
          x += dx / d * f;
          y += dy / d * f;
        }
      }
      if (x < -8 || y < -8 || x > size.width + 8 || y > size.height + 8) continue;
      // The spectrum runs from the middle (low) to the rim (high).
      final band = levelAt(r);
      final tw = _tw[i];
      final twinkle = tw > 0.85 ? 0.6 + 0.4 * math.sin(time * (2 + tw * 5) + tw * 40) * (0.4 + treble) : 1.0;
      final a = ((0.28 + 0.5 * _temp[i] * 0.6 + band * 0.55) * twinkle * (0.55 + 0.45 * k) * bright).clamp(0.0, 1.0);
      final sc = 0.24 * _sz[i] * size1 * k * (1 + band * 0.25);
      final ink = mixArgb(warm, blue, _temp[i], a);
      _batch.add(sc, x, y, 0, _cStar[0], _cStar[1], _cStar[2], _cStar[3], ink);
      // Every few stars also light the space around them: the arms glow
      // as a whole instead of being only dots.
      if (i % 5 == 0) {
        _batch.add(0.13 * k * _scale / 300 * (1.4 - r * 0.6), x, y, 0, _cGlow[0], _cGlow[1], _cGlow[2], _cGlow[3],
            mixArgb(warm, blue, _temp[i], (0.085 + band * 0.07) * bright));
      }
    }
    _batch.flush(canvas, atlas);

    // Dust: dark lanes on the inner edge of the arms, over the stars there.
    final dustInk = Color.lerp(const Color(0xFF05040A), accent, 0.05)!;
    for (var i = 0; i < _dust; i++) {
      final k = _project(_dr[i], _dth[i], 0);
      _batch.add(0.42 * k * (0.6 + _dr[i]) * _scale / 300, _px, _py, _yaw, _cGlow[0], _cGlow[1], _cGlow[2], _cGlow[3],
          mixArgb(dustInk, dustInk, 0, 0.42));
    }
    _batch.flush(canvas, atlas);

    // Pink knots where stars are born, and the bright heart.
    const pink = Color(0xFFFF8FB8);
    final knotInk = Color.lerp(pink, accent, 0.3)!;
    for (var i = 0; i < _knots; i++) {
      final k = _project(_kr[i], _kth[i], 0);
      final pulse = 0.7 + 0.3 * math.sin(time * 0.6 + i) + levelAt(_kr[i]) * 0.5;
      _batch.add(0.16 * k * _scale / 300 * (0.8 + (i % 5) * 0.12), _px, _py, 0, _cGlow[0], _cGlow[1], _cGlow[2], _cGlow[3],
          mixArgb(knotInk, knotInk, 0, (0.42 * pulse * bright).clamp(0.0, 1.0)));
    }
    _project(0, 0, 0);
    _batch.add(core * 0.25, _px, _py, 0, _cGlow[0], _cGlow[1], _cGlow[2], _cGlow[3],
        mixArgb(const Color(0xFFFFFFFF), warm, 0.2, (0.7 + bass * 0.3) * bright));
    _batch.flush(canvas, atlas);
  }

  @override
  void dispose() => _atlas?.dispose();
}

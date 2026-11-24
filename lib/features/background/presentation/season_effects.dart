import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'background_effects.dart';

// Seasonal backgrounds. Moods, not clip art: out-of-focus lights, fog,
// silhouettes. Whatever doesn't move is recorded once per size into a
// picture; what moves goes out in a few `drawRawAtlas` batches from
// preallocated lists (lights add up like light). Everything moves by real
// time (dt); the music drives the lights, each light on its own band.

/// A soft round glow, white in the middle, gone at the edge.
void _glow(Canvas c, Offset at, double r, {double core = 1}) {
  c.drawCircle(
    at,
    r,
    Paint()
      ..shader = ui.Gradient.radial(
        at,
        r,
        [Color.fromRGBO(255, 255, 255, core), Color.fromRGBO(255, 255, 255, 0.35 * core), const Color(0x00FFFFFF)],
        const [0, 0.32, 1],
      ),
  );
}

/// A lens "bokeh" disc: an even fill, a slightly brighter rim, a soft edge.
void _bokeh(Canvas c, Offset at, double r) {
  c.drawCircle(
    at,
    r,
    Paint()
      ..shader = ui.Gradient.radial(
        at,
        r,
        const [Color(0xB3FFFFFF), Color(0xC2FFFFFF), Color(0xFFFFFFFF), Color(0x00FFFFFF)],
        const [0, 0.78, 0.9, 1],
      ),
  );
}

/// 0..1 smooth noise from a few sines (cheap, no allocation).
double _wobble(double t, double seed) =>
    0.5 + 0.25 * math.sin(t * 1.7 + seed) + 0.15 * math.sin(t * 4.3 + seed * 2.1) + 0.1 * math.sin(t * 11.1 + seed * 3.7);

/// True when this frame has no music level (paused, a stream).
bool _silent(Float32List levels) {
  for (var i = 0; i < levels.length; i++) {
    if (levels[i] > 0.02) return false;
  }
  return true;
}

// ------------------------------------------------------------------ Holiday

/// Winter lights, out of focus: warm bokeh drifting in two depths, each light
/// breathing with its own band of the music, fine snow falling in front, a
/// few big blurred flakes passing close by, small glints that twinkle with
/// the treble. The mouse shifts the depths a little and blows the snow away.
class HolidayEffect extends BackgroundEffect {
  HolidayEffect(super.params, super.color, super.accent);

  /// Mostly warm gold and amber, some red and green.
  static const _palette = [0xFFFFB347, 0xFFFF9A3C, 0xFFFFCB7A, 0xFFFF5A4E, 0xFFFFB347, 0xFF4FD488, 0xFFFFCB7A, 0xFFFF9A3C];

  /// The fairy lights in focus: warm white and gold.
  static const _fairy = [0xFFFFE2A8, 0xFFFFC46E, 0xFFFFE2A8, 0xFFFFD08A];

  ui.Image? _atlas;
  ui.Picture? _sky;
  final _batch = SpriteBatch();
  final _rnd = math.Random(12);

  // Lights: x, y (0..1), radius, layer (0 far, 1 near), color index, band, phase.
  Float32List _lights = Float32List(0);
  int _lightCount = 0;
  // Snow: x, y, depth, phase. Big blurred flakes: x, y, radius, speed.
  Float32List _snow = Float32List(0), _big = Float32List(0);
  int _flakes = 0, _bigCount = 0;
  // Glints: x, y (0..1), phase.
  Float32List _glints = Float32List(0);

  static const _cBokeh = [0.0, 0.0, 128.0, 128.0];
  static const _cGlow = [128.0, 0.0, 192.0, 64.0];
  static const _cDot = [128.0, 64.0, 144.0, 80.0];
  static const _cGlint = [144.0, 64.0, 192.0, 112.0];

  @override
  Future<void> prepare() async {
    _atlas = await renderSprites(192, 128, (c) {
      _bokeh(c, const Offset(64, 64), 63);
      _glow(c, const Offset(160, 32), 32);
      c.drawCircle(const Offset(136, 72), 3.2, Paint()..color = const Color(0xFFFFFFFF));
      _glow(c, const Offset(136, 72), 8, core: 0.6);
      // A four-point glint.
      const g = Offset(168, 88);
      final ray = Paint()
        ..shader = ui.Gradient.radial(g, 22, const [Color(0xFFFFFFFF), Color(0x00FFFFFF)])
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      c.drawLine(g - const Offset(22, 0), g + const Offset(22, 0), ray);
      c.drawLine(g - const Offset(0, 22), g + const Offset(0, 22), ray);
      _glow(c, g, 7);
    });
  }

  @override
  void resize(Size s) {
    size = s;
    if (s.isEmpty) return;
    final area = (s.width * s.height / (1280 * 720)).clamp(0.3, 3.0);
    final detail = lowDetail ? 0.55 : 1.0;
    final unit = s.shortestSide / 720;
    _lightCount = (40 * params.density * math.sqrt(area) * detail).round().clamp(12, 120);
    _lights = Float32List(_lightCount * 7);
    for (var i = 0; i < _lightCount; i++) {
      final o = i * 7;
      final near = i % 4 == 0;
      _lights[o] = _rnd.nextDouble();
      // Lights gather lower down, like a town or a tree far away.
      _lights[o + 1] = 0.15 + 0.85 * math.pow(_rnd.nextDouble(), 0.7);
      _lights[o + 2] = (near ? 34 + _rnd.nextDouble() * 40 : 10 + _rnd.nextDouble() * 22) * unit;
      _lights[o + 3] = near ? 1 : 0;
      _lights[o + 4] = _rnd.nextInt(_palette.length).toDouble();
      _lights[o + 5] = _rnd.nextDouble();
      _lights[o + 6] = _rnd.nextDouble() * 100;
    }
    _flakes = (220 * params.density * area * detail).round().clamp(40, 1400);
    _snow = Float32List(_flakes * 4);
    for (var i = 0; i < _flakes; i++) {
      _snow[i * 4] = _rnd.nextDouble() * s.width;
      _snow[i * 4 + 1] = _rnd.nextDouble() * s.height;
      _snow[i * 4 + 2] = 0.25 + 0.75 * _rnd.nextDouble();
      _snow[i * 4 + 3] = _rnd.nextDouble() * 100;
    }
    _bigCount = lowDetail ? 4 : 9;
    _big = Float32List(_bigCount * 4);
    for (var i = 0; i < _bigCount; i++) {
      _big[i * 4] = _rnd.nextDouble() * s.width;
      _big[i * 4 + 1] = _rnd.nextDouble() * s.height;
      _big[i * 4 + 2] = (10 + _rnd.nextDouble() * 16) * unit;
      _big[i * 4 + 3] = 70 + _rnd.nextDouble() * 60;
    }
    final glints = lowDetail ? 8 : 16;
    _glints = Float32List(glints * 3);
    for (var i = 0; i < glints; i++) {
      _glints[i * 3] = _rnd.nextDouble();
      _glints[i * 3 + 1] = _rnd.nextDouble() * 0.8;
      _glints[i * 3 + 2] = _rnd.nextDouble() * 100;
    }
    _strands = [
      (Offset(-s.width * 0.04, s.height * 0.6), Offset(s.width * 1.04, s.height * 0.52), s.height * 0.16, lowDetail ? 16 : 26, 0.0),
      (Offset(s.width * 0.35, s.height * 1.02), Offset(s.width * 1.04, s.height * 0.78), s.height * 0.08, lowDetail ? 8 : 14, 5.0),
    ];
    _sky?.dispose();
    _sky = _recordSky(s);
  }

  /// In-focus strings of fairy lights: ends, sag, bulbs, seed.
  var _strands = <(Offset, Offset, double, int, double)>[];
  final _wire = Path();
  final _wirePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2
    ..color = const Color(0x8C0A0C12);

  ui.Picture _recordSky(Size s) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final rect = Offset.zero & s;
    final top = Color.lerp(const Color(0xFF05070F), accent, 0.05)!;
    final low = Color.lerp(const Color(0xFF111A2E), accent, 0.1)!;
    c.drawRect(rect, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, s.height), [top, low]));
    // A warm haze low down, as if from lights far away.
    c.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.radial(Offset(s.width * 0.5, s.height * 1.1), s.longestSide * 0.7, [
          color.withValues(alpha: 0.16),
          color.withValues(alpha: 0.04),
          color.withValues(alpha: 0),
        ], const [0, 0.5, 1]),
    );
    return rec.endRecording();
  }

  @override
  void step(double dt) {
    super.step(dt);
    if (size.isEmpty) return;
    final sp = params.speed;
    final gust = math.sin(time * 0.07) * 14 + math.sin(time * 0.23) * 6 + bass * 30;
    final p = pointer;
    final push = p != null && params.mouse > 0 ? params.mouse : 0.0;
    for (var i = 0; i < _flakes; i++) {
      final o = i * 4;
      final depth = _snow[o + 2];
      var x = _snow[o] + (math.sin(time * (0.5 + depth * 0.5) + _snow[o + 3]) * 12 * depth + gust * depth) * dt;
      var y = _snow[o + 1] + (14 + 46 * depth) * sp * dt;
      if (push > 0) {
        final dx = x - p!.dx, dy = y - p.dy;
        final d2 = dx * dx + dy * dy;
        if (d2 < 9000) {
          final f = (1 - d2 / 9000) * 150 * push * dt * depth;
          final d = math.sqrt(d2) + 0.01;
          x += dx / d * f;
          y += dy / d * f;
        }
      }
      for (final w in waves) {
        final dx = x - w.at.dx, dy = y - w.at.dy;
        final d = math.sqrt(dx * dx + dy * dy);
        if ((d - w.radius).abs() < 60 && d > 0.01) {
          x += dx / d * w.power * 90 * dt;
          y += dy / d * w.power * 90 * dt;
        }
      }
      if (y > size.height + 8) {
        y = -8;
        x = _rnd.nextDouble() * size.width;
      }
      if (x < -10) x += size.width + 20;
      if (x > size.width + 10) x -= size.width + 20;
      _snow[o] = x;
      _snow[o + 1] = y;
    }
    for (var i = 0; i < _bigCount; i++) {
      final o = i * 4;
      _big[o] += (gust * 1.6 + math.sin(time * 0.4 + i) * 20) * dt;
      _big[o + 1] += _big[o + 3] * sp * dt;
      final r = _big[o + 2] * 2;
      if (_big[o + 1] > size.height + r) {
        _big[o + 1] = -r;
        _big[o] = _rnd.nextDouble() * size.width;
      }
      if (_big[o] < -r) _big[o] += size.width + 2 * r;
      if (_big[o] > size.width + r) _big[o] -= size.width + 2 * r;
    }
  }

  @override
  void paint(Canvas canvas) {
    final atlas = _atlas, sky = _sky;
    if (atlas == null || sky == null || size.isEmpty) return;
    canvas.drawPicture(sky);
    final bright = params.brightness;
    final quiet = _silent(levels);
    final p = pointer;
    final look = p == null ? Offset.zero : (p - size.center(Offset.zero)) * (0.02 * params.mouse);

    // Lights, far then near, adding up like light.
    for (var layer = 0; layer < 2; layer++) {
      for (var i = 0; i < _lightCount; i++) {
        final o = i * 7;
        if (_lights[o + 3] != layer) continue;
        final phase = _lights[o + 6];
        final drift = time * params.speed;
        final x = _lights[o] * size.width + math.sin(drift * 0.11 + phase) * 26 - look.dx * (layer + 1);
        final y = _lights[o + 1] * size.height + math.sin(drift * 0.08 + phase * 1.7) * 14 - look.dy * (layer + 1);
        final band = levelAt(_lights[o + 5]);
        final lit = quiet ? 0.45 + 0.35 * math.sin(drift * 0.5 + phase) : (0.25 + band * 1.1).clamp(0.0, 1.0);
        final r = _lights[o + 2] * params.size * (1 + bass * 0.06);
        final ink = Color(_palette[_lights[o + 4].toInt()]);
        final a = (layer == 0 ? 0.1 + 0.2 * lit : 0.06 + 0.12 * lit) * bright;
        _batch.add(r / 64, x, y, 0, _cBokeh[0], _cBokeh[1], _cBokeh[2], _cBokeh[3], mixArgb(ink, ink, 0, a));
      }
      _batch.flush(canvas, atlas, light: true);
    }

    // Glints twinkle with the treble.
    final treble = levelAt(0.85);
    for (var i = 0; i < _glints.length ~/ 3; i++) {
      final tw = math.max(0.0, math.sin(time * (0.7 + (i % 4) * 0.2) + _glints[i * 3 + 2]));
      final a = math.pow(tw, 6).toDouble() * (0.55 + treble * 0.6) * bright;
      if (a < 0.02) continue;
      _batch.add(0.5 + 0.3 * tw, _glints[i * 3] * size.width, _glints[i * 3 + 1] * size.height, 0, _cGlint[0], _cGlint[1], _cGlint[2],
          _cGlint[3], mixArgb(color, const Color(0xFFFFFFFF), 0.6, a.clamp(0.0, 1.0)));
    }
    _batch.flush(canvas, atlas, light: true);

    // Fairy lights in focus, swaying a little, each bulb on its band.
    _wire.reset();
    for (final (a, b, sag, bulbs, seed) in _strands) {
      final sway = math.sin(time * 0.6 + seed) * 5 + bass * 4;
      final mid = Offset((a.dx + b.dx) / 2 + sway, (a.dy + b.dy) / 2 + sag + sway * 0.5);
      final c = Offset(2 * mid.dx - (a.dx + b.dx) / 2, 2 * mid.dy - (a.dy + b.dy) / 2);
      _wire
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(c.dx, c.dy, b.dx, b.dy);
      for (var k = 1; k < bulbs; k++) {
        final t = k / bulbs, u = 1 - t;
        final x = u * u * a.dx + 2 * u * t * c.dx + t * t * b.dx;
        final y = u * u * a.dy + 2 * u * t * c.dy + t * t * b.dy + 5;
        final band = levelAt(((k * 5 + seed) % 17) / 16);
        final on = quiet ? 0.6 + 0.4 * math.sin(time * 1.3 - k * 0.6 + seed) : (0.45 + band * 0.9).clamp(0.0, 1.0);
        final ink = Color(_fairy[(k + seed.toInt()) % _fairy.length]);
        final sc = params.size * size.shortestSide / 720;
        _batch.add(0.55 * sc * (0.8 + on * 0.4), x, y, 0, _cGlow[0], _cGlow[1], _cGlow[2], _cGlow[3], mixArgb(ink, ink, 0, 0.32 * on * bright));
        _batch.add(0.9 * sc, x, y, 0, _cDot[0], _cDot[1], _cDot[2], _cDot[3],
            mixArgb(ink, const Color(0xFFFFFFFF), 0.4 * on, (0.45 + 0.55 * on) * bright));
      }
    }
    canvas.drawPath(_wire, _wirePaint);
    _batch.flush(canvas, atlas, light: true);

    // Fine snow, in focus.
    final snow = Color.lerp(const Color(0xFFFFFFFF), accent, 0.25)!;
    for (var i = 0; i < _flakes; i++) {
      final depth = _snow[i * 4 + 2];
      _batch.add((0.2 + depth * 0.32) * params.size, _snow[i * 4], _snow[i * 4 + 1], 0, _cDot[0], _cDot[1], _cDot[2], _cDot[3],
          mixArgb(snow, snow, 0, (0.3 + depth * 0.55) * bright));
    }
    _batch.flush(canvas, atlas);
    // Big flakes right in front of the lens, out of focus.
    for (var i = 0; i < _bigCount; i++) {
      final r = _big[i * 4 + 2] * params.size;
      _batch.add(r / 32, _big[i * 4], _big[i * 4 + 1], 0, _cGlow[0], _cGlow[1], _cGlow[2], _cGlow[3], mixArgb(snow, snow, 0, 0.16 * bright));
    }
    _batch.flush(canvas, atlas, light: true);
  }

  @override
  void dispose() {
    _atlas?.dispose();
    _sky?.dispose();
  }
}

// ---------------------------------------------------------------- Halloween

/// The witching hour: a pale moon behind thin drifting clouds, bare branches
/// at the edge, rolling fog in layers, will-o'-wisps floating through it
/// (each pulsing with its band of the music), embers, a few bats crossing
/// now and then.
/// Bats keep away from the mouse; a click scatters them.
class HalloweenEffect extends BackgroundEffect {
  HalloweenEffect(super.params, super.color, super.accent);

  ui.Image? _atlas;
  ui.Picture? _scene;
  final _batch = SpriteBatch();
  final _rnd = math.Random(31);

  // Bats: x, y base, speed (signed), phase, wait before the next pass, size.
  Float32List _bats = Float32List(0);
  int _batCount = 0;
  // Wisps: home x, y (0..1), radius, band, phase.
  Float32List _wisps = Float32List(0);
  int _wispCount = 0;
  // Embers: x, y, vx, life 0..1, seed.
  Float32List _embers = Float32List(0);
  int _emberCount = 0;
  // Fog: x, y, width, speed, alpha. Clouds over the moon: x, y, width, speed.
  Float32List _fog = Float32List(0), _clouds = Float32List(0);
  int _fogCount = 0;
  final _pumpkins = <(Offset, double)>[];
  Offset _moon = Offset.zero;
  double _moonR = 0;

  static const _cGlow = [0.0, 0.0, 64.0, 64.0];
  static const _cDot = [64.0, 0.0, 80.0, 16.0];
  static const _cCloud = [80.0, 0.0, 208.0, 40.0];
  static const _batW = 48.0, _batH = 24.0, _batTop = 64.0;
  static const _cPumpkin = [0.0, 96.0, 72.0, 160.0];
  static const _cFace = [72.0, 96.0, 144.0, 160.0];

  @override
  Future<void> prepare() async {
    _atlas = await renderSprites(208, 160, (c) {
      _glow(c, const Offset(32, 32), 32);
      c.drawCircle(const Offset(72, 8), 2.4, Paint()..color = const Color(0xFFFFFFFF));
      _glow(c, const Offset(72, 8), 8, core: 0.7);
      // A long soft wisp of cloud or fog.
      c.save();
      c.translate(144, 20);
      c.scale(1, 0.31);
      c.drawCircle(
        Offset.zero,
        63,
        Paint()..shader = ui.Gradient.radial(Offset.zero, 63, const [Color(0xFFFFFFFF), Color(0x55FFFFFF), Color(0x00FFFFFF)], const [0, 0.45, 1]),
      );
      c.restore();
      // Bat frames: wings from up to down.
      for (var f = 0; f < 4; f++) {
        final ox = f * _batW, oy = _batTop;
        final lift = const [-0.9, -0.3, 0.35, -0.1][f];
        final ink = Paint()..color = const Color(0xFFFFFFFF);
        c.drawOval(Rect.fromCenter(center: Offset(ox + 24, oy + 13), width: 6, height: 9), ink);
        c.drawCircle(Offset(ox + 24, oy + 8.5), 2.6, ink);
        for (final side in const [-1.0, 1.0]) {
          final tip = Offset(ox + 24 + side * 22, oy + 12 + lift * 10);
          c.drawPath(
            Path()
              ..moveTo(ox + 24 + side * 2, oy + 10)
              ..quadraticBezierTo(ox + 24 + side * 10, oy + 4 + lift * 8, tip.dx, tip.dy)
              ..quadraticBezierTo(ox + 24 + side * 17, oy + 14 + lift * 4, ox + 24 + side * 14, oy + 13 + lift * 5)
              ..quadraticBezierTo(ox + 24 + side * 10, oy + 16 + lift * 3, ox + 24 + side * 7, oy + 14 + lift * 3)
              ..quadraticBezierTo(ox + 24 + side * 5, oy + 17, ox + 24 + side * 2, oy + 15)
              ..close(),
            ink,
          );
        }
      }
      // A carved pumpkin in the dark: a black body, only its edge catches
      // the light (tinted at draw time).
      const pc = Offset(36, 130);
      final body = Path();
      for (final (dx, w) in const [(-15.0, 28.0), (15.0, 28.0), (-7.0, 30.0), (7.0, 30.0), (0.0, 28.0)]) {
        body.addOval(Rect.fromCenter(center: pc + Offset(dx, 2), width: w, height: 44));
      }
      c.drawPath(body, Paint()..color = const Color(0xFF0A0606));
      c.save();
      c.clipPath(body);
      c.drawCircle(
        pc + const Offset(18, 14),
        46,
        Paint()
          ..shader = ui.Gradient.radial(pc + const Offset(18, 14), 46, const [Color(0x00FFFFFF), Color(0x00FFFFFF), Color(0x80FFFFFF)],
              const [0, 0.72, 1]),
      );
      c.restore();
      c.drawRect(Rect.fromLTWH(pc.dx - 2.5, pc.dy - 27, 5, 8), Paint()..color = const Color(0xFF0A0606));
      // Its face, white so it takes the candle's color.
      final face = Paint()..color = const Color(0xFFFFFFFF);
      const fc = Offset(108, 130);
      for (final s in const [-1.0, 1.0]) {
        c.drawPath(
          Path()
            ..moveTo(fc.dx + s * 11, fc.dy - 11)
            ..lineTo(fc.dx + s * 4, fc.dy - 2)
            ..lineTo(fc.dx + s * 17, fc.dy - 2)
            ..close(),
          face,
        );
      }
      final mouth = Path()..moveTo(fc.dx - 17, fc.dy + 6);
      for (var k = 0; k <= 8; k++) {
        mouth.lineTo(fc.dx - 17 + k * 34 / 8, fc.dy + (k.isEven ? 8 : 12));
      }
      mouth
        ..quadraticBezierTo(fc.dx, fc.dy + 21, fc.dx - 17, fc.dy + 6)
        ..close();
      c.drawPath(mouth, face);
    });
  }

  @override
  void resize(Size s) {
    size = s;
    if (s.isEmpty) return;
    final area = (s.width * s.height / (1280 * 720)).clamp(0.3, 3.0);
    final detail = lowDetail ? 0.55 : 1.0;
    _moonR = s.shortestSide * 0.15;
    _moon = Offset(s.width * 0.7, s.height * 0.3);
    _batCount = (5 * params.density * detail).round().clamp(2, 14);
    _bats = Float32List(_batCount * 6);
    for (var i = 0; i < _batCount; i++) {
      _newBat(i, s);
      _bats[i * 6 + 4] = _rnd.nextDouble() * 12;
    }
    _wispCount = (7 * params.density * math.sqrt(area) * detail).round().clamp(3, 20);
    _wisps = Float32List(_wispCount * 5);
    for (var i = 0; i < _wispCount; i++) {
      _wisps[i * 5] = 0.08 + 0.84 * _rnd.nextDouble();
      _wisps[i * 5 + 1] = 0.55 + 0.33 * _rnd.nextDouble();
      _wisps[i * 5 + 2] = 0.6 + _rnd.nextDouble() * 0.6;
      _wisps[i * 5 + 3] = _rnd.nextDouble();
      _wisps[i * 5 + 4] = _rnd.nextDouble() * 100;
    }
    // No pumpkins (the user asked): embers rise from the ground instead.
    _pumpkins.clear();

    _emberCount = (40 * params.density * area * detail).round().clamp(8, 260);
    _embers = Float32List(_emberCount * 5);
    for (var i = 0; i < _emberCount; i++) {
      _newEmber(i, s);
      _embers[i * 5 + 3] = _rnd.nextDouble();
    }
    _fogCount = lowDetail ? 10 : 18;
    _fog = Float32List(_fogCount * 5);
    for (var i = 0; i < _fogCount; i++) {
      final low = i / _fogCount;
      _fog[i * 5] = _rnd.nextDouble() * s.width;
      _fog[i * 5 + 1] = s.height * (0.6 + 0.4 * low + (_rnd.nextDouble() - 0.5) * 0.06);
      _fog[i * 5 + 2] = s.width * (0.45 + _rnd.nextDouble() * 0.45);
      _fog[i * 5 + 3] = (6 + _rnd.nextDouble() * 14) * (i.isEven ? 1 : -1);
      _fog[i * 5 + 4] = 0.05 + 0.07 * low;
    }
    _clouds = Float32List(4 * 4);
    for (var i = 0; i < 4; i++) {
      _clouds[i * 4] = _rnd.nextDouble() * s.width;
      _clouds[i * 4 + 1] = _moon.dy + (_rnd.nextDouble() - 0.4) * _moonR * 1.6;
      _clouds[i * 4 + 2] = _moonR * (3 + _rnd.nextDouble() * 2.5);
      _clouds[i * 4 + 3] = 5 + _rnd.nextDouble() * 8;
    }
    _scene?.dispose();
    _scene = _recordScene(s);
  }

  void _newBat(int i, Size s) {
    final o = i * 6;
    final dir = _rnd.nextBool() ? 1.0 : -1.0;
    _bats[o] = dir > 0 ? -40 : s.width + 40;
    _bats[o + 1] = s.height * (0.1 + _rnd.nextDouble() * 0.4);
    _bats[o + 2] = dir * (70 + _rnd.nextDouble() * 80);
    _bats[o + 3] = _rnd.nextDouble() * 10;
    // Seconds before it flies (a few at a time, not a swarm).
    _bats[o + 4] = 3 + _rnd.nextDouble() * 14;
    _bats[o + 5] = 0.45 + _rnd.nextDouble() * 0.45;
  }

  void _newEmber(int i, Size s) {
    final o = i * 5;
    if (_pumpkins.isNotEmpty && _rnd.nextDouble() < 0.6) {
      final (at, sc) = _pumpkins[_rnd.nextInt(_pumpkins.length)];
      _embers[o] = at.dx + (_rnd.nextDouble() - 0.5) * 20 * sc;
      _embers[o + 1] = at.dy - 34 * sc * s.shortestSide / 720;
    } else {
      _embers[o] = _rnd.nextDouble() * s.width;
      _embers[o + 1] = s.height * (0.75 + _rnd.nextDouble() * 0.25);
    }
    _embers[o + 2] = (_rnd.nextDouble() - 0.5) * 16;
    _embers[o + 3] = 0;
    _embers[o + 4] = _rnd.nextDouble() * 50;
  }

  ui.Picture _recordScene(Size s) {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    final rect = Offset.zero & s;
    final top = Color.lerp(const Color(0xFF040208), accent, 0.06)!;
    final low = Color.lerp(const Color(0xFF1A0C22), accent, 0.2)!;
    c.drawRect(rect, Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(0, s.height), [top, low], const [0.05, 1]));
    final rnd = math.Random(8);
    final star = Paint();
    for (var i = 0; i < (lowDetail ? 40 : 80); i++) {
      star.color = Color.fromRGBO(255, 255, 255, 0.12 + rnd.nextDouble() * 0.3);
      c.drawCircle(Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * 0.55), 0.4 + rnd.nextDouble() * 0.8, star);
    }
    // The moon: a wide halo, the disc, soft darker seas (no hard craters).
    c.drawCircle(
      _moon,
      _moonR * 4,
      Paint()
        ..shader = ui.Gradient.radial(_moon, _moonR * 4, [
          const Color(0xFFE8E4FF).withValues(alpha: 0.16),
          const Color(0xFFE8E4FF).withValues(alpha: 0.05),
          const Color(0x00E8E4FF),
        ], const [0, 0.35, 1]),
    );
    c.drawCircle(
      _moon,
      _moonR,
      Paint()
        ..shader = ui.Gradient.radial(
          _moon - Offset(_moonR * 0.25, _moonR * 0.25),
          _moonR * 1.35,
          const [Color(0xFFF7F3E8), Color(0xFFE2DACB), Color(0xFFBDB3A6)],
          const [0, 0.65, 1],
        ),
    );
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: _moon, radius: _moonR)));
    for (final (dx, dy, r, a) in const [
      (-0.35, -0.15, 0.42, 0.22),
      (0.2, 0.15, 0.36, 0.18),
      (-0.1, 0.45, 0.25, 0.16),
      (0.4, -0.4, 0.2, 0.12),
      (0.05, -0.05, 0.6, 0.06),
    ]) {
      final at = _moon + Offset(dx, dy) * _moonR;
      c.drawCircle(
        at,
        r * _moonR,
        Paint()..shader = ui.Gradient.radial(at, r * _moonR, [Color.fromRGBO(120, 110, 100, a), const Color.fromRGBO(120, 110, 100, 0)]),
      );
    }
    c.restore();
    // Far hills, then the near ground: plain silhouettes.
    final far = Paint()..color = Color.lerp(const Color(0xFF0E0715), accent, 0.1)!;
    final hills = Path()..moveTo(0, s.height);
    for (var x = 0.0; x <= s.width + 8; x += 8) {
      hills.lineTo(x, s.height * 0.76 + math.sin(x / s.width * 4.4 + 0.7) * s.height * 0.035 + math.sin(x / s.width * 11) * s.height * 0.008);
    }
    hills
      ..lineTo(s.width, s.height)
      ..close();
    c.drawPath(hills, far);
    final dark = Paint()..color = const Color(0xFF030105);
    final ground = Path()..moveTo(0, s.height);
    for (var x = 0.0; x <= s.width + 8; x += 8) {
      ground.lineTo(x, s.height * 0.9 + math.sin(x / s.width * 3 + 2) * s.height * 0.02);
    }
    ground
      ..lineTo(s.width, s.height)
      ..close();
    c.drawPath(ground, dark);
    // A few leaning graves, small.
    for (final (f, lean) in const [(0.62, -0.06), (0.67, 0.04), (0.71, -0.02)]) {
      final x = s.width * f, y = s.height * 0.9 + math.sin(f * 3 + 2) * s.height * 0.02;
      final w = s.shortestSide * 0.028, h = s.shortestSide * 0.042;
      c.save();
      c.translate(x, y + 2);
      c.rotate(lean);
      c.drawRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(-w / 2, -h, w, h + 6), topLeft: Radius.circular(w / 2), topRight: Radius.circular(w / 2)),
        dark,
      );
      c.restore();
    }
    // Bare branches reaching in from the top left, and a lone tree on the right.
    _branch(c, Offset(-s.width * 0.02, s.height * 0.05), 0.35, s.shortestSide * 0.22, s.shortestSide * 0.018, 6, rnd, dark);
    _branch(c, Offset(s.width * 0.9, s.height * 0.91), -math.pi / 2 - 0.06, s.shortestSide * 0.2, s.shortestSide * 0.024, 7, rnd, dark);
    return rec.endRecording();
  }

  /// A crooked branch that splits and thins out, bending a little on the way.
  void _branch(Canvas c, Offset from, double angle, double len, double width, int depth, math.Random rnd, Paint ink) {
    final paint = Paint()
      ..color = ink.color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final bend = (rnd.nextDouble() - 0.5) * 0.5;
    final mid = from + Offset(math.cos(angle + bend), math.sin(angle + bend)) * len * 0.5;
    final to = from + Offset(math.cos(angle), math.sin(angle)) * len;
    c.drawPath(Path()..moveTo(from.dx, from.dy)..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy), paint);
    if (depth == 0 || width < 0.6) return;
    final n = rnd.nextDouble() < 0.35 ? 3 : 2;
    for (var k = 0; k < n; k++) {
      final spread = (k - (n - 1) / 2) * (0.5 + rnd.nextDouble() * 0.3) + (rnd.nextDouble() - 0.5) * 0.3;
      _branch(c, to, angle + spread, len * (0.6 + rnd.nextDouble() * 0.2), width * 0.62, depth - 1, rnd, ink);
    }
  }

  @override
  void step(double dt) {
    super.step(dt);
    if (size.isEmpty) return;
    final sp = params.speed;
    final p = pointer;
    final avoid = p != null && params.mouse > 0 ? params.mouse : 0.0;
    for (var i = 0; i < _batCount; i++) {
      final o = i * 6;
      if (_bats[o + 4] > 0) {
        _bats[o + 4] -= dt;
        continue;
      }
      _bats[o] += _bats[o + 2] * dt * sp * (1 + levelAt(0.5) * 0.5);
      if (avoid > 0) {
        final dx = _bats[o] - p!.dx, dy = _bats[o + 1] - p.dy;
        final d2 = dx * dx + dy * dy;
        if (d2 < 22000) _bats[o + 1] += (dy >= 0 ? 1 : -1) * (1 - d2 / 22000) * 200 * avoid * dt;
      }
      for (final w in waves) {
        final dx = _bats[o] - w.at.dx, dy = _bats[o + 1] - w.at.dy;
        final d = math.sqrt(dx * dx + dy * dy);
        if ((d - w.radius).abs() < 90 && d > 0.01) {
          _bats[o] += dx / d * w.power * 160 * dt;
          _bats[o + 1] += dy / d * w.power * 160 * dt;
        }
      }
      if (_bats[o] < -60 || _bats[o] > size.width + 60) _newBat(i, size);
    }
    final rise = (26 + bass * 50) * sp;
    for (var i = 0; i < _emberCount; i++) {
      final o = i * 5;
      _embers[o + 3] += dt * (0.16 + bass * 0.1) * sp;
      if (_embers[o + 3] >= 1) {
        _newEmber(i, size);
        continue;
      }
      _embers[o] += (_embers[o + 2] + math.sin(time * 1.3 + _embers[o + 4]) * 12) * dt;
      _embers[o + 1] -= rise * dt;
    }
    for (var i = 0; i < _fogCount; i++) {
      final o = i * 5;
      _fog[o] += _fog[o + 3] * dt * sp;
      final half = _fog[o + 2] / 2;
      if (_fog[o] < -half) _fog[o] += size.width + 2 * half;
      if (_fog[o] > size.width + half) _fog[o] -= size.width + 2 * half;
    }
    for (var i = 0; i < 4; i++) {
      _clouds[i * 4] += _clouds[i * 4 + 3] * dt * sp;
      final half = _clouds[i * 4 + 2] / 2;
      if (_clouds[i * 4] > size.width + half) _clouds[i * 4] = -half;
    }
  }

  double _flicker(int k) => (_wobble(time * 2.4, k * 3.1) * 0.55 + 0.45 + bass * 0.5).clamp(0.0, 1.4);

  @override
  void paint(Canvas canvas) {
    final atlas = _atlas, scene = _scene;
    if (atlas == null || scene == null || size.isEmpty) return;
    canvas.drawPicture(scene);
    final bright = params.brightness;
    final unit = size.shortestSide / 720;
    final quiet = _silent(levels);

    // Thin clouds sliding over the moon.
    final veil = Color.lerp(const Color(0xFF3A2E48), accent, 0.2)!;
    for (var i = 0; i < 4; i++) {
      _batch.add(_clouds[i * 4 + 2] / 128, _clouds[i * 4], _clouds[i * 4 + 1], 0, _cCloud[0], _cCloud[1], _cCloud[2], _cCloud[3],
          mixArgb(veil, veil, 0, 0.5));
    }
    _batch.flush(canvas, atlas);

    // Bats, small and far.
    final flap = 9 + levelAt(0.5) * 7;
    for (var i = 0; i < _batCount; i++) {
      final o = i * 6;
      if (_bats[o + 4] > 0) continue;
      final y = _bats[o + 1] + math.sin(time * 1.6 + _bats[o + 3]) * 16;
      final f = ((time * flap + _bats[o + 3]) % 4).floor();
      final l = f * _batW;
      _batch.add(_bats[o + 5] * params.size * unit * 1.1, _bats[o], y, _bats[o + 2] > 0 ? 0.08 : -0.08, l, _batTop, l + _batW,
          _batTop + _batH, 0xF2030106);
    }
    _batch.flush(canvas, atlas);

    // Fog, far layers first.
    final mist = Color.lerp(const Color(0xFF9C8FB8), accent, 0.35)!;
    for (var i = 0; i < _fogCount; i++) {
      final o = i * 5;
      _batch.add(_fog[o + 2] / 128, _fog[o], _fog[o + 1], 0, _cCloud[0], _cCloud[1], _cCloud[2], _cCloud[3],
          mixArgb(mist, mist, 0, _fog[o + 4] * bright * (1 + bass * 0.4)));
    }
    _batch.flush(canvas, atlas);

    // Will-o'-wisps drifting in the fog, each on its own band, and the
    // lanterns' glow on the ground.
    final flame = Color.lerp(const Color(0xFFFFA34D), color, 0.5)!;
    for (var i = 0; i < _wispCount; i++) {
      final o = i * 5;
      final ph = _wisps[o + 4];
      final t = time * params.speed;
      final x = (_wisps[o] + 0.05 * math.sin(t * 0.13 + ph) + 0.02 * math.sin(t * 0.37 + ph * 2)) * size.width;
      final y = (_wisps[o + 1] + 0.03 * math.sin(t * 0.21 + ph * 1.3)) * size.height;
      final band = levelAt(_wisps[o + 3]);
      final lit = quiet ? 0.55 + 0.45 * _wobble(t * 0.6, ph) : (0.35 + band * 1.1).clamp(0.0, 1.2);
      final r = 34 * _wisps[o + 2] * unit * params.size * (0.85 + lit * 0.3);
      _batch.add(r / 32 * 2.2, x, y, 0, _cGlow[0], _cGlow[1], _cGlow[2], _cGlow[3], mixArgb(flame, flame, 0, 0.2 * lit * bright));
      _batch.add(r / 32 * 0.6, x, y, 0, _cGlow[0], _cGlow[1], _cGlow[2], _cGlow[3],
          mixArgb(flame, const Color(0xFFFFF0C8), 0.5, (0.8 * lit * bright).clamp(0.0, 1.0)));
    }
    for (var k = 0; k < _pumpkins.length; k++) {
      final (at, sc0) = _pumpkins[k];
      final sc = sc0 * params.size * unit;
      final fl = _flicker(k);
      _batch.add(3.2 * sc * (0.9 + fl * 0.15), at.dx, at.dy - 8 * sc, 0, _cGlow[0], _cGlow[1], _cGlow[2], _cGlow[3],
          mixArgb(flame, flame, 0, (0.12 + 0.12 * fl) * bright));
    }
    _batch.flush(canvas, atlas, light: true);
    // The pumpkins: dark, an edge of candle light, the face glowing.
    for (var k = 0; k < _pumpkins.length; k++) {
      final (at, sc0) = _pumpkins[k];
      final sc = sc0 * params.size * unit;
      _batch.add(sc, at.dx, at.dy - 30 * sc, 0, _cPumpkin[0], _cPumpkin[1], _cPumpkin[2], _cPumpkin[3],
          mixArgb(flame, flame, 0, (0.6 + 0.3 * _flicker(k)).clamp(0.0, 1.0)));
    }
    _batch.flush(canvas, atlas);
    for (var k = 0; k < _pumpkins.length; k++) {
      final (at, sc0) = _pumpkins[k];
      final sc = sc0 * params.size * unit;
      final fl = _flicker(k);
      _batch.add(sc, at.dx, at.dy - 30 * sc, 0, _cFace[0], _cFace[1], _cFace[2], _cFace[3],
          mixArgb(flame, const Color(0xFFFFE9A8), fl * 0.35, (0.45 + 0.5 * fl).clamp(0.0, 1.0)));
    }
    // Embers.
    for (var i = 0; i < _emberCount; i++) {
      final o = i * 5;
      final fade = math.sin(_embers[o + 3] * math.pi);
      final tw = 0.6 + 0.4 * math.sin(time * 8 + _embers[o + 4] * 7) * (0.5 + levelAt(0.85));
      _batch.add(0.35 + 0.15 * fade, _embers[o], _embers[o + 1], 0, _cDot[0], _cDot[1], _cDot[2], _cDot[3],
          mixArgb(flame, color, 0.5, (fade * tw * 0.8 * bright).clamp(0.0, 1.0)));
    }
    _batch.flush(canvas, atlas, light: true);
    // The lowest fog drifts in front of everything a little.
    for (var i = _fogCount ~/ 2; i < _fogCount; i++) {
      final o = i * 5;
      _batch.add(_fog[o + 2] / 128 * 1.2, size.width - _fog[o], _fog[o + 1] + size.height * 0.04, 0, _cCloud[0], _cCloud[1], _cCloud[2],
          _cCloud[3], mixArgb(mist, mist, 0, _fog[o + 4] * 0.6 * bright));
    }
    _batch.flush(canvas, atlas);
  }

  @override
  void dispose() {
    _atlas?.dispose();
    _scene?.dispose();
  }
}

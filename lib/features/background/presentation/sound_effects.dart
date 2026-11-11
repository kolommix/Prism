import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'background_effects.dart';

// Backgrounds made for the music: they draw the song's whole spectrum
// ([BackgroundEffect.levels]), not only the bass. Every one also moves calmly
// without music, so a paused or streamed song still has a living background.

/// Characters from light to heavy. Index 0 is empty space.
const _smokeRamp = ' .:-=+*#%@';
const _donutRamp = ' .,-~:;=!*#\$@';

double _dpr() => ui.PlatformDispatcher.instance.views.firstOrNull?.devicePixelRatio ?? 1;

/// One sheet with every character of a ramp, made at the size it is shown
/// (no shimmer from shrinking), drawn in one `drawRawAtlas` batch.
class _GlyphSheet {
  _GlyphSheet(this.chars);
  final String chars;
  static const _perRow = 16;

  ui.Image? image;
  double sprite = 24;
  double _built = 0;

  int get count => chars.length;

  Future<void> build(double want) async {
    if (want == _built && image != null) return;
    _built = want;
    final rows = (chars.length / _perRow).ceil();
    final img = await renderSprites((_perRow * want).round(), (rows * want).round(), (c) {
      for (var i = 0; i < chars.length; i++) {
        final tp = TextPainter(
          text: TextSpan(
            text: chars[i],
            style: TextStyle(
              color: Colors.white,
              fontSize: want * 0.82,
              fontWeight: FontWeight.w600,
              height: 1,
              fontFamily: 'Consolas',
              fontFamilyFallback: const ['Cascadia Mono', 'Courier New', 'monospace'],
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final x = (i % _perRow) * want + want / 2, y = (i ~/ _perRow) * want + want / 2;
        tp.paint(c, Offset(x - tp.width / 2, y - tp.height / 2));
        tp.dispose();
      }
    });
    if (_built != want) {
      img.dispose(); // a newer size was asked for meanwhile
      return;
    }
    image?.dispose();
    image = img;
    sprite = want;
  }

  void add(SpriteBatch batch, int index, double x, double y, double cell, int argb) {
    final l = (index % _perRow) * sprite, t = (index ~/ _perRow) * sprite;
    batch.add(cell / sprite, x, y, 0, l, t, l + sprite, t + sprite, argb);
  }

  void dispose() {
    image?.dispose();
    image = null;
  }
}

/// Mouse glow and click rings, shared by the ASCII styles: how much brighter
/// the cell at (x, y) gets.
double _touchLight(BackgroundEffect e, double x, double y) {
  var add = 0.0;
  final p = e.pointer;
  if (p != null && e.params.mouse > 0) {
    final dx = x - p.dx, dy = y - p.dy;
    final d2 = dx * dx + dy * dy;
    const r = 140.0;
    if (d2 < r * r) {
      final f = 1 - math.sqrt(d2) / r;
      add += f * f * 0.55 * e.params.mouse;
    }
  }
  for (final w in e.waves) {
    final dx = x - w.at.dx, dy = y - w.at.dy;
    final off = (math.sqrt(dx * dx + dy * dy) - w.radius).abs();
    if (off < 60) add += (1 - off / 60) * w.power * 0.6;
  }
  return add;
}

// --------------------------------------------------------------- ASCII smoke

/// The spectrum as ASCII smoke: every moment of the song is a row of
/// characters at the bottom (bass in the middle, treble at the sides) that
/// rises, sways and fades like smoke. Without music a calm flame idles there.
class AsciiSmokeEffect extends BackgroundEffect {
  AsciiSmokeEffect(super.params, super.color, super.accent);

  final _sheet = _GlyphSheet(_smokeRamp);
  final _batch = SpriteBatch();
  final _rnd = math.Random(3);
  double _cell = 14;
  int _cols = 0, _rows = 0;

  /// Ring of rows, [_head] the newest.
  Float32List _hist = Float32List(0);
  int _head = 0;
  double _tick = 0;

  /// Seconds per row at speed 1.
  static const _rowTime = 0.05;

  @override
  Future<void> prepare() => _sheet.build((_cell * _dpr()).ceilToDouble().clamp(10.0, 64.0));

  @override
  void resize(Size s) {
    size = s;
    _cell = 14 * params.size * (lowDetail ? 1.4 : 1);
    _cols = math.max(1, (s.width / _cell).ceil());
    _rows = math.max(1, (s.height / _cell).ceil() + 1);
    _hist = Float32List(_cols * _rows);
    _head = 0;
    unawaited(prepare());
  }

  void _push() {
    if (_cols == 0) return;
    _head = (_head - 1 + _rows) % _rows;
    final base = _head * _cols;
    for (var c = 0; c < _cols; c++) {
      final x = (c + 0.5) / _cols;
      final d = (x * 2 - 1).abs(); // 0 middle, 1 sides
      // Idle flame: two slow waves, stronger in the middle.
      final idle = (0.3 + 0.22 * math.sin(c * 0.37 + time * 1.4) * math.sin(c * 0.11 - time * 0.6)) * (1 - d * 0.7);
      final music = levelAt(math.pow(d, 0.85).toDouble() * 0.92);
      final v = math.max(idle, music * 1.15) + bass * 0.18 * (1 - d) + (_rnd.nextDouble() - 0.5) * 0.08;
      _hist[base + c] = v.clamp(0.0, 1.4);
    }
  }

  @override
  void step(double dt) {
    super.step(dt);
    _tick += dt * params.speed * (1 + bass * 0.6) / _rowTime;
    var guard = 0;
    while (_tick >= 1 && guard++ < 8) {
      _tick -= 1;
      _push();
    }
    if (_tick >= 1) _tick = 0;
  }

  @override
  void paint(Canvas canvas) {
    final atlas = _sheet.image;
    if (atlas == null || _hist.isEmpty) return;
    final bright = params.brightness;
    final n = _sheet.count;
    for (var k = 0; k < _rows; k++) {
      final age = k + _tick;
      final life = 1 - age / _rows;
      if (life <= 0) continue;
      final fade = math.pow(life, 1.1).toDouble();
      final y = size.height - (age + 0.5) * _cell;
      // Older rows sway further, like smoke in a soft draft.
      final sway = math.sin(k * 0.21 + time * 0.8) * age * 0.05 * _cell;
      // And spread: an old row reads its neighbours a little.
      final row = ((_head + k) % _rows) * _cols;
      for (var c = 0; c < _cols; c++) {
        var v = _hist[row + c];
        if (k > 6) {
          final l = _hist[row + math.max(0, c - 1)], r = _hist[row + math.min(_cols - 1, c + 1)];
          v = v * 0.5 + (l + r) * 0.25;
        }
        final x = (c + 0.5) * _cell + sway;
        v = v * fade + _touchLight(this, x, y) * life;
        if (v < 0.07) continue;
        final idx = (math.pow(math.min(1.0, v), 0.7) * (n - 1)).round().clamp(1, n - 1);
        final a = (0.45 + 0.55 * math.min(1.0, v * 1.4)) * bright;
        _sheet.add(_batch, idx, x, y, _cell, mixArgb(color, accent, v - 0.25, a));
      }
    }
    _batch.flush(canvas, atlas);
  }

  @override
  void dispose() => _sheet.dispose();
}

// --------------------------------------------------------------- ASCII donut

/// A torus drawn in ASCII characters, lit from the top left. It spins faster
/// with the bass, its tube swells where the spectrum is loud (bass on one side
/// of the ring, treble on the other), it leans towards the mouse and a click
/// gives it a spin. Faint sparks around it twinkle with the treble.
class AsciiDonutEffect extends BackgroundEffect {
  AsciiDonutEffect(super.params, super.color, super.accent);

  final _sheet = _GlyphSheet(_donutRamp);
  final _batch = SpriteBatch();
  double _cell = 12;
  int _cols = 0, _rows = 0;
  Float32List _depth = Float32List(0);
  Float32List _light = Float32List(0);
  double _a = 0.4, _b = 0;
  double _spin = 0;
  Offset _lean = Offset.zero;

  @override
  Future<void> prepare() => _sheet.build((_cell * _dpr()).ceilToDouble().clamp(10.0, 64.0));

  @override
  void resize(Size s) {
    size = s;
    _cell = 12 * params.size * (lowDetail ? 1.4 : 1);
    _cols = math.max(1, (s.width / _cell).ceil());
    _rows = math.max(1, (s.height / _cell).ceil());
    _depth = Float32List(_cols * _rows);
    _light = Float32List(_cols * _rows);
    unawaited(prepare());
  }

  @override
  void burst(Offset at, double strength) {
    super.burst(at, strength);
    _spin += strength * 2.2;
  }

  @override
  void step(double dt) {
    super.step(dt);
    final sp = params.speed;
    _spin *= math.exp(-dt * 1.5);
    _a += dt * sp * (0.55 + bass * 1.1 + _spin);
    _b += dt * sp * (0.3 + bass * 0.5 + _spin * 0.5);
    var want = Offset.zero;
    final p = pointer;
    if (p != null && params.mouse > 0 && !size.isEmpty) {
      want = Offset(p.dx / size.width - 0.5, p.dy / size.height - 0.5) * (0.9 * params.mouse);
    }
    _lean = Offset.lerp(_lean, want, 1 - math.exp(-dt * 3))!;
  }

  @override
  void paint(Canvas canvas) {
    final atlas = _sheet.image;
    if (atlas == null || _depth.isEmpty) return;
    _depth.fillRange(0, _depth.length, 0);
    const r1 = 1.0, r2 = 2.0, k2 = 10.0;
    // Fits the screen at any angle, also swollen by loud music.
    const reachOut = r2 + r1 * 1.4;
    final k1 = math.min(size.width, size.height) * 0.54 * (k2 - reachOut) / reachOut * (1 + bass * 0.06);
    final cx = size.width / 2, cy = size.height / 2;
    final a = _a + _lean.dy, b = _b + _lean.dx;
    final ca = math.cos(a), sa = math.sin(a), cb = math.cos(b), sb = math.sin(b);
    // Enough steps that no cell is skipped, no more.
    final reach = k1 / k2 / _cell;
    final detail = lowDetail ? 0.6 : 1.0;
    final np = (2 * math.pi * (r1 + r2) * reach * 1.7 * detail).clamp(60, 520).round();
    final nt = (2 * math.pi * r1 * reach * 2.0 * detail).clamp(24, 200).round();
    for (var j = 0; j < np; j++) {
      final phi = j / np * 2 * math.pi;
      final cp = math.cos(phi), spp = math.sin(phi);
      // Around the ring: bass at phi 0, treble at the far side, both halves.
      final band = levelAt(1 - (phi / math.pi - 1).abs());
      final tube = r1 * (1 + 0.32 * math.min(1.2, band));
      for (var i = 0; i < nt; i++) {
        final th = i / nt * 2 * math.pi;
        final ct = math.cos(th), st = math.sin(th);
        final ox = r2 + tube * ct, oy = tube * st;
        final x = ox * (cb * cp + sa * sb * spp) - oy * ca * sb;
        final y = ox * (sb * cp - sa * cb * spp) + oy * ca * cb;
        final z = k2 + ca * ox * spp + oy * sa;
        final ooz = 1 / z;
        final col = ((cx + k1 * ooz * x) / _cell).floor();
        final row = ((cy - k1 * ooz * y) / _cell).floor();
        if (col < 0 || row < 0 || col >= _cols || row >= _rows) continue;
        final at = row * _cols + col;
        if (ooz > _depth[at]) {
          _depth[at] = ooz;
          _light[at] = cp * ct * sb - ca * ct * spp - sa * st + cb * (ca * st - ct * sa * spp);
        }
      }
    }
    final bright = params.brightness;
    final n = _sheet.count;
    final treble = levelAt(0.8);
    for (var row = 0; row < _rows; row++) {
      final y = (row + 0.5) * _cell;
      for (var col = 0; col < _cols; col++) {
        final at = row * _cols + col;
        final x = (col + 0.5) * _cell;
        if (_depth[at] == 0) {
          // Sparks: a few fixed cells that twinkle, more with the treble.
          final h = ((col * 73856093) ^ (row * 19349663)) & 1023;
          if (h > 14) continue;
          final tw = 0.5 + 0.5 * math.sin(time * (1.5 + h * 0.2) + h);
          final v = (0.1 + treble * 0.5) * tw + _touchLight(this, x, y) * 0.5;
          if (v < 0.05) continue;
          _sheet.add(_batch, 1 + h % 3, x, y, _cell, mixArgb(color, accent, v, v * bright));
          continue;
        }
        final l = (_light[at] / 1.4142).clamp(0.0, 1.0);
        final v = l + _touchLight(this, x, y) * 0.4;
        final idx = (1 + v * (n - 2)).round().clamp(1, n - 1);
        final alpha = (0.35 + 0.65 * math.min(1.0, v)) * bright;
        _sheet.add(_batch, idx, x, y, _cell, mixArgb(color, accent, v * v + bass * 0.2, alpha));
      }
    }
    _batch.flush(canvas, atlas);
  }

  @override
  void dispose() => _sheet.dispose();
}

// --------------------------------------------------------------------- Ridges

/// The song as a landscape: the front line is the spectrum right now (bass in
/// the middle), and every moment rolls back into the distance as a ridge.
/// Lines in front hide the ones behind. Without music, soft hills roll by.
/// The mouse raises a peak under it, a click sends a wave down the valley.
class RidgesEffect extends BackgroundEffect {
  RidgesEffect(super.params, super.color, super.accent);

  static const _points = 112;
  int _lines = 0;
  Float32List _hist = Float32List(0);
  int _head = 0;
  double _tick = 0;
  final _rnd = math.Random(11);
  final _bumps = <(double, double)>[]; // x 0..1, strength
  final _clear = Paint()..blendMode = BlendMode.clear;
  final _stroke = Paint()
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  /// Seconds per ridge at speed 1.
  static const _rowTime = 0.07;

  @override
  Future<void> prepare() async {}

  @override
  void resize(Size s) {
    size = s;
    final n = (34 * params.density * (lowDetail ? 0.6 : 1)).round().clamp(10, 72);
    if (n != _lines) {
      _lines = n;
      _hist = Float32List(_lines * _points);
      _head = 0;
      // Start with a full landscape, not an empty plain.
      for (var i = 0; i < _lines; i++) {
        time += _rowTime;
        _push();
      }
    }
  }

  @override
  void burst(Offset at, double strength) {
    super.burst(at, strength);
    if (!size.isEmpty) _bumps.add((at.dx / size.width, strength));
  }

  void _push() {
    if (_lines == 0) return;
    _head = (_head - 1 + _lines) % _lines;
    final base = _head * _points;
    final p = pointer;
    final px = p == null || size.isEmpty || params.mouse <= 0 ? null : p.dx / size.width;
    for (var i = 0; i < _points; i++) {
      final x = i / (_points - 1);
      final d = (x * 2 - 1).abs();
      final env = math.exp(-math.pow((x - 0.5) / 0.26, 2));
      final idle = (0.5 + 0.5 * math.sin(x * 9 + time * 0.5)) * (0.5 + 0.5 * math.sin(x * 23 - time * 0.8 + 1.3)) * 0.42 + _rnd.nextDouble() * 0.03;
      final music = levelAt(math.pow(d, 0.8).toDouble() * 0.95);
      var h = idle * env * (1 - math.min(1.0, bass + music) * 0.4) + music * (0.35 + 0.65 * env) * 0.95 + bass * 0.15 * env;
      if (px != null) h += math.exp(-math.pow((x - px) / 0.05, 2)) * 0.45 * params.mouse;
      for (final (bx, s) in _bumps) {
        h += math.exp(-math.pow((x - bx) / 0.07, 2)) * 0.7 * s;
      }
      _hist[base + i] = h;
    }
    // A click lasts a few ridges, fading.
    for (var i = _bumps.length - 1; i >= 0; i--) {
      final (bx, s) = _bumps[i];
      if (s < 0.08) {
        _bumps.removeAt(i);
      } else {
        _bumps[i] = (bx, s * 0.6);
      }
    }
  }

  @override
  void step(double dt) {
    super.step(dt);
    _tick += dt * params.speed / _rowTime;
    var guard = 0;
    while (_tick >= 1 && guard++ < 8) {
      _tick -= 1;
      _push();
    }
    if (_tick >= 1) _tick = 0;
  }

  @override
  void paint(Canvas canvas) {
    if (_lines == 0 || size.isEmpty) return;
    final w = size.width, h = size.height;
    final horizon = h * 0.2, front = h * 0.97;
    final bright = params.brightness;
    _stroke.strokeWidth = 1.5 * params.size;
    // Back to front: each line hides what is behind it.
    for (var k = _lines - 1; k >= 0; k--) {
      final depth = (k + _tick) / _lines; // 0 front, 1 far
      if (depth > 1) continue;
      final persp = 1 / (1 + depth * 3);
      final ground = horizon + (front - horizon) * (persp - 0.25) / 0.75;
      final lift = h * 0.36 * persp;
      final spread = w * 1.3 * persp;
      final row = ((_head + k) % _lines) * _points;
      final path = Path();
      var peak = 0.0;
      for (var i = 0; i < _points; i++) {
        final v = _hist[row + i];
        if (v > peak) peak = v;
        final x = w / 2 + (i / (_points - 1) - 0.5) * spread;
        final y = ground - v * lift;
        i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      final fill = Path.from(path)
        ..lineTo(w / 2 + spread / 2, h)
        ..lineTo(w / 2 - spread / 2, h)
        ..close();
      canvas.drawPath(fill, _clear);
      // Far lines fade into the haze; the newest one fades in as it appears.
      final appear = k == 0 ? (1 - _tick) : 1.0;
      final a = bright * (0.15 + 0.85 * math.pow(1 - depth, 1.4)) * appear;
      _stroke.color = Color(mixArgb(color, accent, peak * 1.2 - 0.2, a));
      canvas.drawPath(path, _stroke);
    }
  }
}

// --------------------------------------------------------------------- Galaxy

/// A spiral galaxy seen at a slant: two arms of stars around a dense bulge,
/// turning slowly. The core flares with the bass, the arms brighten with the
/// mids, stars twinkle with the treble. The mouse pulls stars like a small
/// black hole; a click pushes a ring out.
class GalaxyEffect extends BackgroundEffect {
  GalaxyEffect(super.params, super.color, super.accent);

  int _n = 0;
  // Per star: distance 0..1, angle, twinkle seed, kind (0 disk, 1 arm, 2 bulge).
  Float32List _r = Float32List(0), _th = Float32List(0), _tw = Float32List(0);
  Uint8List _kind = Uint8List(0);
  final _pts = [Float32List(0), Float32List(0), Float32List(0)];
  final _count = [0, 0, 0];
  final _dot = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  static double _gauss(math.Random r) => math.sqrt(-2 * math.log(1 - r.nextDouble())) * math.cos(2 * math.pi * r.nextDouble());

  @override
  Future<void> prepare() async {}

  @override
  void resize(Size s) {
    size = s;
    final area = (s.width * s.height / (1280 * 720)).clamp(0.3, 3.0);
    final n = (5000 * params.density * area * (lowDetail ? 0.5 : 1)).round().clamp(400, 18000);
    if (n == _n) return;
    _n = n;
    final rnd = math.Random(21);
    _r = Float32List(n);
    _th = Float32List(n);
    _tw = Float32List(n);
    _kind = Uint8List(n);
    for (var i = 0; i < n; i++) {
      final pick = rnd.nextDouble();
      if (pick < 0.16) {
        // Bulge: dense, round, in the middle.
        _kind[i] = 2;
        _r[i] = (_gauss(rnd).abs() * 0.07).clamp(0.0, 0.3);
        _th[i] = rnd.nextDouble() * 2 * math.pi;
      } else if (pick < 0.78) {
        // Arms: two log spirals, looser at the edge.
        _kind[i] = 1;
        final r = 0.08 + 0.92 * math.pow(rnd.nextDouble(), 0.8);
        _r[i] = r;
        final arm = rnd.nextBool() ? 0.0 : math.pi;
        _th[i] = arm + math.log(r / 0.08) * 1.9 + _gauss(rnd) * (0.18 + 0.22 * r);
      } else {
        // Disk: a thin haze of stars between the arms.
        _kind[i] = 0;
        _r[i] = 0.05 + 0.95 * math.sqrt(rnd.nextDouble());
        _th[i] = rnd.nextDouble() * 2 * math.pi;
      }
      _tw[i] = rnd.nextDouble();
    }
    for (var b = 0; b < 3; b++) {
      _pts[b] = Float32List(n * 2);
    }
  }

  @override
  void paint(Canvas canvas) {
    if (_n == 0 || size.isEmpty) return;
    final cx = size.width / 2, cy = size.height / 2;
    final scale = math.min(size.width, size.height * 1.6) * 0.48 * (1 + bass * 0.05);
    const squash = 0.55;
    final turn = time * 0.06;
    final mids = levelAt(0.45), treble = levelAt(0.85);
    final p = pointer;
    final pull = p != null && params.mouse > 0 ? params.mouse : 0.0;
    _count.fillRange(0, 3, 0);
    for (var i = 0; i < _n; i++) {
      final r = _r[i];
      // Turns as one, the middle a little ahead (no winding up over time).
      final th = _th[i] - turn - 0.15 * math.sin(time * 0.05) * (1 - r);
      var x = cx + r * math.cos(th) * scale;
      var y = cy + r * math.sin(th) * scale * squash;
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
      final tw = _tw[i];
      final twinkle = 0.5 + 0.5 * math.sin(time * (2 + tw * 4) + tw * 40);
      final kind = _kind[i];
      final b = kind == 2 || (tw > 0.9 && twinkle * (0.5 + treble) > 0.55)
          ? 2
          : (kind == 1 ? 1 : 0);
      final list = _pts[b];
      final c = _count[b]++;
      list[c * 2] = x;
      list[c * 2 + 1] = y;
    }
    final bright = params.brightness;
    final core = scale * (0.22 + bass * 0.14);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: core * 2, height: core * 2 * squash * 1.3),
      Paint()
        ..shader = ui.Gradient.radial(Offset(cx, cy), core, [
          accent.withValues(alpha: (0.3 + bass * 0.4).clamp(0.0, 1.0) * bright),
          color.withValues(alpha: 0.1 * bright),
          color.withValues(alpha: 0),
        ], const [0, 0.4, 1]),
    );
    final sizes = [1.2, 1.7, 2.2];
    final alphas = [0.3 + mids * 0.2, 0.7 + mids * 0.3, 0.95];
    for (var b = 0; b < 3; b++) {
      if (_count[b] == 0) continue;
      _dot
        ..strokeWidth = sizes[b] * params.size
        ..color = Color(mixArgb(color, accent, b / 2, (alphas[b] * bright).clamp(0.0, 1.0)));
      canvas.drawRawPoints(ui.PointMode.points, Float32List.sublistView(_pts[b], 0, _count[b] * 2), _dot);
    }
  }
}

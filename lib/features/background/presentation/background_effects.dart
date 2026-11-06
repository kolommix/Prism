import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../domain/background_config.dart';

import 'field_effects.dart';
/// One animated background: state + how to draw it.
///
/// Performance: everything is drawn in one `drawRawAtlas` / `drawRawPoints`
/// batch from preallocated lists, so thousands of symbols cost about a
/// millisecond and nothing is allocated per sprite.
abstract class BackgroundEffect {
  BackgroundEffect(this.params, this.color, this.accent);

  BgParams params;
  Color color;
  Color accent;

  Size size = Size.zero;
  double time = 0;

  /// Fewer sprites (battery saver).
  bool lowDetail = false;

  /// Doesn't move by itself: drawn once, no ticker.
  bool get isStatic => false;

  /// Pointer in this effect's coordinates, null when away.
  Offset? pointer;

  /// 0..1+ bass already scaled by the music setting.
  double bass = 0;

  final waves = <Shockwave>[];

  /// Builds the sprite images; nothing is painted until it finishes.
  Future<void> prepare();

  void resize(Size s);

  void update(BgParams p, Color c, Color a) {
    final rebuild = p.density != params.density || p.size != params.size;
    params = p;
    color = c;
    accent = a;
    if (rebuild && size != Size.zero) resize(size);
  }

  /// Advances by [dt] seconds.
  void step(double dt) {
    time += dt;
    for (var i = waves.length - 1; i >= 0; i--) {
      waves[i].age += dt;
      if (waves[i].age > Shockwave.life) waves.removeAt(i);
    }
  }

  void paint(Canvas canvas);

  /// A click or a logo tap.
  void burst(Offset at, double strength) {
    if (waves.length >= 6) waves.removeAt(0);
    waves.add(Shockwave(at, strength));
  }

  void dispose() {}

  static BackgroundEffect create(BackgroundStyle style, BgParams p, Color color, Color accent, {BackgroundConfig config = const BackgroundConfig()}) {
    final BackgroundEffect e = switch (style) {
      BackgroundStyle.constellation => ConstellationEffect(p, color, accent),
      BackgroundStyle.ripple => RippleEffect(p, color, accent),
      BackgroundStyle.mesh => ShaderFieldEffect(0, p, color, accent),
      BackgroundStyle.aurora => ShaderFieldEffect(1, p, color, accent),
      BackgroundStyle.blobs => ShaderFieldEffect(2, p, color, accent),
      BackgroundStyle.grain => ShaderFieldEffect(3, p, color, accent),
      BackgroundStyle.starfield => StarfieldEffect(p, color, accent),
      BackgroundStyle.rain => PrecipitationEffect(false, p, color, accent),
      BackgroundStyle.snow => PrecipitationEffect(true, p, color, accent),
      BackgroundStyle.gradient => GradientEffect(GradientPreset.parse(config.gradientPreset), p, color, accent),
      BackgroundStyle.image => ImageEffect(config.imagePath, p, color, accent),
      BackgroundStyle.video => VideoFramesEffect(config.videoDir, p, color, accent),
      _ => MatrixEffect(p, color, accent),
    };
    return e..lowDetail = config.batterySaver;
  }
}

class Shockwave {
  Shockwave(this.at, this.strength);
  final Offset at;
  final double strength;
  double age = 0;

  static const life = 1.6;
  static const speed = 620.0;

  double get radius => age * speed;

  /// Dies away smoothly.
  double get power => strength * (1 - age / life) * (1 - age / life);
}

int _mixArgb(Color a, Color b, double t, double alpha) {
  final f = t.clamp(0.0, 1.0);
  final x = a.toARGB32(), y = b.toARGB32();
  final r = ((x >> 16 & 255) + ((y >> 16 & 255) - (x >> 16 & 255)) * f).round();
  final g = ((x >> 8 & 255) + ((y >> 8 & 255) - (x >> 8 & 255)) * f).round();
  final bl = ((x & 255) + ((y & 255) - (x & 255)) * f).round();
  final al = (alpha.clamp(0.0, 1.0) * 255).round();
  return (al << 24) | (r << 16) | (g << 8) | bl;
}

Future<ui.Image> _renderSprites(int w, int h, void Function(Canvas) draw) async {
  final rec = ui.PictureRecorder();
  draw(Canvas(rec));
  final pic = rec.endRecording();
  final img = await pic.toImage(w, h);
  pic.dispose();
  return img;
}

/// Preallocated sprite batch for `drawRawAtlas`.
class _Batch {
  Float32List _xf = Float32List(4 * 4096);
  Float32List _rects = Float32List(4 * 4096);
  Int32List _colors = Int32List(4096);
  int n = 0;

  void add(double scale, double x, double y, double rot, double l, double t, double r, double b, int color) {
    if (n == _colors.length) {
      _xf = Float32List(_xf.length * 2)..setRange(0, _xf.length, _xf);
      _rects = Float32List(_rects.length * 2)..setRange(0, _rects.length, _rects);
      _colors = Int32List(_colors.length * 2)..setRange(0, _colors.length, _colors);
    }
    final i = n * 4;
    final w = (r - l) * scale / 2, h = (b - t) * scale / 2;
    if (rot == 0) {
      _xf[i] = scale;
      _xf[i + 1] = 0;
      _xf[i + 2] = x - w;
      _xf[i + 3] = y - h;
    } else {
      final c = math.cos(rot) * scale, s = math.sin(rot) * scale;
      _xf[i] = c;
      _xf[i + 1] = s;
      _xf[i + 2] = x - (c * (r - l) / 2 - s * (b - t) / 2);
      _xf[i + 3] = y - (s * (r - l) / 2 + c * (b - t) / 2);
    }
    _rects[i] = l;
    _rects[i + 1] = t;
    _rects[i + 2] = r;
    _rects[i + 3] = b;
    _colors[n] = color;
    n++;
  }

  void flush(Canvas canvas, ui.Image atlas) {
    if (n == 0) return;
    canvas.drawRawAtlas(
      atlas,
      Float32List.sublistView(_xf, 0, n * 4),
      Float32List.sublistView(_rects, 0, n * 4),
      Int32List.sublistView(_colors, 0, n),
      BlendMode.modulate,
      null,
      Paint()..filterQuality = FilterQuality.low,
    );
    n = 0;
  }
}

// ------------------------------------------------------------------- Matrix

const _katakana = 'ｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ0123456789:=+*<>';

List<String> matrixSymbols(BgParams p) {
  final text = switch (MatrixGlyphs.parse(p.glyphs)) {
    MatrixGlyphs.katakana => _katakana,
    MatrixGlyphs.binary => '01',
    MatrixGlyphs.hex => '0123456789ABCDEF',
    MatrixGlyphs.latin => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    MatrixGlyphs.notes => '♩♪♫♬♭♮♯',
    MatrixGlyphs.custom => p.customGlyphs.trim().isEmpty ? 'PRISM' : p.customGlyphs,
  };
  final out = <String>{};
  for (final r in text.runes) {
    final ch = String.fromCharCode(r);
    if (ch.trim().isNotEmpty) out.add(ch);
    if (out.length >= 96) break;
  }
  return out.toList();
}

class _Rain {
  double head = 0;
  double speed = 10;
  int length = 16;
}

/// Symbols falling in columns. Near the mouse they glow, bend away and the
/// hidden grid shows through; shockwaves push them; the bass speeds them up.
class MatrixEffect extends BackgroundEffect {
  MatrixEffect(super.params, super.color, super.accent);

  static const _perRow = 12;

  /// Sheet cell size of [_atlas]. Made at the size symbols are shown, so they
  /// don't shimmer from being shrunk.
  double _sprite = 40;
  double _wantSprite = 40;

  ui.Image? _atlas;
  int _count = 1;
  String _builtFor = '';
  final _rnd = math.Random();
  var _cols = 0, _rows = 0;
  double _cell = 16;
  List<_Rain> _rain = const [];
  Uint8List _glyphs = Uint8List(0);
  double _changeDebt = 0;
  final _batch = _Batch();

  @override
  Future<void> prepare() async {
    final symbols = matrixSymbols(params);
    final sprite = _wantSprite;
    final key = '$sprite|${symbols.join()}';
    if (key == _builtFor && _atlas != null) return;
    _builtFor = key;
    final rows = (symbols.length / _perRow).ceil();
    final mirrored = MatrixGlyphs.parse(params.glyphs) == MatrixGlyphs.katakana;
    final img = await _renderSprites((_perRow * sprite).round(), (rows * sprite).round(), (c) {
      for (var i = 0; i < symbols.length; i++) {
        final tp = TextPainter(
          text: TextSpan(
            text: symbols[i],
            style: TextStyle(color: Colors.white, fontSize: sprite * 0.76, fontWeight: FontWeight.w500, height: 1),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final x = (i % _perRow) * sprite + sprite / 2, y = (i ~/ _perRow) * sprite + sprite / 2;
        c.save();
        c.translate(x, y);
        if (mirrored) c.scale(-1, 1); // mirrored symbols read as code, not text
        tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
        c.restore();
        tp.dispose();
      }
    });
    _atlas?.dispose();
    _atlas = img;
    _sprite = sprite;
    _count = symbols.length;
    if (_glyphs.isNotEmpty) _fillGlyphs();
  }

  void _fillGlyphs() {
    for (var i = 0; i < _glyphs.length; i++) {
      _glyphs[i] = _rnd.nextInt(_count);
    }
  }

  void _respawn(_Rain r, {bool fresh = false}) {
    r.speed = 7 + _rnd.nextDouble() * 15;
    r.length = (6 + _rnd.nextInt(24) * params.reach).round().clamp(3, 80);
    // Lower density = longer gaps above the screen before a column restarts.
    final gap = _rows * (0.15 + _rnd.nextDouble() * 1.3) / params.density;
    r.head = fresh ? _rnd.nextDouble() * (_rows + gap) - gap : -gap;
  }

  @override
  void resize(Size s) {
    size = s;
    _cell = 16 * params.size;
    final dpr = ui.PlatformDispatcher.instance.views.firstOrNull?.devicePixelRatio ?? 1;
    final want = (_cell * dpr).ceilToDouble().clamp(10.0, 64.0);
    if (want != _wantSprite) {
      _wantSprite = want;
      unawaited(prepare());
    }
    _cols = math.max(1, (s.width / _cell).ceil());
    _rows = math.max(1, (s.height / _cell).ceil());
    _rain = List.generate(_cols, (_) => _Rain());
    for (final r in _rain) {
      _respawn(r, fresh: true);
    }
    _glyphs = Uint8List(_cols * _rows);
    _fillGlyphs();
  }

  @override
  void step(double dt) {
    super.step(dt);
    if (_rain.isEmpty) return;
    final fast = params.speed * (1 + bass * 1.6);
    final p = pointer;
    final reachCols = 120 / _cell;
    for (var c = 0; c < _rain.length; c++) {
      final r = _rain[c];
      var v = r.speed * fast;
      if (p != null && params.mouse > 0) {
        final off = ((c + 0.5) * _cell - p.dx).abs() / _cell;
        if (off < reachCols) v *= 1 + (1 - off / reachCols) * params.mouse * 1.5;
      }
      r.head += v * dt;
      if (r.head - r.length > _rows) _respawn(r);
    }
    // Symbols keep changing their minds (a share per second, not per frame).
    _changeDebt += _glyphs.length * 0.3 * params.speed * dt;
    while (_changeDebt >= 1 && _glyphs.isNotEmpty) {
      _changeDebt -= 1;
      _glyphs[_rnd.nextInt(_glyphs.length)] = _rnd.nextInt(_count);
    }
  }

  @override
  void burst(Offset at, double strength) {
    super.burst(at, strength);
    // Fresh rain starts from where the click landed.
    if (_rain.isEmpty) return;
    final c = (at.dx / _cell).floor(), row = at.dy / _cell;
    for (var i = -3; i <= 3; i++) {
      final k = c + i;
      if (k >= 0 && k < _rain.length && _rain[k].head - _rain[k].length > row) {
        _rain[k].head = row + _rnd.nextDouble() * 2;
      }
    }
  }

  @override
  void paint(Canvas canvas) {
    final atlas = _atlas;
    if (atlas == null || _rain.isEmpty || _glyphs.isEmpty) return;
    final p = pointer;
    final mouse = params.mouse;
    final bright = params.brightness * (1 + bass * 0.35);
    final scale = _cell / _sprite;
    const radius = 150.0;

    void put(int col, int row, double alpha, double heat) {
      var x = (col + 0.5) * _cell, y = (row + 0.5) * _cell;
      var a = alpha, h = heat;
      if (p != null && mouse > 0) {
        final dx = x - p.dx, dy = y - p.dy;
        final d2 = dx * dx + dy * dy;
        if (d2 < radius * radius) {
          final d = math.sqrt(d2);
          final f = (1 - d / radius) * (1 - d / radius) * mouse;
          if (d > 0.01) {
            x += dx / d * f * 9;
            y += dy / d * f * 9;
          }
          a += f * 0.5;
          h += f * 0.6;
        }
      }
      for (final w in waves) {
        final dx = x - w.at.dx, dy = y - w.at.dy;
        final d = math.sqrt(dx * dx + dy * dy);
        final off = (d - w.radius).abs();
        if (off < 70 && d > 0.01) {
          final f = (1 - off / 70) * w.power;
          x += dx / d * f * 14;
          y += dy / d * f * 14;
          a += f * 0.5;
          h += f * 0.6;
        }
      }
      if (a <= 0.015) return;
      final g = _glyphs[(col + row * _cols) % _glyphs.length];
      final l = (g % _perRow) * _sprite, t = (g ~/ _perRow) * _sprite;
      _batch.add(scale, x, y, 0, l, t, l + _sprite, t + _sprite, _mixArgb(color, accent, h, a));
    }

    for (var c = 0; c < _rain.length; c++) {
      final r = _rain[c];
      final top = r.head.floor();
      final frac = r.head - top;
      for (var i = 0; i < r.length; i++) {
        final row = top - i;
        if (row < 0) break;
        if (row >= _rows) continue;
        // Exact distance from the moving head: every symbol fades continuously
        // and a new one lights up gradually, so the rain flows instead of
        // stepping a whole cell at a time.
        final age = i + frac;
        final f = (1 - age / r.length).clamp(0.0, 1.0);
        final lightUp = i == 0 ? frac : 1.0;
        put(c, row, math.pow(f, 1.3) * bright * lightUp, math.max(0, 1 - age / 1.8));
      }
    }

    // The hidden grid shows through around the mouse.
    if (p != null && mouse > 0) {
      final reach = (radius / _cell).ceil();
      final pc = (p.dx / _cell).floor(), pr = (p.dy / _cell).floor();
      for (var y = pr - reach; y <= pr + reach; y++) {
        if (y < 0 || y >= _rows) continue;
        for (var x = pc - reach; x <= pc + reach; x++) {
          if (x < 0 || x >= _cols) continue;
          put(x, y, 0.0001, 0);
        }
      }
    }
    _batch.flush(canvas, atlas);
  }

  @override
  void dispose() {
    _atlas?.dispose();
    _atlas = null;
  }
}

// ------------------------------------------------------------ Constellation

/// Stars drifting about, joined by lines when close. The mouse pulls them in
/// and links to them; a click throws them outward; the bass makes them swell.
class ConstellationEffect extends BackgroundEffect {
  ConstellationEffect(super.params, super.color, super.accent);

  final _rnd = math.Random();
  Float32List _x = Float32List(0), _y = Float32List(0), _vx = Float32List(0), _vy = Float32List(0);
  int _n = 0;
  static const _buckets = 10;
  final _lines = List.generate(_buckets, (_) => Float32List(4 * 3000));
  final _lineCount = List.filled(_buckets, 0);
  final _hot = List.generate(_hotLevels, (_) => Float32List(4 * 100));
  final _hotCount = List.filled(_hotLevels, 0);
  static const _hotLevels = 6;

  @override
  Future<void> prepare() async {}

  @override
  void resize(Size s) {
    size = s;
    final n = (s.width * s.height / 11000 * params.density).clamp(16.0, 340.0).round();
    if (n == _n) return;
    _n = n;
    _x = Float32List(n);
    _y = Float32List(n);
    _vx = Float32List(n);
    _vy = Float32List(n);
    for (var i = 0; i < n; i++) {
      _x[i] = _rnd.nextDouble() * s.width;
      _y[i] = _rnd.nextDouble() * s.height;
      final a = _rnd.nextDouble() * math.pi * 2;
      final v = 8 + _rnd.nextDouble() * 18;
      _vx[i] = math.cos(a) * v;
      _vy[i] = math.sin(a) * v;
    }
  }

  @override
  void step(double dt) {
    super.step(dt);
    final w = size.width, h = size.height;
    if (w <= 0 || _n == 0) return;
    final p = pointer;
    final pull = 2400 * params.mouse;
    const pullR = 260.0;
    final gear = params.speed * (1 + bass * 1.4);
    for (var i = 0; i < _n; i++) {
      var ax = 0.0, ay = 0.0;
      if (p != null && pull > 0) {
        final dx = p.dx - _x[i], dy = p.dy - _y[i];
        final d2 = dx * dx + dy * dy;
        if (d2 < pullR * pullR && d2 > 1) {
          final d = math.sqrt(d2);
          // Pulled in from afar, pushed back close by: they gather around the
          // mouse in a ring and swirl, they don't collapse into one point.
          const ring = 84.0;
          final f = d > ring ? (1 - d / pullR) * pull / d : -(1 - d / ring) * pull * 2 / d;
          ax += dx * f - dy * 0.35 * pull / pullR;
          ay += dy * f + dx * 0.35 * pull / pullR;
        }
      }
      for (final s in waves) {
        final dx = _x[i] - s.at.dx, dy = _y[i] - s.at.dy;
        final d = math.sqrt(dx * dx + dy * dy);
        final off = (d - s.radius).abs();
        if (off < 60 && d > 1) {
          final f = (1 - off / 60) * s.power * 9000 / d;
          ax += dx * f;
          ay += dy * f;
        }
      }
      _vx[i] += ax * dt;
      _vy[i] += ay * dt;
      // Forces fade away, each star returns to its calm drift speed.
      final v = math.sqrt(_vx[i] * _vx[i] + _vy[i] * _vy[i]);
      if (v > 26) {
        final damp = math.max(0.0, 1 - 1.8 * dt);
        _vx[i] *= damp;
        _vy[i] *= damp;
      }
      _x[i] += _vx[i] * gear * dt;
      _y[i] += _vy[i] * gear * dt;
      if (_x[i] < -30) _x[i] += w + 60;
      if (_x[i] > w + 30) _x[i] -= w + 60;
      if (_y[i] < -30) _y[i] += h + 60;
      if (_y[i] > h + 30) _y[i] -= h + 60;
    }
  }

  @override
  void paint(Canvas canvas) {
    if (_n == 0) return;
    final bright = params.brightness * (1 + bass * 0.4);
    // Small windows and samples keep a readable web, not a knot of lines.
    final link = math.min(120 * params.reach * (1 + bass * 0.2), size.shortestSide * 0.33);
    final link2 = link * link;
    for (var b = 0; b < _buckets; b++) {
      _lineCount[b] = 0;
    }
    for (var i = 0; i < _n; i++) {
      final xi = _x[i], yi = _y[i];
      for (var j = i + 1; j < _n; j++) {
        final dx = xi - _x[j];
        if (dx > link || dx < -link) continue;
        final dy = yi - _y[j];
        final d2 = dx * dx + dy * dy;
        if (d2 >= link2) continue;
        final b = math.min(_buckets - 1, (d2 / link2 * _buckets).floor());
        final k = _lineCount[b];
        final list = _lines[b];
        if (k * 4 + 4 > list.length) continue;
        list[k * 4] = xi;
        list[k * 4 + 1] = yi;
        list[k * 4 + 2] = _x[j];
        list[k * 4 + 3] = _y[j];
        _lineCount[b] = k + 1;
      }
    }
    final line = Paint()
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (var b = 0; b < _buckets; b++) {
      if (_lineCount[b] == 0) continue;
      line.color = color.withValues(alpha: ((1 - b / _buckets) * 0.75 * bright).clamp(0.0, 1.0));
      canvas.drawRawPoints(ui.PointMode.lines, Float32List.sublistView(_lines[b], 0, _lineCount[b] * 4), line);
    }

    // Lines to the mouse + brighter stars around it.
    final p = pointer;
    if (p != null && params.mouse > 0) {
      const r = 190.0;
      for (var l = 0; l < _hotLevels; l++) {
        _hotCount[l] = 0;
      }
      for (var i = 0; i < _n; i++) {
        final dx = _x[i] - p.dx, dy = _y[i] - p.dy;
        final d2 = dx * dx + dy * dy;
        if (d2 >= r * r) continue;
        // Lines fade out with distance, they don't pop in at the edge.
        final level = math.min(_hotLevels - 1, (math.sqrt(d2) / r * _hotLevels).floor());
        final k = _hotCount[level];
        if (k >= 100) continue;
        final list = _hot[level];
        list[k * 4] = p.dx;
        list[k * 4 + 1] = p.dy;
        list[k * 4 + 2] = _x[i];
        list[k * 4 + 3] = _y[i];
        _hotCount[level] = k + 1;
      }
      for (var l = 0; l < _hotLevels; l++) {
        if (_hotCount[l] == 0) continue;
        canvas.drawRawPoints(
          ui.PointMode.lines,
          Float32List.sublistView(_hot[l], 0, _hotCount[l] * 4),
          Paint()
            ..color = accent.withValues(alpha: ((1 - l / _hotLevels) * 0.7 * bright).clamp(0.0, 1.0))
            ..strokeWidth = 1,
        );
      }
    }

    final dots = Float32List(_n * 2);
    for (var i = 0; i < _n; i++) {
      dots[i * 2] = _x[i];
      dots[i * 2 + 1] = _y[i];
    }
    canvas.drawRawPoints(
      ui.PointMode.points,
      dots,
      Paint()
        ..color = accent.withValues(alpha: bright.clamp(0.0, 1.0))
        ..strokeWidth = 3.6 * params.size * (1 + bass * 0.7)
        ..strokeCap = StrokeCap.round,
    );

    for (final s in waves) {
      canvas.drawCircle(
        s.at,
        s.radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = accent.withValues(alpha: (s.power * 0.35).clamp(0.0, 1.0)),
      );
    }
  }
}

// ------------------------------------------------------------------- Ripple

class _Drop {
  _Drop(this.x, this.y, this.amp);
  final double x, y, amp;
  double age = 0;
}

/// A grid of points read as a water surface. Every point sums the waves that
/// pass it: the mouse leaves a wake, clicks make big rings, the bass and an
/// occasional rain drop keep it alive.
class RippleEffect extends BackgroundEffect {
  RippleEffect(super.params, super.color, super.accent);

  static const _sprite = 16.0;
  static const _life = 3.2;

  ui.Image? _atlas;
  final _rnd = math.Random();
  final _drops = <_Drop>[];
  final _batch = _Batch();
  double _spacing = 26;
  var _cols = 0, _rows = 0;
  Offset? _lastWake;
  double _sinceRain = 0, _lastBass = 0;

  @override
  Future<void> prepare() async {
    final img = await _renderSprites((_sprite * 3).round(), _sprite.round(), (c) {
      const m = _sprite / 2;
      c.drawCircle(const Offset(m, m), 3.6, Paint()..color = Colors.white);
      final stroke = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      c.drawLine(const Offset(_sprite + m - 5, m), const Offset(_sprite + m + 5, m), stroke);
      c.drawLine(const Offset(_sprite * 2 + m - 4, m), const Offset(_sprite * 2 + m + 4, m), stroke);
      c.drawLine(const Offset(_sprite * 2 + m, m - 4), const Offset(_sprite * 2 + m, m + 4), stroke);
    });
    _atlas?.dispose();
    _atlas = img;
  }

  @override
  void resize(Size s) {
    size = s;
    _spacing = (26 / params.density).clamp(13.0, 80.0);
    _cols = (s.width / _spacing).ceil() + 1;
    _rows = (s.height / _spacing).ceil() + 1;
  }

  void _drop(double x, double y, double amp) {
    if (_drops.length >= 14) _drops.removeAt(0);
    _drops.add(_Drop(x, y, amp));
  }

  @override
  void burst(Offset at, double strength) {
    super.burst(at, strength);
    _drop(at.dx, at.dy, 1.6 * strength);
  }

  @override
  void step(double dt) {
    super.step(dt);
    final gear = params.speed;
    for (var i = _drops.length - 1; i >= 0; i--) {
      _drops[i].age += dt * gear;
      if (_drops[i].age > _life) _drops.removeAt(i);
    }
    // Wake: a small wave for every stretch the mouse travels.
    final p = pointer;
    if (p != null && params.mouse > 0) {
      final last = _lastWake;
      if (last == null) {
        _lastWake = p;
      } else if ((p - last).distance > 46) {
        _lastWake = p;
        _drop(p.dx, p.dy, 0.55 * params.mouse);
      }
    } else {
      _lastWake = null;
    }
    // Bass hit: a ring somewhere near the middle.
    if (bass > 0.5 && _lastBass <= 0.5) {
      _drop(
        size.width * (0.2 + _rnd.nextDouble() * 0.6),
        size.height * (0.2 + _rnd.nextDouble() * 0.6),
        0.45 + bass * 0.5,
      );
    }
    _lastBass = bass;
    // A quiet surface still gets a drop now and then.
    _sinceRain += dt * gear;
    if (_sinceRain > 1.8) {
      _sinceRain = 0;
      _drop(_rnd.nextDouble() * size.width, _rnd.nextDouble() * size.height, 0.55);
    }
  }

  @override
  void paint(Canvas canvas) {
    final atlas = _atlas;
    if (atlas == null || _cols == 0) return;
    final bright = params.brightness;
    final baseScale = 0.5 * params.size * (_spacing / 26).clamp(0.7, 1.6);
    final shape = RippleShape.parse(params.shape);
    final left = _sprite * shape.index;
    final band = 70 * params.reach;
    final k = 0.075 / math.max(0.6, params.reach);
    final v = 170.0;
    final p = pointer;
    final baseAlpha = 0.3 * bright;

    for (var ry = 0; ry < _rows; ry++) {
      final y0 = ry * _spacing;
      for (var rx = 0; rx < _cols; rx++) {
        final x0 = rx * _spacing;
        var h = 0.0, ox = 0.0, oy = 0.0;
        for (final d in _drops) {
          final dx = x0 - d.x, dy = y0 - d.y;
          final dist = math.sqrt(dx * dx + dy * dy);
          final off = dist - d.age * v;
          if (off > band * 2.2 || off < -band * 2.2) continue;
          // Opens softly and dies away, so a ring never pops in.
          final env = math.exp(-(off * off) / (band * band)) * (1 - d.age / _life) * math.min(1.0, d.age / 0.35);
          final wave = math.cos(off * k * 2) * env * d.amp;
          h += wave;
          if (dist > 0.01) {
            ox += dx / dist * wave;
            oy += dy / dist * wave;
          }
        }
        var heat = 0.0;
        if (p != null && params.mouse > 0) {
          final dx = x0 - p.dx, dy = y0 - p.dy;
          final d2 = dx * dx + dy * dy;
          if (d2 < 120 * 120) {
            final f = 1 - math.sqrt(d2) / 120;
            heat = f * f * params.mouse;
          }
        }
        final level = h.abs();
        final a = baseAlpha + (level * 1.1 + heat * 0.7) * bright;
        final scale = baseScale * (1 + math.max(0.0, h) * 1.1 + heat * 0.6 + bass * 0.2);
        final rot = shape == RippleShape.dots ? 0.0 : (ox == 0 && oy == 0 ? 0.0 : math.atan2(oy, ox));
        _batch.add(
          scale,
          x0 + ox * 10,
          y0 + oy * 10,
          rot,
          left,
          0,
          left + _sprite,
          _sprite,
          _mixArgb(color, accent, level + heat, a),
        );
      }
    }
    _batch.flush(canvas, atlas);
  }

  @override
  void dispose() {
    _atlas?.dispose();
    _atlas = null;
  }
}


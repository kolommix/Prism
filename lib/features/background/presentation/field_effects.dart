import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../domain/background_config.dart';
import 'background_effects.dart';

/// Mesh gradient, aurora and liquid blobs: one fragment shader, one draw
/// call, nothing per frame on the CPU beyond the uniforms.
class ShaderFieldEffect extends BackgroundEffect {
  ShaderFieldEffect(this.mode, super.params, super.color, super.accent);

  /// 0 mesh, 1 aurora, 2 blobs (see shaders/bg_field.frag).
  final int mode;

  static Future<ui.FragmentProgram?>? _program;
  ui.FragmentShader? _shader;
  bool _ready = false;

  static Future<ui.FragmentProgram?> _load() => _program ??= () async {
        try {
          return await ui.FragmentProgram.fromAsset('shaders/bg_field.frag');
        } on Object {
          return null; // Plain gradient instead.
        }
      }();

  @override
  Future<void> prepare() async {
    final program = await _load();
    _shader = program?.fragmentShader();
    _ready = true;
  }

  @override
  void resize(Size s) => size = s;

  @override
  void step(double dt) {
    // Slower than the others: these are large, calm shapes.
    time += dt * params.speed;
  }

  @override
  void paint(Canvas canvas) {
    if (size.isEmpty || !_ready) return;
    final rect = Offset.zero & size;
    final f = _shader;
    if (f == null) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(rect.topLeft, rect.bottomRight, [
            color.withValues(alpha: params.brightness * 0.5),
            accent.withValues(alpha: params.brightness * 0.3),
          ]),
      );
      return;
    }
    var u = 0;
    void put(double v) => f.setFloat(u++, v);
    put(size.width);
    put(size.height);
    put(time);
    put(mode.toDouble());
    put(bass.clamp(0.0, 1.5));
    final pt = pointer;
    final reacts = params.mouse > 0 && pt != null;
    put(reacts ? pt.dx / size.width : -1);
    put(reacts ? pt.dy / size.height : -1);
    put(color.r);
    put(color.g);
    put(color.b);
    put(accent.r);
    put(accent.g);
    put(accent.b);
    put(params.brightness);
    put(params.density);
    put(params.size);
    canvas.drawRect(rect, Paint()..shader = f);
  }

  @override
  void dispose() {
    _shader?.dispose();
    super.dispose();
  }
}

/// Stars flying towards the screen, three brightness batches.
class StarfieldEffect extends BackgroundEffect {
  StarfieldEffect(super.params, super.color, super.accent);

  final _rnd = math.Random(5);
  late Float32List _stars = Float32List(0);
  int _n = 0;

  @override
  Future<void> prepare() async {}

  @override
  void resize(Size s) {
    size = s;
    final area = (s.width * s.height / (1280 * 720)).clamp(0.3, 3.0);
    _n = (500 * params.density * area * (lowDetail ? 0.5 : 1)).round();
    _stars = Float32List(_n * 3);
    for (var i = 0; i < _n; i++) {
      _stars[i * 3] = _rnd.nextDouble() * 2 - 1;
      _stars[i * 3 + 1] = _rnd.nextDouble() * 2 - 1;
      _stars[i * 3 + 2] = _rnd.nextDouble();
    }
  }

  @override
  void step(double dt) {
    super.step(dt);
    final v = dt * 0.09 * params.speed * (1 + bass * 1.2);
    for (var i = 0; i < _n; i++) {
      var z = _stars[i * 3 + 2] - v;
      if (z <= 0.02) {
        z = 1;
        _stars[i * 3] = _rnd.nextDouble() * 2 - 1;
        _stars[i * 3 + 1] = _rnd.nextDouble() * 2 - 1;
      }
      _stars[i * 3 + 2] = z;
    }
  }

  @override
  void paint(Canvas canvas) {
    if (size.isEmpty) return;
    final c = size.center(Offset.zero);
    final far = Float32List(_n * 2), mid = Float32List(_n * 2), near = Float32List(_n * 2);
    var a = 0, b = 0, d = 0;
    final pull = pointer == null || params.mouse <= 0 ? Offset.zero : (pointer! - c) * (0.04 * params.mouse);
    for (var i = 0; i < _n; i++) {
      final z = _stars[i * 3 + 2];
      final x = c.dx + _stars[i * 3] / z * c.dx * 0.5 - pull.dx * (1 - z);
      final y = c.dy + _stars[i * 3 + 1] / z * c.dy * 0.5 - pull.dy * (1 - z);
      if (x < 0 || y < 0 || x > size.width || y > size.height) continue;
      if (z > 0.66) {
        far[a++] = x;
        far[a++] = y;
      } else if (z > 0.33) {
        mid[b++] = x;
        mid[b++] = y;
      } else {
        near[d++] = x;
        near[d++] = y;
      }
    }
    void draw(Float32List pts, int n, double w, double alpha, Color ink) {
      if (n == 0) return;
      canvas.drawRawPoints(ui.PointMode.points, Float32List.sublistView(pts, 0, n), Paint()
        ..color = ink.withValues(alpha: alpha * params.brightness)
        ..strokeWidth = w * params.size
        ..strokeCap = StrokeCap.round);
    }

    draw(far, a, 1.2, 0.45, color);
    draw(mid, b, 1.8, 0.75, color);
    draw(near, d, 2.6, 1, accent);
  }
}

/// Falling rain (thin lines) or snow (drifting dots). One batch per layer.
class PrecipitationEffect extends BackgroundEffect {
  PrecipitationEffect(this.snow, super.params, super.color, super.accent);

  final bool snow;
  final _rnd = math.Random(9);
  late Float32List _p = Float32List(0);
  int _n = 0;

  @override
  Future<void> prepare() async {}

  @override
  void resize(Size s) {
    size = s;
    final area = (s.width * s.height / (1280 * 720)).clamp(0.3, 3.0);
    _n = ((snow ? 260 : 340) * params.density * area * (lowDetail ? 0.5 : 1)).round();
    _p = Float32List(_n * 3);
    for (var i = 0; i < _n; i++) {
      _p[i * 3] = _rnd.nextDouble() * s.width;
      _p[i * 3 + 1] = _rnd.nextDouble() * s.height;
      _p[i * 3 + 2] = 0.3 + _rnd.nextDouble() * 0.7;
    }
  }

  @override
  void step(double dt) {
    super.step(dt);
    final wind = pointer == null || params.mouse <= 0 ? 0.0 : (pointer!.dx / math.max(1, size.width) - 0.5) * 80 * params.mouse;
    for (var i = 0; i < _n; i++) {
      final depth = _p[i * 3 + 2];
      final fall = (snow ? 42.0 : 720.0) * depth * params.speed * (1 + bass * 0.6);
      final sway = snow ? math.sin(time * 0.9 + i) * 16 * depth : 0.0;
      var x = _p[i * 3] + (sway + wind * depth) * dt;
      var y = _p[i * 3 + 1] + fall * dt;
      if (y > size.height + 20) {
        y = -20;
        x = _rnd.nextDouble() * size.width;
      }
      if (x < -20) x += size.width + 40;
      if (x > size.width + 20) x -= size.width + 40;
      _p[i * 3] = x;
      _p[i * 3 + 1] = y;
    }
  }

  @override
  void paint(Canvas canvas) {
    if (size.isEmpty) return;
    if (snow) {
      final small = Float32List(_n * 2), big = Float32List(_n * 2);
      var a = 0, b = 0;
      for (var i = 0; i < _n; i++) {
        final near = _p[i * 3 + 2] > 0.7;
        final list = near ? big : small;
        final at = near ? b : a;
        list[at] = _p[i * 3];
        list[at + 1] = _p[i * 3 + 1];
        if (near) {
          b += 2;
        } else {
          a += 2;
        }
      }
      void draw(Float32List pts, int n, double w, double alpha) {
        if (n == 0) return;
        canvas.drawRawPoints(ui.PointMode.points, Float32List.sublistView(pts, 0, n), Paint()
          ..color = color.withValues(alpha: alpha * params.brightness)
          ..strokeWidth = w * params.size
          ..strokeCap = StrokeCap.round);
      }

      draw(small, a, 2.2, 0.55);
      draw(big, b, 3.8, 0.9);
      return;
    }
    final lines = Float32List(_n * 4);
    final length = 26 * params.reach;
    for (var i = 0; i < _n; i++) {
      final x = _p[i * 3], y = _p[i * 3 + 1], d = _p[i * 3 + 2];
      lines[i * 4] = x;
      lines[i * 4 + 1] = y;
      lines[i * 4 + 2] = x;
      lines[i * 4 + 3] = y - length * d;
    }
    canvas.drawRawPoints(ui.PointMode.lines, lines, Paint()
      ..color = color.withValues(alpha: 0.5 * params.brightness)
      ..strokeWidth = 1.1 * params.size);
  }
}

/// A still gradient: it never ticks, so it costs nothing after the first frame.
class GradientEffect extends BackgroundEffect {
  GradientEffect(this.preset, super.params, super.color, super.accent);

  final GradientPreset preset;

  @override
  bool get isStatic => true;

  @override
  Future<void> prepare() async {}

  @override
  void resize(Size s) => size = s;

  @override
  void paint(Canvas canvas) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          rect.topLeft,
          rect.bottomRight,
          [for (final c in preset.colors) Color(c).withValues(alpha: params.brightness)],
          [for (var i = 0; i < preset.colors.length; i++) i / (preset.colors.length - 1)],
        ),
    );
  }
}

void _paintCover(Canvas canvas, Size size, ui.Image image, double opacity) {
  final src = Offset.zero & Size(image.width.toDouble(), image.height.toDouble());
  final scale = math.max(size.width / src.width, size.height / src.height);
  final dst = Rect.fromCenter(center: size.center(Offset.zero), width: src.width * scale, height: src.height * scale);
  canvas.drawImageRect(image, src, dst, Paint()
    ..filterQuality = FilterQuality.medium
    ..color = Color.fromRGBO(0, 0, 0, opacity));
}

/// The user's own picture.
class ImageEffect extends BackgroundEffect {
  ImageEffect(this.path, super.params, super.color, super.accent);

  final String path;
  ui.Image? _image;

  @override
  bool get isStatic => true;

  @override
  Future<void> prepare() async {
    if (path.isEmpty) return;
    try {
      final codec = await ui.instantiateImageCodec(await File(path).readAsBytes(), targetWidth: 2200, allowUpscaling: false);
      _image = (await codec.getNextFrame()).image;
      codec.dispose();
    } on Object {
      _image = null; // Gone or not a picture: the page behind just shows.
    }
  }

  @override
  void resize(Size s) => size = s;

  @override
  void paint(Canvas canvas) {
    final img = _image;
    if (img != null && !size.isEmpty) _paintCover(canvas, size, img, params.brightness);
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }
}

/// The user's own video as a soundless loop: frames were extracted once with
/// FFmpeg (see `BackgroundVideo`) and only the next one is decoded at a time, so
/// it works where no video player exists and stays light. It sits blurred behind
/// the app, where 12 frames a second are plenty.
class VideoFramesEffect extends BackgroundEffect {
  VideoFramesEffect(this.dir, super.params, super.color, super.accent);

  final String dir;
  static const fps = 12;
  List<File> _files = const [];
  ui.Image? _current;
  int _shown = -1;
  bool _decoding = false;

  @override
  Future<void> prepare() async {
    if (dir.isEmpty) return;
    try {
      _files = Directory(dir).listSync().whereType<File>().where((f) => p.extension(f.path) == '.jpg').toList()
        ..sort((a, b) => a.path.compareTo(b.path));
    } on Object {
      _files = const [];
    }
    await _decode(0);
  }

  Future<void> _decode(int index) async {
    if (_decoding || _files.isEmpty) return;
    _decoding = true;
    try {
      final codec = await ui.instantiateImageCodec(await _files[index].readAsBytes());
      final next = (await codec.getNextFrame()).image;
      codec.dispose();
      _current?.dispose();
      _current = next;
      _shown = index;
    } on Object {
      // A missing frame: keep showing the last one.
    } finally {
      _decoding = false;
    }
  }

  @override
  void resize(Size s) => size = s;

  @override
  void step(double dt) {
    time += dt * params.speed;
    if (_files.isEmpty) return;
    final want = (time * fps).floor() % _files.length;
    if (want != _shown) _decode(want);
  }

  @override
  void paint(Canvas canvas) {
    final img = _current;
    if (img != null && !size.isEmpty) _paintCover(canvas, size, img, params.brightness);
  }

  @override
  void dispose() {
    _current?.dispose();
    _current = null;
    super.dispose();
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/prism_theme_extensions.dart';

/// Background of the black & white theme: the current cover, blurred and
/// turned grey, under a dark (or light) wash.
///
/// Performance: the cover is decoded at 64 px, blurred + desaturated once
/// into a 48 px image (cached per cover), and drawn stretched. Nothing runs
/// between track changes – no timer, no ticker – and a change cross-fades
/// with one short animation.
class AmbientBackdrop extends StatefulWidget {
  const AmbientBackdrop({super.key, required this.artworkPath, this.child, this.strength = 0.5});

  /// Cover file path or https URL; null = plain surface.
  final String? artworkPath;
  final Widget? child;

  /// 0..1 how much of the cover shows through the wash.
  final double strength;

  @override
  State<AmbientBackdrop> createState() => _AmbientBackdropState();
}

class _AmbientBackdropState extends State<AmbientBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(vsync: this, value: 1);
  ui.Image? _from;
  ui.Image? _to;
  String? _loading;

  @override
  void initState() {
    super.initState();
    _load(widget.artworkPath, animate: false);
  }

  @override
  void didUpdateWidget(AmbientBackdrop old) {
    super.didUpdateWidget(old);
    if (old.artworkPath != widget.artworkPath) _load(widget.artworkPath, animate: true);
  }

  Future<void> _load(String? path, {required bool animate}) async {
    _loading = path;
    final image = path == null ? null : await AmbientImages.instance.get(path);
    if (!mounted || _loading != path) return; // a newer track won
    if (image == _to) return;
    setState(() {
      _from = _to;
      _to = image;
    });
    final d = context.motion.d(const Duration(milliseconds: 700));
    if (!animate || d == Duration.zero) {
      _fade.value = 1;
    } else {
      _fade.duration = d;
      unawaited(_fade.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              // Static between songs: let the engine keep it as a texture
              // instead of re-drawing three full-window layers every frame.
              isComplex: true,
              willChange: false,
              painter: _BackdropPainter(
                fade: _fade,
                from: _from,
                to: _to,
                base: scheme.surface,
                dark: scheme.brightness == Brightness.dark,
                strength: widget.strength,
              ),
            ),
          ),
        ),
        if (widget.child != null) RepaintBoundary(child: widget.child),
      ],
    );
  }
}

class _BackdropPainter extends CustomPainter {
  _BackdropPainter({
    required this.fade,
    required this.from,
    required this.to,
    required this.base,
    required this.dark,
    required this.strength,
  }) : super(repaint: fade);

  final Animation<double> fade;
  final ui.Image? from;
  final ui.Image? to;
  final Color base;
  final bool dark;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = base);
    final t = fade.value;
    // Covers are a little brighter in dark mode, a little darker in light.
    final alpha = (dark ? 0.9 : 0.6) * (0.3 + 0.7 * strength);
    void cover(ui.Image? image, double opacity) {
      if (image == null || opacity <= 0) return;
      final src = Offset.zero & Size(image.width.toDouble(), image.height.toDouble());
      // BoxFit.cover, slightly zoomed so the blurred edges never show.
      final scale = 1.12 * (size.width > size.height ? size.width / src.width : size.height / src.height);
      final dst = Rect.fromCenter(center: rect.center, width: src.width * scale, height: src.height * scale);
      canvas.drawImageRect(
        image,
        src,
        dst,
        Paint()
          ..filterQuality = FilterQuality.medium
          ..color = Color.fromRGBO(0, 0, 0, opacity * alpha),
      );
    }

    cover(from, 1 - t);
    cover(to, t);

    // Wash: lighter at the top, almost solid at the bottom so controls and
    // text stay readable; a soft vignette adds depth.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [base.withValues(alpha: 0.05), base.withValues(alpha: 0.75)],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 1.1,
          colors: [
            base.withValues(alpha: 0),
            base.withValues(alpha: dark ? 0.55 : 0.35),
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.from != from || old.to != to || old.base != base || old.dark != dark || old.strength != strength;
}

/// Small blurred grey versions of covers, shared by every backdrop.
class AmbientImages {
  AmbientImages._();
  static final instance = AmbientImages._();

  static const _size = 48;
  final _cache = <String, Future<ui.Image?>>{}; // insertion-ordered

  Future<ui.Image?> get(String path) {
    final hit = _cache.remove(path);
    final result = hit ?? _make(path);
    _cache[path] = result; // most recent last
    // Old entries are just dropped (48 px images; still-shown ones live on
    // in the widgets that hold them).
    while (_cache.length > 32) {
      _cache.remove(_cache.keys.first);
    }
    return result;
  }

  static Future<ui.Image?> _make(String path) async {
    try {
      final ImageProvider source = path.startsWith('http') ? NetworkImage(path) : FileImage(File(path));
      final small = await _decode(ResizeImage(source, width: 64, height: 64, policy: ResizeImagePolicy.fit));
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const s = _size * 1.0;
      canvas.saveLayer(
        const Rect.fromLTWH(0, 0, s, s),
        Paint()
          ..imageFilter = ui.ImageFilter.blur(sigmaX: 3.5, sigmaY: 3.5, tileMode: TileMode.clamp)
          ..colorFilter = const ColorFilter.matrix(_greyscale),
      );
      canvas.drawImageRect(
        small,
        Offset.zero & Size(small.width.toDouble(), small.height.toDouble()),
        const Rect.fromLTWH(-4, -4, s + 8, s + 8),
        Paint()..filterQuality = FilterQuality.medium,
      );
      canvas.restore();
      final picture = recorder.endRecording();
      final image = await picture.toImage(_size, _size);
      picture.dispose();
      small.dispose();
      return image;
    } on Object {
      return null; // missing / broken cover: plain background
    }
  }

  static Future<ui.Image> _decode(ImageProvider provider) {
    final done = Completer<ui.Image>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        if (!done.isCompleted) done.complete(info.image.clone());
        info.dispose();
      },
      onError: (e, s) {
        stream.removeListener(listener);
        if (!done.isCompleted) done.completeError(e, s);
      },
    );
    stream.addListener(listener);
    return done.future;
  }

  /// Rec. 709 luma.
  static const _greyscale = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

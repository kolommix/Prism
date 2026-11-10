import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// Colors pulled out of a cover image.
@immutable
class AlbumPalette {
  const AlbumPalette({required this.seed, required this.gradient});

  /// Main color used as the theme seed when dynamic color is on.
  final Color seed;

  /// 3 colors for the animated background gradient.
  final List<Color> gradient;

  @override
  bool operator ==(Object other) =>
      other is AlbumPalette && other.seed == seed && _listEq(other.gradient, gradient);

  @override
  int get hashCode => Object.hash(seed, Object.hashAll(gradient));

  static bool _listEq(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Extracts an [AlbumPalette] from cover art.
///
/// Uses `palette_generator` on a 64 px thumbnail. The picture is decoded by
/// the engine and the colors are counted in a background isolate, so a song
/// change costs the UI thread nothing (it ran there before: a stutter on a
/// busy PC, now that Prism colors with cover tint are the default). The
/// package is marked discontinued upstream but is stable; it is isolated in
/// this one function so it can be replaced later without touching callers.
class AlbumPaletteExtractor {
  final _cache = <String, AlbumPalette?>{};

  Future<AlbumPalette?> fromFile(String? path) async {
    if (path == null) return null;
    if (_cache.containsKey(path)) return _cache[path];
    // Streamed songs have an https cover; local songs a cached file.
    final remote = path.startsWith('http');
    final file = File(path);
    if (!remote && !await file.exists()) return _cache[path] = null;
    try {
      final pixels = await _thumbnail(remote ? NetworkImage(path) : FileImage(file));
      if (pixels == null) return _cache[path] = null;
      final colors = await _countInBackground(pixels);
      if (colors == null) return _cache[path] = null;
      final result = AlbumPalette(seed: Color(colors[0]), gradient: [for (final c in colors.skip(1)) Color(c)]);
      if (_cache.length > 200) _cache.remove(_cache.keys.first);
      return _cache[path] = result;
    } on Object {
      return _cache[path] = null;
    }
  }

  static const _side = 64;

  /// The cover as 64 x 64 RGBA pixels (decoded by the engine, off this thread).
  static Future<({Uint8List bytes, int width, int height})?> _thumbnail(ImageProvider provider) async {
    final stream = ResizeImage(provider, width: _side, height: _side).resolve(ImageConfiguration.empty);
    final info = Completer<ImageInfo?>();
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (i, _) => info.isCompleted ? null : info.complete(i),
      onError: (_, _) => info.isCompleted ? null : info.complete(null),
    );
    stream.addListener(listener);
    try {
      final image = await info.future.timeout(const Duration(seconds: 15), onTimeout: () => null);
      if (image == null) return null;
      final data = await image.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final w = image.image.width, h = image.image.height;
      image.dispose();
      return data == null ? null : (bytes: data.buffer.asUint8List(), width: w, height: h);
    } finally {
      stream.removeListener(listener);
    }
  }

  /// Seed + 3 gradient colors as ARGB ints.
  static Future<List<int>?> _countInBackground(({Uint8List bytes, int width, int height}) px) async {
    try {
      return await Isolate.run(() => countColors(px.bytes, px.width, px.height));
    } on Object {
      // No background isolate for this (tests, odd platforms): here then.
      return countColors(px.bytes, px.width, px.height);
    }
  }

  /// The colors of an RGBA picture: seed, then the 3 gradient colors.
  @visibleForTesting
  static Future<List<int>?> countColors(Uint8List rgba, int width, int height) async {
    final palette = await PaletteGenerator.fromByteData(
      EncodedImage(ByteData.sublistView(rgba), width: width, height: height),
      maximumColorCount: 16,
    );
    final seed = palette.vibrantColor?.color ?? palette.dominantColor?.color;
    if (seed == null) return null;
    return [
      seed.toARGB32(),
      (palette.dominantColor?.color ?? seed).toARGB32(),
      (palette.vibrantColor?.color ?? palette.lightVibrantColor?.color ?? seed).toARGB32(),
      (palette.darkMutedColor?.color ?? palette.darkVibrantColor?.color ?? seed).toARGB32(),
    ];
  }
}

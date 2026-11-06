import 'dart:io';

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
/// Uses `palette_generator` on a 96 px thumbnail (fast: a few ms). The
/// package is marked discontinued upstream but is stable; it is isolated in
/// this one function so it can be replaced by `material_color_utilities`
/// quantisation later without touching callers.
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
      final ImageProvider image = remote ? NetworkImage(path) : FileImage(file);
      final palette = await PaletteGenerator.fromImageProvider(
        ResizeImage(image, width: 96, height: 96),
        maximumColorCount: 16,
      );
      final seed = palette.vibrantColor?.color ?? palette.dominantColor?.color;
      if (seed == null) return _cache[path] = null;
      final result = AlbumPalette(
        seed: seed,
        gradient: [
          palette.dominantColor?.color ?? seed,
          palette.vibrantColor?.color ?? palette.lightVibrantColor?.color ?? seed,
          palette.darkMutedColor?.color ?? palette.darkVibrantColor?.color ?? seed,
        ],
      );
      if (_cache.length > 200) _cache.remove(_cache.keys.first);
      return _cache[path] = result;
    } on Object {
      return _cache[path] = null;
    }
  }
}

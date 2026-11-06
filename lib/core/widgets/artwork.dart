import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/prism_theme_extensions.dart';

/// Hero tag shared by the mini-player cover and the full player cover.
const nowPlayingArtHeroTag = 'now-playing-artwork';

/// Square cover image with a pretty placeholder for songs without art.
///
/// Images are decoded at the size they are shown ([cacheSize] in physical
/// pixels), which keeps memory low and scrolling smooth in long lists.
class Artwork extends StatelessWidget {
  const Artwork({
    super.key,
    required this.path,
    this.size,
    this.borderRadius,
    this.seed,
    this.icon = Icons.music_note_rounded,
  });

  final String? path;
  final double? size;
  final BorderRadius? borderRadius;

  /// Used to vary the placeholder gradient between items.
  final Object? seed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? context.shape.small;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheSize = size == null ? 600 : (size! * dpr).round();
    final p = path;
    Widget child;
    if (p == null) {
      child = _Placeholder(seed: seed, icon: icon);
    } else {
      Widget frame(BuildContext context, Widget child, int? frame, bool sync) {
        if (sync) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: context.motion.d(PrismMotion.medium),
          child: child,
        );
      }

      // Streamed songs (YouTube, SoundCloud) have an https cover.
      child = p.startsWith('http')
          ? Image.network(
              p,
              fit: BoxFit.cover,
              cacheWidth: cacheSize,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => _Placeholder(seed: seed, icon: icon),
              frameBuilder: frame,
            )
          : Image.file(
              File(p),
              fit: BoxFit.cover,
              cacheWidth: cacheSize,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (_, _, _) => _Placeholder(seed: seed, icon: icon),
              frameBuilder: frame,
            );
    }
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(width: size, height: size, child: AspectRatio(aspectRatio: 1, child: child)),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({this.seed, required this.icon});

  final Object? seed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A plain sleeve: one neutral tone (a step lighter or darker per album so
    // a grid does not look like one block) and a quiet glyph. No hues.
    final step = ((seed?.hashCode ?? 0) % 4) * 0.02;
    final dark = scheme.brightness == Brightness.dark;
    final base = Color.lerp(scheme.surfaceContainerHigh, dark ? Colors.white : Colors.black, step)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: base,
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.06)),
      ),
      child: LayoutBuilder(
        builder: (context, c) => Center(
          child: Icon(icon, size: c.biggest.shortestSide * 0.36, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
        ),
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/prism_theme_extensions.dart';
import 'cover_urls.dart';

/// Hero tag shared by the mini-player cover and the full player cover.
const nowPlayingArtHeroTag = 'now-playing-artwork';

/// Square cover image with a pretty placeholder for songs without art.
///
/// Images are decoded at the size they are shown, in physical pixels: small
/// list covers stay light, and the big player cover is as sharp as the
/// picture allows (it used to be decoded at a fixed 600 px). Online covers
/// are asked for in the service's largest size ([sharperCoverUrl]).
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
    final fixed = size;
    final Widget child = fixed != null
        ? _image(context, fixed)
        // No size given (the big covers): measure, so it decodes at its real size.
        : LayoutBuilder(builder: (context, c) => _image(context, c.biggest.shortestSide.isFinite ? c.biggest.shortestSide : 600));
    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(width: size, height: size, child: AspectRatio(aspectRatio: 1, child: child)),
    );
  }

  Widget _image(BuildContext context, double logical) {
    final p = path;
    if (p == null) return _Placeholder(seed: seed, icon: icon);
    // Rounded up to steps of 64 px, so a cover that grows a little while a
    // panel animates isn't decoded again for every pixel.
    final px = ((logical * MediaQuery.devicePixelRatioOf(context)) / 64).ceil() * 64;
    final cacheSize = px.clamp(64, 2048);
    // Big covers get the better (slower) scaling; list thumbnails don't need it.
    final quality = logical >= 160 ? FilterQuality.high : FilterQuality.medium;
    Widget frame(BuildContext context, Widget child, int? frame, bool sync) {
      if (sync) return child;
      return AnimatedOpacity(
        opacity: frame == null ? 0 : 1,
        duration: context.motion.d(PrismMotion.medium),
        child: child,
      );
    }

    Widget placeholder(BuildContext _, Object _, StackTrace? _) => _Placeholder(seed: seed, icon: icon);
    if (!p.startsWith('http')) {
      return Image.file(
        File(p),
        fit: BoxFit.cover,
        cacheWidth: cacheSize,
        gaplessPlayback: true,
        filterQuality: quality,
        errorBuilder: placeholder,
        frameBuilder: frame,
      );
    }
    // Streamed and imported songs have an https cover.
    Widget network(String url, ImageErrorWidgetBuilder onError) => Image.network(
          url,
          fit: BoxFit.cover,
          cacheWidth: cacheSize,
          gaplessPlayback: true,
          filterQuality: quality,
          errorBuilder: onError,
          frameBuilder: frame,
        );
    final sharp = sharperCoverUrl(p);
    final fallback = fallbackCoverUrl(p) ?? p;
    if (sharp == p) return network(p, placeholder);
    return network(sharp, (context, _, _) => network(fallback, placeholder));
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

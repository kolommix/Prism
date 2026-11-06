import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/prism_theme_extensions.dart';

/// Translucent "glass" panel whose opacity (and blur) follow the theme's
/// glass setting.
///
/// Blur is expensive: a `BackdropFilter` re-blurs everything behind it on
/// every frame the backdrop changes (and the background gradient animates).
/// Profiling showed the four always-on desktop panels costing ~5 ms of GPU
/// time per frame for no visible gain – blurring a soft gradient looks the
/// same as not blurring it. So blur is opt-in via [backdrop] and only used
/// where real content scrolls underneath (phone mini-player and nav bar).
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.border = true,
    this.color,
    this.backdrop = false,
  });

  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool border;

  /// Override tint (defaults to the theme surface).
  final Color? color;

  /// Blur what is behind the panel (only when content scrolls under it).
  final bool backdrop;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final scheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? context.shape.medium;
    final tint = color ?? glass.tint;
    final frost = glass.frosted && glass.panelOverride != null;
    final blur = (backdrop && glass.enabled) || frost;
    final decoration = BoxDecoration(
      // Without blur the panel needs a bit more body to stay readable.
      color: tint.withValues(
        alpha: glass.panelOverride ?? (!glass.enabled ? 1 : (blur ? glass.opacity : (glass.opacity + 0.12).clamp(0, 1))),
      ),
      borderRadius: radius,
      border: border ? Border.all(color: scheme.onSurface.withValues(alpha: 0.08)) : null,
    );
    final content = DecoratedBox(
      decoration: decoration,
      // Hover and click effects of what is inside paint on this, above the tint.
      child: Material(
        type: MaterialType.transparency,
        child: padding == null ? child : Padding(padding: padding!, child: child),
      ),
    );
    if (!blur) return ClipRRect(borderRadius: radius, child: content);
    final sigma = frost ? 6.0 : glass.blurSigma;
    final filter = ImageFilter.blur(sigmaX: sigma, sigmaY: sigma);
    // One shared blur for all panels when the engine can do that.
    return ClipRRect(
      borderRadius: radius,
      child: BackdropGroup.of(context) != null
          ? BackdropFilter.grouped(filter: filter, child: content)
          : BackdropFilter(filter: filter, child: content),
    );
  }
}

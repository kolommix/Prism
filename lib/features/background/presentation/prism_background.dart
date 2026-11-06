import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/ambient_backdrop.dart';
import '../../settings/application/settings_controller.dart';
import 'live_background.dart';

/// The app background in every theme: the current cover, blurred and grey
/// under a wash, or the animated background chosen in Settings → Appearance.
///
/// The child always stays in the same slot, so switching backgrounds never
/// rebuilds (or loses the state of) what is on top.
class PrismBackground extends ConsumerWidget {
  const PrismBackground({
    super.key,
    required this.artworkPath,
    this.intensity = 1,
    this.child,
    this.nested = false,
    this.plain = false,
  });

  final String? artworkPath;
  final double intensity;
  final Widget? child;

  /// Inside the shell (album page): lets the live background show through.
  final bool nested;

  /// Always the cover (mini player: no room or need for an animation).
  final bool plain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(settingsProvider.select((s) => s.background.current));
    final params = ref.watch(settingsProvider.select((s) => s.background.paramsFor(s.background.current)));
    final showCover = ref.watch(settingsProvider.select((s) => s.background.showCover));
    final live = !plain && ref.watch(settingsProvider.select((s) => s.background.isLive));
    if (live && nested) return child ?? const SizedBox.shrink();
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: live && !showCover
              ? ColoredBox(color: Theme.of(context).colorScheme.surface)
              : AmbientBackdrop(artworkPath: artworkPath, strength: intensity),
        ),
        Positioned.fill(
          child: live
              ? IgnorePointer(child: LiveBackground(style: style, params: params))
              : const SizedBox.shrink(),
        ),
        // Darker towards the edges: the animation sinks into the page.
        Positioned.fill(
          child: live
              ? IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 1.05,
                        colors: [
                          Theme.of(context).colorScheme.surface.withValues(alpha: 0.05),
                          Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        if (child != null) RepaintBoundary(child: child),
      ],
    );
  }
}

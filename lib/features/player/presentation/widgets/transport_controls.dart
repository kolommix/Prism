import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/motion/spring_button.dart';
import '../../../../core/theme/prism_theme_extensions.dart';
import '../../application/player_providers.dart';
import '../../domain/playback_queue.dart';
import 'play_pause_button.dart';
import '../../../../l10n/l10n.dart';

/// shuffle · previous · play/pause · next · repeat
class TransportControls extends ConsumerWidget {
  const TransportControls({super.key, this.big = true});

  final bool big;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerControllerProvider);
    final shuffled = ref.watch(queueProvider.select((q) => q.value?.shuffled ?? false));
    final repeat = ref.watch(queueProvider.select((q) => q.value?.repeatMode ?? QueueRepeatMode.off));
    final scheme = Theme.of(context).colorScheme;
    final side = big ? 26.0 : 20.0;
    final skip = big ? 38.0 : 26.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Toggle(
          active: shuffled,
          tooltip: shuffled ? l10n.shuffleOn : l10n.shuffleOff,
          icon: Icons.shuffle_rounded,
          size: side,
          onPressed: player.toggleShuffle,
        ),
        SizedBox(width: big ? 12 : 4),
        SpringIconButton(
          icon: const Icon(Icons.skip_previous_rounded),
          size: skip,
          tooltip: l10n.previous,
          onPressed: player.skipPrevious,
        ),
        SizedBox(width: big ? 12 : 4),
        PlayPauseButton(size: big ? 36 : 24),
        SizedBox(width: big ? 12 : 4),
        SpringIconButton(
          icon: const Icon(Icons.skip_next_rounded),
          size: skip,
          tooltip: l10n.next,
          onPressed: player.skipNext,
        ),
        SizedBox(width: big ? 12 : 4),
        _Toggle(
          active: repeat != QueueRepeatMode.off,
          tooltip: switch (repeat) {
            QueueRepeatMode.off => l10n.repeatOff,
            QueueRepeatMode.all => l10n.repeatAll,
            QueueRepeatMode.one => l10n.repeatOne,
          },
          icon: repeat == QueueRepeatMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
          size: side,
          color: scheme.primary,
          onPressed: player.cycleRepeat,
        ),
      ],
    );
  }
}

/// Icon toggle that glows with a small dot when active.
class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.active,
    required this.tooltip,
    required this.icon,
    required this.size,
    required this.onPressed,
    this.color,
  });

  final bool active;
  final String tooltip;
  final IconData icon;
  final double size;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = active ? (color ?? scheme.primary) : scheme.onSurfaceVariant;
    final d = context.motion.d(PrismMotion.medium);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SpringIconButton(
          tooltip: tooltip,
          size: size,
          color: c,
          onPressed: onPressed,
          icon: AnimatedSwitcher(
            duration: d,
            transitionBuilder: (child, a) => RotationTransition(
              turns: Tween(begin: 0.75, end: 1.0).animate(a),
              child: FadeTransition(opacity: a, child: child),
            ),
            child: Icon(icon, key: ValueKey(icon)),
          ),
        ),
        AnimatedContainer(
          duration: d,
          curve: PrismMotion.curve,
          width: active ? 5 : 0,
          height: active ? 5 : 0,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/motion/spring_button.dart';
import '../../../../core/theme/prism_theme_extensions.dart';
import '../../application/player_providers.dart';
import '../../../../l10n/l10n.dart';

/// Play/pause with a morphing icon and spring press feedback.
class PlayPauseButton extends ConsumerStatefulWidget {
  const PlayPauseButton({super.key, this.size = 32, this.filled = true});

  final double size;
  final bool filled;

  @override
  ConsumerState<PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends ConsumerState<PlayPauseButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, value: ref.read(isPlayingProvider) ? 1 : 0);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playing = ref.watch(isPlayingProvider);
    final d = context.motion.d(PrismMotion.medium);
    _c.duration = d;
    playing ? _c.forward() : _c.reverse();
    return SpringIconButton(
      filled: widget.filled,
      size: widget.size,
      padding: widget.filled ? widget.size * 0.45 : 8,
      tooltip: playing ? l10n.pause : l10n.play,
      onPressed: () => ref.read(playerControllerProvider).togglePlay(),
      icon: AnimatedIcon(icon: AnimatedIcons.play_pause, progress: _c, size: widget.size),
    );
  }
}

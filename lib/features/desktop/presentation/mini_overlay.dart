import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/motion/spring_button.dart';
import '../../../core/widgets/artwork.dart';
import '../../background/presentation/prism_background.dart';
import '../../player/application/player_providers.dart';
import '../../player/presentation/widgets/play_pause_button.dart';
import '../../player/presentation/widgets/track_text.dart';
import '../../player/presentation/widgets/waveform_seek_bar.dart';
import '../application/desktop_extras.dart';
import '../../../l10n/l10n.dart';

/// Compact always-on-top player (Windows mini mode). Drag anywhere to move.
class MiniOverlay extends ConsumerWidget {
  const MiniOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    final player = ref.read(playerControllerProvider);
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: PrismBackground(
        artworkPath: track?.artworkPath,
        intensity: 0.7,
        plain: true,
        child: DragToMoveArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
            child: Column(children: [
              Expanded(
                child: Row(children: [
                  Artwork(path: track?.artworkPath, size: 64, seed: track?.album),
                  const SizedBox(width: 10),
                  Expanded(
                    child: track == null ? Text(l10n.nothingPlaying) : TrackText(track: track, dense: true, linkArtists: false),
                  ),
                  SpringIconButton(icon: const Icon(Icons.skip_previous_rounded), size: 22, onPressed: player.skipPrevious),
                  const PlayPauseButton(size: 22, filled: false),
                  SpringIconButton(icon: const Icon(Icons.skip_next_rounded), size: 22, onPressed: player.skipNext),
                  SpringIconButton(
                    tooltip: l10n.backToFullWindow,
                    icon: const Icon(Icons.open_in_full_rounded),
                    size: 18,
                    onPressed: () => ref.read(miniModeProvider.notifier).exit(),
                  ),
                ]),
              ),
              const WaveformSeekBar(compact: true, showTimes: false),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Player-bar button that switches to mini mode.
class MiniModeButton extends ConsumerWidget {
  const MiniModeButton({super.key, this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SpringIconButton(
        tooltip: l10n.miniPlayerAlwaysOnTop,
        size: size,
        icon: const Icon(Icons.picture_in_picture_alt_rounded),
        onPressed: () => ref.read(miniModeProvider.notifier).enter(),
      );
}

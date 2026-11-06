import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/spring_button.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/glass.dart';
import '../application/player_providers.dart';
import 'widgets/play_pause_button.dart';
import 'widgets/track_text.dart';
import 'widgets/waveform_seek_bar.dart';
import '../../../l10n/l10n.dart';

/// Phone mini-player above the bottom navigation.
///
/// Tap (or swipe up) opens the full player; the cover flies there through a
/// shared [Hero]. Swipe left/right to skip.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    if (track == null) return const SizedBox.shrink();
    final player = ref.read(playerControllerProvider);

    return GestureDetector(
      onTap: () => context.push(Routes.player),
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < -300) context.push(Routes.player);
      },
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -400) player.skipNext();
        if (v > 400) player.skipPrevious();
      },
      child: GlassPanel(
        backdrop: true, // list content scrolls under the mini-player
        borderRadius: context.shape.large,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 4, 2),
              child: Row(
                children: [
                  Hero(
                    tag: nowPlayingArtHeroTag,
                    child: Artwork(path: track.artworkPath, size: 46, seed: track.album),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: TrackText(track: track, dense: true)),
                  const PlayPauseButton(size: 26, filled: false),
                  SpringIconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    tooltip: l10n.next,
                    onPressed: player.skipNext,
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: WaveformSeekBar(compact: true, showTimes: false),
            ),
          ],
        ),
      ),
    );
  }
}

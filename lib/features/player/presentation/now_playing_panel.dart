import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';

import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/glass.dart';
import '../application/player_providers.dart';
import 'immersive_player_page.dart';
import 'queue_list.dart';
import '../../lyrics/presentation/lyrics_view.dart';
import 'widgets/track_text.dart';
import '../../../l10n/l10n.dart';

/// Right-hand panel on wide windows: big cover, track info and the queue.
///
/// The cover here is deliberately *not* a Hero (the player bar owns the hero
/// tag), so both can be on screen at once.
class NowPlayingPanel extends ConsumerWidget {
  const NowPlayingPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    if (track == null) return const SizedBox.shrink();
    final playing = ref.watch(isPlayingProvider);
    final motion = context.motion;
    // A big cover must not push the queue off a normal window.
    final coverSide = (MediaQuery.sizeOf(context).height * 0.3).clamp(140.0, 300.0);

    return GlassPanel(
      borderRadius: context.shape.large,
      border: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Center(
              child: SizedBox.square(
                dimension: coverSide,
                child: AnimatedScale(
                  scale: playing ? 1 : 0.92,
                  duration: motion.d(PrismMotion.long),
                  curve: PrismMotion.curve,
                  child: _PanelCover(
                    child: AnimatedSwitcher(
                      duration: motion.d(PrismMotion.long),
                      child: Container(
                        key: ValueKey(track.artworkPath ?? track.id),
                        decoration: BoxDecoration(
                          borderRadius: context.shape.large,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Artwork(path: track.artworkPath, borderRadius: context.shape.large, seed: track.album),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TrackText(track: track),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.upNext)),
                ButtonSegment(value: true, label: Text(l10n.lyrics)),
              ],
              selected: {ref.watch(_panelLyricsProvider)},
              showSelectedIcon: false,
              onSelectionChanged: (s) => ref.read(_panelLyricsProvider.notifier).state = s.first,
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: motion.d(PrismMotion.medium),
              child: ref.watch(_panelLyricsProvider)
                  ? const LyricsView(key: ValueKey('lyrics'))
                  : const QueueList(key: ValueKey('queue'), padding: EdgeInsets.only(bottom: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelLyrics extends Notifier<bool> {
  @override
  bool build() => false;

  @override
  set state(bool v) => super.state = v;
}

/// Side panel tab: false = queue, true = lyrics.
final _panelLyricsProvider = NotifierProvider<_PanelLyrics, bool>(_PanelLyrics.new);

/// The panel cover: click fills the app window with the lyrics view (the
/// window itself stays as it is) and the cover flies there (Hero). Hovering
/// lifts it a little and shows an icon.
class _PanelCover extends StatefulWidget {
  const _PanelCover({required this.child});

  final Widget child;

  @override
  State<_PanelCover> createState() => _PanelCoverState();
}

class _PanelCoverState extends State<_PanelCover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.push(Routes.immersive),
        child: Tooltip(
          message: l10n.expand,
          waitDuration: const Duration(milliseconds: 600),
          child: AnimatedScale(
            scale: _hover ? 1.03 : 1,
            duration: motion.d(PrismMotion.medium),
            curve: Curves.easeOutCubic,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Hero(tag: panelArtHeroTag, child: widget.child),
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _hover ? 1 : 0,
                    duration: motion.d(PrismMotion.short),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), shape: BoxShape.circle),
                      child: const Icon(Icons.open_in_full_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

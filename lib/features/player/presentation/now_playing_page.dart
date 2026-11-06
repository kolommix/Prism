import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/spring_button.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/widgets/artwork.dart';
import '../../background/presentation/prism_background.dart';
import '../../library/presentation/widgets/track_actions.dart';
import '../application/player_providers.dart';
import 'player_extras.dart';
import 'queue_list.dart';
import 'tuning_controls.dart';
import '../../together/presentation/together_sheet.dart';
import '../../lyrics/presentation/lyrics_view.dart';
import '../../visualizer/presentation/visualizer.dart';
import 'widgets/track_text.dart';
import 'widgets/transport_controls.dart';
import 'widgets/waveform_seek_bar.dart';
import '../../../l10n/l10n.dart';

/// Full-screen player.
///
/// * Background: animated gradient from the cover's palette.
/// * Cover: shared [Hero] with the mini-player/player bar; it breathes
///   (scales down a bit) when paused.
/// * Drag down to dismiss (phone). On wide windows the queue is shown on the
///   right instead of in a sheet.
class NowPlayingPage extends ConsumerStatefulWidget {
  const NowPlayingPage({super.key});

  @override
  ConsumerState<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends ConsumerState<NowPlayingPage> {
  double _drag = 0;
  bool _closing = false;

  void _close() {
    // Once only: a rebuild while the page is already leaving must not pop
    // the page underneath as well.
    if (_closing || !mounted) return;
    if (context.canPop()) {
      _closing = true;
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(currentTrackProvider);
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 900;

    if (track == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _close());
      return const SizedBox.shrink();
    }

    final content = SafeArea(
      child: Column(
        children: [
          _TopBar(onClose: _close, onMore: () => showTrackActions(context, ref, track)),
          Expanded(
            child: wide
                ? Row(
                    children: [
                      Expanded(flex: 5, child: _PlayerColumn(maxArt: size.height * 0.5)),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 24, bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.upNext, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              const Expanded(child: QueueList()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : _PlayerColumn(maxArt: size.width - 56),
          ),
        ],
      ),
    );

    return GestureDetector(
      onVerticalDragUpdate: wide ? null : (d) => setState(() => _drag = (_drag + d.delta.dy).clamp(0, size.height)),
      onVerticalDragEnd: wide
          ? null
          : (d) {
              if (_drag > 140 || (d.primaryVelocity ?? 0) > 700) {
                _close();
              } else {
                setState(() => _drag = 0);
              }
            },
      child: AnimatedContainer(
        duration: _drag == 0 ? context.motion.d(PrismMotion.medium) : Duration.zero,
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _drag, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_drag > 0 ? context.shape.radius * 1.5 : 0),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            child: PrismBackground(artworkPath: track.artworkPath, child: content),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onClose, required this.onMore});

  final VoidCallback onClose;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          SpringIconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            size: 30,
            tooltip: l10n.close,
            onPressed: onClose,
          ),
          Expanded(
            child: Text(
              l10n.nowPlaying,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
          SpringIconButton(icon: const Icon(Icons.more_horiz_rounded), tooltip: l10n.more, onPressed: onMore),
        ],
      ),
    );
  }
}

class _PlayerColumn extends ConsumerWidget {
  const _PlayerColumn({required this.maxArt});

  final double maxArt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider)!;
    final playing = ref.watch(isPlayingProvider);
    final motion = context.motion;
    final art = maxArt.clamp(160.0, 520.0);
    final stage = ref.watch(playerStageProvider);

    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        clipBehavior: Clip.none, // the cover halo and shadow reach past the edges
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const _StageSwitch(),
                const SizedBox(height: 12),
                // Cover, lyrics and visualizer cross-fade (with a little
                // zoom) instead of jumping.
                SizedBox(
                  height: art,
                  child: AnimatedSwitcher(
                    duration: motion.d(PrismMotion.long),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: ScaleTransition(scale: Tween(begin: 0.94, end: 1.0).animate(a), child: child),
                    ),
                    child: switch (stage) {
                      PlayerStage.lyrics => const LyricsView(key: ValueKey('lyrics')),
                      PlayerStage.visualizer => const Column(
                          key: ValueKey('viz'),
                          children: [
                            Expanded(child: Visualizer()),
                            SizedBox(height: 8),
                            VisualizerStylePicker(),
                          ],
                        ),
                      PlayerStage.cover => Center(
                          key: const ValueKey('cover'),
                          child: AnimatedScale(
                            scale: playing ? 1 : 0.88,
                            duration: motion.d(PrismMotion.long),
                            curve: playing ? PrismMotion.curve : Curves.easeOutCubic,
                            child: AnimatedContainer(
                              duration: motion.d(PrismMotion.long),
                              width: art,
                              height: art,
                              decoration: BoxDecoration(
                                borderRadius: context.shape.large,
                                boxShadow: [
                                  BoxShadow(
                                    // Black & white: a real drop shadow (the
                                    // halo behind the cover is the light).
                                    color: Colors.black
                                        .withValues(alpha: playing ? 0.5 : 0.25),
                                    blurRadius: playing ? 60 : 30,
                                    offset: const Offset(0, 24),
                                  ),
                                ],
                              ),
                              child: BeatPulse(
                                radius: context.shape.large,
                                child: Hero(
                                  tag: nowPlayingArtHeroTag,
                                  child: AnimatedSwitcher(
                                    duration: motion.d(PrismMotion.long),
                                    child: Artwork(
                                      key: ValueKey(track.artworkPath ?? track.id),
                                      path: track.artworkPath,
                                      size: art,
                                      borderRadius: context.shape.large,
                                      seed: track.album,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    },
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(child: TrackText(track: track)),
                    const FavoriteButton(size: 26),
                  ],
                ),
                const SizedBox(height: 18),
                const WaveformSeekBar(height: 56),
                const SizedBox(height: 16),
                const TransportControls(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SleepTimerButton(),
                    const TuningButton(),
                    const AbLoopButton(),
                    const EqButton(),
                    const TogetherButton(),
                    SpringIconButton(
                      icon: const Icon(Icons.content_cut_rounded),
                      tooltip: l10n.editThisSong,
                      onPressed: () => context.go(Routes.editor(track.id)),
                    ),
                    if (MediaQuery.sizeOf(context).width < 900)
                      SpringIconButton(
                        icon: const Icon(Icons.queue_music_rounded),
                        tooltip: l10n.queue,
                        onPressed: () => _showQueueSheet(context),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQueueSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Text(l10n.upNext, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Expanded(child: QueueList()),
        ],
      ),
    ),
  );
}

/// What the big area of the full player shows.
enum PlayerStage { cover, lyrics, visualizer }

class PlayerStageNotifier extends Notifier<PlayerStage> {
  @override
  PlayerStage build() => PlayerStage.cover;
  void set(PlayerStage s) => state = s;
}

final playerStageProvider = NotifierProvider<PlayerStageNotifier, PlayerStage>(PlayerStageNotifier.new);

class _StageSwitch extends ConsumerWidget {
  const _StageSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) => SegmentedButton<PlayerStage>(
    segments: [
      ButtonSegment(value: PlayerStage.cover, icon: Icon(Icons.album_rounded), label: Text(l10n.cover)),
      ButtonSegment(value: PlayerStage.lyrics, icon: Icon(Icons.lyrics_rounded), label: Text(l10n.lyrics)),
      ButtonSegment(value: PlayerStage.visualizer, icon: Icon(Icons.graphic_eq_rounded), label: Text(l10n.visualizer)),
    ],
    selected: {ref.watch(playerStageProvider)},
    showSelectedIcon: false,
    onSelectionChanged: (s) => ref.read(playerStageProvider.notifier).set(s.first),
  );
}

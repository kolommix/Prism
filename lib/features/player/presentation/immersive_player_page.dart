import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/motion/spring_button.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/widgets/artwork.dart';
import '../../background/presentation/prism_background.dart';
import '../../lyrics/presentation/lyrics_view.dart';
import '../../visualizer/presentation/visualizer.dart';
import '../application/player_providers.dart';
import 'player_extras.dart';
import 'widgets/track_text.dart';
import 'widgets/transport_controls.dart';
import 'widgets/waveform_seek_bar.dart';
import '../../../l10n/l10n.dart';

/// Hero tag of the cover in the desktop side panel, which flies into the
/// full-screen view.
const panelArtHeroTag = 'panel-artwork';

/// Full-screen "stage": big synced lyrics on the left, the cover (pulsing
/// with the bass) and controls on the right, the grey cover glowing behind.
///
/// It fills the app window. With [windowFullScreen] (the player bar's
/// full-screen button) the Windows window goes full screen as well; F11 toggles
/// that in both cases, Esc closes and restores the window as it was.
class ImmersivePlayerPage extends ConsumerStatefulWidget {
  const ImmersivePlayerPage({super.key, this.windowFullScreen = false});

  final bool windowFullScreen;

  @override
  ConsumerState<ImmersivePlayerPage> createState() => _ImmersivePlayerPageState();
}

class _ImmersivePlayerPageState extends ConsumerState<ImmersivePlayerPage> {
  bool _fullScreen = false;

  /// Only undo full screen if this page turned it on.
  bool _weEnteredFullScreen = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) {
      if (widget.windowFullScreen) {
        unawaited(_enterFullScreen());
      } else {
        unawaited(_readFullScreen());
      }
    }
  }

  /// The window may already be full screen when the page opens in-app.
  Future<void> _readFullScreen() async {
    try {
      final on = await windowManager.isFullScreen();
      if (mounted && on) setState(() => _fullScreen = true);
    } on Object {
      // No window manager (tests).
    }
  }

  Future<void> _enterFullScreen() async {
    try {
      if (await windowManager.isFullScreen()) {
        if (mounted) setState(() => _fullScreen = true);
        return;
      }
      await windowManager.setFullScreen(true);
      _weEnteredFullScreen = true;
      if (mounted) setState(() => _fullScreen = true);
    } on Object {
      // No window manager (tests) – the page still fills the window.
    }
  }

  Future<void> _toggleFullScreen() async {
    try {
      final next = !_fullScreen;
      await windowManager.setFullScreen(next);
      _weEnteredFullScreen = next;
      if (mounted) setState(() => _fullScreen = next);
    } on Object {
      // ignore
    }
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    if (_weEnteredFullScreen) {
      try {
        await windowManager.setFullScreen(false);
      } on Object {
        // ignore
      }
    }
    if (mounted) await Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    // Left another way (e.g. a route change): still restore the window.
    if (_weEnteredFullScreen && !_closing) unawaited(windowManager.setFullScreen(false).catchError((_) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(currentTrackProvider);
    if (track == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _close());
      return const SizedBox.shrink();
    }
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 900;
    final art = wide
        ? (size.width * 0.32).clamp(220.0, size.height * 0.52)
        : (size.width * 0.5).clamp(140.0, size.height * 0.3);

    final cover = _CoverColumn(art: art, wide: wide);
    const lyrics = LyricsView(textAlign: TextAlign.left, large: true);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _close,
        const SingleActivator(LogicalKeyboardKey.f11): _toggleFullScreen,
        const SingleActivator(LogicalKeyboardKey.space): () => ref.read(playerControllerProvider).togglePlay(),
      },
      child: Focus(
        autofocus: true,
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          child: PrismBackground(
            artworkPath: track.artworkPath,
            child: SafeArea(
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(wide ? 56 : 20, 56, wide ? 56 : 20, 28),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // The lyrics fade out at the top and bottom edges.
                              const Expanded(flex: 6, child: _EdgeFade(child: lyrics)),
                              const SizedBox(width: 56),
                              Expanded(flex: 5, child: cover),
                            ],
                          )
                        : Column(
                            children: [
                              cover,
                              const SizedBox(height: 16),
                              const Expanded(child: _EdgeFade(child: lyrics)),
                            ],
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 12,
                    child: Row(
                      children: [
                        if (Platform.isWindows)
                          SpringIconButton(
                            tooltip: _fullScreen ? l10n.leaveFullScreenF11 : l10n.fullScreenF11,
                            icon: Icon(_fullScreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded),
                            onPressed: _toggleFullScreen,
                          ),
                        SpringIconButton(
                          tooltip: l10n.closeEsc,
                          icon: const Icon(Icons.close_rounded),
                          onPressed: _close,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cover, title and controls.
class _CoverColumn extends ConsumerWidget {
  const _CoverColumn({required this.art, required this.wide});

  final double art;
  final bool wide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider)!;
    final playing = ref.watch(isPlayingProvider);
    final motion = context.motion;
    final radius = context.shape.large;
    final coverBox = AnimatedScale(
      scale: playing ? 1 : 0.92,
      duration: motion.d(PrismMotion.long),
      curve: playing ? PrismMotion.curve : Curves.easeOutCubic,
      child: Container(
        width: art,
        height: art,
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 60, offset: const Offset(0, 28))],
        ),
        child: BeatPulse(
          radius: radius,
          child: Hero(
            tag: panelArtHeroTag,
            child: AnimatedSwitcher(
              duration: motion.d(PrismMotion.long),
              child: Artwork(
                key: ValueKey(track.artworkPath ?? track.id),
                path: track.artworkPath,
                size: art,
                borderRadius: radius,
                seed: track.album,
              ),
            ),
          ),
        ),
      ),
    );
    if (!wide) {
      return Column(
        children: [
          coverBox,
          const SizedBox(height: 14),
          TrackText(track: track, center: true),
          const SizedBox(height: 8),
          const TransportControls(big: false),
        ],
      );
    }
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: art + 80),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            coverBox,
            const SizedBox(height: 36),
            Row(
              children: [
                Expanded(child: TrackText(track: track)),
                const FavoriteButton(size: 26),
              ],
            ),
            const SizedBox(height: 18),
            const WaveformSeekBar(height: 44),
            const SizedBox(height: 10),
            const TransportControls(),
          ],
        ),
      ),
    );
  }
}

/// Fades its child out towards the top and bottom edges.
class _EdgeFade extends StatelessWidget {
  const _EdgeFade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (r) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black, Colors.black, Colors.transparent],
          stops: [0, 0.14, 0.86, 1],
        ).createShader(r),
        child: child,
      );
}

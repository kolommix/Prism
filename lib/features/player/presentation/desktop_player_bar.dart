import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/spring_button.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/led_dot.dart';
import '../../audio_fx/application/eq_controller.dart';
import '../../desktop/application/desktop_extras.dart';
import '../../together/application/together_controller.dart';
import '../../together/presentation/together_sheet.dart';
import '../application/player_controller.dart';
import '../application/player_providers.dart';
import 'player_extras.dart';
import 'sleep_timer_sheet.dart';
import 'tuning_controls.dart';
import 'widgets/track_text.dart';
import 'widgets/transport_controls.dart';
import 'widgets/waveform_seek_bar.dart';
import '../../../l10n/l10n.dart';

/// Full-width player bar at the bottom of the desktop layout.
///
/// Left: cover + title (click → full player, cover flies via Hero).
/// Center: transport, then elapsed | waveform | total.
/// Right: only the everyday buttons (favorite, full-screen lyrics, volume);
/// sleep timer, speed, A-B loop, EQ, listen together and mini player live in
/// one "More" menu, with a dot on it while any of them is active.
class DesktopPlayerBar extends ConsumerWidget {
  const DesktopPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    if (track == null) return const SizedBox.shrink();
    // Volume slider only when the right-hand area has room for it.
    final width = MediaQuery.sizeOf(context).width;
    final wide = width > 1100;

    return GlassPanel(
      borderRadius: context.shape.large,
      border: false,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: SizedBox(
        height: 94,
        child: Row(
          children: [
            Expanded(
              // Narrow windows: the song name matters more than a long seek bar.
              flex: width < 1250 ? 4 : 3,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.push(Routes.player),
                  child: Row(
                    children: [
                      Hero(
                        tag: nowPlayingArtHeroTag,
                        child: Artwork(path: track.artworkPath, size: 64, seed: track.album),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: TrackText(track: track, dense: true)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            const Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TransportControls(big: false),
                  SizedBox(height: 10),
                  WaveformSeekBar(height: 28, showTimes: false, inlineTimes: true),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const FavoriteButton(size: 22),
                  const SizedBox(width: 4),
                  SpringIconButton(
                    tooltip: l10n.fullScreen,
                    size: 22,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    icon: const Icon(Icons.fullscreen_rounded),
                    onPressed: () => context.push(Routes.immersiveWindow),
                  ),
                  const SizedBox(width: 4),
                  const PlayerMoreButton(),
                  const SizedBox(width: 8),
                  VolumeSlider(showSlider: wide),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "More" button: a menu with the less-used player tools, each with its
/// current state on the right. A dot shows when one of them is switched on.
class PlayerMoreButton extends ConsumerWidget {
  const PlayerMoreButton({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final sleep = ref.watch(sleepTimerStateProvider).value;
    final tuning = ref.watch(tuningProvider).value ?? const PlaybackTuning();
    final eqOn = ref.watch(eqControllerProvider.select((e) => e.settings.enabled));
    final together = ref.watch(togetherProvider.select((s) => s.connected));
    final player = ref.read(playerControllerProvider);

    final sleepOn = sleep?.isActive ?? false;
    final tuned = tuning.speed != 1 || tuning.pitchSemitones != 0;
    final looping = tuning.loopA != null;
    final anyOn = sleepOn || tuned || looping || together;

    String? sleepLabel() {
      if (sleep == null || !sleep.isActive) return null;
      if (sleep.endOfTrack) return l10n.endOfSong;
      final m = sleep.remaining(DateTime.now()).inMinutes;
      return m < 1 ? l10n.x1Min : l10n.minutesValue(m);
    }

    String speedLabel() {
      String f(double v) => fmtNum(v, 2).replaceFirst(RegExp(r'\.?0+$'), '');
      if (!tuned) return l10n.normal;
      final pitch = tuning.pitchSemitones == 0
          ? ''
          : ' · ${l10n.stValue(tuning.pitchSemitones > 0 ? '+' : '', f(tuning.pitchSemitones.toDouble()))}';
      return '${f(tuning.speed)}x$pitch';
    }

    Widget item(IconData icon, String label, String? state, VoidCallback onPressed, {bool on = false}) =>
        MenuItemButton(
          leadingIcon: Icon(icon, size: 20, color: on ? scheme.onSurface : scheme.onSurfaceVariant),
          trailingIcon: state == null
              ? null
              : Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    state,
                    style: TextStyle(
                      color: on ? context.look.led : scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
          onPressed: onPressed,
          child: Text(label),
        );

    return MenuAnchor(
      alignmentOffset: const Offset(-150, 8),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: context.shape.medium)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
      ),
      menuChildren: [
        item(Icons.bedtime_rounded, l10n.sleepTimer, sleepLabel() ?? l10n.xOff, () => showSleepTimerSheet(context), on: sleepOn),
        item(Icons.speed_rounded, l10n.speedPitch, speedLabel(), () => showTuningSheet(context), on: tuned),
        item(
          Icons.repeat_one_rounded,
          l10n.aBLoop,
          tuning.looping ? l10n.xOn : (looping ? l10n.setB : l10n.xOff),
          player.cycleAbLoop,
          on: looping,
        ),
        item(Icons.equalizer_rounded, l10n.equalizer, eqOn ? l10n.xOn : l10n.xOff, () => context.go(Routes.equalizer), on: eqOn),
        item(
          Icons.groups_rounded,
          l10n.listenTogether,
          together ? l10n.connected : null,
          () => showTogetherSheet(context),
          on: together,
        ),
        const Divider(height: 12),
        item(Icons.picture_in_picture_alt_rounded, l10n.miniPlayer, null, () => ref.read(miniModeProvider.notifier).enter()),
      ],
      builder: (context, menu, _) => Stack(
        clipBehavior: Clip.none,
        children: [
          SpringIconButton(
            tooltip: l10n.more,
            size: size,
            color: anyOn ? scheme.onSurface : scheme.onSurfaceVariant,
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => menu.isOpen ? menu.close() : menu.open(),
          ),
          // Something in the menu is switched on: the LED is lit.
          Positioned(right: 6, top: 6, child: IgnorePointer(child: LedDot(on: anyOn))),
        ],
      ),
    );
  }
}

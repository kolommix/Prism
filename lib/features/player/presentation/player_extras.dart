import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/spring_button.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../library/application/library_providers.dart';
import '../application/player_providers.dart';
import 'sleep_timer_sheet.dart';
import '../../../l10n/l10n.dart';

/// Heart that pops when toggled.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    final fav = ref.watch(favoriteIdsProvider.select((s) => track != null && (s.value?.contains(track.id) ?? false)));
    final scheme = Theme.of(context).colorScheme;
    return SpringIconButton(
      tooltip: fav ? l10n.removeFromFavorites : l10n.addToFavorites,
      size: size,
      color: fav ? scheme.tertiary : scheme.onSurfaceVariant,
      onPressed: track == null ? null : () => ref.read(libraryRepositoryProvider).toggleFavorite(track.id),
      icon: AnimatedSwitcher(
        duration: context.motion.d(PrismMotion.medium),
        transitionBuilder: (child, a) => ScaleTransition(
          scale: CurvedAnimation(parent: a, curve: PrismMotion.curve, reverseCurve: Curves.easeIn),
          child: child,
        ),
        child: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, key: ValueKey(fav)),
      ),
    );
  }
}

/// Moon icon; highlighted while a sleep timer runs.
class SleepTimerButton extends ConsumerWidget {
  const SleepTimerButton({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(sleepTimerStateProvider.select((s) => s.value?.isActive ?? false));
    final scheme = Theme.of(context).colorScheme;
    return SpringIconButton(
      tooltip: l10n.sleepTimer,
      size: size,
      color: active ? scheme.primary : scheme.onSurfaceVariant,
      onPressed: () => showSleepTimerSheet(context),
      icon: Icon(active ? Icons.bedtime_rounded : Icons.bedtime_outlined),
    );
  }
}

/// Player volume 0..1 for the UI. Kept here (not in a widget) so the slider
/// shows the real value after the player bar is rebuilt or re-created.
class PlayerVolume extends Notifier<double> {
  double _beforeMute = 1;

  @override
  double build() => 1;

  void set(double v) {
    state = v.clamp(0.0, 1.0);
    ref.read(playerControllerProvider).setVolume(state);
  }

  void toggleMute() {
    if (state == 0) {
      set(_beforeMute == 0 ? 1 : _beforeMute);
    } else {
      _beforeMute = state;
      set(0);
    }
  }
}

final playerVolumeProvider = NotifierProvider<PlayerVolume, double>(PlayerVolume.new);

/// Speaker icon (tap = mute) + a slim slider; the mouse wheel over it
/// changes the volume too.
class VolumeSlider extends ConsumerWidget {
  const VolumeSlider({super.key, this.showSlider = true});

  final bool showSlider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final volume = ref.watch(playerVolumeProvider);
    final ctrl = ref.read(playerVolumeProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final icon = volume == 0
        ? Icons.volume_off_rounded
        : (volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded);
    return Listener(
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) ctrl.set(volume - e.scrollDelta.dy / 1500);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpringIconButton(
            tooltip: volume == 0 ? l10n.unmute : l10n.mute((volume * 100).round()),
            size: 22,
            color: scheme.onSurfaceVariant,
            icon: Icon(icon),
            onPressed: ctrl.toggleMute,
          ),
          if (showSlider)
            SizedBox(
              width: 96,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6, elevation: 0, pressedElevation: 0),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: scheme.onSurface,
                  inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.18),
                  thumbColor: scheme.onSurface,
                  showValueIndicator: ShowValueIndicator.never,
                ),
                child: Slider(value: volume, onChanged: ctrl.set),
              ),
            ),
        ],
      ),
    );
  }
}

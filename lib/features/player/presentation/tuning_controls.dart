import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/spring_button.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../audio_fx/application/eq_controller.dart';
import '../application/player_controller.dart';
import '../application/player_providers.dart';
import 'widgets/waveform_seek_bar.dart';
import '../../../l10n/l10n.dart';

/// Speed / pitch chip that opens [showTuningSheet]; shows the current values.
class TuningButton extends ConsumerWidget {
  const TuningButton({super.key, this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tuningProvider).value ?? const PlaybackTuning();
    final changed = t.speed != 1 || t.pitchSemitones != 0;
    final scheme = Theme.of(context).colorScheme;
    return SpringIconButton(
      tooltip: l10n.speedPitch,
      size: size,
      color: changed ? scheme.primary : scheme.onSurfaceVariant,
      onPressed: () => showTuningSheet(context),
      icon: changed
          ? Text('${_fmt(t.speed)}x', style: TextStyle(fontWeight: FontWeight.w600, fontSize: size * 0.6, color: scheme.primary))
          : const Icon(Icons.speed_rounded),
    );
  }
}

String _fmt(double v) => fmtNum(v, 2).replaceFirst(RegExp(r'\.?0+$'), '');

/// A-B loop: first tap marks A, second marks B and starts looping, third clears.
class AbLoopButton extends ConsumerWidget {
  const AbLoopButton({super.key, this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(tuningProvider).value ?? const PlaybackTuning();
    final scheme = Theme.of(context).colorScheme;
    final label = t.looping ? 'A-B' : (t.loopA != null ? 'A-' : 'A-B');
    final active = t.loopA != null;
    return SpringIconButton(
      tooltip: t.looping
          ? l10n.loopingTapToClear(formatDuration(t.loopA!), formatDuration(t.loopB!))
          : (active ? l10n.tapAgainToSetB : l10n.aBLoopTapToSet),
      size: size,
      color: active ? scheme.primary : scheme.onSurfaceVariant,
      onPressed: () => ref.read(playerControllerProvider).cycleAbLoop(),
      icon: AnimatedContainer(
        duration: context.motion.d(PrismMotion.short),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: active ? scheme.primary : scheme.onSurfaceVariant, width: 1.5),
          color: t.looping ? scheme.primary.withValues(alpha: 0.18) : Colors.transparent,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: size * 0.5, fontWeight: FontWeight.w600, color: active ? scheme.primary : scheme.onSurfaceVariant)),
      ),
    );
  }
}

/// Opens the equalizer.
class EqButton extends ConsumerWidget {
  const EqButton({super.key, this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(eqControllerProvider.select((e) => e.settings.enabled));
    final scheme = Theme.of(context).colorScheme;
    return SpringIconButton(
      tooltip: l10n.equalizer,
      size: size,
      color: on ? scheme.primary : scheme.onSurfaceVariant,
      // go() replaces the whole stack, so this also closes the full player.
      onPressed: () => context.go(Routes.equalizer),
      icon: const Icon(Icons.equalizer_rounded),
    );
  }
}

/// Bottom sheet with playback speed and pitch.
Future<void> showTuningSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      builder: (context) => Consumer(builder: (context, ref, _) {
        final t = ref.watch(tuningProvider).value ?? const PlaybackTuning();
        final player = ref.read(playerControllerProvider);
        final text = Theme.of(context).textTheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(l10n.speed, style: text.titleMedium),
                  const Spacer(),
                  Text(l10n.xPitchKept(_fmt(t.speed)), style: text.labelLarge),
                ]),
                Slider(
                  value: t.speed.clamp(0.5, 2.0),
                  min: 0.5,
                  max: 2.0,
                  divisions: 30,
                  onChanged: (v) => player.setSpeed((v * 20).round() / 20),
                ),
                Wrap(spacing: 8, children: [
                  for (final v in const [0.75, 1.0, 1.25, 1.5, 2.0])
                    ChoiceChip(label: Text('${_fmt(v)}x'), selected: t.speed == v, onSelected: (_) => player.setSpeed(v)),
                ]),
                const SizedBox(height: 20),
                Row(children: [
                  Text(l10n.pitch, style: text.titleMedium),
                  const Spacer(),
                  Text(l10n.semitonesSpeedKept(t.pitchSemitones > 0 ? '+' : '', _fmt(t.pitchSemitones)),
                      style: text.labelLarge),
                ]),
                Slider(
                  value: t.pitchSemitones,
                  min: -12,
                  max: 12,
                  divisions: 48,
                  onChanged: (v) => player.setPitchSemitones((v * 2).round() / 2),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      player.setSpeed(1);
                      player.setPitchSemitones(0);
                    },
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: Text(l10n.reset2),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );

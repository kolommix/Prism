import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/smooth_scroll.dart';
import '../../../core/motion/spring_button.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/widgets/glass.dart';
import '../../library/presentation/widgets/library_widgets.dart';
import '../../playlists/presentation/playlist_dialogs.dart';
import '../application/eq_controller.dart';
import '../domain/eq_math.dart';
import '../domain/eq_settings.dart';
import 'eq_response_curve.dart';
import '../../../l10n/l10n.dart';

/// 10-band graphic EQ with presets, preamp, bass boost and a live curve.
/// Same screen and model on Android and Windows.
class EqualizerPage extends ConsumerWidget {
  const EqualizerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eq = ref.watch(eqControllerProvider);
    final ctrl = ref.read(eqControllerProvider.notifier);
    final s = eq.settings;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final limitations = ref.watch(audioEffectsProvider).limitations;
    final headroom = eqPeakBoostDb(s) + s.preampDb;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.equalizer),
        actions: [
          IconButton(tooltip: l10n.resetToFlat, icon: const Icon(Icons.restart_alt_rounded), onPressed: ctrl.reset),
          IconButton(
            tooltip: l10n.saveAsPreset,
            icon: const Icon(Icons.bookmark_add_rounded),
            onPressed: () async {
              final name = await showPlaylistNameDialog(context, title: l10n.saveEqPreset, initial: l10n.myPreset);
              if (name != null) ctrl.savePreset(name);
            },
          ),
          Switch(value: s.enabled, onChanged: ctrl.setEnabled),
          const SizedBox(width: 8),
        ],
      ),
      body: SmoothListView(
        padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset(context)),
        children: [
          GlassPanel(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
            child: EqResponseCurve(settings: s, onBandChanged: ctrl.setBand),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: context.motion.d(PrismMotion.medium),
            child: s.enabled && headroom > 1
                ? Padding(
                    key: const ValueKey('clip'),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Icon(Icons.warning_amber_rounded, size: 18, color: scheme.tertiary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${l10n.boostMayClip(fmtNum(headroom, 1))}${l10n.limiterNote}',
                          style: text.bodySmall,
                        ),
                      ),
                    ]),
                  )
                : const SizedBox.shrink(key: ValueKey('ok')),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final p in eq.allPresets)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SpringButton(
                      onLongPress: p.builtIn
                          ? null
                          : () async {
                              if (await confirmDelete(context, l10n.preset(p.name))) ctrl.deletePreset(p.name);
                            },
                      child: ChoiceChip(
                        label: Text(eqPresetLabel(p.name)),
                        selected: s.enabled && s.presetName == p.name,
                        avatar: p.builtIn ? null : const Icon(Icons.person_rounded, size: 16),
                        onSelected: (_) => ctrl.applyPreset(p),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: Row(
              children: [
                for (var i = 0; i < eqBandFrequencies.length; i++)
                  Expanded(child: _BandSlider(index: i, value: s.gainsDb[i], enabled: s.enabled, onChanged: (v) => ctrl.setBand(i, v))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _LabeledSlider(
            icon: Icons.tune_rounded,
            label: l10n.preamp,
            value: s.preampDb,
            min: -eqMaxPreampDb,
            max: eqMaxPreampDb,
            format: (v) => l10n.dbValue(v >= 0 ? '+' : '', fmtNum(v, 1)),
            onChanged: ctrl.setPreamp,
          ),
          _LabeledSlider(
            icon: Icons.speaker_rounded,
            label: l10n.bassBoost,
            value: s.bassBoost,
            min: 0,
            max: 1,
            format: (v) => v < 0.005 ? l10n.xOff : '${(v * 100).round()} %',
            onChanged: ctrl.setBassBoost,
          ),
          const SizedBox(height: 12),
          for (final l in limitations)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline_rounded, size: 16, color: scheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(child: Text(l, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant))),
              ]),
            ),
        ],
      ),
    );
  }
}

class _BandSlider extends StatelessWidget {
  const _BandSlider({required this.index, required this.value, required this.enabled, required this.onChanged});

  final int index;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final f = eqBandFrequencies[index];
    final label = f >= 1000 ? '${(f / 1000).round()}k' : f.round().toString();
    final style = Theme.of(context).textTheme.labelSmall;
    return Column(
      children: [
        Text('${value > 0 ? '+' : ''}${fmtNum(value, value.abs() < 10 ? 1 : 0)}', style: style),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(trackHeight: 4, overlayShape: SliderComponentShape.noOverlay),
              child: Slider(
                value: value,
                min: -eqMaxGainDb,
                max: eqMaxGainDb,
                divisions: 48,
                onChanged: onChanged,
                inactiveColor: enabled ? null : Theme.of(context).disabledColor.withValues(alpha: 0.2),
              ),
            ),
          ),
        ),
        Text(label, style: style),
      ],
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  const _LabeledSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.format,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final double value, min, max;
  final String Function(double) format;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Row(children: [Text(label), const Spacer(), Text(format(value), style: Theme.of(context).textTheme.labelMedium)]),
        subtitle: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
      );
}

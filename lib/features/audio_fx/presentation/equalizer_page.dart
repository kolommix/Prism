import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/smooth_scroll.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/widgets/glass.dart';
import '../../../core/widgets/led_dot.dart';
import '../../library/presentation/widgets/library_widgets.dart';
import '../../player/application/player_providers.dart';
import '../../player/presentation/widgets/live_position.dart';
import '../../playlists/presentation/playlist_dialogs.dart';
import '../../settings/application/settings_controller.dart';
import '../../visualizer/presentation/visualizer.dart' show spectrumProvider;
import '../application/eq_controller.dart';
import '../domain/eq_math.dart';
import '../domain/eq_settings.dart';
import 'eq_response_curve.dart';
import '../../../l10n/l10n.dart';

/// The equalizer, its own place in the sidebar.
///
/// One curve on top shows what the EQ does (with the song's spectrum behind
/// it) and can be dragged directly. Below it two ways to change it:
/// * Simple: Bass, Mids, Treble, Bass boost and Volume, plus presets;
/// * Detailed: all 10 bands with exact values, preamp with "Auto".
/// Same model and sound on Android and Windows.
class EqualizerPage extends ConsumerStatefulWidget {
  const EqualizerPage({super.key});

  @override
  ConsumerState<EqualizerPage> createState() => _EqualizerPageState();
}

class _EqualizerPageState extends ConsumerState<EqualizerPage> with SingleTickerProviderStateMixin {
  late final LivePosition _pos = LivePosition(this);
  bool _comparing = false;

  @override
  void dispose() {
    if (_comparing) ref.read(eqControllerProvider.notifier).compare(false);
    _pos.dispose();
    super.dispose();
  }

  void _compare(bool on) {
    if (_comparing == on) return;
    setState(() => _comparing = on);
    ref.read(eqControllerProvider.notifier).compare(on);
  }

  @override
  Widget build(BuildContext context) {
    final eq = ref.watch(eqControllerProvider);
    final ctrl = ref.read(eqControllerProvider.notifier);
    final s = eq.settings;
    final detailed = ref.watch(settingsProvider.select((x) => x.eqDetailed));
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final limitations = ref.watch(audioEffectsProvider).limitations;
    final headroom = eqPeakBoostDb(s) + s.preampDb;

    // The playing song's spectrum behind the curve (cached analysis only).
    final track = ref.watch(currentTrackProvider);
    final spectrum = track == null ? null : ref.watch(spectrumProvider(track)).value;
    final engine = ref.watch(engineStateProvider).value;
    final speed = ref.watch(tuningProvider.select((t) => t.value?.speed ?? 1));
    if (engine != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pos.sync(engine, speed: speed);
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SmoothListView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset(context)),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ---------------------------------------------------- header
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 8,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n.equalizer, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LedDot(on: s.enabled && !_comparing),
                              const SizedBox(width: 8),
                              Text(
                                _comparing
                                    ? l10n.eqComparingWithout
                                    : (s.enabled ? eqPresetLabel(s.presetName) : l10n.xOff),
                                style: muted,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 2,
                        children: [
                          Tooltip(
                            message: l10n.eqCompareHint,
                            // Raw pointer events: the button inside must not
                            // swallow the press.
                            child: Listener(
                              onPointerDown: s.enabled ? (_) => _compare(true) : null,
                              onPointerUp: (_) => _compare(false),
                              onPointerCancel: (_) => _compare(false),
                              child: OutlinedButton.icon(
                                onPressed: s.enabled ? () {} : null,
                                icon: Icon(_comparing ? Icons.hearing_disabled_rounded : Icons.compare_arrows_rounded, size: 18),
                                label: Text(l10n.eqCompare),
                              ),
                            ),
                          ),
                          IconButton(tooltip: l10n.resetToFlat, icon: const Icon(Icons.restart_alt_rounded), onPressed: ctrl.reset),
                          IconButton(
                            tooltip: l10n.saveAsPreset,
                            icon: const Icon(Icons.bookmark_add_outlined),
                            onPressed: () async {
                              final name = await showPlaylistNameDialog(context, title: l10n.saveEqPreset, initial: l10n.myPreset);
                              if (name != null) ctrl.savePreset(name);
                            },
                          ),
                          Switch(value: s.enabled, onChanged: ctrl.setEnabled),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ----------------------------------------------------- curve
                  GlassPanel(
                    padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                    child: EqResponseCurve(
                      settings: s,
                      onBandChanged: ctrl.setBand,
                      spectrum: spectrum,
                      position: _pos,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                    child: Text(l10n.eqCurveHint, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ),
                  AnimatedSize(
                    duration: context.motion.d(PrismMotion.medium),
                    curve: PrismMotion.curve,
                    child: s.enabled && headroom > 1
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: GlassPanel(
                              padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 20, color: scheme.onSurfaceVariant),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(l10n.eqMayDistort(fmtNum(headroom, 1)), style: text.bodyMedium)),
                                  TextButton(onPressed: ctrl.autoPreamp, child: Text(l10n.eqFixVolume)),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox(width: double.infinity),
                  ),
                  const SizedBox(height: 20),

                  // ------------------------------------------------ mode switch
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(value: false, icon: const Icon(Icons.tune_rounded), label: Text(l10n.eqSimple)),
                        ButtonSegment(value: true, icon: const Icon(Icons.equalizer_rounded), label: Text(l10n.eqDetailed)),
                      ],
                      selected: {detailed},
                      showSelectedIcon: false,
                      onSelectionChanged: (v) =>
                          ref.read(settingsProvider.notifier).update((x) => x.copyWith(eqDetailed: v.first)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: context.motion.d(PrismMotion.medium),
                    switchInCurve: PrismMotion.curve,
                    switchOutCurve: PrismMotion.curve,
                    child: detailed
                        ? _Detailed(key: const ValueKey('detailed'), settings: s)
                        : _Simple(key: const ValueKey('simple'), settings: s),
                  ),
                  const SizedBox(height: 24),

                  // --------------------------------------------------- presets
                  Text(l10n.eqPresets, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final p in eq.allPresets)
                        _PresetCard(
                          preset: p,
                          selected: s.enabled && s.presetName == p.name,
                          onTap: () => ctrl.applyPreset(p),
                          onDelete: p.builtIn
                              ? null
                              : () async {
                                  if (await confirmDelete(context, l10n.preset(p.name))) ctrl.deletePreset(p.name);
                                },
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- simple

class _Simple extends ConsumerWidget {
  const _Simple({super.key, required this.settings});
  final EqSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(eqControllerProvider.notifier);
    final tones = eqToneLevels(settings.gainsDb);
    String db(double v) => eqDbLabel(v);
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        children: [
          for (final t in EqTone.values)
            _BigSlider(
              icon: switch (t) {
                EqTone.bass => Icons.speaker_rounded,
                EqTone.mids => Icons.mic_rounded,
                EqTone.treble => Icons.auto_awesome_rounded,
              },
              title: switch (t) {
                EqTone.bass => l10n.eqToneBass,
                EqTone.mids => l10n.eqToneMids,
                EqTone.treble => l10n.eqToneTreble,
              },
              hint: switch (t) {
                EqTone.bass => l10n.eqToneBassHint,
                EqTone.mids => l10n.eqToneMidsHint,
                EqTone.treble => l10n.eqToneTrebleHint,
              },
              value: tones[t]!,
              min: -eqMaxGainDb,
              max: eqMaxGainDb,
              centered: true,
              format: db,
              onChanged: (v) => ctrl.setTone(t, (v * 2).round() / 2),
              onReset: () => ctrl.setTone(t, 0),
            ),
          const Divider(height: 20),
          _BigSlider(
            icon: Icons.graphic_eq_rounded,
            title: l10n.bassBoost,
            hint: l10n.eqBassBoostHint,
            value: settings.bassBoost,
            min: 0,
            max: 1,
            format: (v) => v < 0.005 ? l10n.xOff : '${(v * 100).round()} %',
            onChanged: ctrl.setBassBoost,
            onReset: () => ctrl.setBassBoost(0),
          ),
          _PreampSlider(settings: settings),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- detailed

class _Detailed extends ConsumerWidget {
  const _Detailed({super.key, required this.settings});
  final EqSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(eqControllerProvider.notifier);
    return Column(
      children: [
        GlassPanel(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          child: SizedBox(
            height: 250,
            child: Row(
              children: [
                for (var i = 0; i < eqBandFrequencies.length; i++)
                  Expanded(
                    child: _BandColumn(
                      index: i,
                      value: settings.gainsDb[i],
                      enabled: settings.enabled,
                      onChanged: (v) => ctrl.setBand(i, v),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        GlassPanel(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            children: [
              _PreampSlider(settings: settings),
              _BigSlider(
                icon: Icons.graphic_eq_rounded,
                title: l10n.bassBoost,
                hint: l10n.eqBassBoostHint,
                value: settings.bassBoost,
                min: 0,
                max: 1,
                format: (v) => v < 0.005 ? l10n.xOff : '${(v * 100).round()} %',
                onChanged: ctrl.setBassBoost,
                onReset: () => ctrl.setBassBoost(0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One band: exact value on top (click to type one), slider, frequency.
class _BandColumn extends StatelessWidget {
  const _BandColumn({required this.index, required this.value, required this.enabled, required this.onChanged});

  final int index;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  Future<void> _type(BuildContext context) async {
    final field = TextEditingController(text: fmtNum(value, 1));
    final picked = await showDialog<double>(
      context: context,
      useRootNavigator: true,
      builder: (c) {
        void done() => Navigator.pop(c, double.tryParse(field.text.replaceAll(',', '.').replaceAll('+', '').trim()));
        return AlertDialog(
          title: Text(eqFreqLong(eqBandFrequencies[index])),
          content: TextField(
            controller: field,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-+0-9.,]'))],
            decoration: InputDecoration(suffixText: l10n.eqDb, helperText: l10n.eqBandRange(fmtNum(eqMaxGainDb))),
            onSubmitted: (_) => done(),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: Text(l10n.cancel)),
            FilledButton(onPressed: done, child: Text(l10n.ok)),
          ],
        );
      },
    );
    field.dispose();
    if (picked != null) onChanged(picked.clamp(-eqMaxGainDb, eqMaxGainDb));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelSmall;
    return Column(
      children: [
        Tooltip(
          message: l10n.eqTypeExact,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => _type(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                eqDbLabel(value).replaceAll(' ${l10n.eqDb}', ''),
                style: style?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: value.abs() < 0.05 ? scheme.onSurfaceVariant : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          // No double-tap here: it held every tap back 300 ms (the value on
          // top types an exact one, double-click on the curve resets).
          child: RepaintBoundary(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  overlayShape: SliderComponentShape.noOverlay,
                  inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: value.clamp(-eqMaxGainDb, eqMaxGainDb),
                  min: -eqMaxGainDb,
                  max: eqMaxGainDb,
                  divisions: 48,
                  onChanged: onChanged,
                  activeColor: enabled ? null : scheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(eqFreqLabel(eqBandFrequencies[index]), style: style?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

/// Volume before the EQ, with "Auto" (keeps the loudest point at 0 dB).
class _PreampSlider extends ConsumerWidget {
  const _PreampSlider({required this.settings});
  final EqSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(eqControllerProvider.notifier);
    return _BigSlider(
      icon: Icons.volume_down_rounded,
      title: l10n.preamp,
      hint: l10n.eqPreampHint,
      value: settings.preampDb,
      min: -eqMaxPreampDb,
      max: eqMaxPreampDb,
      centered: true,
      format: eqDbLabel,
      onChanged: (v) => ctrl.setPreamp((v * 2).round() / 2),
      onReset: () => ctrl.setPreamp(0),
      trailing: TextButton(onPressed: ctrl.autoPreamp, child: Text(l10n.eqAuto)),
    );
  }
}

/// A labelled horizontal slider with a short explanation; click the value to
/// reset.
class _BigSlider extends StatelessWidget {
  const _BigSlider({
    required this.icon,
    required this.title,
    required this.hint,
    required this.value,
    required this.min,
    required this.max,
    required this.format,
    required this.onChanged,
    required this.onReset,
    this.centered = false,
    this.trailing,
  });

  final IconData icon;
  final String title, hint;
  final double value, min, max;
  final String Function(double) format;
  final ValueChanged<double> onChanged;
  final VoidCallback onReset;

  /// The slider fills from the middle (0 dB), not from the left.
  final bool centered;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(title, style: text.bodyLarge, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        hint,
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Tooltip(
                      message: l10n.eqReset,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: onReset,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            format(value),
                            style: text.labelLarge?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                          ),
                        ),
                      ),
                    ),
                    ?trailing,
                  ],
                ),
                // No double-tap: it held taps on the slider back 300 ms; the
                // value above resets.
                RepaintBoundary(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      inactiveTrackColor: scheme.onSurface.withValues(alpha: 0.12),
                    ),
                    child: Slider(
                      value: value.clamp(min, max),
                      min: min,
                      max: max,
                      secondaryTrackValue: null,
                      onChanged: onChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- presets

class _PresetCard extends StatelessWidget {
  const _PresetCard({required this.preset, required this.selected, required this.onTap, this.onDelete});

  final EqPreset preset;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final look = context.look;
    final ink = look.monochrome ? scheme.onSurface : scheme.primary;
    final shape = context.shape;
    return SizedBox(
      width: 132,
      child: Material(
        color: selected ? scheme.onSurface.withValues(alpha: 0.10) : scheme.onSurface.withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: shape.small,
          side: BorderSide(color: selected ? ink.withValues(alpha: 0.6) : scheme.onSurface.withValues(alpha: 0.08)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onDelete,
          onSecondaryTap: onDelete,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 30,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _MiniCurve(
                      gains: preset.gainsDb,
                      bassBoost: preset.bassBoost,
                      color: selected ? ink : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (selected) ...[const LedDot(on: true), const SizedBox(width: 6)],
                    if (!preset.builtIn) ...[
                      Icon(Icons.person_rounded, size: 14, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        eqPresetLabel(preset.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelLarge?.copyWith(fontWeight: selected ? FontWeight.w600 : null),
                      ),
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
}

class _MiniCurve extends CustomPainter {
  _MiniCurve({required this.gains, required this.bassBoost, required this.color});
  final List<double> gains;
  final double bassBoost;
  final Color color;

  static final _freqs = logFrequencies(40);

  @override
  void paint(Canvas canvas, Size size) {
    final eq = EqSettings(enabled: true, gainsDb: gains, bassBoost: bassBoost);
    final mid = size.height / 2;
    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), Paint()..color = color.withValues(alpha: 0.2));
    final path = Path();
    for (var i = 0; i < _freqs.length; i++) {
      final x = i / (_freqs.length - 1) * size.width;
      final y = mid - (eqResponseDb(eq, _freqs[i], includePreamp: false) / 12).clamp(-1.0, 1.0) * mid;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_MiniCurve old) => old.color != color || old.gains != gains || old.bassBoost != bassBoost;
}

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p_;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/smooth_scroll.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/widgets/led_dot.dart';
import '../../library/presentation/widgets/library_widgets.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/presentation/color_picker.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../domain/background_config.dart';
import 'live_background.dart';
import '../../../l10n/l10n.dart';

/// Settings → Appearance → Background: pick a style (each card is a working
/// sample) and change everything about it. Changes apply live, the app's own
/// background is the big preview.
class BackgroundPage extends ConsumerWidget {
  const BackgroundPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(settingsProvider.select((s) => s.background));
    final ctrl = ref.read(settingsProvider.notifier);
    final style = cfg.current;
    final p = cfg.paramsFor(style);

    void setCfg(BackgroundConfig Function(BackgroundConfig c) f) =>
        ctrl.update((s) => s.copyWith(background: f(s.background)));
    void setP(BgParams Function(BgParams p) f) =>
        setCfg((c) => c.withParams(style, f(c.paramsFor(style))));

    final reachLabel = switch (style) {
      BackgroundStyle.matrix => l10n.trailLength,
      BackgroundStyle.constellation => l10n.lineLength,
      BackgroundStyle.ripple => l10n.waveWidth,
      _ => l10n.lineLength,
    };
    final densityLabel = switch (style) {
      BackgroundStyle.matrix => l10n.amountOfRain,
      BackgroundStyle.constellation ||
      BackgroundStyle.starfield => l10n.numberOfStars,
      BackgroundStyle.ripple => l10n.dotsPerArea,
      BackgroundStyle.galaxy => l10n.numberOfStars,
      BackgroundStyle.ridges => l10n.bgNumberOfRidges,
      _ => l10n.bgDensity,
    };
    final sizeLabel = switch (style) {
      BackgroundStyle.matrix => l10n.symbolSize,
      BackgroundStyle.constellation ||
      BackgroundStyle.starfield => l10n.starSize,
      BackgroundStyle.ripple => l10n.dotSize,
      BackgroundStyle.asciiSmoke || BackgroundStyle.asciiDonut => l10n.symbolSize,
      BackgroundStyle.galaxy => l10n.starSize,
      BackgroundStyle.lyrics => l10n.bgTextSize,
      BackgroundStyle.ridges => l10n.bgLineWidth,
      _ => l10n.bgSize,
    };

    // Each style only shows the settings that change something for it.
    final detail = style.hasDetailSettings;
    const flowing = {
      BackgroundStyle.starfield,
      BackgroundStyle.rain,
      BackgroundStyle.snow,
    };
    final usesDensity =
        detail || flowing.contains(style) || style == BackgroundStyle.aurora || style == BackgroundStyle.galaxy || style == BackgroundStyle.ridges;
    final usesSize =
        detail ||
        flowing.contains(style) ||
        style == BackgroundStyle.blobs ||
        style.showsSpectrum;
    final usesReach = detail || style == BackgroundStyle.rain;
    final moves =
        style != BackgroundStyle.gradient && style != BackgroundStyle.image;
    final reacts = moves && style != BackgroundStyle.video;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.background),
        actions: [
          if (cfg.isLive)
            TextButton.icon(
              onPressed: () => showBackgroundPreview(context),
              icon: const Icon(Icons.fullscreen_rounded),
              label: Text(l10n.tryIt),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SmoothListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset(context)),
        children: [
          if (_touch)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(l10n.bgPhonePreviews, style: Theme.of(context).textTheme.bodyMedium),
            ),
          LayoutBuilder(
            builder: (context, c) {
              final perRow = c.maxWidth >= 720 ? 4 : 2;
              const visibleStyles = BackgroundStyle.values;
              final w = (c.maxWidth - 12 * (perRow - 1)) / perRow;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final s in visibleStyles)
                    SizedBox(
                      width: w,
                      child: _StyleCard(
                        style: s,
                        params: cfg.paramsFor(s),
                        selected: s == style,
                        hasFile: switch (s) {
                          BackgroundStyle.image => cfg.imagePath.isNotEmpty,
                          BackgroundStyle.video => cfg.videoDir.isNotEmpty,
                          _ => true,
                        },
                        onTap: () => setCfg((c) => c.copyWith(style: s.name)),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
            child: Text(
              style.showsSpectrum ? '${style.description}\n${l10n.bgSpectrumNote}' : style.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (style == BackgroundStyle.matrix)
            SettingsGroup(
              title: l10n.symbols,
              children: [
                _Chips<MatrixGlyphs>(
                  values: MatrixGlyphs.values,
                  label: (g) => g.label,
                  selected: MatrixGlyphs.parse(p.glyphs),
                  onSelected: (g) => setP((x) => x.copyWith(glyphs: g.name)),
                ),
                if (MatrixGlyphs.parse(p.glyphs) == MatrixGlyphs.custom)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: TextFormField(
                      initialValue: p.customGlyphs,
                      maxLength: 96,
                      decoration: InputDecoration(
                        labelText: l10n.yourSymbols,
                        hintText: l10n.anyLettersOrSymbolsEG,
                        isDense: true,
                      ),
                      onChanged: (v) =>
                          setP((x) => x.copyWith(customGlyphs: v)),
                    ),
                  ),
              ],
            ),
          if (style == BackgroundStyle.gradient)
            SettingsGroup(
              title: l10n.bgPresets,
              children: [
                _Chips<GradientPreset>(
                  values: gradientPresets,
                  label: (g) => g.label,
                  selected: GradientPreset.parse(cfg.gradientPreset),
                  onSelected: (g) =>
                      setCfg((c) => c.copyWith(gradientPreset: g.id)),
                ),
              ],
            ),
          if (style == BackgroundStyle.image)
            SettingsGroup(
              children: [
                SettingsTile(
                  icon: Icons.add_photo_alternate_outlined,
                  title: l10n.bgChooseImage,
                  subtitle: cfg.imagePath.isEmpty
                      ? null
                      : p_.basename(cfg.imagePath),
                  chevron: true,
                  onTap: () async {
                    final f = await FilePicker.pickFile(
                      type: FileType.image,
                      dialogTitle: l10n.bgChooseImage,
                    );
                    final path = f?.path;
                    if (path == null) return;
                    final copy = await ref
                        .read(backgroundFilesProvider)
                        .addImage(path);
                    setCfg((c) => c.copyWith(imagePath: copy));
                  },
                ),
              ],
            ),
          if (style == BackgroundStyle.video)
            SettingsGroup(
              children: [
                SettingsTile(
                  icon: Icons.video_library_outlined,
                  title: l10n.bgChooseVideo,
                  chevron: true,
                  onTap: () async {
                    final f = await FilePicker.pickFile(
                      type: FileType.video,
                      dialogTitle: l10n.bgChooseVideo,
                    );
                    final path = f?.path;
                    if (path == null || !context.mounted) return;
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    messenger?.showSnackBar(
                      SnackBar(content: Text(l10n.bgPreparingVideo)),
                    );
                    try {
                      final dir = await ref
                          .read(backgroundFilesProvider)
                          .addVideo(path);
                      setCfg((c) => c.copyWith(videoDir: dir));
                    } on Object catch (e) {
                      messenger?.showSnackBar(SnackBar(content: Text('$e')));
                    }
                  },
                ),
              ],
            ),
          if (style == BackgroundStyle.ripple)
            SettingsGroup(
              title: l10n.shape,
              children: [
                _Chips<RippleShape>(
                  values: RippleShape.values,
                  label: (s) => s.label,
                  selected: RippleShape.parse(p.shape),
                  onSelected: (s) => setP((x) => x.copyWith(shape: s.name)),
                ),
              ],
            ),
          if (cfg.isLive) ...[
            SettingsGroup(
              title: l10n.colors,
              children: [
                SettingsSwitch(
                  icon: Icons.palette_outlined,
                  title: l10n.useTheThemeColors,
                  value: p.followTheme,
                  onChanged: (v) => setP((x) => x.copyWith(followTheme: v)),
                ),
                if (!p.followTheme) ...[
                  ColorPickerTile(
                    title: l10n.mainColor,
                    color: Color(p.color),
                    onChanged: (c) =>
                        setP((x) => x.copyWith(color: c.toARGB32())),
                  ),
                  ColorPickerTile(
                    title: l10n.highlightColor,
                    color: Color(p.accent),
                    onChanged: (c) =>
                        setP((x) => x.copyWith(accent: c.toARGB32())),
                  ),
                ],
              ],
            ),
            SettingsGroup(
              title: l10n.look,
              children: [
                _SliderRow(
                  icon: Icons.brightness_6_outlined,
                  title: l10n.brightness,
                  value: p.brightness,
                  min: 0.1,
                  max: 1,
                  percent: true,
                  onChanged: (v) => setP((x) => x.copyWith(brightness: v)),
                ),
                if (moves)
                  _SliderRow(
                    icon: Icons.speed_rounded,
                    title: l10n.speed,
                    value: p.speed,
                    min: 0.2,
                    max: 3,
                    onChanged: (v) => setP((x) => x.copyWith(speed: v)),
                  ),
                if (usesDensity)
                  _SliderRow(
                    icon: Icons.grain_rounded,
                    title: densityLabel,
                    value: p.density,
                    min: 0.3,
                    max: 2,
                    onChanged: (v) => setP((x) => x.copyWith(density: v)),
                  ),
                if (usesSize)
                  _SliderRow(
                    icon: Icons.format_size_rounded,
                    title: sizeLabel,
                    value: p.size,
                    min: 0.5,
                    max: 2,
                    onChanged: (v) => setP((x) => x.copyWith(size: v)),
                  ),
                if (usesReach)
                  _SliderRow(
                    icon: Icons.linear_scale_rounded,
                    title: reachLabel,
                    value: p.reach,
                    min: 0.2,
                    max: 2,
                    onChanged: (v) => setP((x) => x.copyWith(reach: v)),
                  ),
              ],
            ),
            if (reacts)
              SettingsGroup(
                title: l10n.reactions,
                footer: _touch ? l10n.tapsAlsoSendAWaveMusic : l10n.clicksAlsoSendAWaveMusic,
                children: [
                  _SliderRow(
                    icon: _touch ? Icons.touch_app_outlined : Icons.mouse_outlined,
                    title: _touch ? l10n.bgTouch : l10n.mouse,
                    value: p.mouse,
                    min: 0,
                    max: 2,
                    onChanged: (v) => setP((x) => x.copyWith(mouse: v)),
                  ),
                  _SliderRow(
                    icon: Icons.graphic_eq_rounded,
                    title: l10n.music,
                    value: p.music,
                    min: 0,
                    max: 2,
                    onChanged: (v) => setP((x) => x.copyWith(music: v)),
                  ),
                ],
              ),
            SettingsGroup(
              title: l10n.forEveryAnimatedBackground,
              children: [
                _SliderRow(
                  icon: Icons.opacity_rounded,
                  title: l10n.strength,
                  value: cfg.strength,
                  min: 0.2,
                  max: 1,
                  percent: true,
                  onChanged: (v) => setCfg((c) => c.copyWith(strength: v)),
                ),
                _SliderRow(
                  icon: Icons.blur_on_rounded,
                  title: l10n.outOfFocus,
                  value: cfg.softness,
                  min: 0,
                  max: 1,
                  percent: true,
                  onChanged: (v) => setCfg((c) => c.copyWith(softness: v)),
                ),
                _SliderRow(
                  icon: Icons.brightness_low_rounded,
                  title: l10n.bgDim,
                  value: cfg.dim,
                  min: 0,
                  max: 0.9,
                  percent: true,
                  onChanged: (v) => setCfg((c) => c.copyWith(dim: v)),
                ),
                SettingsSwitch(
                  icon: Icons.open_with_rounded,
                  title: l10n.bgParallax,
                  subtitle: l10n.bgParallaxHint,
                  value: cfg.parallax,
                  onChanged: (v) => setCfg((c) => c.copyWith(parallax: v)),
                ),
                SettingsSwitch(
                  icon: Icons.battery_saver_outlined,
                  title: l10n.bgBatterySaver,
                  subtitle: l10n.bgBatterySaverHint,
                  value: cfg.batterySaver,
                  onChanged: (v) => setCfg((c) => c.copyWith(batterySaver: v)),
                ),
                SettingsSwitch(
                  icon: Icons.filter_drama_outlined,
                  title: l10n.frostedPanels,
                  subtitle: l10n.panelsBlurWhatIsBehindThem,
                  value: cfg.frosted,
                  onChanged: (v) => setCfg((c) => c.copyWith(frosted: v)),
                ),
                _SliderRow(
                  icon: Icons.layers_outlined,
                  title: l10n.solidPanels,
                  value: cfg.panelOpacity,
                  min: 0.15,
                  max: 1,
                  percent: true,
                  onChanged: (v) => setCfg((c) => c.copyWith(panelOpacity: v)),
                ),
                SettingsSwitch(
                  icon: Icons.image_outlined,
                  title: l10n.keepTheCoverUnderneath,
                  value: cfg.showCover,
                  onChanged: (v) => setCfg((c) => c.copyWith(showCover: v)),
                ),
                SettingsSwitch(
                  icon: Icons.pause_circle_outline_rounded,
                  title: l10n.stopWhileTheMusicIsPaused,
                  subtitle: l10n.savesPower,
                  value: cfg.onlyWhilePlaying,
                  onChanged: (v) =>
                      setCfg((c) => c.copyWith(onlyWhilePlaying: v)),
                ),
                SettingsTile(
                  icon: Icons.av_timer_rounded,
                  title: l10n.framesPerSecond,
                  subtitle: l10n.lowerSavesPower,
                  trailing: SegmentedButton<int>(
                    segments: [
                      ButtonSegment(value: 30, label: Text('30')),
                      ButtonSegment(value: 60, label: Text('60')),
                      ButtonSegment(value: 0, label: Text(l10n.screen)),
                    ],
                    selected: {cfg.frameRate},
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                    ),
                    onSelectionChanged: (s) =>
                        setCfg((c) => c.copyWith(frameRate: s.first)),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setCfg(
                  (c) =>
                      c.withParams(style, BackgroundConfig.defaultsFor(style)),
                ),
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(l10n.reset(style.label)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Phones and tablets: no mouse, no Esc key; the words say touch and tap.
bool get _touch => Platform.isAndroid || Platform.isIOS;

/// Only the background, with no panels on top. Esc or a button closes it.
Future<void> showBackgroundPreview(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        transitionDuration: context.motion.d(PrismMotion.medium),
        reverseTransitionDuration: context.motion.d(PrismMotion.medium),
        transitionsBuilder: (_, a, _, child) =>
            FadeTransition(opacity: a, child: child),
        pageBuilder: (_, _, _) => const _FullPreview(),
      ),
    );

class _FullPreview extends ConsumerWidget {
  const _FullPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(settingsProvider.select((s) => s.background));
    final scheme = Theme.of(context).colorScheme;
    void close() => Navigator.of(context).maybePop();
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
      child: Focus(
        autofocus: true,
        child: Material(
          color: scheme.surface,
          child: Stack(
            fit: StackFit.expand,
            children: [
              LiveBackground(
                style: cfg.current,
                params: cfg.paramsFor(cfg.current),
              ),
              // Below the status bar on phones and below the window buttons on Windows.
              Positioned(
                top: 12 + MediaQuery.paddingOf(context).top,
                right: 12,
                child: FilledButton.tonalIcon(
                  onPressed: close,
                  icon: const Icon(Icons.close_rounded),
                  label: Text(_touch ? l10n.close : l10n.closeEsc),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Text(
                    _touch ? l10n.touchAndTapTheScreen : l10n.moveTheMouseAndClick,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleCard extends StatelessWidget {
  const _StyleCard({
    required this.style,
    required this.params,
    required this.selected,
    required this.onTap,
    this.hasFile = true,
  });

  /// Picture or video chosen already.
  final bool hasFile;

  final BackgroundStyle style;
  final BgParams params;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(14);
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: context.motion.d(PrismMotion.short),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: selected ? 0.5 : 0.08),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 110,
                child: switch (style) {
                  BackgroundStyle.cover => Icon(
                    Icons.image_outlined,
                    color: scheme.onSurfaceVariant,
                    size: 32,
                  ),
                  BackgroundStyle.image when !hasFile => Icon(
                    Icons.add_photo_alternate_outlined,
                    color: scheme.onSurfaceVariant,
                    size: 32,
                  ),
                  BackgroundStyle.video when !hasFile => Icon(
                    Icons.video_library_outlined,
                    color: scheme.onSurfaceVariant,
                    size: 32,
                  ),
                  // Phones: a plain sign per style. Some phone GPU drivers
                  // (Samsung Exynos) crashed drawing all the samples at once;
                  // the app's own background and Try it show the real thing.
                  _ when _touch => Icon(
                    _styleIcon(style),
                    color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                    size: 32,
                  ),
                  // Only the selected card moves: fourteen at once would be a waste.
                  _ => IgnorePointer(
                    child: LiveBackground(
                      style: style,
                      params: params,
                      preview: true,
                      fps: 30,
                      still: !selected,
                    ),
                  ),
                },
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        style.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    LedDot(on: selected),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _styleIcon(BackgroundStyle s) => switch (s) {
      BackgroundStyle.cover => Icons.image_outlined,
      BackgroundStyle.mesh => Icons.blur_on_rounded,
      BackgroundStyle.aurora => Icons.waves_rounded,
      BackgroundStyle.blobs => Icons.bubble_chart_outlined,
      BackgroundStyle.gradient => Icons.gradient_rounded,
      BackgroundStyle.starfield => Icons.auto_awesome_outlined,
      BackgroundStyle.rain => Icons.water_drop_outlined,
      BackgroundStyle.snow => Icons.ac_unit_rounded,
      BackgroundStyle.asciiSmoke => Icons.terminal_rounded,
      BackgroundStyle.asciiDonut => Icons.donut_large_rounded,
      BackgroundStyle.ridges => Icons.landscape_outlined,
      BackgroundStyle.galaxy => Icons.cyclone_rounded,
      BackgroundStyle.lyrics => Icons.lyrics_outlined,
      BackgroundStyle.matrix => Icons.code_rounded,
      BackgroundStyle.constellation => Icons.hub_outlined,
      BackgroundStyle.ripple => Icons.blur_circular_rounded,
      BackgroundStyle.image => Icons.photo_outlined,
      BackgroundStyle.video => Icons.movie_outlined,
    };

class _Chips<T> extends StatelessWidget {
  const _Chips({
    required this.values,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final List<T> values;
  final String Function(T) label;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final v in values)
            ChoiceChip(
              label: Text(label(v)),
              selected: v == selected,
              onSelected: (_) => onSelected(v),
            ),
        ],
      ),
    ),
  );
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.percent = false,
  });

  final IconData icon;
  final String title;
  final double value, min, max;
  final ValueChanged<double> onChanged;
  final bool percent;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(min, max);
    final shown = percent
        ? '${(v * 100).round()} %'
        : (v == 0 ? l10n.xOff : '${fmtNum(v, 1)}x');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 128,
            child: Text(title, style: const TextStyle(fontSize: 15)),
          ),
          Expanded(
            child: Slider(value: v, min: min, max: max, onChanged: onChanged),
          ),
          SizedBox(
            width: 52,
            child: Align(
              alignment: Alignment.centerRight,
              child: SettingsValue(shown),
            ),
          ),
        ],
      ),
    );
  }
}

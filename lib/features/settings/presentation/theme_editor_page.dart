import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/smooth_scroll.dart';
import '../../../core/motion/spring_button.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/theme/theme_config.dart';
import '../../../core/widgets/glass.dart';
import '../../library/presentation/widgets/library_widgets.dart';
import '../../playlists/presentation/playlist_dialogs.dart';
import '../application/settings_controller.dart';
import 'color_picker.dart';
import '../../../l10n/l10n.dart';

/// Live theme editor. Every change applies instantly to the whole app
/// (themes animate between values), and themes can be saved, exported to a
/// `.prism-theme.json` file and imported from one.
class ThemeEditorPage extends ConsumerWidget {
  const ThemeEditorPage({super.key});

  void _snack(BuildContext context, String msg) =>
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _export(BuildContext context, WidgetRef ref, ThemeConfig theme) async {
    final themed = await ref.read(settingsProvider.notifier).withCurrentBackground(theme);
    final safe = theme.name.replaceAll(RegExp(r'[^\w\- ]'), '').trim();
    final uri = await FilePicker.saveFile(
      dialogTitle: l10n.exportTheme,
      fileName: '${safe.isEmpty ? 'theme' : safe}.prism-theme.json',
      bytes: utf8.encode(themed.toShareableJson()),
      mimeType: 'application/json',
    );
    if (uri != null && context.mounted) _snack(context, l10n.themeExported);
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final file = await FilePicker.pickFile(dialogTitle: l10n.importTheme, type: FileType.custom, allowedExtensions: ['json']);
    if (file == null) return;
    try {
      final theme = ThemeConfig.fromShareableJson(utf8.decode(await file.readAsBytes()));
      await ref.read(settingsProvider.notifier).applyTheme(theme);
      await ref.read(savedThemesRepositoryProvider).save(theme);
      if (context.mounted) _snack(context, l10n.imported(theme.name));
    } on FormatException catch (e) {
      if (context.mounted) _snack(context, l10n.couldNotImport(e.message));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(settingsProvider.select((s) => s.theme));
    final ctrl = ref.read(settingsProvider.notifier);
    final saved = ref.watch(savedThemesProvider).value ?? const [];
    final text = Theme.of(context).textTheme;

    Widget label(String s) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
          child: Text(s, style: text.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.theme),
        actions: [
          IconButton(tooltip: l10n.importTheme, icon: const Icon(Icons.file_open_rounded), onPressed: () => _import(context, ref)),
          IconButton(tooltip: l10n.exportTheme, icon: const Icon(Icons.ios_share_rounded), onPressed: () => _export(context, ref, theme)),
          IconButton(
            tooltip: l10n.saveAs,
            icon: const Icon(Icons.bookmark_add_rounded),
            onPressed: () async {
              final name = await showPlaylistNameDialog(context, initial: theme.name, title: l10n.saveThemeAs);
              if (name == null) return;
              final named = await ctrl.withCurrentBackground(theme.copyWith(name: name.trim().isEmpty ? l10n.myTheme : name.trim()));
              ctrl.setTheme(named);
              await ref.read(savedThemesRepositoryProvider).save(named);
              if (context.mounted) _snack(context, l10n.saved(named.name));
            },
          ),
        ],
      ),
      body: SmoothListView(
        padding: EdgeInsets.only(bottom: bottomInset(context)),
        children: [
          const _Preview(),
          label(l10n.presets),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final t in builtInThemes) _ThemeChip(theme: t, selected: t == theme, onTap: () => ctrl.setTheme(t)),
                for (final (id, t) in saved)
                  _ThemeChip(
                    theme: t,
                    selected: t == theme,
                    onTap: () => ctrl.applyTheme(t),
                    onDelete: () => ref.read(savedThemesRepositoryProvider).delete(id),
                  ),
              ],
            ),
          ),
          label(l10n.mode),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeBrightnessMode>(
              segments: [
                ButtonSegment(value: ThemeBrightnessMode.system, label: Text(l10n.auto), icon: Icon(Icons.brightness_auto_rounded)),
                ButtonSegment(value: ThemeBrightnessMode.light, label: Text(l10n.light), icon: Icon(Icons.light_mode_rounded)),
                ButtonSegment(value: ThemeBrightnessMode.dark, label: Text(l10n.dark), icon: Icon(Icons.dark_mode_rounded)),
                ButtonSegment(value: ThemeBrightnessMode.amoled, label: Text('AMOLED'), icon: Icon(Icons.contrast_rounded)),
              ],
              selected: {theme.brightness},
              showSelectedIcon: false,
              onSelectionChanged: (s) => ctrl.updateTheme((t) => t.copyWith(brightness: s.first)),
            ),
          ),
          label(l10n.colors),
          SwitchListTile(
            title: Text(l10n.blackWhite),
            subtitle: Text(l10n.greysOnlyCoversStayInColor),
            value: theme.monochrome,
            onChanged: (v) => ctrl.updateTheme((t) => t.copyWith(monochrome: v)),
          ),
          // Color settings only matter for color themes.
          AnimatedSize(
            duration: context.motion.d(PrismMotion.medium),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: theme.monochrome
                ? const SizedBox(width: double.infinity)
                : Column(
                    children: [
                      SwitchListTile(
                        title: Text(l10n.colorsFromAlbumArt),
                        subtitle: Text(l10n.primaryColorFollowsTheCurrentCover),
                        value: theme.dynamicColor,
                        onChanged: (v) => ctrl.updateTheme((t) => t.copyWith(dynamicColor: v)),
                      ),
                      ColorPickerTile(
                        title: l10n.primary,
                        color: Color(theme.primaryColor),
                        onChanged: (c) => ctrl.updateTheme((t) => t.copyWith(primaryColor: c.toARGB32())),
                      ),
                      ColorPickerTile(
                        title: l10n.accent,
                        color: Color(theme.accentColor),
                        onChanged: (c) => ctrl.updateTheme((t) => t.copyWith(accentColor: c.toARGB32())),
                      ),
                    ],
                  ),
          ),
          label(l10n.shapeSurfaces),
          _SliderTile(
            title: l10n.cornerRadius,
            value: theme.cornerRadius,
            max: 40,
            format: (v) => l10n.px(v.round()),
            onChanged: (v) => ctrl.updateTheme((t) => t.copyWith(cornerRadius: v)),
          ),
          _SliderTile(
            title: l10n.glassBlur,
            value: theme.glassIntensity,
            max: 1,
            format: (v) => v < 0.02 ? l10n.xOff : '${(v * 100).round()} %',
            onChanged: (v) => ctrl.updateTheme((t) => t.copyWith(glassIntensity: v)),
          ),
          label(l10n.textMotion),
          ListTile(
            title: Text(l10n.font),
            trailing: DropdownButton<String?>(
              value: availableFonts.contains(theme.fontFamily) ? theme.fontFamily : null,
              onChanged: (f) => ctrl.updateTheme((t) => t.copyWith(fontFamily: f)),
              items: [
                for (final f in availableFonts) DropdownMenuItem(value: f, child: Text(f ?? l10n.system)),
              ],
            ),
          ),
          _SliderTile(
            title: l10n.animationSpeed,
            value: theme.animationSpeed,
            min: 0.25,
            max: 3,
            // Slider shows "speed", the config stores a duration multiplier.
            format: (v) => v <= 0.75 ? l10n.fastX(fmtNum(v, 2)) : (v >= 1.5 ? l10n.slowX(fmtNum(v, 2)) : l10n.normalX(fmtNum(v, 2))),
            onChanged: (v) => ctrl.updateTheme((t) => t.copyWith(animationSpeed: v)),
          ),
          ListTile(
            title: Text(l10n.themeName),
            subtitle: Text(theme.name),
            trailing: const Icon(Icons.edit_rounded),
            onTap: () async {
              final n = await showPlaylistNameDialog(context, initial: theme.name, title: l10n.themeName);
              if (n != null && n.trim().isNotEmpty) ctrl.updateTheme((t) => t.copyWith(name: n.trim()));
            },
          ),
        ],
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.title,
    required this.value,
    required this.format,
    required this.onChanged,
    this.min = 0,
    required this.max,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final String Function(double) format;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
        title: Row(children: [Text(title), const Spacer(), Text(format(value), style: Theme.of(context).textTheme.labelMedium)]),
        subtitle: Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
      );
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({required this.theme, required this.selected, required this.onTap, this.onDelete});

  final ThemeConfig theme;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = theme.brightness != ThemeBrightnessMode.light;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SpringButton(
        onTap: onTap,
        onLongPress: onDelete,
        tooltip: onDelete == null ? theme.name : l10n.longPressToDelete(theme.name),
        child: AnimatedContainer(
          duration: context.motion.d(PrismMotion.medium),
          width: 92,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.brightness == ThemeBrightnessMode.amoled ? Colors.black : (dark ? const Color(0xFF1E1E24) : Colors.white),
            borderRadius: BorderRadius.circular(theme.cornerRadius.clamp(4, 24)),
            border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2.5 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 12, backgroundColor: theme.monochrome ? Colors.white : Color(theme.primaryColor)),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.monochrome ? const Color(0xFF3A3A3A) : Color(theme.accentColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                theme.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: dark ? Colors.white : Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small live sample of the current theme.
class _Preview extends StatelessWidget {
  const _Preview();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          borderRadius: context.shape.large,
          color: scheme.onSurface.withValues(alpha: 0.05),
          border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
        ),
        padding: const EdgeInsets.all(16),
        alignment: Alignment.bottomCenter,
        child: GlassPanel(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: context.shape.small),
                child: Icon(Icons.music_note_rounded, color: scheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.previewSong, style: Theme.of(context).textTheme.titleSmall),
                    Text(l10n.glassPanelPx(context.shape.radius.round()), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              FilledButton(onPressed: () {}, child: Text(l10n.play)),
            ],
          ),
        ),
      ),
    );
  }
}

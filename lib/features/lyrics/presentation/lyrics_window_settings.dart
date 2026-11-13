import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/lyrics_window.dart';

/// Settings → Windows → Floating lyrics.
class LyricsWindowSettings extends ConsumerWidget {
  const LyricsWindowSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!LyricsWindowController.supported) return const SizedBox.shrink();
    final s = ref.watch(lyricsWindowProvider);
    final ctrl = ref.read(lyricsWindowProvider.notifier);
    return SettingsGroup(
      title: l10n.lyricsWindowTitle,
      footer: l10n.lyricsWindowFooter,
      children: [
        SettingsSwitch(
          icon: Icons.subtitles_outlined,
          title: l10n.lyricsWindowShow,
          subtitle: l10n.lyricsWindowShowSubtitle,
          value: s.open,
          onChanged: ctrl.setOpen,
        ),
        SettingsTile(
          title: l10n.lyricsWindowSeeThrough,
          trailing: SettingsValue('${fmtNum((1 - s.opacity / 0.95) * 100, 0)} %'),
        ),
        SettingsControl(
          child: Slider(
            // Right = more see-through.
            value: (0.95 - s.opacity).clamp(0.0, 0.95),
            max: 0.95,
            onChanged: (v) => ctrl.setStyle(opacity: 0.95 - v),
          ),
        ),
        SettingsTile(
          title: l10n.lyricsWindowTextSize,
          trailing: SettingsValue(fmtNum(s.fontSize, 0)),
        ),
        SettingsControl(
          child: Slider(
            value: s.fontSize.clamp(14, 72),
            min: 14,
            max: 72,
            divisions: 29,
            onChanged: (v) => ctrl.setStyle(fontSize: v),
          ),
        ),
        SettingsSwitch(
          icon: Icons.lock_outline_rounded,
          title: l10n.lyricsWindowLocked,
          subtitle: l10n.lyricsWindowLockedSubtitle,
          value: s.locked,
          onChanged: (v) => ctrl.setStyle(locked: v),
        ),
      ],
    );
  }
}

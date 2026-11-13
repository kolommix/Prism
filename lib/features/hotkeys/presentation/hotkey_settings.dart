import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/hotkey_controller.dart';
import '../domain/hotkeys.dart';

/// Settings → Windows → Hotkeys: on/off, and a key for every action.
class HotkeySettings extends ConsumerWidget {
  const HotkeySettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(hotkeysProvider);
    final ctrl = ref.read(hotkeysProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    return SettingsGroup(
      title: l10n.hotkeysTitle,
      footer: l10n.hotkeysFooter,
      children: [
        SettingsSwitch(
          icon: Icons.keyboard_outlined,
          title: l10n.hotkeysEnabled,
          subtitle: l10n.hotkeysEnabledSubtitle,
          value: s.enabled,
          onChanged: ctrl.setEnabled,
        ),
        for (final a in HotkeyAction.values)
          SettingsTile(
            title: a.label,
            subtitle: s.enabled && s.refused.contains(a) ? l10n.hotkeyTaken : null,
            enabled: s.enabled,
            onTap: () => _change(context, ref, a),
            trailing: Text(
              s.keys[a]?.label ?? l10n.hotkeyNone,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: s.refused.contains(a) ? scheme.error : scheme.onSurfaceVariant,
                  ),
            ),
          ),
        SettingsTile(
          icon: Icons.restart_alt_rounded,
          title: l10n.hotkeysReset,
          enabled: s.enabled,
          onTap: ctrl.resetAll,
        ),
      ],
    );
  }

  Future<void> _change(BuildContext context, WidgetRef ref, HotkeyAction action) async {
    final ctrl = ref.read(hotkeysProvider.notifier);
    // While choosing, the current hotkeys are off: Windows would take the keys
    // before this window sees them.
    await ctrl.suspend();
    if (!context.mounted) return;
    final result = await showDialog<(HotkeyCombo?,)>(
      context: context,
      builder: (_) => _CaptureDialog(action: action, current: ref.read(hotkeysProvider).keys[action]),
    );
    if (result != null) {
      await ctrl.setKey(action, result.$1);
    } else {
      await ctrl.resume();
    }
  }
}

/// "Press the keys": shows them as they are pressed. Returns (combo,) to set,
/// (null,) to clear, or null when cancelled.
class _CaptureDialog extends StatefulWidget {
  const _CaptureDialog({required this.action, this.current});
  final HotkeyAction action;
  final HotkeyCombo? current;

  @override
  State<_CaptureDialog> createState() => _CaptureDialogState();
}

class _CaptureDialogState extends State<_CaptureDialog> {
  HotkeyCombo? _combo;
  bool _needsModifier = false;

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.handled;
    final keys = HardwareKeyboard.instance;
    final vk = vkForPhysicalKey(e.physicalKey);
    final mods = keys.isControlPressed || keys.isAltPressed || keys.isShiftPressed || keys.isMetaPressed;
    if (e.logicalKey == LogicalKeyboardKey.escape && !mods) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (vk == null) return KeyEventResult.handled; // a modifier alone, or a key hotkeys can't use
    final combo = HotkeyCombo(
      vk,
      ctrl: keys.isControlPressed,
      alt: keys.isAltPressed,
      shift: keys.isShiftPressed,
      win: keys.isMetaPressed,
    );
    setState(() {
      _needsModifier = !combo.valid;
      _combo = combo.valid ? combo : null;
    });
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final shown = _combo ?? widget.current;
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: AlertDialog(
        title: Text(widget.action.label),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.hotkeyPressKeys, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Center(
              child: Text(
                shown?.label ?? l10n.hotkeyNone,
                style: text.headlineSmall?.copyWith(
                  color: _combo == null ? scheme.onSurfaceVariant : scheme.onSurface,
                ),
              ),
            ),
            if (_needsModifier) ...[
              const SizedBox(height: 12),
              Text(l10n.hotkeyNeedsModifier, style: text.bodySmall?.copyWith(color: scheme.error)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop((null,)), child: Text(l10n.hotkeyClear)),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: _combo == null ? null : () => Navigator.of(context).pop((_combo,)),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }
}

/// Keys inside Prism's window (no need for Ctrl + Alt there): Space plays or
/// pauses, Ctrl + arrows skip and change the volume. Text fields keep their
/// keys, and pages with their own (the editor) win.
class InAppPlayerKeys extends ConsumerWidget {
  const InAppPlayerKeys({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void run(HotkeyAction a) => unawaited(ref.read(hotkeysProvider.notifier).run(a));
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): () => run(HotkeyAction.playPause),
        const SingleActivator(LogicalKeyboardKey.mediaPlayPause): () => run(HotkeyAction.playPause),
        const SingleActivator(LogicalKeyboardKey.arrowRight, control: true): () => run(HotkeyAction.next),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): () => run(HotkeyAction.previous),
        const SingleActivator(LogicalKeyboardKey.arrowUp, control: true): () => run(HotkeyAction.volumeUp),
        const SingleActivator(LogicalKeyboardKey.arrowDown, control: true): () => run(HotkeyAction.volumeDown),
        const SingleActivator(LogicalKeyboardKey.arrowRight, control: true, shift: true): () =>
            run(HotkeyAction.seekForward),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, control: true, shift: true): () =>
            run(HotkeyAction.seekBack),
      },
      // Something in here must hold the focus, or no key reaches these.
      child: Focus(autofocus: true, child: child),
    );
  }
}

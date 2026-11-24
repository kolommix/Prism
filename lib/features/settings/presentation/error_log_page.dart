import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/diagnostics/error_log.dart';
import '../../../core/diagnostics/error_ui.dart';
import '../../../core/motion/smooth_scroll.dart';
import '../../../l10n/l10n.dart';
import '../application/settings_controller.dart';
import 'settings_widgets.dart';

/// Settings → About → Error log: everything that went wrong, to copy or save
/// as a text file and send to the developer.
Future<void> showErrorLog(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute<void>(builder: (_) => const ErrorLogPage()));

class ErrorLogPage extends ConsumerWidget {
  const ErrorLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final log = ErrorLog.instance;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.errorLog)),
      body: ValueListenableBuilder<List<ErrorEntry>>(
        valueListenable: log.entries,
        builder: (context, entries, _) {
          final shown = entries.reversed.toList();
          return SmoothListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              SettingsGroup(
                footer: l10n.errorLogHint,
                children: [
                  SettingsTile(
                    icon: Icons.copy_rounded,
                    title: l10n.errorCopyAll,
                    subtitle: l10n.errorCopyAllHint,
                    onTap: () async {
                      final all = await log.fileText();
                      await Clipboard.setData(ClipboardData(text: all));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorCopied)));
                      }
                    },
                  ),
                  SettingsTile(
                    icon: Icons.save_alt_rounded,
                    title: l10n.errorSaveFile,
                    onTap: () => _save(context),
                  ),
                  if (Platform.isWindows && log.file != null)
                    SettingsTile(
                      icon: Icons.folder_open_rounded,
                      title: l10n.openFolder,
                      onTap: () => launchUrl(Uri.file(log.file!.parent.path)),
                    ),
                  SettingsSwitch(
                    icon: Icons.notification_important_outlined,
                    title: l10n.errorPopups,
                    subtitle: l10n.errorPopupsHint,
                    value: ref.watch(settingsProvider.select((s) => s.errorPopups)),
                    onChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(errorPopups: v)),
                  ),
                  SettingsTile(
                    icon: Icons.delete_outline_rounded,
                    title: l10n.errorClear,
                    enabled: entries.isNotEmpty,
                    onTap: log.clear,
                  ),
                ],
              ),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(l10n.errorNone, textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                ),
              for (final e in shown) _EntryTile(entry: e),
            ],
          );
        },
      ),
    );
  }

  static Future<void> _save(BuildContext context) async {
    final all = await ErrorLog.instance.fileText();
    final stamp = DateTime.now().toIso8601String().substring(0, 16).replaceAll(':', '-');
    try {
      final uri = await FilePicker.saveFile(
        dialogTitle: l10n.errorSaveFile,
        fileName: 'prism-errors-$stamp.txt',
        bytes: utf8.encode(all),
        mimeType: 'text/plain',
      );
      if (uri == null || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorSaved)));
    } on Object catch (e, st) {
      if (context.mounted) showErrorSnack(context, l10n.error(e), error: e, stack: st, where: 'error log');
    }
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});
  final ErrorEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final t = entry.time;
    String two(int v) => v.toString().padLeft(2, '0');
    final when = '${dateShort(t)} ${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
    final color = switch (entry.level) {
      ErrorLevel.crash || ErrorLevel.error => scheme.error,
      ErrorLevel.note => scheme.onSurfaceVariant,
    };
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Icon(
          entry.level == ErrorLevel.note ? Icons.info_outline_rounded : Icons.error_outline_rounded,
          color: color,
          size: 20,
        ),
        title: Text(entry.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodyMedium),
        subtitle: Text(
          '$when · ${entry.where}${entry.repeats > 1 ? ' · ×${fmtNum(entry.repeats)}' : ''}',
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        trailing: IconButton(
          tooltip: l10n.errorCopyTooltip,
          icon: const Icon(Icons.copy_rounded, size: 18),
          onPressed: () => copyErrorReport(only: entry, messenger: ScaffoldMessenger.maybeOf(context)),
        ),
        children: [
          if (entry.details != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: SelectableText(
                entry.details!,
                style: text.bodySmall?.copyWith(fontFamily: 'Consolas', fontFamilyFallback: const ['monospace']),
              ),
            ),
        ],
      ),
    );
  }
}

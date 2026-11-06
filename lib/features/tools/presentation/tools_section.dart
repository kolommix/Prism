import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../audio_fx/application/eq_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../application/tools_providers.dart';
import '../../../l10n/l10n.dart';

/// Settings → Backup: save everything to one file, or restore it (also on
/// another device: songs are matched by path or title + artist).
abstract final class BackupActions {
  static void _snack(BuildContext context, String msg) =>
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(msg)));

  static Future<void> backup(BuildContext context, WidgetRef ref) async {
    try {
      final json = await ref.read(backupServiceProvider).export(
            settings: ref.read(settingsProvider),
            eq: ref.read(eqControllerProvider),
          );
      final now = DateTime.now();
      final uri = await FilePicker.saveFile(
        dialogTitle: l10n.savePrismBackup,
        fileName: 'prism-${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.prism-backup.json',
        bytes: utf8.encode(json),
        mimeType: 'application/json',
      );
      if (uri != null && context.mounted) _snack(context, l10n.backupSaved);
    } on Object catch (e) {
      if (context.mounted) _snack(context, l10n.backupFailed(e));
    }
  }

  static Future<void> restore(BuildContext context, WidgetRef ref) async {
    final f = await FilePicker.pickFile(dialogTitle: l10n.restorePrismBackup, type: FileType.custom, allowedExtensions: ['json']);
    if (f == null) return;
    try {
      final report = await ref.read(backupServiceProvider).restore(utf8.decode(await f.readAsBytes()));
      if (report.settings != null) ref.read(settingsProvider.notifier).update((_) => report.settings!);
      final eq = report.eq;
      if (eq != null) {
        final current = ref.read(eqControllerProvider);
        final names = {for (final p in current.customPresets) p.name};
        ref.read(eqControllerProvider.notifier).restore(EqState(
              settings: eq.settings,
              customPresets: [...current.customPresets, ...eq.customPresets.where((p) => names.add(p.name))],
            ));
      }
      if (context.mounted) _snack(context, l10n.restored2(report));
    } on Object catch (e) {
      if (context.mounted) _snack(context, l10n.restoreFailed(e));
    }
  }

}

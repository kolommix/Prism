import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/platform/android_permissions.dart';

import '../application/library_providers.dart';
import '../../../l10n/l10n.dart';

/// The platform's usual music folder, if it exists.
String? defaultMusicFolder() {
  final candidate = Platform.isAndroid
      ? '/storage/emulated/0/Music'
      : (Platform.environment['USERPROFILE'] == null ? null : p.join(Platform.environment['USERPROFILE']!, l10n.music));
  return candidate != null && Directory(candidate).existsSync() ? candidate : null;
}

/// Android needs runtime permission to read audio files (READ_MEDIA_AUDIO on
/// 13+, READ_EXTERNAL_STORAGE before). Windows needs nothing.
Future<bool> ensureAudioPermission() => AndroidPermissions.requestAudioFiles();

/// Lets the user pick a folder (or uses [path]) and scans it.
Future<void> addLibraryFolder(BuildContext context, WidgetRef ref, {String? path}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (!await ensureAudioPermission()) {
    messenger?.showSnackBar(
      SnackBar(
        content: Text(l10n.prismNeedsPermissionToReadYour),
        action: SnackBarAction(label: l10n.settings, onPressed: AndroidPermissions.openSettings),
      ),
    );
    return;
  }
  final folder = path ?? await FilePicker.getDirectoryPath(dialogTitle: l10n.chooseAMusicFolder);
  if (folder == null) return;
  await ref.read(scanControllerProvider.notifier).addFolder(folder);
}

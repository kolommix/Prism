import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../library/data/library_repository.dart';
import '../../library/domain/track.dart';

/// What a cleanup did.
class CleanupResult {
  const CleanupResult({required this.removed, required this.filesDeleted, required this.filesKept});

  /// Extra copies taken out of the library.
  final int removed;

  /// Of those, files that went to the Recycle Bin / were deleted.
  final int filesDeleted;

  /// Files asked to be deleted that had to stay (Android: not Prism's own).
  final int filesKept;
}

/// Keeps one copy of each song and takes the rest out of the library, moving
/// their playlists, likes and listens to the kept copy first. With
/// [deleteFiles] the extra files go too: to the Recycle Bin on Windows (so they
/// can be brought back); on Android only files Prism saved itself, because an
/// app can't delete the user's other files.
class DuplicateCleaner {
  DuplicateCleaner(this._repo, {Future<Directory> Function()? appDir, this.trash})
      : _appDir = appDir ?? getApplicationSupportDirectory;

  final LibraryRepository _repo;
  final Future<Directory> Function() _appDir;

  /// Moves files to the bin; returns the ones that are gone. Replaceable in tests.
  final Future<Set<String>> Function(List<String> paths)? trash;

  Future<CleanupResult> run(List<(Track keep, List<Track> extras)> groups, {required bool deleteFiles}) async {
    var removed = 0;
    final files = <String>[];
    for (final (keep, extras) in groups) {
      final others = [for (final t in extras) if (t.id != keep.id) t];
      if (others.isEmpty) continue;
      await _repo.mergeDuplicates(keep, others);
      removed += others.length;
      // Two library entries may share one file (the same path is never deleted).
      files.addAll([for (final t in others) if (t.sourceId == 'local' && t.uri != keep.uri) t.uri]);
    }
    if (!deleteFiles || files.isEmpty) return CleanupResult(removed: removed, filesDeleted: 0, filesKept: 0);

    final List<String> allowed;
    if (Platform.isAndroid) {
      final own = (await _appDir()).path;
      allowed = [for (final f in files) if (p.isWithin(own, f)) f];
    } else {
      allowed = files;
    }
    final gone = await (trash ?? _moveToBin)(allowed);
    return CleanupResult(removed: removed, filesDeleted: gone.length, filesKept: files.length - gone.length);
  }

  /// Windows: one PowerShell call sends all of them to the Recycle Bin.
  /// Elsewhere: deleted (Android only gets Prism's own files here).
  static Future<Set<String>> _moveToBin(List<String> paths) async {
    if (paths.isEmpty) return {};
    if (Platform.isWindows) {
      final dir = await Directory.systemTemp.createTemp('prism_bin_');
      try {
        final list = File(p.join(dir.path, 'files.txt'));
        await list.writeAsString(paths.join('\n'), encoding: utf8);
        final script = 'Add-Type -AssemblyName Microsoft.VisualBasic; '
            "Get-Content -LiteralPath '${list.path.replaceAll("'", "''")}' -Encoding UTF8 | ForEach-Object { "
            r"if (Test-Path -LiteralPath $_) { [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($_, 'OnlyErrorDialogs', 'SendToRecycleBin') } }";
        await Process.run('powershell', ['-NoProfile', '-NonInteractive', '-Command', script]);
      } finally {
        await dir.delete(recursive: true);
      }
    } else {
      for (final f in paths) {
        try {
          await File(f).delete();
        } on FileSystemException {
          // Stays; counted as kept below.
        }
      }
    }
    return {for (final f in paths) if (!File(f).existsSync()) f};
  }
}

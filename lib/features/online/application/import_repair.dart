import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/db/app_database.dart';
import '../../../core/providers.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/track.dart';
import '../services/youtube/youtube_module.dart';
import 'import_downloader.dart';
import 'import_file_check.dart';
import 'online_providers.dart';

/// Finds imported songs that older versions saved broken (only the first
/// megabyte of sound, zeros after it, or cut off) and puts them right: the
/// broken file goes, the song streams again in its import, and the downloader
/// saves it once more (when saving is on).
///
/// Every file is checked once; a small list in the folder remembers which
/// ones were whole (by size and date), so later starts only look at new ones.
class ImportRepair {
  ImportRepair(this._ref);
  final Ref _ref;

  static const marksFile = '.prism-checked.json';

  bool _running = false;

  /// Returns how many broken songs were found.
  Future<int> run() async {
    if (_running) return 0;
    _running = true;
    try {
      return await _run();
    } on Object catch (e) {
      debugPrint('Prism import repair: $e');
      return 0;
    } finally {
      _running = false;
    }
  }

  Future<int> _run() async {
    final dir = _ref.read(importDownloadDirProvider);
    if (!await dir.exists()) return 0;
    final db = _ref.read(appDatabaseProvider);
    final checker = _ref.read(importFileCheckProvider);
    final marks = await _loadMarks(dir);
    final rows = await (db.select(db.tracks)
          ..where((t) => t.folder.equals(dir.path) & t.sourceId.equals('local')))
        .get();
    final broken = <TrackRow>[];
    for (final row in rows) {
      final file = File(row.uri);
      final FileStat stat;
      try {
        stat = await file.stat();
      } on FileSystemException {
        continue;
      }
      if (stat.type == FileSystemEntityType.notFound) continue;
      final key = '${stat.size}:${stat.modified.millisecondsSinceEpoch}';
      if (marks[row.uri] == key) continue;
      final audio = await checker.check(file, expectedMs: row.durationMs);
      if (audio.ok) {
        marks[row.uri] = key;
      } else {
        debugPrint('Prism import repair: ${row.uri} is broken (${audio.reason})');
        broken.add(row);
      }
    }
    final jobs = <int>{};
    for (final row in broken) {
      jobs.addAll(await _undo(row));
      marks.remove(row.uri);
    }
    await _saveMarks(dir, marks);
    if (jobs.isNotEmpty) {
      final repo = _ref.read(importRepositoryProvider);
      for (final j in jobs) {
        await repo.writePlaylist(j, finish: false);
      }
      if (_ref.read(onlineHubProvider).flags.importDownload) {
        for (final j in jobs) {
          _ref.read(importDownloaderProvider.notifier).poke(j);
        }
      }
    }
    return broken.length;
  }

  /// The song goes back to streaming in every import that has it; the file
  /// and its library entry go. Returns the jobs touched.
  Future<Set<int>> _undo(TrackRow row) async {
    final db = _ref.read(appDatabaseProvider);
    final id = videoIdInFileName(row.uri);
    final jobs = <int>{};
    if (id != null) {
      final remote = await _ref.read(remoteTrackStoreProvider).ensure(Track(
            id: 0,
            sourceId: youtubeSourceId,
            uri: 'https://www.youtube.com/watch?v=$id',
            title: row.title,
            artist: row.artist,
            album: row.album,
            durationMs: row.durationMs,
            artworkPath: row.artworkPath,
          ));
      final items = await (db.select(db.importItems)..where((i) => i.trackId.equals(row.id))).get();
      for (final i in items) {
        jobs.add(i.jobId);
        await (db.update(db.importItems)..where((x) => x.id.equals(i.id))).write(ImportItemsCompanion(trackId: Value(remote.id)));
      }
    }
    await _ref.read(libraryRepositoryProvider).deleteByUris([row.uri]);
    try {
      await File(row.uri).delete();
    } on FileSystemException {
      // In use (playing right now): the downloader replaces it later.
    }
    return jobs;
  }

  /// The YouTube video id Prism puts in the names of saved songs.
  static String? videoIdInFileName(String path) =>
      RegExp(r'\[([A-Za-z0-9_-]{11})\]\.[A-Za-z0-9]+$').firstMatch(p.basename(path))?.group(1);

  static Future<Map<String, String>> _loadMarks(Directory dir) async {
    try {
      final raw = jsonDecode(await File(p.join(dir.path, marksFile)).readAsString());
      if (raw is Map) return {for (final e in raw.entries) '${e.key}': '${e.value}'};
    } on Object {
      // None yet, or unreadable: check everything once.
    }
    return {};
  }

  static Future<void> _saveMarks(Directory dir, Map<String, String> marks) async {
    try {
      await File(p.join(dir.path, marksFile)).writeAsString(jsonEncode(marks));
    } on FileSystemException {
      // Next start checks again.
    }
  }
}

final importRepairProvider = Provider<ImportRepair>(ImportRepair.new);

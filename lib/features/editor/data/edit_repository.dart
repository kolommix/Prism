import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/providers.dart';
import '../../library/domain/track.dart';
import '../../player/domain/playback_plan.dart';
import '../domain/edit_decision_list.dart';

/// A stored edit and whether the player uses it live.
class StoredEdit {
  const StoredEdit(this.edl, this.livePreset);
  final EditDecisionList edl;
  final bool livePreset;
}

/// Persists one [EditDecisionList] per track (`track_edits` table). The
/// audio file itself is never modified.
class EditRepository {
  EditRepository(this._db);

  final AppDatabase _db;

  StoredEdit? _parse(TrackEdit? row) {
    if (row == null) return null;
    try {
      return StoredEdit(EditDecisionList.fromJson(jsonDecode(row.json) as Map<String, dynamic>), row.livePreset);
    } on Object {
      return null; // corrupt/unknown version: treat as no edit
    }
  }

  Future<StoredEdit?> load(int trackId) async =>
      _parse(await (_db.select(_db.trackEdits)..where((e) => e.trackId.equals(trackId))).getSingleOrNull());

  Stream<StoredEdit?> watch(int trackId) =>
      (_db.select(_db.trackEdits)..where((e) => e.trackId.equals(trackId))).watchSingleOrNull().map(_parse);

  /// Track ids that currently play with a live preset.
  Stream<Set<int>> watchLiveIds() => (_db.select(_db.trackEdits)..where((e) => e.livePreset.equals(true)))
      .map((e) => e.trackId)
      .watch()
      .map((ids) => ids.toSet());

  Future<void> save(int trackId, EditDecisionList edl, {required bool livePreset}) =>
      _db.into(_db.trackEdits).insertOnConflictUpdate(TrackEditsCompanion.insert(
            trackId: Value(trackId),
            json: jsonEncode(edl.toJson()),
            livePreset: Value(livePreset),
            updatedAt: Value(DateTime.now()),
          ));

  Future<void> setLivePreset(int trackId, bool on) => (_db.update(_db.trackEdits)
        ..where((e) => e.trackId.equals(trackId)))
      .write(TrackEditsCompanion(livePreset: Value(on), updatedAt: Value(DateTime.now())));

  Future<void> delete(int trackId) => (_db.delete(_db.trackEdits)..where((e) => e.trackId.equals(trackId))).go();

  /// Every stored edit (for backups).
  Future<List<(int, StoredEdit)>> all() async => [
        for (final row in await _db.select(_db.trackEdits).get())
          if (_parse(row) case final e?) (row.trackId, e),
      ];

  /// Folder for rendered live presets (set once at startup).
  static String? renderDir;

  /// Where the rendered version of [edl] goes; the name changes with the edit.
  static String? renderPath(int trackId, EditDecisionList edl) {
    final dir = renderDir;
    if (dir == null) return null;
    final key = md5.convert(utf8.encode(jsonEncode([for (final o in edl.ops) o.toJson()])));
    return p.join(dir, '$trackId-$key.wav');
  }

  /// Plan for the player when [t] has an active live preset (else null). An
  /// edit the player can't do on the fly plays its rendered file; until that
  /// exists the song plays unedited.
  Future<PlaybackPlan?> livePlanFor(Track t) async {
    final stored = await load(t.id);
    if (stored == null || !stored.livePreset || stored.edl.sourceUri != t.uri) return null;
    final timeline = stored.edl.build();
    if (timeline.isUnedited) return null;
    if (timeline.isLiveCompatible) return timeline.toPlan();
    final path = renderPath(t.id, stored.edl);
    if (path == null || !await File(path).exists()) return null;
    return PlaybackPlan(renderedFile: path);
  }
}

final editRepositoryProvider = Provider<EditRepository>((ref) => EditRepository(ref.watch(appDatabaseProvider)));

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../library/data/library_repository.dart';
import '../../library/domain/track.dart';
import '../domain/external_track.dart';
import '../domain/matching.dart';
import '../../../l10n/l10n.dart';

enum ImportItemStatus { pending, matched, unmatched, duplicate, skipped }

enum ImportJobState { matching, paused, review, done }

class ImportJob {
  const ImportJob({
    required this.id,
    required this.name,
    required this.origin,
    this.sourceUrl,
    this.playlistId,
    required this.state,
    this.message,
    required this.createdAt,
    this.total = 0,
    this.pending = 0,
    this.matched = 0,
    this.lowConfidence = 0,
  });

  final int id;
  final String name;
  final OnlineService origin;
  final String? sourceUrl;
  final int? playlistId;
  final ImportJobState state;
  final String? message;
  final DateTime createdAt;
  final int total;
  final int pending;
  final int matched;
  final int lowConfidence;
}

class ImportItem {
  const ImportItem({
    required this.id,
    required this.jobId,
    required this.position,
    required this.wanted,
    required this.status,
    this.track,
    this.confidence = 0,
    this.matchSource,
    this.note,
    this.duplicateOf,
  });

  final int id;
  final int jobId;
  final int position;
  final ExternalTrack wanted;
  final ImportItemStatus status;
  final Track? track;
  final double confidence;
  final String? matchSource;
  final String? note;
  final int? duplicateOf;

  MatchConfidence get level =>
      status == ImportItemStatus.matched ? MatchConfidence.of(confidence) : MatchConfidence.none;
  bool get needsReview =>
      status == ImportItemStatus.unmatched || (status == ImportItemStatus.matched && level == MatchConfidence.low);
}

/// Import jobs and their items (schema v4). Matching progress is written per
/// item, so a closed app / lost connection resumes where it stopped.
class ImportRepository {
  ImportRepository(this._db);
  final AppDatabase _db;

  Future<int> createJob(ImportedList list, {bool skipDuplicates = true}) => _db.transaction(() async {
    final id = await _db
        .into(_db.importJobs)
        .insert(
          ImportJobsCompanion.insert(name: list.name, origin: list.origin.name, sourceUrl: Value(list.sourceUrl)),
        );
    final dupes = findImportDuplicates(list.tracks);
    await _db.batch((b) {
      for (var i = 0; i < list.tracks.length; i++) {
        final dupOf = dupes[i];
        b.insert(
          _db.importItems,
          ImportItemsCompanion.insert(
            jobId: id,
            position: i,
            json: jsonEncode(list.tracks[i].toJson()),
            status: Value(
              (dupOf != null && skipDuplicates ? ImportItemStatus.duplicate : ImportItemStatus.pending).name,
            ),
            duplicateOf: Value(dupOf),
          ),
        );
      }
    });
    return id;
  });

  /// Earlier import of the same link / file (to warn before importing twice).
  /// Earlier import of the same link / file (to warn before importing twice).
  Future<ImportJob?> jobForSource(String? sourceUrl) async {
    if (sourceUrl == null) return null;
    final rows = await _jobsQuery('WHERE j.source_url = ?', [Variable.withString(sourceUrl)]).get();
    return rows.isEmpty ? null : rows.first;
  }

  /// Jobs with their item counts, newest first.
  Selectable<ImportJob> _jobsQuery(String where, List<Variable> vars) => _db
      .customSelect(
        'SELECT j.*, c.total, c.pending, c.matched, c.low FROM import_jobs j LEFT JOIN ('
        'SELECT job_id, COUNT(*) AS total, '
        "SUM(CASE WHEN status = 'pending' THEN 1 ELSE 0 END) AS pending, "
        "SUM(CASE WHEN status = 'matched' THEN 1 ELSE 0 END) AS matched, "
        "SUM(CASE WHEN status = 'matched' AND confidence < 0.7 THEN 1 ELSE 0 END) AS low "
        'FROM import_items GROUP BY job_id) c ON c.job_id = j.id $where ORDER BY j.updated_at DESC, j.id DESC',
        variables: vars,
        readsFrom: {_db.importJobs, _db.importItems},
      )
      .map((r) {
        final j = _db.importJobs.map(r.data);
        return ImportJob(
          id: j.id,
          name: j.name,
          origin: OnlineService.byName(j.origin) ?? OnlineService.file,
          sourceUrl: j.sourceUrl,
          playlistId: j.playlistId,
          state: ImportJobState.values.byName(j.state),
          message: j.message,
          createdAt: j.createdAt,
          total: r.readNullable<int>('total') ?? 0,
          pending: r.readNullable<int>('pending') ?? 0,
          matched: r.readNullable<int>('matched') ?? 0,
          lowConfidence: r.readNullable<int>('low') ?? 0,
        );
      });

  Stream<List<ImportJob>> watchJobs() => _jobsQuery('', const []).watch();

  Stream<ImportJob?> watchJob(int id) =>
      _jobsQuery('WHERE j.id = ?', [Variable.withInt(id)]).watch().map((l) => l.firstOrNull);

  Stream<List<ImportItem>> watchItems(int jobId) {
    final q =
        _db.select(_db.importItems).join([leftOuterJoin(_db.tracks, _db.tracks.id.equalsExp(_db.importItems.trackId))])
          ..where(_db.importItems.jobId.equals(jobId))
          ..orderBy([OrderingTerm(expression: _db.importItems.position)]);
    return q.watch().map(
      (rows) => [for (final row in rows) _item(row.readTable(_db.importItems), row.readTableOrNull(_db.tracks))],
    );
  }

  ImportItem _item(ImportItemRow r, TrackRow? t) => ImportItem(
    id: r.id,
    jobId: r.jobId,
    position: r.position,
    wanted: ExternalTrack.fromJson(jsonDecode(r.json) as Map<String, dynamic>),
    status: ImportItemStatus.values.byName(r.status),
    track: t == null ? null : LibraryRepository.rowToTrack(t),
    confidence: r.confidence,
    matchSource: r.matchSource,
    note: r.note,
    duplicateOf: r.duplicateOf,
  );

  Future<List<ImportItem>> pendingItems(int jobId) async {
    final rows =
        await (_db.select(_db.importItems)
              ..where((i) => i.jobId.equals(jobId) & i.status.equals(ImportItemStatus.pending.name))
              ..orderBy([(i) => OrderingTerm(expression: i.position)]))
            .get();
    return [for (final r in rows) _item(r, null)];
  }

  Future<void> saveMatch(
    int itemId, {
    required int? trackId,
    required double confidence,
    String? source,
    String? note,
  }) => (_db.update(_db.importItems)..where((i) => i.id.equals(itemId))).write(
    ImportItemsCompanion(
      status: Value((trackId == null ? ImportItemStatus.unmatched : ImportItemStatus.matched).name),
      trackId: Value(trackId),
      confidence: Value(confidence),
      matchSource: Value(source),
      note: Value(note),
    ),
  );

  Future<void> setItemStatus(int itemId, ImportItemStatus status) => (_db.update(
    _db.importItems,
  )..where((i) => i.id.equals(itemId))).write(ImportItemsCompanion(status: Value(status.name)));

  Future<void> setState(int jobId, ImportJobState state, {String? message}) =>
      (_db.update(_db.importJobs)..where((j) => j.id.equals(jobId))).write(
        ImportJobsCompanion(state: Value(state.name), message: Value(message), updatedAt: Value(DateTime.now())),
      );

  Future<void> rename(int jobId, String name) =>
      (_db.update(_db.importJobs)..where((j) => j.id.equals(jobId))).write(ImportJobsCompanion(name: Value(name)));

  Future<void> deleteJob(int jobId) => (_db.delete(_db.importJobs)..where((j) => j.id.equals(jobId))).go();

  /// Creates (or refreshes) the Prism playlist: matched songs in import order.
  /// Refreshing rewrites the playlist's entries, so fixed matches show up.
  Future<int> writePlaylist(int jobId) => _db.transaction(() async {
    final job = await (_db.select(_db.importJobs)..where((j) => j.id.equals(jobId))).getSingle();
    final items =
        await (_db.select(_db.importItems)
              ..where(
                (i) => i.jobId.equals(jobId) & i.status.equals(ImportItemStatus.matched.name) & i.trackId.isNotNull(),
              )
              ..orderBy([(i) => OrderingTerm(expression: i.position)]))
            .get();
    var playlistId = job.playlistId;
    if (playlistId != null &&
        await (_db.select(_db.playlists)..where((p) => p.id.equals(playlistId!))).getSingleOrNull() == null) {
      playlistId = null; // deleted by the user meanwhile
    }
    playlistId ??= await _db.into(_db.playlists).insert(PlaylistsCompanion.insert(name: _name(job.name)));
    await (_db.delete(_db.playlistEntries)..where((e) => e.playlistId.equals(playlistId!))).go();
    await _db.batch((b) {
      for (var i = 0; i < items.length; i++) {
        b.insert(
          _db.playlistEntries,
          PlaylistEntriesCompanion.insert(playlistId: playlistId!, trackId: items[i].trackId!, position: i),
        );
      }
    });
    await (_db.update(
      _db.playlists,
    )..where((p) => p.id.equals(playlistId!))).write(PlaylistsCompanion(updatedAt: Value(DateTime.now())));
    await (_db.update(_db.importJobs)..where((j) => j.id.equals(jobId))).write(
      ImportJobsCompanion(
        playlistId: Value(playlistId),
        state: Value(ImportJobState.done.name),
        message: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return playlistId;
  });

  static String _name(String n) {
    final t = n.trim();
    return t.isEmpty ? l10n.importedPlaylist : (t.length > 200 ? t.substring(0, 200) : t);
  }
}

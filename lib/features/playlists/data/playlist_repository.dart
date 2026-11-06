import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../library/data/library_repository.dart';
import '../../library/domain/library_models.dart';
import '../../library/domain/track.dart';
import '../../../l10n/l10n.dart';

import '../../player/domain/reorder.dart';
/// One playlist item: the entry id (stable across reorders) + its track.
class PlaylistItem {
  const PlaylistItem({required this.entryId, required this.track});
  final int entryId;
  final Track track;
}

/// CRUD + ordering for user playlists.
///
/// Order is stored in `playlist_entries.position` (0..n-1, dense). Every
/// mutation rewrites positions inside one transaction, which keeps the logic
/// trivial and is fast enough for playlists of a few thousand songs.
class PlaylistRepository {
  PlaylistRepository(this._db);

  final AppDatabase _db;

  Stream<List<PlaylistSummary>> watchPlaylists() {
    return _db
        .customSelect(
          'SELECT p.id, p.name, p.updated_at, COUNT(e.id) AS cnt, '
          '(SELECT t.artwork_path FROM playlist_entries e2 JOIN tracks t ON t.id = e2.track_id '
          ' WHERE e2.playlist_id = p.id AND t.artwork_path IS NOT NULL ORDER BY e2.position LIMIT 1) AS art '
          'FROM playlists p LEFT JOIN playlist_entries e ON e.playlist_id = p.id '
          'GROUP BY p.id ORDER BY p.name COLLATE NOCASE',
          readsFrom: {_db.playlists, _db.playlistEntries, _db.tracks},
        )
        .watch()
        .map((rows) => [
              for (final r in rows)
                PlaylistSummary(
                  id: r.read<int>('id'),
                  name: r.read<String>('name'),
                  trackCount: r.read<int>('cnt'),
                  // drift stores DateTime as unix seconds by default.
                  updatedAt: r.read<DateTime>('updated_at'),
                  artworkPath: r.readNullable<String>('art'),
                ),
            ]);
  }

  Stream<String?> watchName(int playlistId) =>
      (_db.select(_db.playlists)..where((p) => p.id.equals(playlistId)))
          .map((p) => p.name)
          .watchSingleOrNull();

  Stream<List<PlaylistItem>> watchItems(int playlistId) {
    final q = _db.select(_db.playlistEntries).join([
      innerJoin(_db.tracks, _db.tracks.id.equalsExp(_db.playlistEntries.trackId)),
    ])
      ..where(_db.playlistEntries.playlistId.equals(playlistId))
      ..orderBy([OrderingTerm(expression: _db.playlistEntries.position)]);
    return q.watch().map((rows) => [
          for (final row in rows)
            PlaylistItem(
              entryId: row.readTable(_db.playlistEntries).id,
              track: LibraryRepository.rowToTrack(row.readTable(_db.tracks)),
            ),
        ]);
  }

  Future<int> create(String name) =>
      _db.into(_db.playlists).insert(PlaylistsCompanion.insert(name: _cleanName(name)));

  Future<void> rename(int playlistId, String name) =>
      (_db.update(_db.playlists)..where((p) => p.id.equals(playlistId))).write(
        PlaylistsCompanion(name: Value(_cleanName(name)), updatedAt: Value(DateTime.now())),
      );

  /// Deletes the playlist; entries go with it (ON DELETE CASCADE).
  Future<void> delete(int playlistId) =>
      (_db.delete(_db.playlists)..where((p) => p.id.equals(playlistId))).go();

  /// Appends tracks at the end.
  Future<void> addTracks(int playlistId, List<int> trackIds) => _db.transaction(() async {
        final max = _db.playlistEntries.position.max();
        final row = await (_db.selectOnly(_db.playlistEntries)
              ..addColumns([max])
              ..where(_db.playlistEntries.playlistId.equals(playlistId)))
            .getSingle();
        var pos = (row.read(max) ?? -1) + 1;
        await _db.batch((b) {
          for (final id in trackIds) {
            b.insert(
              _db.playlistEntries,
              PlaylistEntriesCompanion.insert(playlistId: playlistId, trackId: id, position: pos++),
            );
          }
        });
        await _touch(playlistId);
      });

  Future<void> removeEntry(int playlistId, int entryId) => _db.transaction(() async {
        await (_db.delete(_db.playlistEntries)..where((e) => e.id.equals(entryId))).go();
        await _renumber(playlistId);
        await _touch(playlistId);
      });

  /// Moves the item at [from] to final index [to].
  Future<void> move(int playlistId, int from, int to) => _db.transaction(() async {
        final ids = await (_db.select(_db.playlistEntries)
              ..where((e) => e.playlistId.equals(playlistId))
              ..orderBy([(e) => OrderingTerm(expression: e.position)]))
            .map((e) => e.id)
            .get();
        if (from < 0 || from >= ids.length || to < 0 || to >= ids.length || from == to) return;
        final id = ids.removeAt(from);
        ids.insert(to, id);
        await _writePositions(ids);
        await _touch(playlistId);
      });

  /// Gathers the items at [indices] at final index [start], keeping their order.
  Future<void> moveMany(int playlistId, Set<int> indices, int start) => _db.transaction(() async {
        final ids = await _entryIds(playlistId);
        final moves = groupMoves(ids.length, indices, start);
        if (moves.isEmpty) return;
        await _writePositions(applyMoves(ids, moves));
        await _touch(playlistId);
      });

  Future<void> removeEntries(int playlistId, Set<int> entryIds) => _db.transaction(() async {
        await (_db.delete(_db.playlistEntries)..where((e) => e.id.isIn(entryIds))).go();
        await _renumber(playlistId);
        await _touch(playlistId);
      });

  Future<void> moveEntryToEdge(int playlistId, int entryId, {required bool top}) async {
    final ids = await _entryIds(playlistId);
    final i = ids.indexOf(entryId);
    if (i >= 0) await moveMany(playlistId, {i}, top ? 0 : ids.length);
  }

  /// Makes [orderedEntryIds] the saved order.
  Future<void> setOrder(int playlistId, List<int> orderedEntryIds) => _db.transaction(() async {
        await _writePositions(orderedEntryIds);
        await _touch(playlistId);
      });

  Stream<PlaylistSort> watchSort(int playlistId) => (_db.select(_db.playlists)..where((p) => p.id.equals(playlistId)))
      .map((p) => PlaylistSort.parse(p.sortMode))
      .watchSingleOrNull()
      .map((s) => s ?? PlaylistSort.custom);

  Future<void> setSort(int playlistId, PlaylistSort sort) =>
      (_db.update(_db.playlists)..where((p) => p.id.equals(playlistId))).write(PlaylistsCompanion(sortMode: Value(sort.name)));

  Future<List<int>> _entryIds(int playlistId) => (_db.select(_db.playlistEntries)
        ..where((e) => e.playlistId.equals(playlistId))
        ..orderBy([(e) => OrderingTerm(expression: e.position)]))
      .map((e) => e.id)
      .get();

  Future<void> _renumber(int playlistId) async {
    final ids = await (_db.select(_db.playlistEntries)
          ..where((e) => e.playlistId.equals(playlistId))
          ..orderBy([(e) => OrderingTerm(expression: e.position)]))
        .map((e) => e.id)
        .get();
    await _writePositions(ids);
  }

  Future<void> _writePositions(List<int> orderedEntryIds) => _db.batch((b) {
        for (var i = 0; i < orderedEntryIds.length; i++) {
          b.update(
            _db.playlistEntries,
            PlaylistEntriesCompanion(position: Value(i)),
            where: (e) => e.id.equals(orderedEntryIds[i]),
          );
        }
      });

  Future<void> _touch(int playlistId) =>
      (_db.update(_db.playlists)..where((p) => p.id.equals(playlistId)))
          .write(PlaylistsCompanion(updatedAt: Value(DateTime.now())));

  static String _cleanName(String name) {
    final n = name.trim();
    return n.isEmpty ? l10n.newPlaylist : (n.length > 200 ? n.substring(0, 200) : n);
  }
}

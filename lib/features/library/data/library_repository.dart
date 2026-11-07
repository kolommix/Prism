import 'dart:io';

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../../core/db/app_database.dart';
import '../domain/library_models.dart';
import '../domain/track.dart';
import 'search_text.dart';

/// Columns the songs list can be sorted by.
enum TrackSort { title, artist, album, recentlyAdded, duration }

/// All read/write access to the local music library.
///
/// UI code never builds SQL – it calls (or watches) these methods through
/// Riverpod providers. Every `watch*` method returns a stream that re-emits
/// when the underlying tables change, so lists update live during a scan.
class LibraryRepository {
  LibraryRepository(this._db);

  final AppDatabase _db;

  /// Library views (songs, albums, artists, folders, search) show files on
  /// this device only; streamed tracks live in the same table but are reached
  /// through playlists, favorites and online search.
  static const _local = 'local';

  // ---------------------------------------------------------------- folders

  Stream<List<String>> watchFolders() =>
      (_db.select(_db.libraryFolders)..orderBy([(f) => OrderingTerm(expression: f.path)]))
          .map((f) => f.path)
          .watch();

  Future<List<String>> folders() =>
      _db.select(_db.libraryFolders).map((f) => f.path).get();

  Future<void> addFolder(String path) => _db
      .into(_db.libraryFolders)
      .insert(LibraryFoldersCompanion.insert(path: path), mode: InsertMode.insertOrIgnore);

  /// Removes a folder and every track that was found inside it.
  Future<void> removeFolder(String path) => _db.transaction(() async {
        await (_db.delete(_db.libraryFolders)..where((f) => f.path.equals(path))).go();
        // Trailing separator so removing "C:\Music" keeps "C:\Music2".
        final prefix = path.endsWith(p.separator) ? path : '$path${p.separator}';
        await (_db.delete(_db.tracks)
              ..where((t) => t.uri.like('${_escapeLike(prefix)}%', escapeChar: '\\')))
            .go();
        // Adding the folder again means all of it.
        await (_db.delete(_db.removedTracks)
              ..where((t) => t.uri.like('${_escapeLike(prefix)}%', escapeChar: '\\')))
            .go();
      });

  // ----------------------------------------------------------------- tracks

  Stream<List<Track>> watchTracks({TrackSort sort = TrackSort.title}) {
    final q = _db.select(_db.tracks)
      ..where((t) => t.sourceId.equals(_local))
      ..orderBy(_orderFor(sort));
    return q.map(rowToTrack).watch();
  }

  Future<Track?> trackById(int id) =>
      (_db.select(_db.tracks)..where((t) => t.id.equals(id))).map(rowToTrack).getSingleOrNull();

  /// Exact file (case-insensitive, Windows paths), e.g. from an M3U playlist.
  Future<Track?> trackByUri(String uri) => (_db.select(_db.tracks)
        ..where((t) => t.uri.lower().equals(uri.toLowerCase()))
        ..limit(1))
      .map(rowToTrack)
      .getSingleOrNull();

  /// Loads several tracks and returns them **in the order of [ids]**
  /// (used to restore the queue). Missing ids are skipped.
  Future<List<Track>> tracksByIds(List<int> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await (_db.select(_db.tracks)..where((t) => t.id.isIn(ids))).map(rowToTrack).get();
    final byId = {for (final t in rows) t.id: t};
    return [for (final id in ids) if (byId[id] != null) byId[id]!];
  }

  Future<int> trackCount() async {
    final count = _db.tracks.id.count();
    final row = await (_db.selectOnly(_db.tracks)
          ..addColumns([count])
          ..where(_db.tracks.sourceId.equals(_local)))
        .getSingle();
    return row.read(count) ?? 0;
  }

  /// Fast token search. Every word of [query] must appear somewhere in
  /// title/artist/album (accents and case ignored). Uses the pre-computed
  /// `search_text` column, so it is a single indexed-free scan of one column –
  /// a few milliseconds even for tens of thousands of songs.
  Future<List<Track>> search(String query, {int limit = 200}) {
    final tokens = searchTokens(query);
    if (tokens.isEmpty) return Future.value(const []);
    final q = _db.select(_db.tracks)
      ..where((t) {
        Expression<bool> expr = t.sourceId.equals(_local);
        for (final token in tokens) {
          expr = expr & t.searchText.like('%${_escapeLike(token)}%', escapeChar: '\\');
        }
        return expr;
      })
      ..orderBy([(t) => OrderingTerm(expression: t.title.collate(Collate.noCase))])
      ..limit(limit);
    return q.map(rowToTrack).get();
  }

  // ----------------------------------------------------- albums / artists

  Stream<List<AlbumSummary>> watchAlbums() {
    return _db
        .customSelect(
          'SELECT album, '
          "CASE WHEN album_artist <> '' THEN album_artist ELSE artist END AS a_artist, "
          'COUNT(*) AS cnt, MAX(year) AS yr, MAX(artwork_path) AS art '
          "FROM tracks WHERE source_id = 'local' GROUP BY album, a_artist "
          'ORDER BY album COLLATE NOCASE',
          readsFrom: {_db.tracks},
        )
        .watch()
        .map((rows) => [
              for (final r in rows)
                AlbumSummary(
                  name: r.read<String>('album'),
                  artist: r.read<String>('a_artist'),
                  trackCount: r.read<int>('cnt'),
                  year: r.readNullable<int>('yr'),
                  artworkPath: r.readNullable<String>('art'),
                ),
            ]);
  }

  Stream<List<ArtistSummary>> watchArtists() {
    return _db
        .customSelect(
          'SELECT artist, COUNT(*) AS cnt, COUNT(DISTINCT album) AS albums, '
          "MAX(artwork_path) AS art FROM tracks WHERE source_id = 'local' "
          'GROUP BY artist ORDER BY artist COLLATE NOCASE',
          readsFrom: {_db.tracks},
        )
        .watch()
        .map((rows) => [
              for (final r in rows)
                ArtistSummary(
                  name: r.read<String>('artist'),
                  trackCount: r.read<int>('cnt'),
                  albumCount: r.read<int>('albums'),
                  artworkPath: r.readNullable<String>('art'),
                ),
            ]);
  }

  Stream<List<FolderSummary>> watchFolderSummaries() {
    return _db
        .customSelect(
          "SELECT folder, COUNT(*) AS cnt FROM tracks WHERE source_id = 'local' GROUP BY folder ORDER BY folder COLLATE NOCASE",
          readsFrom: {_db.tracks},
        )
        .watch()
        .map((rows) => [
              for (final r in rows)
                FolderSummary(path: r.read<String>('folder'), trackCount: r.read<int>('cnt')),
            ]);
  }

  /// Tracks of one album ordered by disc/track number.
  Stream<List<Track>> watchAlbumTracks(String album, String artist) {
    final q = _db.select(_db.tracks)
      ..where((t) =>
          t.sourceId.equals(_local) &
          t.album.equals(album) &
          (t.albumArtist.equals(artist) | (t.albumArtist.equals('') & t.artist.equals(artist))))
      ..orderBy([
        (t) => OrderingTerm(expression: t.discNumber),
        (t) => OrderingTerm(expression: t.trackNumber),
        (t) => OrderingTerm(expression: t.title),
      ]);
    return q.map(rowToTrack).watch();
  }

  Stream<List<Track>> watchArtistTracks(String artist) {
    final q = _db.select(_db.tracks)
      ..where((t) => t.sourceId.equals(_local) & t.artist.equals(artist))
      ..orderBy([
        (t) => OrderingTerm(expression: t.album),
        (t) => OrderingTerm(expression: t.discNumber),
        (t) => OrderingTerm(expression: t.trackNumber),
      ]);
    return q.map(rowToTrack).watch();
  }

  Stream<List<Track>> watchFolderTracks(String folder) {
    final q = _db.select(_db.tracks)
      ..where((t) => t.sourceId.equals(_local) & t.folder.equals(folder))
      ..orderBy([(t) => OrderingTerm(expression: t.uri)]);
    return q.map(rowToTrack).watch();
  }

  // -------------------------------------------------------------- favorites

  Stream<Set<int>> watchFavoriteIds() =>
      _db.select(_db.favorites).map((f) => f.trackId).watch().map((ids) => ids.toSet());

  Stream<List<Track>> watchFavoriteTracks() {
    final q = _db.select(_db.tracks).join([
      innerJoin(_db.favorites, _db.favorites.trackId.equalsExp(_db.tracks.id)),
    ])
      ..orderBy([OrderingTerm.desc(_db.favorites.addedAt)]);
    return q.map((row) => rowToTrack(row.readTable(_db.tracks))).watch();
  }

  Future<bool> isFavorite(int trackId) async =>
      await (_db.select(_db.favorites)..where((f) => f.trackId.equals(trackId))).getSingleOrNull() !=
      null;

  /// Toggles favorite and returns the new state.
  Future<bool> toggleFavorite(int trackId) async {
    if (await isFavorite(trackId)) {
      await (_db.delete(_db.favorites)..where((f) => f.trackId.equals(trackId))).go();
      return false;
    }
    await _db.into(_db.favorites).insert(FavoritesCompanion.insert(trackId: Value(trackId)));
    return true;
  }

  // --------------------------------------------------------------- loudness

  /// Local tracks with neither ReplayGain tags nor a measurement.
  Future<List<Track>> tracksWithoutLoudness({int limit = 100000}) =>
      (_db.select(_db.tracks)
            ..where((t) => t.rgTrackGain.isNull() & t.loudnessLufs.isNull() & t.sourceId.equals('local'))
            ..limit(limit))
          .map(rowToTrack)
          .get();

  Stream<int> watchTracksWithoutLoudnessCount() {
    final count = _db.tracks.id.count();
    final q = _db.selectOnly(_db.tracks)
      ..addColumns([count])
      ..where(_db.tracks.rgTrackGain.isNull() & _db.tracks.loudnessLufs.isNull() & _db.tracks.sourceId.equals(_local));
    return q.watchSingle().map((r) => r.read(count) ?? 0);
  }

  Future<void> saveLoudness(int trackId, {required double lufs, required double truePeakDb}) =>
      (_db.update(_db.tracks)..where((t) => t.id.equals(trackId)))
          .write(TracksCompanion(loudnessLufs: Value(lufs), truePeakDb: Value(truePeakDb)));

  // ------------------------------------------------------- scanner support

  /// `uri -> (size, mtime)` of every local track, so the scanner can skip
  /// unchanged files without reading their tags again.
  Future<Map<String, (int, int)>> fileFingerprints() async {
    final rows = await (_db.selectOnly(_db.tracks)
          ..addColumns([_db.tracks.uri, _db.tracks.fileSize, _db.tracks.modifiedMs])
          ..where(_db.tracks.sourceId.equals('local')))
        .get();
    return {
      for (final r in rows)
        r.read(_db.tracks.uri)!: (r.read(_db.tracks.fileSize)!, r.read(_db.tracks.modifiedMs)!),
    };
  }

  // ---------------------------------------------------- info found online

  /// Local songs with something missing that haven't been looked up yet.
  Future<List<Track>> tracksMissingInfo() async {
    final rows = await (_db.select(_db.tracks)
          ..where((t) =>
              t.sourceId.equals('local') &
              t.infoCheckedMs.isNull() &
              ((t.artist.equals('') & t.albumArtist.equals('')) | t.artworkPath.isNull()))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    return rows.map(rowToTrack).toList();
  }

  Future<void> markInfoChecked(int id) => (_db.update(_db.tracks)..where((t) => t.id.equals(id)))
      .write(TracksCompanion(infoCheckedMs: Value(DateTime.now().millisecondsSinceEpoch)));

  /// Fills in what was found. The audio file is not touched, and what the row
  /// held before is kept for [undoAutoTags].
  Future<void> applyAutoTag(Track t, AutoTagChange c) async {
    final title = c.title ?? t.title;
    final artist = c.artist ?? t.artist;
    final album = c.album ?? t.album;
    await (_db.update(_db.tracks)..where((r) => r.id.equals(t.id))).write(
      TracksCompanion(
        title: Value(title),
        artist: Value(artist),
        album: Value(album),
        genre: Value(c.genre ?? t.genre),
        year: Value(c.year ?? t.year),
        artworkPath: Value(c.artworkPath ?? t.artworkPath),
        searchText: Value(buildSearchText(title: title, artist: artist, album: album, albumArtist: t.albumArtist)),
        infoCheckedMs: Value(DateTime.now().millisecondsSinceEpoch),
        infoOriginal: Value(jsonEncode({
          'title': t.title,
          'artist': t.artist,
          'album': t.album,
          'genre': t.genre,
          'year': t.year,
          'artworkPath': t.artworkPath,
        })),
      ),
    );
  }

  /// Everything found online goes back to what the files say. They stay marked
  /// as checked, so they aren't searched for again by themselves.
  Future<int> undoAutoTags() async {
    final rows = await (_db.select(_db.tracks)..where((t) => t.infoOriginal.isNotNull())).get();
    await _db.batch((b) {
      for (final r in rows) {
        final o = jsonDecode(r.infoOriginal!) as Map<String, dynamic>;
        final title = o['title'] as String? ?? r.title;
        final artist = o['artist'] as String? ?? '';
        final album = o['album'] as String? ?? '';
        b.update(
          _db.tracks,
          TracksCompanion(
            title: Value(title),
            artist: Value(artist),
            album: Value(album),
            genre: Value(o['genre'] as String? ?? ''),
            year: Value(o['year'] as int?),
            artworkPath: Value(o['artworkPath'] as String?),
            searchText: Value(buildSearchText(title: title, artist: artist, album: album, albumArtist: r.albumArtist)),
            infoOriginal: const Value(null),
          ),
          where: (t) => t.id.equals(r.id),
        );
      }
    });
    return rows.length;
  }

  /// Songs without a result (or undone) can be looked up again.
  Future<void> clearInfoChecks() => (_db.update(_db.tracks)..where((t) => t.infoOriginal.isNull()))
      .write(const TracksCompanion(infoCheckedMs: Value(null)));

  /// How many songs have info found online.
  Stream<int> watchAutoTaggedCount() {
    final c = _db.tracks.id.count();
    return (_db.selectOnly(_db.tracks)
          ..addColumns([c])
          ..where(_db.tracks.infoOriginal.isNotNull()))
        .watchSingle()
        .map((r) => r.read(c) ?? 0);
  }

  /// Inserts or updates tracks by `uri`, keeping existing ids (so favorites
  /// and playlists survive rescans).
  Future<void> upsertTracks(List<TracksCompanion> rows) async {
    if (rows.isEmpty) return;
    await _db.batch((b) {
      for (final row in rows) {
        b.insert(
          _db.tracks,
          row,
          onConflict: DoUpdate((_) => row, target: [_db.tracks.uri]),
        );
      }
    });
  }

  /// Takes songs out of Prism without touching their files: scans skip them
  /// from now on. Returns an undo that puts back everything, also their plays,
  /// favorites and playlist places (it only works while the app is open; after
  /// that [restoreRemoved] brings the song back through a scan).
  Future<Future<void> Function()> removeFromLibrary(Iterable<Track> tracks) => _db.transaction(() async {
        final ids = [for (final t in tracks) t.id];
        final uris = [for (final t in tracks) t.uri];
        final rows = await (_db.select(_db.tracks)..where((t) => t.id.isIn(ids))).get();
        final plays = await (_db.select(_db.plays)..where((x) => x.trackId.isIn(ids))).get();
        final favorites = await (_db.select(_db.favorites)..where((x) => x.trackId.isIn(ids))).get();
        final entries = await (_db.select(_db.playlistEntries)..where((x) => x.trackId.isIn(ids))).get();
        final edits = await (_db.select(_db.trackEdits)..where((x) => x.trackId.isIn(ids))).get();
        final lyrics = await (_db.select(_db.lyricsCache)..where((x) => x.trackId.isIn(ids))).get();
        final imports = await (_db.select(_db.importItems)..where((x) => x.trackId.isIn(ids))).get();
        await _db.batch((b) {
          for (final t in tracks) {
            b.insert(
              _db.removedTracks,
              RemovedTracksCompanion.insert(uri: t.uri, title: Value(t.title), artist: Value(t.artist)),
              mode: InsertMode.insertOrReplace,
            );
          }
        });
        await (_db.delete(_db.tracks)..where((t) => t.id.isIn(ids))).go();
        return () => _db.transaction(() async {
              await (_db.delete(_db.removedTracks)..where((r) => r.uri.isIn(uris))).go();
              await _db.batch((b) {
                b.insertAll(_db.tracks, rows, mode: InsertMode.insertOrIgnore);
                b.insertAll(_db.plays, plays, mode: InsertMode.insertOrIgnore);
                b.insertAll(_db.favorites, favorites, mode: InsertMode.insertOrIgnore);
                b.insertAll(_db.playlistEntries, entries, mode: InsertMode.insertOrIgnore);
                b.insertAll(_db.trackEdits, edits, mode: InsertMode.insertOrIgnore);
                b.insertAll(_db.lyricsCache, lyrics, mode: InsertMode.insertOrIgnore);
                for (final i in imports) {
                  b.update(_db.importItems, ImportItemsCompanion(trackId: Value(i.trackId)), where: (t) => t.id.equals(i.id));
                }
              });
            });
      });

  /// A song saved by an import becomes a normal library song. Returns its id.
  Future<int> addDownloadedFile(
    File file, {
    required String title,
    required String artist,
    required String album,
    required int durationMs,
    String? artwork,
  }) async {
    final stat = await file.stat();
    await upsertTracks([
      TracksCompanion.insert(
        uri: file.path,
        folder: p.dirname(file.path),
        title: title,
        artist: Value(artist),
        album: Value(album),
        durationMs: Value(durationMs),
        artworkPath: Value(artwork),
        fileSize: Value(stat.size),
        modifiedMs: Value(stat.modified.millisecondsSinceEpoch),
        searchText: Value(buildSearchText(title: title, artist: artist, album: album, albumArtist: '')),
      ),
    ]);
    final row = await (_db.select(_db.tracks)..where((t) => t.uri.equals(file.path))).getSingle();
    return row.id;
  }

  Stream<List<RemovedTrackRow>> watchRemoved() =>
      (_db.select(_db.removedTracks)..orderBy([(r) => OrderingTerm.desc(r.removedAt)])).watch();

  Future<Set<String>> removedUris() async => {for (final r in await _db.select(_db.removedTracks).get()) r.uri};

  /// Scans may add this song again.
  Future<void> restoreRemoved(String uri) => (_db.delete(_db.removedTracks)..where((r) => r.uri.equals(uri))).go();

  Future<int> deleteByUris(Iterable<String> uris) async {
    final list = uris.toList();
    var deleted = 0;
    // SQLite has a limit on bound variables; chunk large deletions.
    for (var i = 0; i < list.length; i += 500) {
      final chunk = list.sublist(i, i + 500 > list.length ? list.length : i + 500);
      deleted += await (_db.delete(_db.tracks)..where((t) => t.uri.isIn(chunk))).go();
    }
    return deleted;
  }

  // ---------------------------------------------------------------- helpers

  /// Maps a database row to the domain [Track] (also used by playlists).
  static Track rowToTrack(TrackRow r) => Track(
        id: r.id,
        sourceId: r.sourceId,
        uri: r.uri,
        title: r.title,
        artist: r.artist,
        album: r.album,
        albumArtist: r.albumArtist,
        genre: r.genre,
        year: r.year,
        trackNumber: r.trackNumber,
        discNumber: r.discNumber,
        durationMs: r.durationMs,
        artworkPath: r.artworkPath,
        rgTrackGain: r.rgTrackGain,
        rgTrackPeak: r.rgTrackPeak,
        rgAlbumGain: r.rgAlbumGain,
        rgAlbumPeak: r.rgAlbumPeak,
        loudnessLufs: r.loudnessLufs,
        truePeakDb: r.truePeakDb,
      );

  List<OrderClauseGenerator<$TracksTable>> _orderFor(TrackSort sort) => switch (sort) {
        TrackSort.title => [(t) => OrderingTerm(expression: t.title.collate(Collate.noCase))],
        TrackSort.artist => [
            (t) => OrderingTerm(expression: t.artist.collate(Collate.noCase)),
            (t) => OrderingTerm(expression: t.album.collate(Collate.noCase)),
            (t) => OrderingTerm(expression: t.trackNumber),
          ],
        TrackSort.album => [
            (t) => OrderingTerm(expression: t.album.collate(Collate.noCase)),
            (t) => OrderingTerm(expression: t.discNumber),
            (t) => OrderingTerm(expression: t.trackNumber),
          ],
        TrackSort.recentlyAdded => [(t) => OrderingTerm.desc(t.addedAt), (t) => OrderingTerm.desc(t.id)],
        TrackSort.duration => [(t) => OrderingTerm.desc(t.durationMs)],
      };

  static String _escapeLike(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll('%', '\\%').replaceAll('_', '\\_');
}

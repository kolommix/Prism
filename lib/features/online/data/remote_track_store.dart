import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../library/data/library_repository.dart';
import '../../library/data/search_text.dart';
import '../../library/domain/track.dart';

/// Saves streamed tracks (YouTube, SoundCloud) into the `tracks` table so
/// they get a real id – then queue restore, favorites, playlists, play
/// history and lyrics all work for them like for local files. Upserts by
/// `uri`, so the same video always keeps the same id.
class RemoteTrackStore {
  RemoteTrackStore(this._db);
  final AppDatabase _db;

  Future<Track> ensure(Track t) async => (await ensureAll([t])).single;

  Future<List<Track>> ensureAll(List<Track> tracks) async {
    final todo = [
      for (final t in tracks)
        if (t.id <= 0 && t.sourceId != 'local') t,
    ];
    if (todo.isEmpty) return tracks;
    await _db.batch((b) {
      for (final t in todo) {
        final row = TracksCompanion.insert(
          sourceId: Value(t.sourceId),
          uri: t.uri,
          folder: '',
          title: t.title,
          artist: Value(t.artist),
          album: Value(t.album),
          genre: Value(t.genre),
          durationMs: Value(t.durationMs),
          artworkPath: Value(t.artworkPath),
          searchText: Value(buildSearchText(title: t.title, artist: t.artist, album: t.album)),
        );
        // Keep the id (and favorites/playlists) when the same track comes again.
        b.insert(_db.tracks, row, onConflict: DoUpdate((_) => row, target: [_db.tracks.uri]));
      }
    });
    final rows = await (_db.select(_db.tracks)..where((r) => r.uri.isIn(todo.map((t) => t.uri).toSet()))).get();
    final byUri = {for (final r in rows) r.uri: LibraryRepository.rowToTrack(r)};
    return [for (final t in tracks) t.id > 0 || t.sourceId == 'local' ? t : (byUri[t.uri] ?? t)];
  }
}

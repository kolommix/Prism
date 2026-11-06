import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Folders the user picked for scanning.
class LibraryFolders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text().unique()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();
}

/// One row per audio file (or, later, per remote track).
@DataClassName('TrackRow')
class Tracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sourceId => text().withDefault(const Constant('local'))();

  /// Absolute path for local files. Unique so rescans can upsert.
  TextColumn get uri => text().unique()();

  /// Parent directory, used by the folders view.
  TextColumn get folder => text()();
  TextColumn get title => text()();
  TextColumn get artist => text().withDefault(const Constant(''))();
  TextColumn get album => text().withDefault(const Constant(''))();
  TextColumn get albumArtist => text().withDefault(const Constant(''))();
  TextColumn get genre => text().withDefault(const Constant(''))();
  IntColumn get year => integer().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get discNumber => integer().nullable()();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  TextColumn get artworkPath => text().nullable()();

  /// File size + mtime let the scanner skip unchanged files.
  IntColumn get fileSize => integer().withDefault(const Constant(0))();
  IntColumn get modifiedMs => integer().withDefault(const Constant(0))();

  /// Lower-cased, accent-free "title artist album" for fast LIKE search.
  TextColumn get searchText => text().withDefault(const Constant(''))();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  // ---- loudness (schema v2) ----
  /// ReplayGain values from the file's tags (dB, linear peak 0..1+).
  RealColumn get rgTrackGain => real().nullable()();
  RealColumn get rgTrackPeak => real().nullable()();
  RealColumn get rgAlbumGain => real().nullable()();
  RealColumn get rgAlbumPeak => real().nullable()();

  /// Measured by Prism with FFmpeg's EBU R128 scanner when tags are missing.
  RealColumn get loudnessLufs => real().nullable()();
  RealColumn get truePeakDb => real().nullable()();

  // ---- found online (schema v5) ----
  /// When Prism last looked this song up, so it isn't searched for again.
  IntColumn get infoCheckedMs => integer().nullable()();

  /// What the row held before info was found (JSON), for undo.
  TextColumn get infoOriginal => text().nullable()();
}

/// One row per finished listen (schema v3) – feeds smart playlists + stats.
class Plays extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackId => integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get playedAt => dateTime()();

  /// How long the user actually listened (ms), not the track length.
  IntColumn get listenedMs => integer()();
}

/// User-defined smart playlists (schema v3); rules are JSON.
@DataClassName('SmartPlaylistRow')
class SmartPlaylists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get json => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Lyrics cache (schema v3): LRC (synced) and/or plain text per track.
@DataClassName('LyricsRow')
class LyricsCache extends Table {
  IntColumn get trackId => integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  TextColumn get synced => text().nullable()();
  TextColumn get plain => text().nullable()();

  /// `lrc-file`, `embedded`, `lrclib`, or `none` (nothing found – don't ask again soon).
  TextColumn get source => text()();
  DateTimeColumn get fetchedAt => dateTime().withDefault(currentDateAndTime)();

  /// Manual timing fix for this song, added to the position (schema v6).
  IntColumn get offsetMs => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {trackId};
}

/// Non-destructive edits (schema v2): one edit decision list per track.
class TrackEdits extends Table {
  IntColumn get trackId => integer().references(Tracks, #id, onDelete: KeyAction.cascade)();

  /// `EditDecisionList` JSON (list of operations).
  TextColumn get json => text()();

  /// When true the player plays the track *with* the edit (live preset).
  BoolColumn get livePreset => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {trackId};
}

/// Playlist imports (schema v4): one job per imported list, so matching can
/// be paused/resumed and matches fixed later.
@DataClassName('ImportJobRow')
class ImportJobs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();

  /// `OnlineService` name (spotify, youtube, file…).
  TextColumn get origin => text()();
  TextColumn get sourceUrl => text().nullable()();

  /// Prism playlist created from this import (null until created).
  IntColumn get playlistId => integer().nullable().references(Playlists, #id, onDelete: KeyAction.setNull)();

  /// `matching`, `paused`, `review` (all matched), `done` (playlist created).
  TextColumn get state => text().withDefault(const Constant('matching'))();

  /// Why matching paused (offline, rate limit…).
  TextColumn get message => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// One song of an import: the service's metadata + what it was matched to.
@DataClassName('ImportItemRow')
class ImportItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get jobId => integer().references(ImportJobs, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();

  /// `ExternalTrack` JSON.
  TextColumn get json => text()();

  /// `pending`, `matched`, `unmatched`, `duplicate`, `skipped`.
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get trackId => integer().nullable().references(Tracks, #id, onDelete: KeyAction.setNull)();
  RealColumn get confidence => real().withDefault(const Constant(0))();

  /// `local`, `youtube`, `soundcloud`, `direct` (the linked video itself), `manual`.
  TextColumn get matchSource => text().nullable()();
  TextColumn get note => text().nullable()();

  /// Position of the earlier copy for duplicates.
  IntColumn get duplicateOf => integer().nullable()();
}

/// Favorites live in their own table so a tag rescan can never wipe them.
class Favorites extends Table {
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {trackId};
}

class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// `PlaylistSort` name the playlist is shown in (schema v7).
  TextColumn get sortMode => text().withDefault(const Constant('custom'))();
}

/// Ordered playlist items. The same track may appear more than once.
class PlaylistEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playlistId =>
      integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get trackId =>
      integer().references(Tracks, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
}

/// User themes (stored as the same JSON used for export/import).
class SavedThemes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get json => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// The single SQLite database of the app.
///
/// Feature repositories receive this object and own their queries; the
/// database class itself only defines schema + migrations.
@DriftDatabase(
  tables: [
    LibraryFolders,
    Tracks,
    Favorites,
    Playlists,
    PlaylistEntries,
    SavedThemes,
    TrackEdits,
    Plays,
    SmartPlaylists,
    LyricsCache,
    ImportJobs,
    ImportItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openDefault());

  /// Opens `prism.sqlite` in the app support directory.
  static QueryExecutor _openDefault() => driftDatabase(name: 'prism');

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement('CREATE INDEX IF NOT EXISTS idx_plays_time ON plays (played_at)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_plays_track ON plays (track_id)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_plays_track_time ON plays (track_id, played_at)');
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_tracks_album ON tracks (album, album_artist)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_tracks_artist ON tracks (artist)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_tracks_folder ON tracks (folder)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_entries_playlist ON playlist_entries (playlist_id, position)',
          );
          await customStatement('CREATE INDEX IF NOT EXISTS idx_import_items ON import_items (job_id, position)');
          await customStatement('CREATE INDEX IF NOT EXISTS idx_tracks_source ON tracks (source_id)');
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v2: loudness normalisation + non-destructive editor.
            await m.addColumn(tracks, tracks.rgTrackGain);
            await m.addColumn(tracks, tracks.rgTrackPeak);
            await m.addColumn(tracks, tracks.rgAlbumGain);
            await m.addColumn(tracks, tracks.rgAlbumPeak);
            await m.addColumn(tracks, tracks.loudnessLufs);
            await m.addColumn(tracks, tracks.truePeakDb);
            await m.createTable(trackEdits);
            // Force tags to be re-read so ReplayGain values get picked up.
            await customStatement('UPDATE tracks SET modified_ms = 0');
          }
          if (from < 3) {
            // v3: play history, smart playlists, lyrics cache.
            await m.createTable(plays);
            await m.createTable(smartPlaylists);
            await m.createTable(lyricsCache);
            await customStatement('CREATE INDEX IF NOT EXISTS idx_plays_time ON plays (played_at)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_plays_track ON plays (track_id)');
          }
          if (from < 4) {
            // v4: playlist imports; remote (streamed) tracks share `tracks`.
            await m.createTable(importJobs);
            await m.createTable(importItems);
            await customStatement('CREATE INDEX IF NOT EXISTS idx_import_items ON import_items (job_id, position)');
            await customStatement('CREATE INDEX IF NOT EXISTS idx_tracks_source ON tracks (source_id)');
          }
          if (from < 5) {
            // v5: covers and artists found online.
            await m.addColumn(tracks, tracks.infoCheckedMs);
            await m.addColumn(tracks, tracks.infoOriginal);
          }
          if (from < 6) {
            await m.addColumn(lyricsCache, lyricsCache.offsetMs);
          }
          if (from < 7) {
            await m.addColumn(playlists, playlists.sortMode);
            // Stats and smart playlists ask for one song's plays in a time window.
            await customStatement('CREATE INDEX IF NOT EXISTS idx_plays_track_time ON plays (track_id, played_at)');
          }
        },
        beforeOpen: (details) async {
          // Needed for ON DELETE CASCADE to work in SQLite.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

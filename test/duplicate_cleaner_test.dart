import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/db/app_database.dart';
import 'package:prism/features/library/data/library_repository.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/tools/application/duplicate_cleaner.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late LibraryRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LibraryRepository(db);
  });
  tearDown(() => db.close());

  Future<Track> add(String uri) async {
    await repo.upsertTracks([TracksCompanion.insert(uri: uri, folder: '/m', title: 'Song', artist: const Value('Band'))]);
    return LibraryRepository.rowToTrack(await (db.select(db.tracks)..where((t) => t.uri.equals(uri))).getSingle());
  }

  test('extras leave; playlists, likes and listens move to the kept copy', () async {
    final keep = await add('/m/song.flac');
    final mp3 = await add('/m/song.mp3');
    final m4a = await add('/m/song.m4a');
    final both = await db.into(db.playlists).insert(PlaylistsCompanion.insert(name: 'Both'));
    final onlyExtra = await db.into(db.playlists).insert(PlaylistsCompanion.insert(name: 'Extra'));
    await db.batch((b) {
      b.insertAll(db.playlistEntries, [
        PlaylistEntriesCompanion.insert(playlistId: both, trackId: keep.id, position: 0),
        PlaylistEntriesCompanion.insert(playlistId: both, trackId: mp3.id, position: 1),
        PlaylistEntriesCompanion.insert(playlistId: onlyExtra, trackId: m4a.id, position: 0),
      ]);
      b.insert(db.favorites, FavoritesCompanion.insert(trackId: Value(mp3.id)));
      b.insert(db.plays, PlaysCompanion.insert(trackId: m4a.id, playedAt: DateTime(2026), listenedMs: 60000));
    });

    final trashed = <String>[];
    final result = await DuplicateCleaner(repo, trash: (paths) async {
      trashed.addAll(paths);
      return paths.toSet();
    }).run([(keep, [keep, mp3, m4a])], deleteFiles: true);

    expect(result.removed, 2);
    expect(result.filesDeleted, 2);
    expect(trashed, unorderedEquals(['/m/song.mp3', '/m/song.m4a']), reason: 'never the kept file');
    expect((await db.select(db.tracks).get()).map((t) => t.uri), ['/m/song.flac']);
    final entries = await db.select(db.playlistEntries).get();
    expect(entries.where((e) => e.playlistId == both).map((e) => e.trackId), [keep.id], reason: 'not twice');
    expect(entries.where((e) => e.playlistId == onlyExtra).map((e) => e.trackId), [keep.id]);
    expect((await db.select(db.favorites).get()).map((f) => f.trackId), [keep.id]);
    expect((await db.select(db.plays).get()).single.trackId, keep.id);
    expect((await db.select(db.removedTracks).get()).map((r) => r.uri), unorderedEquals(['/m/song.mp3', '/m/song.m4a']),
        reason: 'rescans skip them');
  });

  test('without deleting files nothing is trashed', () async {
    final a = await add('/m/a.mp3');
    final b = await add('/m/b.mp3');
    var called = false;
    final result = await DuplicateCleaner(repo, trash: (p) async {
      called = true;
      return p.toSet();
    }).run([(a, [a, b])], deleteFiles: false);
    expect(result.removed, 1);
    expect(called, isFalse);
  });
}

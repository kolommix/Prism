import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/playlists/application/share_inbox.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/db/app_database.dart';
import 'package:prism/features/library/data/library_repository.dart';
import 'package:prism/features/library/data/library_scanner.dart';
import 'package:prism/features/library/data/search_text.dart';
import 'package:prism/features/library/domain/library_models.dart';
import 'package:prism/features/library/domain/tag_reader.dart';
import 'package:prism/features/playlists/data/playlist_repository.dart';

/// Returns tags based on the file name: "Artist - Title.mp3". Counts reads so
/// tests can check that unchanged files are skipped.
class FakeTagReader extends TagReader {
  int reads = 0;

  @override
  Future<AudioTags> read(String path, {bool withCover = true}) async {
    reads++;
    final name = p.basenameWithoutExtension(path);
    final parts = name.split(' - ');
    return AudioTags(
      artist: parts.length > 1 ? parts.first : null,
      title: parts.length > 1 ? parts.last : null,
      album: p.basename(p.dirname(path)),
      duration: const Duration(minutes: 3),
      coverBytes: name.contains('cover') ? Uint8List.fromList([0xFF, 0xD8, 0xFF, 0x00]) : null,
    );
  }
}

TracksCompanion row(String uri, String title, {String artist = '', String album = ''}) => TracksCompanion.insert(
      uri: uri,
      folder: p.dirname(uri),
      title: title,
      artist: Value(artist),
      album: Value(album),
      searchText: Value(buildSearchText(title: title, artist: artist, album: album)),
    );

void main() {
  late AppDatabase db;
  late LibraryRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = LibraryRepository(db);
  });
  tearDown(() => db.close());

  group('search', () {
    test('normalizes accents, case and punctuation', () {
      expect(normalizeForSearch('Beyoncé — AC/DC!'), 'beyonce — ac dc');
      expect(searchTokens('  Daft   PUNK '), ['daft', 'punk']);
    });

    test('every token must match somewhere', () async {
      await repo.upsertTracks([
        row('/m/a.mp3', 'One More Time', artist: 'Daft Punk', album: 'Discovery'),
        row('/m/b.mp3', 'Around the World', artist: 'Daft Punk', album: 'Homework'),
        row('/m/c.mp3', 'Café del Mar', artist: 'Energy 52'),
      ]);
      expect((await repo.search('daft')).length, 2);
      expect((await repo.search('daft discovery')).single.title, 'One More Time');
      expect((await repo.search('cafe')).single.artist, 'Energy 52');
      expect(await repo.search('nothing here'), isEmpty);
      expect(await repo.search('   '), isEmpty);
    });

    test('LIKE wildcards in the query are treated literally', () async {
      await repo.upsertTracks([row('/m/a.mp3', '100% Pure'), row('/m/b.mp3', '1000 Pure')]);
      expect((await repo.search('100%')).single.title, '100% Pure');
    });
  });

  group('repository', () {
    test('upsert by uri keeps the id (favorites survive rescans)', () async {
      await repo.upsertTracks([row('/m/a.mp3', 'Old title')]);
      final id = (await repo.search('old')).single.id;
      await repo.toggleFavorite(id);
      await repo.upsertTracks([row('/m/a.mp3', 'New title')]);
      final t = (await repo.search('new')).single;
      expect(t.id, id);
      expect(await repo.isFavorite(id), isTrue);
    });

    test('albums and artists are aggregated', () async {
      await repo.upsertTracks([
        row('/m/1.mp3', 'a', artist: 'X', album: 'A1'),
        row('/m/2.mp3', 'b', artist: 'X', album: 'A1'),
        row('/m/3.mp3', 'c', artist: 'X', album: 'A2'),
        row('/m/4.mp3', 'd', artist: 'Y', album: 'B'),
      ]);
      final albums = await repo.watchAlbums().first;
      expect(albums.map((a) => (a.name, a.trackCount)), containsAll([('A1', 2), ('A2', 1), ('B', 1)]));
      final artists = await repo.watchArtists().first;
      final x = artists.firstWhere((a) => a.name == 'X');
      expect((x.trackCount, x.albumCount), (3, 2));
    });

    test('tracksByIds keeps the requested order and skips missing ids', () async {
      await repo.upsertTracks([row('/m/1.mp3', 'a'), row('/m/2.mp3', 'b'), row('/m/3.mp3', 'c')]);
      final all = await repo.watchTracks().first;
      final idOf = {for (final t in all) t.title: t.id};
      final got = await repo.tracksByIds([idOf['c']!, 999, idOf['a']!]);
      expect(got.map((t) => t.title), ['c', 'a']);
    });

    test('removeFolder deletes only that folder (not a prefix sibling)', () async {
      final sep = p.separator;
      await repo.addFolder('${sep}music');
      await repo.upsertTracks([
        row('${sep}music${sep}a.mp3', 'a'),
        row('${sep}music2${sep}b.mp3', 'b'),
      ]);
      await repo.removeFolder('${sep}music');
      final left = await repo.watchTracks().first;
      expect(left.single.title, 'b');
    });
  });

  group('scanner', () {
    late Directory root;
    late Directory artDir;
    late FakeTagReader tags;
    late LibraryScanner scanner;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('prism_scan_');
      artDir = Directory(p.join(root.path, '_art'));
      tags = FakeTagReader();
      scanner = LibraryScanner(repository: repo, tagReader: tags, artworkDir: artDir, batchSize: 2);
    });
    tearDown(() => root.delete(recursive: true));

    Future<File> touch(String rel) async {
      final f = File(p.join(root.path, rel));
      await f.create(recursive: true);
      await f.writeAsString('fake audio $rel');
      return f;
    }

    test('finds supported files only, reads tags, falls back to file name', () async {
      await touch('Album A/Daft Punk - One More Time.mp3');
      await touch('Album A/Untagged.flac');
      await touch('Album B/sub/Artist - Song cover.m4a');
      await touch('Album B/notes.txt');
      await touch('Album B/image.jpg');

      final events = await scanner.scanFolders([root.path]).toList();
      final done = events.last as ScanFinished;
      expect(done.added, 3);

      final tracks = await repo.watchTracks().first;
      expect(tracks.map((t) => t.title), containsAll(['One More Time', 'Untagged', 'Song cover']));
      final omt = tracks.firstWhere((t) => t.title == 'One More Time');
      expect(omt.artist, 'Daft Punk');
      expect(omt.album, 'Album A');
      expect(omt.durationMs, 180000);
      // Cover written to the artwork cache.
      final withArt = tracks.firstWhere((t) => t.title == 'Song cover');
      expect(withArt.artworkPath, isNotNull);
      expect(File(withArt.artworkPath!).existsSync(), isTrue);
    });

    test('rescan skips unchanged files and removes deleted ones', () async {
      await touch('a/X - One.mp3');
      final gone = await touch('a/X - Two.ogg');
      await scanner.scanFolders([root.path]).drain<void>();
      expect(tags.reads, 2);

      await gone.delete();
      final events = await scanner.scanFolders([root.path]).toList();
      final done = events.last as ScanFinished;
      expect(tags.reads, 2, reason: 'unchanged file must not be re-read');
      expect((done.added, done.updated, done.removed), (0, 0, 1));
      expect((await repo.watchTracks().first).single.title, 'One');
    });

    test('missing root folder is ignored', () async {
      final events = await scanner.scanFolders([p.join(root.path, 'does-not-exist')]).toList();
      expect((events.last as ScanFinished).added, 0);
    });

    test('dropped songs join the library at once, without their folder', () async {
      final a = await touch('Downloads/Daft Punk - One More Time.mp3');
      final b = await touch('Downloads/Untagged.flac');
      await touch('Downloads/other.mp3'); // not dropped
      final events = await scanner.scanFiles([a.path, b.path, p.join(root.path, 'Downloads', 'readme.txt')]).toList();
      expect((events.last as ScanFinished).added, 2);
      expect((await repo.watchTracks().first).map((t) => t.title), unorderedEquals(['One More Time', 'Untagged']));
      expect(await repo.folders(), isEmpty, reason: 'only the songs, not the whole folder');

      // A scan of the library folders later leaves them alone.
      await touch('Library/X - Song.mp3');
      await scanner.scanFolders([p.join(root.path, 'Library')]).drain<void>();
      expect(await repo.watchTracks().first, hasLength(3));
    });

    test('what was dropped: songs, folders, and playlists for import', () async {
      final song = await touch('d/a.MP3');
      final list = await touch('d/list.m3u');
      final folder = Directory(p.join(root.path, 'album'))..createSync();
      final (songs, folders, others) = await DeepLinks.sortDropped([list.path, folder.path, song.path]);
      expect(songs, [song.path]);
      expect(folders, [folder.path]);
      expect(others, [list.path]);
    });
  });

  group('playlists', () {
    late PlaylistRepository playlists;
    late List<int> trackIds;

    setUp(() async {
      playlists = PlaylistRepository(db);
      await repo.upsertTracks([for (var i = 1; i <= 4; i++) row('/m/$i.mp3', 'S$i')]);
      trackIds = [for (final t in await repo.watchTracks().first) t.id];
    });

    Future<List<String>> titles(int id) async => [for (final i in await playlists.watchItems(id).first) i.track.title];

    test('create, add, reorder, remove, rename, delete', () async {
      final id = await playlists.create('  Road trip  ');
      await playlists.addTracks(id, trackIds);
      expect(await titles(id), ['S1', 'S2', 'S3', 'S4']);

      await playlists.move(id, 0, 3);
      expect(await titles(id), ['S2', 'S3', 'S4', 'S1']);

      final items = await playlists.watchItems(id).first;
      await playlists.removeEntry(id, items[1].entryId);
      expect(await titles(id), ['S2', 'S4', 'S1']);

      await playlists.rename(id, 'Night drive');
      final list = await playlists.watchPlaylists().first;
      expect((list.single.name, list.single.trackCount), ('Night drive', 3));

      await playlists.delete(id);
      expect(await playlists.watchPlaylists().first, isEmpty);
    });

    test('same song can be added twice; empty names get a default', () async {
      final id = await playlists.create('   ');
      await playlists.addTracks(id, [trackIds[0], trackIds[0]]);
      expect(await titles(id), ['S1', 'S1']);
      expect((await playlists.watchPlaylists().first).single.name, 'New playlist');
    });

    test('deleting a track removes it from playlists (cascade)', () async {
      final id = await playlists.create('p');
      await playlists.addTracks(id, trackIds);
      await repo.deleteByUris(['/m/2.mp3']);
      expect(await titles(id), ['S1', 'S3', 'S4']);
    });
  });
}

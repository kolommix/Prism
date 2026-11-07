import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show OrderingTerm, Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/db/app_database.dart';
import 'package:prism/features/library/data/library_repository.dart';
import 'package:prism/features/library/data/library_scanner.dart';
import 'package:prism/features/library/domain/tag_reader.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/online/application/import_flow.dart';
import 'package:prism/features/online/data/import_repository.dart';
import 'package:prism/features/online/data/remote_track_store.dart';
import 'package:prism/features/online/domain/external_track.dart';
import 'package:prism/features/online/domain/import_intake.dart';
import 'package:prism/features/online/domain/link_parser.dart';
import 'package:prism/features/online/domain/online_error.dart';
import 'package:prism/features/online/services/public_links/public_readers.dart';
import 'package:prism/features/playlists/application/share_inbox.dart';
import 'package:prism/l10n/l10n.dart';

import '../tool/privacy_check.dart';

Uint8List _bytes(List<int> b) => Uint8List.fromList(b);

class _NoTags extends TagReader {
  @override
  Future<AudioTags> read(String path, {bool withCover = true}) async => const AudioTags();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('link detection', () {
    final cases = <String, (OnlineService, LinkKind, String)>{
      'https://open.spotify.com/playlist/37i9dQZF1DX?si=abc': (OnlineService.spotify, LinkKind.playlist, '37i9dQZF1DX'),
      'https://open.spotify.com/intl-de/album/4aawy': (OnlineService.spotify, LinkKind.album, '4aawy'),
      'https://open.spotify.com/user/someone/playlist/7abc': (OnlineService.spotify, LinkKind.playlist, '7abc'),
      'spotify:playlist:37i9': (OnlineService.spotify, LinkKind.playlist, '37i9'),
      'https://spotify.link/xyz': (OnlineService.spotify, LinkKind.shortLink, ''),
      'https://www.youtube.com/playlist?list=PL123': (OnlineService.youtube, LinkKind.playlist, 'PL123'),
      'https://music.youtube.com/playlist?list=OLAK5': (OnlineService.youtube, LinkKind.playlist, 'OLAK5'),
      'https://www.youtube.com/watch?v=abc&list=PL9': (OnlineService.youtube, LinkKind.playlist, 'PL9'),
      'https://youtu.be/abc?list=PL7': (OnlineService.youtube, LinkKind.playlist, 'PL7'),
      'https://youtu.be/abc': (OnlineService.youtube, LinkKind.track, 'abc'),
      'https://soundcloud.com/artist/sets/best': (OnlineService.soundcloud, LinkKind.playlist, 'artist/sets/best'),
      'https://on.soundcloud.com/AbC': (OnlineService.soundcloud, LinkKind.shortLink, ''),
      'https://music.yandex.ru/users/me/playlists/1001': (OnlineService.yandex, LinkKind.playlist, 'me:1001'),
      'https://music.yandex.com/album/42': (OnlineService.yandex, LinkKind.album, '42'),
      'https://music.yandex.ru/playlists/lk.abc-def': (OnlineService.yandex, LinkKind.playlist, 'lk.abc-def'),
      'https://music.apple.com/us/playlist/hits/pl.u-123': (OnlineService.appleMusic, LinkKind.playlist, 'pl.u-123'),
      'https://www.deezer.com/en/playlist/908622995': (OnlineService.deezer, LinkKind.playlist, '908622995'),
      'https://dzr.page.link/abc': (OnlineService.deezer, LinkKind.shortLink, ''),
    };
    cases.forEach((url, want) {
      test(url, () {
        final l = parseMusicLink(url)!;
        expect((l.service, l.kind, l.id), want);
      });
    });

    test('finds the link inside the text a share sheet sends', () {
      expect(
        findMusicLink('Listen on Spotify: https://open.spotify.com/playlist/37i9?si=1. Enjoy!')?.id,
        '37i9',
      );
      expect(findMusicLink('Мой плейлист https://music.yandex.ru/users/me/playlists/7 «Лето»')?.id, 'me:7');
      expect(findMusicLink('(https://www.deezer.com/playlist/55)')?.id, '55');
      expect(findMusicLink('open.spotify.com/album/abc')?.kind, LinkKind.album);
      expect(findMusicLink('look at https://example.com/x then https://youtu.be/q')?.id, 'q');
    });

    test('ignores what is not a music link', () {
      for (final text in ['', 'hello there', 'https://example.com/playlist/1', 'https://www.youtube.com/@channel', 'C:\\music\\song.mp3']) {
        expect(findMusicLink(text), isNull, reason: text);
      }
      // A mix is made per viewer: it can't be imported, the song can.
      expect(parseMusicLink('https://www.youtube.com/watch?v=abc&list=RDabc')?.kind, LinkKind.track);
    });

    test('tracking bits do not make it a different playlist', () {
      final a = parseMusicLink('https://open.spotify.com/playlist/37i9?si=one')!;
      final b = parseMusicLink('https://open.spotify.com/intl-de/playlist/37i9?si=two')!;
      expect(a.canonicalUrl, b.canonicalUrl);
      final c = parseMusicLink('https://www.youtube.com/watch?v=x&list=PL1')!;
      expect(c.canonicalUrl, 'https://www.youtube.com/playlist?list=PL1');
      // It still reads back as the same link: that is what a re-sync opens.
      for (final url in ['https://soundcloud.com/a/sets/b?si=9', 'https://music.yandex.ru/users/me/playlists/7?x=1', 'https://music.apple.com/us/album/x/12?i=34']) {
        final l = parseMusicLink(url)!;
        expect(parseMusicLink(l.canonicalUrl), l, reason: url);
      }
    });

    test('a list is offered from the clipboard, one song is not', () {
      expect(parseMusicLink('https://open.spotify.com/playlist/1')!.isList, isTrue);
      expect(parseMusicLink('https://youtu.be/q')!.isList, isFalse);
    });

    test('classifies link, shared playlist, file and rubbish', () {
      expect(classifyImportText('see https://youtu.be/q'), isA<ServiceLinkInput>());
      expect(classifyImportText('liner://p/abc'), isA<SharedPlaylistInput>());
      expect(classifyImportText('C:\\exports\\mine.csv'), isA<FileInput>());
      expect(classifyImportText('D:\\x\\list.M3U8'), isA<FileInput>());
      expect(classifyImportText('D:\\x\\song.mp3'), isA<UnknownInput>());
      expect(classifyImportText('   '), isA<UnknownInput>());
    });
  });

  group('things arriving from outside', () {
    test('share text, a dropped file, an Android file, the same share twice', () async {
      final got = <ImportRequest>[];
      final links = DeepLinks(got.add);
      await links.handle('Listen https://open.spotify.com/playlist/1');
      expect(got.single.text, contains('open.spotify.com'));

      final dir = await Directory.systemTemp.createTemp('prism_drop_');
      final file = File(p.join(dir.path, 'mine.csv'));
      await file.writeAsString('title,artist\nOne,A\n');
      await links.handle(file.path);
      expect(got.last.fileName, file.path);
      expect(got.last.fileText, contains('One,A'));
      await dir.delete(recursive: true);

      await links.handle({'name': 'shared.m3u', 'text': '#EXTM3U'});
      expect(got.last.fileName, 'shared.m3u');
      final before = got.length;
      await links.handle({'name': 'shared.m3u', 'text': '#EXTM3U'});
      expect(got.length, before, reason: 'a start value and a message can be the same share');
    });

    test('command line: only what is meant for import', () {
      expect(classifyImportText('--some-flag'), isA<UnknownInput>());
      expect(classifyImportText('liner://p/x'), isA<SharedPlaylistInput>());
    });
  });

  group('friendly errors', () {
    final link = parseMusicLink('https://open.spotify.com/playlist/1');

    test('a private playlist says what to do', () {
      final p = importProblemFor(OnlineException(OnlineErrorKind.notFound, service: OnlineService.spotify), link: link);
      expect(p.message, l10n.importErrorPrivate);
      expect(p.message, contains('public'));
      expect(p.step, ImportNextStep.chooseFile);
    });

    test('every kind has a next step except a retry-less one', () {
      for (final kind in OnlineErrorKind.values) {
        final p = importProblemFor(OnlineException(kind, service: OnlineService.deezer));
        expect(p.message, isNotEmpty);
        expect(p.step, isNot(ImportNextStep.none), reason: kind.name);
      }
    });

    test('offline retries, a missing key goes to set-up, a blocked region to a file', () {
      expect(importProblemFor(OnlineException(OnlineErrorKind.offline)).step, ImportNextStep.tryAgain);
      expect(importProblemFor(OnlineException(OnlineErrorKind.notConfigured, service: OnlineService.soundcloud)).step, ImportNextStep.advanced);
      final blocked = importProblemFor(OnlineException(OnlineErrorKind.forbidden, service: OnlineService.yandex, isRegionBlocked: true));
      expect(blocked.step, ImportNextStep.chooseFile);
      expect(blocked.message, contains('country'));
    });
  });

  group('Spotify public page', () {
    String page(Map<String, Object?> entity) =>
        '<html><script id="__NEXT_DATA__" type="application/json">'
        '${jsonEncode({'props': {'pageProps': {'state': {'data': {'entity': entity}}}}})}'
        '</script></html>';

    test('reads a playlist', () {
      final list = parseSpotifyEmbed(page({
        'type': 'playlist',
        'name': 'Road',
        'trackList': [
          {'uri': 'spotify:track:aa', 'title': 'One', 'subtitle': 'Ashe, Finneas', 'duration': 198840},
          {'uri': 'spotify:track:bb', 'title': '', 'subtitle': 'skipped'},
        ],
      }), sourceUrl: 'https://open.spotify.com/playlist/1')!;
      expect(list.name, 'Road');
      expect(list.tracks.single.title, 'One');
      expect(list.tracks.single.artists, ['Ashe', 'Finneas']);
      expect(list.tracks.single.durationMs, 198840);
      expect(list.tracks.single.externalId, 'aa');
      expect(list.sourceUrl, 'https://open.spotify.com/playlist/1');
    });

    test('reads one song', () {
      final list = parseSpotifyEmbed(page({
        'type': 'track',
        'id': 'cc',
        'name': 'Solo',
        'artists': [{'name': 'Carly'}],
        'duration': 200000,
      }))!;
      expect(list.tracks.single.artists, ['Carly']);
    });

    test('no list means private or gone; a changed page says so', () {
      expect(parseSpotifyEmbed(page({'type': 'playlist', 'name': 'Empty', 'trackList': []})), isNull);
      expect(
        () => parseSpotifyEmbed('<html>new layout</html>'),
        throwsA(isA<OnlineException>().having((e) => e.kind, 'kind', OnlineErrorKind.badResponse)),
      );
    });
  });

  group('privacy check', () {
    const ok = '<manifest><uses-permission android:name="android.permission.INTERNET"/>'
        '<uses-permission\n android:name="com.kolommix.prism.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION" /></manifest>';

    test('passes what docs/PRIVACY.md lists', () => expect(checkManifest(ok), isEmpty));

    test('fails on a location permission, however it is written', () {
      for (final name in ['ACCESS_FINE_LOCATION', 'ACCESS_COARSE_LOCATION', 'ACCESS_BACKGROUND_LOCATION']) {
        expect(checkManifest('<uses-permission android:name="android.permission.$name"/>').single, contains('LOCATION'));
        expect(checkManifest('<uses-permission-sdk-23\n  android:name="android.permission.$name" />').single, contains('LOCATION'));
      }
    });

    test('fails on any permission not on the list', () {
      expect(checkManifest('<uses-permission android:name="android.permission.READ_CONTACTS"/>'), hasLength(1));
    });

    test('fails on packages that read location or report home', () {
      expect(checkLock('packages:\n  http:\n    x\n  permission_handler_android:\n    y\n'), isEmpty);
      for (final name in ['permission_handler_windows', 'permission_handler', 'geolocator', 'firebase_core', 'sentry_flutter', 'device_info_plus']) {
        expect(checkLock('packages:\n  $name:\n    x\n'), hasLength(1), reason: name);
      }
    });

    test('this project is clean', () {
      expect(checkLock(File('pubspec.lock').readAsStringSync()), isEmpty);
    });

    test('spots the Windows location API in a binary', () {
      final ascii = 'xx Windows.Devices.Geolocation.Geolocator yy'.codeUnits;
      final wide = [for (final c in 'Windows.Devices.Geolocation'.codeUnits) ...[c, 0]];
      expect(mentionsGeolocation(_bytes(ascii)), isTrue);
      expect(mentionsGeolocation(_bytes(wide)), isTrue);
      expect(mentionsGeolocation(_bytes('Windows.Devices.Radios'.codeUnits)), isFalse);
    });
  });

  group('import repository', () {
    late AppDatabase db;
    late ImportRepository repo;
    late RemoteTrackStore store;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = ImportRepository(db);
      store = RemoteTrackStore(db);
    });
    tearDown(() => db.close());

    ExternalTrack song(String id, [String? title]) =>
        ExternalTrack(service: OnlineService.spotify, title: title ?? 'Song $id', artists: const ['A'], externalId: id);
    ImportedList list(List<ExternalTrack> tracks) =>
        ImportedList(name: 'Mix', origin: OnlineService.spotify, sourceUrl: 'https://open.spotify.com/playlist/1', tracks: tracks);
    Future<Track> track(String v) => store.ensure(
          Track(id: 0, sourceId: 'youtube', uri: 'https://www.youtube.com/watch?v=$v', title: v, artist: 'A'),
        );
    Future<List<int>> playlistOf(int jobId) async {
      final job = (await repo.watchJob(jobId).first)!;
      final rows = await (db.select(db.playlistEntries)
            ..where((e) => e.playlistId.equals(job.playlistId!))
            ..orderBy([(e) => OrderingTerm(expression: e.position)]))
          .get();
      return [for (final r in rows) r.trackId];
    }

    test('songs reach the playlist as they are found, nothing empty is created', () async {
      final id = await repo.createJob(list([song('1'), song('2')]));
      expect(await repo.writePlaylist(id, finish: false), isNull, reason: 'no empty playlists');
      final items = await repo.watchItems(id).first;
      final t1 = await track('one');
      await repo.saveMatch(items[0].id, trackId: t1.id, confidence: 0.9, source: 'youtube');
      expect(await repo.writePlaylist(id, finish: false), isNotNull);
      expect(await playlistOf(id), [t1.id]);
      expect((await repo.watchJob(id).first)!.state, ImportJobState.matching, reason: 'still going');
    });

    test('review: only what needs a decision, and a decision is final', () async {
      final id = await repo.createJob(list([song('1'), song('2'), song('3')]));
      final items = await repo.watchItems(id).first;
      final t = await track('x');
      await repo.saveMatch(items[0].id, trackId: t.id, confidence: 0.95, source: 'youtube');
      await repo.saveMatch(items[1].id, trackId: t.id, confidence: 0.55, source: 'youtube');
      await repo.saveMatch(items[2].id, trackId: null, confidence: 0.1);

      var review = await repo.watchReview().first;
      expect(review.map((i) => i.wanted.title), ['Song 2', 'Song 3']);
      expect(review.first.jobName, 'Mix');
      expect((await repo.watchJob(id).first)!.lowConfidence, 1);

      await repo.acceptMatch(review[0].id);
      await repo.rejectMatch(review[1].id);
      review = await repo.watchReview().first;
      expect(review, isEmpty);
      expect((await repo.watchJob(id).first)!.lowConfidence, 0);
      final after = await repo.watchItems(id).first;
      expect(after[1].needsReview, isFalse);
      expect(after[1].status, ImportItemStatus.matched);
      expect(after[2].needsReview, isFalse);
    });

    test('searching again keeps "no match" decisions', () async {
      final id = await repo.createJob(list([song('1'), song('2')]));
      final items = await repo.watchItems(id).first;
      await repo.saveMatch(items[0].id, trackId: null, confidence: 0.1);
      await repo.rejectMatch(items[1].id);
      await repo.requeueUnmatched(id);
      expect((await repo.pendingItems(id)).map((i) => i.wanted.title), ['Song 1']);
    });

    test('re-sync adds new songs, drops gone ones, keeps matches and decisions, follows the order', () async {
      final id = await repo.createJob(list([song('1'), song('2'), song('3')]));
      final items = await repo.watchItems(id).first;
      final t1 = await track('one');
      final t3 = await track('three');
      await repo.saveMatch(items[0].id, trackId: t1.id, confidence: 0.6, source: manualSource);
      await repo.saveMatch(items[1].id, trackId: t1.id, confidence: 0.9, source: 'youtube');
      await repo.saveMatch(items[2].id, trackId: t3.id, confidence: 0.9, source: 'youtube');

      final r = await repo.resync(id, list([song('3'), song('4'), song('1', 'Song 1 (renamed)')]));
      expect(r.added, 1);
      expect(r.removed, 1);
      final now = await repo.watchItems(id).first;
      expect(now.map((i) => i.wanted.title), ['Song 3', 'Song 4', 'Song 1 (renamed)']);
      expect(now[0].track?.id, t3.id);
      expect(now[1].status, ImportItemStatus.pending);
      expect(now[2].track?.id, t1.id);
      expect(now[2].decided, isTrue, reason: 'the user already said yes');
    });

    test('importing the same source twice is found, so it syncs instead of copying', () async {
      final id = await repo.createJob(list([song('1')]));
      expect((await repo.jobForSource('https://open.spotify.com/playlist/1'))?.id, id);
      expect(await repo.jobForSource('https://open.spotify.com/playlist/2'), isNull);
    });

    test('rewriting a playlist leaves songs added by hand alone', () async {
      final id = await repo.createJob(list([song('1'), song('2')]));
      final items = await repo.watchItems(id).first;
      final t1 = await track('one');
      final t2 = await track('two');
      final mine = await track('mine');
      await repo.saveMatch(items[0].id, trackId: t1.id, confidence: 0.9, source: 'youtube');
      final playlistId = (await repo.writePlaylist(id))!;
      await db.into(db.playlistEntries).insert(
            PlaylistEntriesCompanion.insert(playlistId: playlistId, trackId: mine.id, position: 1),
          );
      await repo.saveMatch(items[1].id, trackId: t2.id, confidence: 0.9, source: 'youtube');
      await repo.writePlaylist(id);
      expect(await playlistOf(id), [t1.id, t2.id, mine.id]);

      // A changed match replaces the old song, it doesn't stay as "by hand".
      await repo.saveMatch(items[0].id, trackId: t2.id, confidence: 1, source: manualSource);
      await repo.writePlaylist(id);
      expect(await playlistOf(id), [t2.id, t2.id, mine.id]);
    });

    test('only known sources can re-sync', () {
      ImportJob job(String? url, OnlineService origin) =>
          ImportJob(id: 1, name: 'x', origin: origin, sourceUrl: url, state: ImportJobState.done, createdAt: DateTime(2026), updatedAt: DateTime(2026));
      expect(ImportFlow.canResync(job('https://open.spotify.com/playlist/1', OnlineService.spotify)), isTrue);
      expect(ImportFlow.canResync(job('C:\\x.csv#Mix', OnlineService.file)), isTrue);
      expect(ImportFlow.canResync(job(null, OnlineService.file)), isFalse);
    });
  });

  group('remove from Prism', () {
    late AppDatabase db;
    late LibraryRepository repo;
    late Directory root;
    late LibraryScanner scanner;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = LibraryRepository(db);
      root = await Directory.systemTemp.createTemp('prism_remove_');
      scanner = LibraryScanner(repository: repo, tagReader: _NoTags(), artworkDir: Directory(p.join(root.path, '_art')));
    });
    tearDown(() async {
      await db.close();
      await root.delete(recursive: true);
    });

    Future<void> scan() async {
      await repo.addFolder(root.path);
      await scanner.scanAll().drain<void>();
    }

    test('the file stays, a rescan does not bring it back, restore does', () async {
      final file = File(p.join(root.path, 'Song.mp3'));
      await file.writeAsString('audio');
      await scan();
      final song = (await repo.watchTracks().first).single;

      await repo.removeFromLibrary([song]);
      expect(await repo.watchTracks().first, isEmpty);
      expect(file.existsSync(), isTrue, reason: 'never the file');
      expect((await repo.watchRemoved().first).single.title, song.title);

      await scan();
      expect(await repo.watchTracks().first, isEmpty, reason: 'rescan skips it');

      await repo.restoreRemoved(song.uri);
      await scan();
      expect((await repo.watchTracks().first).single.uri, song.uri);
    });

    test('undo puts back favorites, plays and playlist places', () async {
      await File(p.join(root.path, 'Song.mp3')).writeAsString('audio');
      await scan();
      final song = (await repo.watchTracks().first).single;
      final playlist = await db.into(db.playlists).insert(PlaylistsCompanion.insert(name: 'P'));
      await db.into(db.playlistEntries).insert(PlaylistEntriesCompanion.insert(playlistId: playlist, trackId: song.id, position: 0));
      await db.into(db.favorites).insert(FavoritesCompanion.insert(trackId: Value(song.id)));

      final undo = await repo.removeFromLibrary([song]);
      expect(await db.select(db.playlistEntries).get(), isEmpty);
      expect(await db.select(db.favorites).get(), isEmpty);

      await undo();
      expect((await repo.watchTracks().first).single.id, song.id);
      expect(await db.select(db.playlistEntries).get(), hasLength(1));
      expect(await db.select(db.favorites).get(), hasLength(1));
      expect(await repo.watchRemoved().first, isEmpty);
    });

    test('removing the folder forgets its removed songs', () async {
      await File(p.join(root.path, 'Song.mp3')).writeAsString('audio');
      await scan();
      await repo.removeFromLibrary(await repo.watchTracks().first);
      await repo.removeFolder(root.path);
      expect(await repo.watchRemoved().first, isEmpty);
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prism/core/db/app_database.dart';
import 'package:prism/core/providers.dart';
import 'package:prism/features/desktop/data/cover_lookup.dart';
import 'package:prism/features/library/application/auto_tagger.dart';
import 'package:prism/features/library/data/library_repository.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/settings/application/settings_controller.dart';
import 'package:prism/features/settings/domain/app_settings.dart';

void main() {
  group('what may change', () {
    final info = CoverInfo(title: 'Black Knife', artist: 'Toby Fox', album: 'Deltarune', genre: 'Soundtrack', year: 2025);

    test('a song without tags gets everything', () {
      final c = autoTagChangeFor(const Track(id: 1, uri: 'x', title: '30_Black_Knife'), info, '/c.jpg')!;
      expect((c.title, c.artist, c.album, c.genre, c.year, c.artworkPath), ('Black Knife', 'Toby Fox', 'Deltarune', 'Soundtrack', 2025, '/c.jpg'));
    });

    test('your own tags are never replaced', () {
      final c = autoTagChangeFor(
        const Track(id: 1, uri: 'x', title: 'My Title', artist: 'My Band', album: 'My LP', genre: 'Rock', year: 1999),
        info,
        '/c.jpg',
      )!;
      expect((c.title, c.artist, c.album, c.genre, c.year), (null, null, null, null, null));
      expect(c.artworkPath, '/c.jpg');
    });

    test('nothing to add = no change', () {
      expect(
        autoTagChangeFor(
          const Track(id: 1, uri: 'x', title: 'T', artist: 'A', album: 'L', genre: 'G', year: 1, artworkPath: '/own.jpg'),
          info,
          null,
        ),
        isNull,
      );
    });
  });

  group('the whole run on a real database', () {
    late AppDatabase db;
    late LibraryRepository repo;
    late Directory dir;
    late ProviderContainer c;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = LibraryRepository(db);
      dir = await Directory.systemTemp.createTemp('prism_autotag_');
      c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          artworkDirProvider.overrideWithValue(dir),
          initialSettingsProvider.overrideWithValue(const AppSettings(autoFindInfo: false)),
        ],
      );
      await repo.upsertTracks([
        for (final (uri, title, artist) in const [
          ('/m/1.mp3', '30_Black_Knife_DELTARUNE_Toby_Fox', ''),
          ('/m/2.mp3', 'Nothing Known', ''),
          ('/m/3.mp3', 'Own Song', 'Own Band'),
        ])
          TracksCompanion.insert(
            uri: uri,
            folder: '/m',
            title: title,
            artist: Value(artist),
            durationMs: const Value(121000),
            searchText: Value(title.toLowerCase()),
          ),
      ]);
    });

    tearDown(() async {
      c.dispose();
      await db.close();
      await dir.delete(recursive: true);
    });

    http.Client service({bool fail = false}) => MockClient((req) async {
          if (fail) return http.Response('slow down', 403);
          if (req.url.host.contains('example')) return http.Response.bytes(utf8.encode('jpeg bytes'), 200);
          if (!req.url.host.contains('itunes')) return http.Response('{"data":[]}', 200);
          final q = (req.url.queryParameters['term'] ?? '').toLowerCase();
          if (q.contains('black knife') || q.contains('own band')) {
            final own = q.contains('own band');
            return http.Response(
              jsonEncode({
                'results': [
                  {
                    'trackName': own ? 'Own Song' : 'Black Knife',
                    'artistName': own ? 'Own Band' : 'Toby Fox',
                    'collectionName': 'Deltarune',
                    'primaryGenreName': 'Soundtrack',
                    'releaseDate': '2025-06-04T07:00:00Z',
                    'trackTimeMillis': 121000,
                    'artworkUrl100': 'https://example.com/100x100bb.jpg',
                  },
                ],
              }),
              200,
            );
          }
          return http.Response('{"results":[]}', 200);
        });

    Future<List<Track>> songs() => repo.watchTracks().first;
    Track byUri(List<Track> l, String u) => l.firstWhere((t) => t.uri == u);

    test('fills songs in, keeps tags, downloads one cover, can be undone', () async {
      final tagger = c.read(autoTaggerProvider.notifier);
      await tagger.start(client: service(), pace: Duration.zero);

      final l = await songs();
      final knife = byUri(l, '/m/1.mp3');
      expect((knife.title, knife.artist, knife.album, knife.year), ('Black Knife', 'Toby Fox', 'Deltarune', 2025));
      expect(File(knife.artworkPath!).readAsStringSync(), 'jpeg bytes');
      expect(byUri(l, '/m/2.mp3').title, 'Nothing Known', reason: 'no result: unchanged');
      final own = byUri(l, '/m/3.mp3');
      expect((own.title, own.artist), ('Own Song', 'Own Band'));
      expect(own.artworkPath, isNotNull, reason: 'only the missing cover is added');
      expect(c.read(autoTaggerProvider).found, 2);
      expect(await repo.search('toby'), hasLength(1), reason: 'search knows the new artist');

      // Not looked up twice.
      expect(await repo.tracksMissingInfo(), isEmpty);

      expect(await tagger.undoAll(), 2);
      final back = await songs();
      expect((byUri(back, '/m/1.mp3').title, byUri(back, '/m/1.mp3').artist), ('30_Black_Knife_DELTARUNE_Toby_Fox', ''));
      expect(byUri(back, '/m/3.mp3').artworkPath, isNull);
      expect(await repo.tracksMissingInfo(), isEmpty, reason: 'undone songs stay as they are');

      await repo.clearInfoChecks();
      expect(await repo.tracksMissingInfo(), hasLength(3), reason: 'Look again');
    });

    test('services not answering: songs stay on the list, it stops and says so', () async {
      await c.read(autoTaggerProvider.notifier).start(client: service(fail: true), pace: Duration.zero);
      final s = c.read(autoTaggerProvider);
      expect((s.running, s.found), (false, 0));
      expect(s.note, contains('not answering'));
      expect(await repo.tracksMissingInfo(), hasLength(3));
    });

    test('a rescan of a changed file takes what the file says', () async {
      await c.read(autoTaggerProvider.notifier).start(client: service(), pace: Duration.zero);
      await repo.upsertTracks([
        TracksCompanion.insert(
          uri: '/m/1.mp3',
          folder: '/m',
          title: 'Tagged Now',
          artist: const Value('New Artist'),
          album: const Value(''),
          artworkPath: const Value(null),
          infoCheckedMs: const Value(null),
          infoOriginal: const Value(null),
        ),
      ]);
      final t = byUri(await songs(), '/m/1.mp3');
      expect((t.title, t.artist), ('Tagged Now', 'New Artist'));
      expect(await repo.undoAutoTags(), 1, reason: 'only the other song is left to undo');
    });
  });
}

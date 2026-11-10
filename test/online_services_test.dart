import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prism/core/db/app_database.dart';
import 'package:prism/features/library/data/library_repository.dart';
import 'package:prism/features/library/data/search_text.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/online/application/match_service.dart';
import 'package:prism/features/online/data/import_repository.dart';
import 'package:prism/features/online/data/oauth.dart';
import 'package:prism/features/online/data/online_http.dart';
import 'package:prism/features/online/data/remote_track_store.dart';
import 'package:prism/features/online/data/stream_proxy.dart';
import 'package:prism/features/online/domain/external_track.dart';
import 'package:prism/features/online/domain/link_parser.dart';
import 'package:prism/features/online/domain/matching.dart';
import 'package:prism/features/online/domain/online_error.dart';
import 'package:prism/features/online/services/link_only/link_modules.dart';
import 'package:prism/features/online/services/music_service_module.dart';
import 'package:prism/features/online/services/spotify/spotify_module.dart';
import 'package:prism/features/online/services/youtube/data_api_backend.dart';
import 'package:prism/features/online/services/youtube/web_playlist_reader.dart';
import 'package:prism/features/online/services/youtube/youtube_backend.dart';
import 'package:prism/features/online/services/youtube/youtube_module.dart';

/// A playable service that answers searches from a fixed list.
class FakeService extends MusicServiceModule {
  FakeService(this.sourceId, this.results, {this.error});
  final String sourceId;
  final List<Track> results;
  final OnlineException? error;
  final queries = <String>[];

  @override
  OnlineService get service => sourceId == 'youtube' ? OnlineService.youtube : OnlineService.soundcloud;
  @override
  Set<ModuleFeature> get features => const {ModuleFeature.search, ModuleFeature.stream};
  @override
  String? get playableSourceId => sourceId;
  @override
  Future<List<Track>> search(String query, {int limit = 20}) async {
    queries.add(query);
    if (error != null) throw error!;
    return results;
  }
}

Track local(int id, String title, String artist, {int sec = 200}) =>
    Track(id: id, uri: '/music/$id.mp3', title: title, artist: artist, durationMs: sec * 1000);

Track yt(String id, String title, String channel, {int sec = 200}) => Track(
  id: 0,
  sourceId: 'youtube',
  uri: 'https://www.youtube.com/watch?v=$id',
  title: title,
  artist: channel,
  durationMs: sec * 1000,
);

ExternalTrack want(
  String title,
  String artist, {
  int sec = 200,
  OnlineService service = OnlineService.spotify,
  String? id,
  String? url,
}) =>
    ExternalTrack(service: service, title: title, artists: [artist], durationMs: sec * 1000, externalId: id, url: url);

MatchService matcher(List<Track> library, List<MusicServiceModule> services) => MatchService(
  localSearch: (q) async {
    final tokens = searchTokens(q);
    return library.where((t) {
      final hay = buildSearchText(title: t.title, artist: t.artist, album: t.album);
      return tokens.every(hay.contains);
    }).toList();
  },
  localByUri: (uri) async => library.where((t) => t.uri.toLowerCase() == uri.toLowerCase()).firstOrNull,
  playable: () => services,
);

void main() {
  group('MatchService', () {
    test('local file first, online is not even asked', () async {
      final yt1 = FakeService('youtube', [yt('a', 'Band - Song', 'BandVEVO')]);
      final r = await matcher([local(1, 'Song', 'Band')], [yt1]).match(want('Song', 'Band'));
      expect(r.track!.id, 1);
      expect(r.source, 'local');
      expect(yt1.queries, isEmpty);
    });

    test('falls back to YouTube, then SoundCloud, keeps the best', () async {
      final ytS = FakeService('youtube', [yt('a', 'Song (Karaoke)', 'Karaoke Hits')]);
      final sc = FakeService('soundcloud', [
        const Track(
          id: 0,
          sourceId: 'soundcloud',
          uri: 'https://soundcloud.com/band/song#sc=5',
          title: 'Song',
          artist: 'Band',
          durationMs: 200000,
        ),
      ]);
      final r = await matcher(const [], [ytS, sc]).match(want('Song', 'Band'));
      expect(r.source, 'soundcloud');
      expect(r.score.confidence, MatchConfidence.high);
      expect(ytS.queries.single, 'Band song');
    });

    test('stops after a high-confidence match', () async {
      final ytS = FakeService('youtube', [yt('a', 'Song', 'Band - Topic')]);
      final sc = FakeService('soundcloud', const []);
      await matcher(const [], [ytS, sc]).match(want('Song', 'Band'));
      expect(sc.queries, isEmpty);
    });

    test('a weak local copy still beats a slightly better stream', () async {
      final ytS = FakeService('youtube', [yt('a', 'Band - Song Title', 'BandVEVO', sec: 200)]);
      // Local: right song, unknown length and a typo – scores a bit lower.
      final lib = [local(1, 'Song Titel', 'Band', sec: 0)];
      final r = await matcher(lib, [ytS]).match(want('Song Title', 'Band'));
      expect(r.source, 'local');
    });

    test('exact M3U path wins', () async {
      final r = await matcher([
        local(7, 'Whatever', 'X'),
      ], const []).match(want('Other', 'Y', service: OnlineService.file, url: '/MUSIC/7.mp3'));
      expect(r.track!.id, 7);
      expect(r.score.value, 1);
    });

    test('YouTube import uses the linked video itself', () async {
      final ytS = FakeService('youtube', const []);
      final r = await matcher(const [], [ytS]).match(
        want('Song', 'Band', service: OnlineService.youtube, id: 'abc', url: 'https://www.youtube.com/watch?v=abc'),
      );
      expect(r.source, 'direct');
      expect(r.track!.uri, 'https://www.youtube.com/watch?v=abc');
      expect(ytS.queries, isEmpty);
    });

    test('nothing good → unmatched with a hint', () async {
      final r = await matcher(const [], const []).match(want('Song', 'Band'));
      expect(r.matched, isFalse);
      expect(r.note, contains('Turn on'));
    });

    test('offline pauses (throws), a broken service is skipped', () async {
      final offline = FakeService('youtube', const [], error: OnlineException(OnlineErrorKind.offline));
      await expectLater(matcher(const [], [offline]).match(want('Song', 'Band')), throwsA(isA<OnlineException>()));

      final broken = FakeService('youtube', const [], error: OnlineException(OnlineErrorKind.badResponse));
      final sc = FakeService('soundcloud', [
        const Track(id: 0, sourceId: 'soundcloud', uri: 'u#sc=1', title: 'Song', artist: 'Band', durationMs: 200000),
      ]);
      final r = await matcher(const [], [broken, sc]).match(want('Song', 'Band'));
      expect(r.source, 'soundcloud');
    });

    test('candidates for "fix match": all sources, best first, errors per service', () async {
      final ytS = FakeService('youtube', [
        yt('a', 'Band - Song (Live)', 'Band', sec: 260),
        yt('b', 'Band - Song', 'Band - Topic'),
      ]);
      final sc = FakeService(
        'soundcloud',
        const [],
        error: OnlineException(OnlineErrorKind.rateLimited, service: OnlineService.soundcloud),
      );
      final (list, errors) = await matcher([local(1, 'Song', 'Band')], [ytS, sc]).candidates(want('Song', 'Band'), '');
      expect(list.length, 3);
      expect(list.first.score.value, greaterThanOrEqualTo(list.last.score.value));
      expect(list.last.track.title, contains('Live'));
      expect(errors.keys, ['SoundCloud']);
    });
  });

  group('OnlineHttp', () {
    test('retries after 429 Retry-After, then succeeds', () async {
      var calls = 0;
      final waits = <Duration>[];
      final h = OnlineHttp(
        client: MockClient((req) async {
          calls++;
          return calls == 1 ? http.Response('', 429, headers: {'retry-after': '2'}) : http.Response('{"ok":true}', 200);
        }),
        sleep: (d) async => waits.add(d),
      );
      final j = await h.getJson(Uri.parse('https://x/y'), service: OnlineService.spotify);
      expect(j['ok'], true);
      expect(waits, [const Duration(seconds: 2)]);
    });

    test('gives up on a long Retry-After with rateLimited', () async {
      final h = OnlineHttp(
        client: MockClient((_) async => http.Response('', 429, headers: {'retry-after': '3600'})),
        sleep: (_) async {},
      );
      await expectLater(
        h.getJson(Uri.parse('https://x'), service: OnlineService.spotify),
        throwsA(isA<OnlineException>().having((e) => e.kind, 'kind', OnlineErrorKind.rateLimited)),
      );
    });

    test('offline: retries with backoff then reports offline', () async {
      var calls = 0;
      final waits = <Duration>[];
      final h = OnlineHttp(
        client: MockClient((_) async {
          calls++;
          throw const SocketException('no route');
        }),
        sleep: (d) async => waits.add(d),
      );
      await expectLater(
        h.getJson(Uri.parse('https://x'), service: OnlineService.youtube),
        throwsA(isA<OnlineException>().having((e) => e.isTransient, 'transient', true)),
      );
      expect(calls, 3);
      expect(waits, [const Duration(milliseconds: 500), const Duration(seconds: 1)]);
    });

    test('5xx retried, 404/401/403 mapped at once, API message kept', () async {
      var calls = 0;
      final h = OnlineHttp(
        client: MockClient((_) async => ++calls < 3 ? http.Response('', 503) : http.Response('[1,2]', 200)),
        sleep: (_) async {},
      );
      expect((await h.getJson(Uri.parse('https://x'), service: OnlineService.deezer))['items'], [1, 2]);

      Future<OnlineErrorKind> kind(int code, [String body = '']) async {
        final c = OnlineHttp(client: MockClient((_) async => http.Response(body, code)), sleep: (_) async {});
        try {
          await c.getJson(Uri.parse('https://x'), service: OnlineService.spotify);
        } on OnlineException catch (e) {
          return e.kind;
        }
        return OnlineErrorKind.server;
      }

      expect(await kind(404), OnlineErrorKind.notFound);
      expect(await kind(401), OnlineErrorKind.auth);
      expect(await kind(403, '{"error":{"message":"nope"}}'), OnlineErrorKind.forbidden);
      // YouTube quota is a 403 with quotaExceeded → rate limit.
      expect(await kind(403, '{"error":{"errors":[{"reason":"quotaExceeded"}]}}'), OnlineErrorKind.rateLimited);
    });
  });

  group('OAuth', () {
    test('PKCE challenge = base64url(sha256(verifier)) without padding', () {
      // Expected value computed separately with .NET SHA256 + base64url.
      expect(
        Pkce.challenge('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWZFUN74'),
        'J0087RlMHQAcaGm5eanWY3zDjZlV4769kBncbFtAtb0',
      );
      expect(Pkce.verifier().length, 64);
      expect(Pkce.verifier(), matches(RegExp(r'^[A-Za-z0-9._~-]{64}$')));
    });

    test('expired token is refreshed once for parallel callers; revoked → logged out', () async {
      final store = MemoryTokenStore();
      var refreshes = 0;
      var revoked = false;
      final client = OAuthClient(
        service: OnlineService.spotify,
        authorizeUrl: Uri.parse('https://a/auth'),
        tokenUrl: Uri.parse('https://a/token'),
        clientId: 'id',
        scopes: const [],
        port: 1,
        store: store,
        launch: (_) async => true,
        http: OnlineHttp(
          client: MockClient((req) async {
            if (revoked) return http.Response('{"error":"invalid_grant"}', 400);
            refreshes++;
            expect(req.bodyFields['grant_type'], 'refresh_token');
            return http.Response('{"access_token":"new","expires_in":3600}', 200);
          }),
          sleep: (_) async {},
        ),
      );
      await store.write(
        'prism.oauth.spotify',
        jsonEncode(OAuthToken(accessToken: 'old', refreshToken: 'r1', expiresAt: DateTime.now()).toJson()),
      );
      final tokens = await Future.wait([client.accessToken(), client.accessToken()]);
      expect(tokens, ['new', 'new']);
      expect(refreshes, 1);
      // Refresh token is kept when the provider doesn't send a new one.
      expect((await client.stored())!.refreshToken, 'r1');

      revoked = true;
      await store.write(
        'prism.oauth.spotify',
        jsonEncode(OAuthToken(accessToken: 'x', refreshToken: 'r1', expiresAt: DateTime.now()).toJson()),
      );
      await client.logout(); // drop the cached copy
      await store.write(
        'prism.oauth.spotify',
        jsonEncode(OAuthToken(accessToken: 'x', refreshToken: 'r1', expiresAt: DateTime.now()).toJson()),
      );
      await expectLater(
        client.accessToken(),
        throwsA(isA<OnlineException>().having((e) => e.kind, 'kind', OnlineErrorKind.auth)),
      );
      expect(await client.isLoggedIn, isFalse);
    });
  });

  group('services (mocked HTTP)', () {
    test('Spotify playlist: /items with "item" rows, falls back to /tracks; skips episodes', () async {
      final store = MemoryTokenStore();
      await store.write(
        'prism.oauth.spotify',
        jsonEncode(OAuthToken(accessToken: 't', expiresAt: DateTime.now().add(const Duration(hours: 1))).toJson()),
      );
      Map<String, Object?> song(String name) => {
        'type': 'track',
        'id': name,
        'name': name,
        'duration_ms': 1000,
        'artists': [
          {'name': 'A'},
        ],
        'album': {'name': 'Al', 'images': []},
        'external_ids': {'isrc': 'X'},
      };
      var itemsMissing = false;
      final m = SpotifyModule(
        clientId: 'c',
        port: 1,
        store: store,
        launch: (_) async => true,
        http: OnlineHttp(
          client: MockClient((req) async {
            final path = req.url.path;
            if (path.endsWith('/playlists/p1')) return http.Response('{"name":"Mix"}', 200);
            if (path.endsWith('/items')) {
              if (itemsMissing) return http.Response('', 404);
              return http.Response(
                jsonEncode({
                  'items': [
                    {'item': song('one')},
                    {
                      'item': {'type': 'episode', 'name': 'pod'},
                    },
                  ],
                  'next': null,
                }),
                200,
              );
            }
            if (path.endsWith('/tracks')) {
              return http.Response(
                jsonEncode({
                  'items': [
                    {'track': song('old')},
                  ],
                }),
                200,
              );
            }
            return http.Response('', 404);
          }),
          sleep: (_) async {},
        ),
      );
      final info = RemotePlaylistInfo(service: OnlineService.spotify, id: 'p1', name: 'Mix');
      final l = await m.fetchList(info);
      expect(l.name, 'Mix');
      expect(l.tracks.map((t) => t.title), ['one']);
      expect(l.tracks.single.isrc, 'X');
      itemsMissing = true;
      expect((await m.fetchList(info)).tracks.single.title, 'old');
    });

    test('Spotify: playlist of someone else explains the dev-mode limit', () async {
      final store = MemoryTokenStore();
      await store.write(
        'prism.oauth.spotify',
        jsonEncode(OAuthToken(accessToken: 't', expiresAt: DateTime.now().add(const Duration(hours: 1))).toJson()),
      );
      final m = SpotifyModule(
        clientId: 'c',
        port: 1,
        store: store,
        launch: (_) async => true,
        http: OnlineHttp(client: MockClient((_) async => http.Response('', 403)), sleep: (_) async {}),
      );
      await expectLater(
        m.fetchList(const RemotePlaylistInfo(service: OnlineService.spotify, id: 'x', name: 'x')),
        throwsA(isA<OnlineException>().having((e) => e.message, 'message', contains('Exportify'))),
      );
    });

    test('Deezer: error-in-200 is mapped, pages are followed', () async {
      final d = DeezerModule(
        OnlineHttp(
          client: MockClient((req) async {
            if (req.url.path == '/playlist/1') return http.Response('{"title":"P"}', 200);
            if (req.url.path == '/playlist/1/tracks') {
              final index = int.parse(req.url.queryParameters['index']!);
              return http.Response(
                jsonEncode({
                  'data': [
                    {
                      'title': 'S$index',
                      'duration': 100,
                      'artist': {'name': 'A'},
                      'id': index,
                    },
                  ],
                  'next': index < 1 ? 'more' : null,
                }),
                200,
              );
            }
            return http.Response('{"error":{"code":800,"message":"no data"}}', 200);
          }),
          sleep: (_) async {},
        ),
      );
      final l = await d.openLink(parseMusicLink('https://www.deezer.com/playlist/1')!);
      expect(l.tracks.map((t) => t.title), ['S0', 'S1']);
      expect(l.tracks.first.durationMs, 100000);
      await expectLater(
        d.openLink(parseMusicLink('https://www.deezer.com/album/9')!),
        throwsA(isA<OnlineException>().having((e) => e.kind, 'kind', OnlineErrorKind.notFound)),
      );
    });

    test('YouTube Data API: search → durations; quota error is a rate limit', () async {
      final api = DataApiBackend((endpoint, params) async {
        if (endpoint == 'search') {
          return {
            'items': [
              {
                'id': {'videoId': 'v1'},
              },
            ],
          };
        }
        return {
          'items': [
            {
              'id': 'v1',
              'snippet': {'title': 'Band - Song &amp; More', 'channelTitle': 'BandVEVO'},
              'contentDetails': {'duration': 'PT3M5S'},
            },
          ],
        };
      });
      final r = await api.search('x');
      expect(r.single.title, 'Band - Song & More');
      expect(r.single.durationMs, 185000);
      expect(parseIsoDuration('PT1H0M1S'), 3601000);
    });

    test('YouTube import splits "Artist - Title", channel as fallback artist', () {
      final a = YoutubeModule.externalFromVideo(
        const YtVideo(id: 'x', title: 'Daft Punk - One More Time (Official Video)', channel: 'Daft Punk'),
      );
      expect(a.artists, ['Daft Punk']);
      expect(cleanTitle(a.title), 'one more time');
      final b = YoutubeModule.externalFromVideo(
        const YtVideo(id: 'y', title: 'One More Time', channel: 'Daft Punk - Topic'),
      );
      expect(b.artists, ['Daft Punk']);
    });

    test('YouTube web playlist: lockup rows, durations, only the video list continuation', () {
      Map<String, Object?> lockup(String id, String title, String channel, String time) => {
        'lockupViewModel': {
          'contentId': id,
          'contentType': 'LOCKUP_CONTENT_TYPE_VIDEO',
          'contentImage': {
            'thumbnailViewModel': {
              'image': {
                'sources': [
                  {'url': 'https://i/$id.jpg'},
                ],
              },
              'overlays': [
                {
                  'thumbnailBottomOverlayViewModel': {
                    'badges': [
                      {
                        'thumbnailBadgeViewModel': {'text': time},
                      },
                    ],
                  },
                },
              ],
            },
          },
          'metadata': {
            'lockupMetadataViewModel': {
              'title': {'content': title},
              'metadata': {
                'contentMetadataViewModel': {
                  'metadataRows': [
                    {
                      'metadataParts': [
                        {
                          'text': {'content': channel},
                        },
                      ],
                    },
                  ],
                },
              },
            },
          },
        },
      };
      final data = {
        'contents': {
          'list': [
            lockup('a', 'Song A', 'Chan', '3:55'),
            lockup('b', 'Song B', 'Chan', '1:02:03'),
            {
              'continuationItemViewModel': {
                'continuationCommand': {'token': 'VIDEOS'},
              },
            },
          ],
          'shelf': [
            {
              'lockupViewModel': {'contentId': 'pl', 'contentType': 'LOCKUP_CONTENT_TYPE_PLAYLIST'},
            },
            {
              'continuationItemViewModel': {
                'continuationCommand': {'token': 'RELATED'},
              },
            },
          ],
        },
      };
      final out = <YtVideo>[];
      final token = WebPlaylistReader.collect(data, out, {});
      expect(token, 'VIDEOS');
      expect(out.map((v) => v.id), ['a', 'b']);
      expect(out[0].durationMs, 235000);
      expect(out[1].durationMs, 3723000);
      expect(out[0].channel, 'Chan');
      expect(out[0].thumbnailUrl, 'https://i/a.jpg');
    });

    test('Apple Music page: schema.org album, app data for playlists', () {
      const album =
          '<script type="application/ld+json">{"@type":"MusicAlbum","name":"RAM","byArtist":{"name":"Daft Punk"},'
          '"tracks":[{"name":"Touch","duration":"PT8M18S"}]}</script>';
      final a = parseAppleMusicPage(album)!;
      expect(a.name, 'RAM');
      expect(a.tracks.single.artists, ['Daft Punk']);
      expect(a.tracks.single.durationMs, 498000);

      const playlist =
          '<script type="application/ld+json">{"@type":"MusicPlaylist","name":"Hits","track":[{"name":"X"}]}</script>'
          '<script type="application/json" id="serialized-server-data">[{"data":{"sections":[{"items":['
          '{"title":"X","artistName":"Drake & Don Toliver","duration":218389}]}]}}]</script>';
      final p = parseAppleMusicPage(playlist)!;
      expect(p.name, 'Hits');
      expect(p.tracks.single.artists, ['Drake', 'Don Toliver']);
      expect(p.tracks.single.durationMs, 218389);
      expect(parseAppleMusicPage('<html></html>'), isNull);
    });
  });

  group('StreamProxy', () {
    test('turns open-ended player requests into bounded chunks; seeks; re-resolves an expired URL', () async {
      final data = List<int>.generate(300000, (i) => i % 251);
      final seen = <String>[];
      var expired = false;
      // Fake googlevideo: 403 for open-ended ranges or an expired token.
      final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      upstream.listen((req) async {
        final range = req.headers.value('range') ?? '';
        seen.add('${req.uri.queryParameters['v']} $range');
        final m = RegExp(r'^bytes=(\d+)-(\d+)$').firstMatch(range);
        if (m == null || (expired && req.uri.queryParameters['v'] == 'old')) {
          req.response.statusCode = 403;
          await req.response.close();
          return;
        }
        final a = int.parse(m[1]!), b = int.parse(m[2]!);
        req.response
          ..statusCode = 206
          ..add(data.sublist(a, b + 1));
        await req.response.close();
      });
      var version = 'old';
      final proxy = StreamProxy(chunkSize: 100000);
      final url = await proxy.register('yt:x', ({bool refresh = false}) async {
        if (refresh) version = 'new';
        return ProxiedStream(
          url: Uri.parse('http://127.0.0.1:${upstream.port}/v?v=$version'),
          length: data.length,
          mimeType: 'audio/webm',
        );
      });

      Future<(int, List<int>, String?)> get(String? range) async {
        final c = HttpClient();
        final req = await c.getUrl(url);
        if (range != null) req.headers.set('range', range);
        final res = await req.close();
        final body = await res.fold<List<int>>([], (a, b) => a..addAll(b));
        c.close();
        return (res.statusCode, body, res.headers.value('content-range'));
      }

      final (code, body, _) = await get(null);
      expect(code, 200);
      expect(body, data);
      expect(seen.every((s) => RegExp(r'bytes=\d+-\d+$').hasMatch(s)), isTrue, reason: '$seen');

      final (c2, seek, cr) = await get('bytes=250000-');
      expect(c2, 206);
      expect(cr, 'bytes 250000-299999/300000');
      expect(seek, data.sublist(250000));

      expired = true;
      final (c3, after, _) = await get('bytes=10-19');
      expect(c3, 206);
      expect(after, data.sublist(10, 20));
      expect(version, 'new');

      expect((await get('bytes=400000-')).$1, 416);

      // Guessing the address or coming in under another host name gets nothing.
      final c = HttpClient();
      final guessed = await (await c.getUrl(url.replace(path: '/s/yt%3Ax'))).close();
      expect(guessed.statusCode, 404);
      final rebound = await (await c.getUrl(url)..headers.host = 'evil.example').close();
      expect(rebound.statusCode, 404);
      c.close();
      await proxy.close();
      await upstream.close(force: true);
    });
  });

  group('database', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('remote tracks keep their id and stay out of library views', () async {
      final lib = LibraryRepository(db);
      await lib.upsertTracks([
        TracksCompanion.insert(
          uri: '/m/1.mp3',
          folder: '/m',
          title: 'Local Song',
          searchText: const Value('local song'),
        ),
      ]);
      final store = RemoteTrackStore(db);
      final a = await store.ensure(yt('v1', 'Remote Song', 'Chan'));
      final again = await store.ensure(yt('v1', 'Remote Song (renamed)', 'Chan'));
      expect(a.id, greaterThan(0));
      expect(again.id, a.id);
      expect(again.title, 'Remote Song (renamed)');
      expect((await lib.watchTracks().first).map((t) => t.title), ['Local Song']);
      expect(await lib.search('song'), hasLength(1));
      expect(await lib.trackCount(), 1);
      expect((await lib.watchArtists().first).map((x) => x.name), ['']);
      // …but playlists / favorites can hold them.
      expect((await lib.trackById(a.id))!.sourceId, 'youtube');
    });

    test('import job: duplicates skipped, progress per item, resumable, playlist rewritten', () async {
      final repo = ImportRepository(db);
      final store = RemoteTrackStore(db);
      final list = ImportedList(
        name: 'Mix',
        origin: OnlineService.spotify,
        sourceUrl: 'https://open.spotify.com/playlist/1',
        tracks: [want('One', 'A'), want('Two', 'A'), want('One - Remastered', 'A'), want('Three', 'A')],
      );
      final id = await repo.createJob(list);
      var items = await repo.watchItems(id).first;
      expect(items.map((i) => i.status), [
        ImportItemStatus.pending,
        ImportItemStatus.pending,
        ImportItemStatus.duplicate,
        ImportItemStatus.pending,
      ]);
      expect(items[2].duplicateOf, 0);

      // Match the first two, then "close the app".
      final t1 = await store.ensure(yt('1', 'A - One', 'A'));
      final t2 = await store.ensure(yt('2', 'A - Two', 'A'));
      await repo.saveMatch(items[0].id, trackId: t1.id, confidence: 0.95, source: 'youtube');
      await repo.saveMatch(items[1].id, trackId: t2.id, confidence: 0.55, source: 'youtube', note: 'check');
      await repo.setState(id, ImportJobState.paused, message: 'offline');

      final pending = await repo.pendingItems(id);
      expect(pending.map((i) => i.wanted.title), ['Three']);
      final job = (await repo.watchJob(id).first)!;
      expect(job.state, ImportJobState.paused);
      expect(job.matched, 2);
      expect(job.lowConfidence, 1);
      expect(job.pending, 1);
      expect((await repo.jobForSource('https://open.spotify.com/playlist/1'))!.id, id);

      await repo.saveMatch(pending.single.id, trackId: null, confidence: 0.2);
      final playlistId = (await repo.writePlaylist(id))!;
      final entries = await (db.select(db.playlistEntries)..where((e) => e.playlistId.equals(playlistId))).get();
      expect(entries.map((e) => e.trackId), [t1.id, t2.id]);

      // Fix a match → playlist rewritten in import order, same playlist.
      items = await repo.watchItems(id).first;
      await repo.saveMatch(items[1].id, trackId: t1.id, confidence: 1, source: 'manual');
      expect(await repo.writePlaylist(id), playlistId);
      final again = await (db.select(db.playlistEntries)..where((e) => e.playlistId.equals(playlistId))).get();
      expect(again.map((e) => e.trackId), [t1.id, t1.id]);
      expect((await repo.watchJob(id).first)!.state, ImportJobState.done);
    });
  });
}

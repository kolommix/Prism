import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prism/features/online/data/oauth.dart';
import 'package:prism/features/online/data/online_http.dart';
import 'package:prism/features/online/domain/external_track.dart';
import 'package:prism/features/online/domain/import_parsers.dart';
import 'package:prism/features/online/domain/link_parser.dart';
import 'package:prism/features/online/domain/online_error.dart';
import 'package:prism/features/online/services/yandex/yandex_module.dart';

class MemoryTokens implements TokenStore {
  final map = <String, String>{};
  @override
  Future<String?> read(String key) async => map[key];
  @override
  Future<void> write(String key, String value) async => map[key] = value;
  @override
  Future<void> delete(String key) async => map.remove(key);
}

Map<String, dynamic> track(int id, String title, {String? version}) => {
      'id': id,
      'title': title,
      'version': ?version,
      'durationMs': 200000,
      'artists': [
        {'name': 'Artist'},
      ],
      'albums': [
        {'id': 7, 'title': 'Album'},
      ],
      'coverUri': 'avatars.yandex.net/x/%%',
    };

http.Response ok(Object result) =>
    http.Response.bytes(utf8.encode(jsonEncode({'result': result})), 200, headers: {'content-type': 'application/json'});

void main() {
  group('links', () {
    test('every link form is understood', () {
      final p = parseMusicLink('https://music.yandex.ru/users/ivan/playlists/1003')!;
      expect(p.service, OnlineService.yandex);
      expect(p.kind, LinkKind.playlist);
      expect(p.id, 'ivan:1003');
      expect(parseMusicLink('https://music.yandex.com/playlists/lk.abc-123')!.id, 'lk.abc-123');
      final a = parseMusicLink('https://music.yandex.by/album/9046986')!;
      expect((a.kind, a.id), (LinkKind.album, '9046986'));
      final t = parseMusicLink('https://music.yandex.ru/album/7/track/42')!;
      expect((t.kind, t.id), (LinkKind.track, '42:7'));
      final l = parseMusicLink('https://music.yandex.ru/users/ivan/tracks')!;
      expect((l.kind, l.id), (LinkKind.likes, 'ivan'));
      expect(parseMusicLink('https://music.yandex.ru/'), isNull);
      expect(parseMusicLink('https://yandex.ru/album/1'), isNull);
    });
  });

  group('module', () {
    late List<http.Request> calls;
    late MemoryTokens tokens;

    YandexModule module(Future<http.Response> Function(http.Request) handler) {
      calls = [];
      tokens = MemoryTokens();
      return YandexModule(
        OnlineHttp(
          client: MockClient((r) {
            calls.add(r);
            return handler(r);
          }),
          maxAttempts: 1,
        ),
        tokens,
      );
    }

    test('public playlist by link, full tracks, no token sent', () async {
      final m = module((r) async => ok([
            {
              'title': 'My list',
              'tracks': [
                {'id': 1, 'track': track(1, 'One', version: 'Live')},
              ],
            },
          ]));
      final list = await m.openLink(parseMusicLink('https://music.yandex.ru/users/ivan/playlists/5')!);
      expect(list.name, 'My list');
      expect(list.origin, OnlineService.yandex);
      expect(list.tracks.single.title, 'One (Live)');
      expect(list.tracks.single.artists, ['Artist']);
      expect(list.tracks.single.album, 'Album');
      expect(list.tracks.single.artworkUrl, 'https://avatars.yandex.net/x/200x200');
      expect(calls.single.url.path, '/users/ivan/playlists');
      expect(calls.single.bodyFields['kinds'], '5');
      expect(calls.single.headers.containsKey('Authorization'), isFalse);
    });

    test('ids only: asked for in batches, order kept', () async {
      final shorts = [for (var i = 0; i < 450; i++) {'id': i, 'albumId': 7}];
      final m = module((r) async {
        if (r.url.path.endsWith('/tracks')) {
          final ids = r.bodyFields['track-ids']!.split(',');
          return ok([for (final id in ids.reversed) track(int.parse(id.split(':').first), 'T${id.split(':').first}')]);
        }
        return ok({'title': 'Big', 'tracks': shorts});
      });
      final list = await m.openLink(parseMusicLink('https://music.yandex.ru/playlists/lk.x')!);
      expect(list.tracks.length, 450);
      expect(list.tracks.first.title, 'T0');
      expect(list.tracks.last.title, 'T449');
      expect(calls.where((c) => c.url.path == '/tracks').length, 3);
    });

    test('album with volumes', () async {
      final m = module((r) async => ok({
            'title': 'Album',
            'artists': [
              {'name': 'A'},
            ],
            'volumes': [
              [track(1, 'One')],
              [track(2, 'Two')],
            ],
          }));
      final list = await m.openLink(parseMusicLink('https://music.yandex.ru/album/7')!);
      expect(list.name, 'Album – A');
      expect(list.tracks.map((t) => t.title), ['One', 'Two']);
    });

    test('a removed track without a title is skipped', () {
      expect(yandexTrack(const {'id': 1, 'title': ''}), isNull);
    });

    test('token: checked, kept in the store, sent as OAuth, removed on disconnect', () async {
      final m = module((r) async {
        if (r.url.path == '/account/status') {
          return ok({
            'account': {'uid': 11, 'displayName': 'Ivan'},
          });
        }
        return ok([
          {'uid': 11, 'kind': 3, 'title': 'Mine', 'trackCount': 2},
        ]);
      });
      final a = await m.setToken('  secret  ');
      expect(a.name, 'Ivan');
      expect(tokens.map[YandexModule.tokenKey], 'secret');
      expect(calls.first.headers['Authorization'], 'OAuth secret');
      expect(calls.first.headers['X-Yandex-Music-Client'], isNotEmpty);
      final lists = await m.myPlaylists();
      expect(lists.single.id, '11:3');
      expect(lists.single.trackCount, 2);
      await m.disconnect();
      expect(tokens.map, isEmpty);
      expect(await m.account(), isNull);
    });

    test('a bad token is not kept', () async {
      final m = module((_) async => http.Response('', 401));
      await expectLater(m.setToken('bad'), throwsA(isA<OnlineException>().having((e) => e.kind, 'kind', OnlineErrorKind.auth)));
      expect(tokens.map, isEmpty);
    });

    test('likes: ids resolved to tracks', () async {
      final m = module((r) async {
        if (r.url.path == '/account/status') {
          return ok({
            'account': {'uid': 11},
          });
        }
        if (r.url.path == '/users/11/likes/tracks') {
          return ok({
            'library': {
              'tracks': [
                {'id': 1, 'albumId': 7},
              ],
            },
          });
        }
        return ok([track(1, 'One')]);
      });
      await m.setToken('t');
      expect((await m.likedSongs()).tracks.single.title, 'One');
    });

    test('no token: likes and own playlists say a token is needed', () async {
      final m = module((_) async => ok({}));
      await expectLater(m.likedSongs(), throwsA(isA<OnlineException>().having((e) => e.kind, 'kind', OnlineErrorKind.auth)));
    });

    test('blocked region says so', () async {
      final m = module((_) async => http.Response('{"error":{"name":"Unavailable For Legal Reasons"}}', 451));
      await expectLater(
        m.openLink(parseMusicLink('https://music.yandex.ru/album/7')!),
        throwsA(isA<OnlineException>().having((e) => e.kind, 'kind', OnlineErrorKind.forbidden).having((e) => e.message, 'message', contains('CSV'))),
      );
    });

    test('an answer in a new shape is a clear error, not a crash', () async {
      final m = module((_) async => ok(const ['surprise']));
      await expectLater(
        m.openLink(parseMusicLink('https://music.yandex.ru/album/7')!),
        throwsA(isA<OnlineException>().having((e) => e.message, 'message', contains('CSV'))),
      );
      final html = module((_) async => http.Response('<html>captcha</html>', 200));
      await expectLater(
        html.openLink(parseMusicLink('https://music.yandex.ru/album/7')!),
        throwsA(isA<OnlineException>().having((e) => e.message, 'message', contains('CSV'))),
      );
    });
  });

  group('fallback files', () {
    test('CSV with Russian headers', () {
      final lists = parseImportFile('yandex.csv', 'Название,Исполнитель,Альбом,Длительность\nПесня,Группа,Альбом 1,3:20\n');
      final t = lists.single.tracks.single;
      expect(t.title, 'Песня');
      expect(t.artists, ['Группа']);
      expect(t.album, 'Альбом 1');
      expect(t.durationMs, 200000);
    });

    test('JSON shaped like the API', () {
      final body = jsonEncode({
        'title': 'Экспорт',
        'tracks': [
          {'track': track(1, 'One')},
        ],
      });
      final lists = parseImportFile('yandex.json', body);
      final t = lists.single.tracks.single;
      expect(lists.single.name, 'Экспорт');
      expect(t.title, 'One');
      expect(t.artists, ['Artist']);
      expect(t.album, 'Album');
      expect(t.durationMs, 200000);
    });
  });
}

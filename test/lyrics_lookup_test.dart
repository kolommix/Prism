import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/lyrics/data/lyrics_repository.dart';

Map<String, Object?> _entry(int id, String title, String artist, double secs, {bool synced = true, bool plain = true}) => {
      'id': id,
      'trackName': title,
      'artistName': artist,
      'albumName': '',
      'duration': secs,
      'instrumental': false,
      'plainLyrics': plain ? 'words of $title' : null,
      'syncedLyrics': synced ? '[00:01.00]words of $title' : null,
    };

void main() {
  group('what is asked for', () {
    test('YouTube title "Artist - Song (Official Video)" by a channel', () {
      final w = lyricsWanted(const Track(
        id: 1,
        sourceId: 'youtube',
        uri: 'x',
        title: 'Дора - Трудный возраст (Official Video)',
        artist: 'ДораVEVO',
        durationMs: 200000,
      ));
      expect(w.title, 'Трудный возраст (Official Video)');
      expect(w.artists.first, 'Дора');
    });

    test('a file without tags named "03. Artist - Song"', () {
      final w = lyricsWanted(const Track(id: 1, uri: 'x', title: '03. Сплин - Мало огня'));
      expect((w.artists.single, w.title), ('Сплин', 'Мало огня'));
    });

    test('"Song - Remastered 2011" keeps its name; no artist is not "Unknown artist"', () {
      final w = lyricsWanted(const Track(id: 1, uri: 'x', title: 'Heroes - 2017 Remaster'));
      expect(w.title, 'Heroes - 2017 Remaster');
      expect(w.artists, isEmpty);
    });

    test('a tagged local file is left alone', () {
      final w = lyricsWanted(const Track(id: 1, uri: 'x', title: 'Kids - Live', artist: 'MGMT', album: 'Live'));
      expect((w.title, w.artist, w.album), ('Kids - Live', 'MGMT', 'Live'));
    });
  });

  group('picking among search answers', () {
    Future<LrclibResult> run(Track t, List<Map<String, Object?>> Function(Map<String, String> q) search) {
      final client = MockClient((req) async {
        if (req.url.path == '/api/get') return http.Response('{"code":404}', 404);
        return http.Response.bytes(utf8.encode(jsonEncode(search(req.url.queryParameters))), 200,
            headers: {'content-type': 'application/json'});
      });
      return LrclibClient(client: client).lookup(t);
    }

    test('the right song wins over a same-named one by someone else and a long version', () async {
      final r = await run(
        const Track(id: 1, uri: 'x', title: 'Kids', artist: 'MGMT', durationMs: 302000),
        (_) => [
          _entry(1, 'Kids', 'Kylie Minogue', 300),
          _entry(2, 'Kids (Extended Mix)', 'MGMT', 420),
          _entry(3, 'Kids', 'MGMT', 302, synced: false),
          _entry(4, 'Kids', 'MGMT', 303),
        ],
      );
      expect((r as LrclibFound).synced, '[00:01.00]words of Kids');
    });

    test('found through the free-text search when the title search misses', () async {
      final r = await run(
        const Track(id: 1, uri: 'x', sourceId: 'youtube', title: 'Дора - Трудный возраст (Lyric Video)', artist: 'Дора', durationMs: 201000),
        (q) => q.containsKey('q') ? [_entry(9, 'Трудный возраст', 'Дора', 200)] : [],
      );
      expect(r, isA<LrclibFound>());
    });

    test('nothing close enough: not found (and cached as such)', () async {
      final r = await run(
        const Track(id: 1, uri: 'x', title: 'Мало огня', artist: 'Сплин', durationMs: 198000),
        (_) => [_entry(1, 'Мало огня', 'Другой', 198), _entry(2, 'Много огня', 'Кто-то', 150)],
      );
      expect(r, isA<LrclibNotFound>());
    });

    test('an instrumental match means there are no words', () async {
      final r = await run(
        const Track(id: 1, uri: 'x', title: 'Intro', artist: 'The xx', durationMs: 128000),
        (_) => [_entry(1, 'Intro', 'The xx', 128, synced: false, plain: false)..['instrumental'] = true],
      );
      expect(r, isA<LrclibNotFound>());
    });
  });
}

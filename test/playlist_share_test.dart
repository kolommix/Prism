import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/online/domain/import_parsers.dart';
import 'package:prism/features/playlists/domain/playlist_share.dart';

void main() {
  const local = Track(id: 1, uri: r'C:\Users\me\Music\secret folder\song.mp3', title: 'Песня', artist: 'Группа', album: 'Альбом', durationMs: 200400);
  const remote = Track(id: 2, sourceId: 'youtube', uri: 'https://www.youtube.com/watch?v=abc', title: 'Video', artist: 'Chan', durationMs: 61000);

  test('round trip keeps what is needed to find each song', () {
    final code = encodeSharedPlaylist('Мой плейлист', [local, remote]);
    expect(code, startsWith('liner://p/'));
    final list = decodeSharedPlaylist(code);
    expect(list.name, 'Мой плейлист');
    expect(list.tracks.length, 2);
    final a = list.tracks[0], b = list.tracks[1];
    expect(a.title, 'Песня');
    expect(a.artists, ['Группа']);
    expect(a.album, 'Альбом');
    expect(a.durationMs, 200000);
    expect(b.url, 'https://www.youtube.com/watch?v=abc');
  });

  test('never carries a file path', () {
    final code = encodeSharedPlaylist('x', [local]);
    final packed = base64Url.decode(base64Url.normalize(code.substring('liner://p/'.length)));
    final json = utf8.decode(gzip.decode(packed));
    expect(json, isNot(contains('secret')));
    expect(json, isNot(contains('Users')));
    expect(decodeSharedPlaylist(code).tracks.single.url, isNull);
  });

  test('compact: a 500-song list fits in a chat message limit', () {
    final tracks = [
      for (var i = 0; i < 500; i++) Track(id: i, uri: 'x$i', title: 'Song number $i', artist: 'Artist ${i % 30}', album: 'Album ${i % 40}', durationMs: 180000 + i),
    ];
    final code = encodeSharedPlaylist('Big', tracks);
    expect(code.length, lessThan(14000));
    expect(decodeSharedPlaylist(code).tracks.length, 500);
  });

  test('found inside a message, surrounded by other text', () {
    final code = encodeSharedPlaylist('x', [local]);
    expect(isSharedPlaylistText('look at this: $code nice right?'), isTrue);
    expect(decodeSharedPlaylist('look at this: $code nice right?').tracks.length, 1);
  });

  test('bad codes give a message, not a crash', () {
    for (final bad in ['nothing', 'liner://p/', 'liner://p/!!!!', 'liner://p/aGVsbG8']) {
      expect(() => decodeSharedPlaylist(bad), throwsA(isA<ShareFormatException>()), reason: bad);
    }
  });

  String pack(Object json) => 'liner://p/${base64Url.encode(gzip.encode(utf8.encode(jsonEncode(json)))).replaceAll('=', '')}';

  test('a code from a newer version says so', () {
    expect(
      () => decodeSharedPlaylist(pack({'v': 99, 'n': 'x', 't': []})),
      throwsA(isA<ShareFormatException>().having((e) => e.message, 'message', contains('newer'))),
    );
  });

  test('wrong shapes are refused or skipped', () {
    expect(() => decodeSharedPlaylist(pack({'v': 1, 'n': 'x', 't': 'no'})), throwsA(isA<ShareFormatException>()));
    expect(() => decodeSharedPlaylist(pack({'v': 1, 'n': 'x', 't': []})), throwsA(isA<ShareFormatException>()));
    final list = decodeSharedPlaylist(pack({
      'v': 1,
      'n': 5,
      't': [
        [1, 2],
        ['Good', 3, 4, 'x'],
        'junk',
      ],
    }));
    expect(list.tracks.single.title, 'Good');
    expect(list.tracks.single.artists, isEmpty);
    expect(list.name, isNotEmpty);
  });

  test('a code can not point at a local file or a plain http address', () {
    final list = decodeSharedPlaylist(pack({
      'v': 1,
      'n': 'x',
      't': [
        ['A', '', '', 0, 'file:///C:/Windows/system.ini'],
        ['B', '', '', 0, 'http://example.com/a'],
        ['C', '', '', 0, 'https://example.com/a'],
      ],
    }));
    expect(list.tracks.map((t) => t.url), [null, null, 'https://example.com/a']);
  });

  test('a code that unpacks to something huge is refused', () {
    final bomb = 'liner://p/${base64Url.encode(gzip.encode(List<int>.filled(64 * 1024 * 1024, 32))).replaceAll('=', '')}';
    expect(() => decodeSharedPlaylist(bomb), throwsA(isA<ShareFormatException>()));
  });

  test('a .liner file imports like any other', () {
    final code = encodeSharedPlaylist('Файл', [local]);
    final lists = parseImportFile('Файл.liner', code);
    expect(lists.single.name, 'Файл');
    expect(lists.single.tracks.single.title, 'Песня');
  });
}

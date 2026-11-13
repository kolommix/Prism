import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/db/app_database.dart';
import 'package:prism/features/library/data/library_repository.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/lyrics/data/lyrics_repository.dart';
import 'package:prism/features/lyrics/domain/lrc.dart';

void main() {
  group('LRC parsing', () {
    test('timestamps, multi-stamps, offset, word tags, metadata', () {
      final lines = parseLrc('''
[ar:Someone]
[offset:+500]
[00:10.00]First line
[00:05.50][01:00.25]Chorus <00:05.80>with <00:06.10>words
[00:20.123]Milliseconds
just text without time
''');
      expect(lines.map((l) => l.text), ['Chorus with words', 'First line', 'Milliseconds', 'Chorus with words']);
      // +500 ms offset shifts everything earlier.
      expect(lines.map((l) => l.time.inMilliseconds), [5000, 9500, 19623, 59750]);
    });

    test('enhanced LRC keeps word times', () {
      final lines = parseLrc('[00:10.00]<00:10.00>Hello <00:11.00>big <00:12.00>world');
      expect(lines.single.text, 'Hello big world');
      expect(lines.single.words.map((w) => w.time.inMilliseconds), [10000, 11000, 12000]);
      expect(lines.single.words.map((w) => w.text).join(), 'Hello big world');
    });

    test('text before the first word tag starts with the line', () {
      final l = parseLrc('[00:05.00]Chorus <00:06.00>words').single;
      expect(l.words.first.time.inMilliseconds, 5000);
      expect(l.words.first.text, 'Chorus ');
    });

    test('a repeated enhanced line times its words for each repeat', () {
      final lines = parseLrc('[00:10.00][01:00.00]<00:10.00>a <00:11.00>b');
      expect(lines[1].words.map((w) => w.time.inMilliseconds), [60000, 61000]);
    });

    test('bad files: out of order, duplicates, same time, word times outside the line', () {
      final lines = parseLrc('[00:20.00]later\n[00:10.00]first\n[00:10.00]first\n[00:15.00]one\n[00:15.00]two\n[00:30.00]<00:29.00>early <01:00.00>late\n[00:40.00]end');
      expect(lines.map((l) => l.text), ['first', 'one\ntwo', 'later', 'early late', 'end']);
      final w = lines[3].words;
      expect(w[0].time, const Duration(seconds: 30));
      expect(w[1].time, const Duration(seconds: 40));
    });

    test('sung part: even pace, words, and a long gap does not crawl', () {
      final even = Lyrics(lines: parseLrc('[00:10.00]aaaaaaaaaa\n[00:14.00]b'), source: 't');
      expect(even.sungAt(0, const Duration(seconds: 9)), 0);
      expect(even.sungAt(0, const Duration(seconds: 11)), closeTo(1 / 2.2, 0.01), reason: "220 ms per character");
      expect(even.sungAt(0, const Duration(seconds: 13)), 1);
      final gap = Lyrics(lines: parseLrc('[00:10.00]aaaaaaaaaa\n[01:10.00]b'), source: 't');
      expect(gap.sungAt(0, const Duration(milliseconds: 12200)), 1, reason: 'done long before the next line');
      final words = Lyrics(lines: parseLrc('[00:10.00]<00:10.00>aa <00:12.00>bb\n[00:14.00]c'), source: 't');
      // After "aa " (3 of 5 chars) at 12 s, half of "bb" 0.75 s later.
      expect(words.sungAt(0, const Duration(seconds: 12)), closeTo(3 / 5, 0.01));
      expect(words.sungAt(0, const Duration(milliseconds: 12750)), closeTo(4 / 5, 0.01));
    });

    test('plain text has no lines', () {
      expect(parseLrc('just\nplain\nlyrics'), isEmpty);
    });

    test('current line and karaoke progress', () {
      final l = Lyrics(lines: parseLrc('[00:01.00]a\n[00:03.00]b\n[00:07.00]c'), source: 'test');
      expect(l.indexAt(const Duration(milliseconds: 500)), -1);
      expect(l.indexAt(const Duration(seconds: 3)), 1);
      expect(l.indexAt(const Duration(seconds: 99)), 2);
      expect(l.progressAt(1, const Duration(seconds: 5)), closeTo(0.5, 1e-9));
      expect(l.progressAt(2, const Duration(seconds: 9)), closeTo(0.5, 1e-9), reason: 'last line: 4 s');
    });
  });

  group('lyrics repository', () {
    late AppDatabase db;
    late Directory dir;
    late Track track;
    var calls = 0;
    var mode = 'found';

    final client = MockClient((req) async {
      calls++;
      if (mode == 'down') return http.Response('error code: 502', 502);
      if (mode == 'none') return http.Response('{"code":404}', 404);
      expect(req.url.path, '/api/get');
      expect(req.url.queryParameters['track_name'], 'Song');
      expect(req.url.queryParameters['duration'], '180');
      return http.Response(jsonEncode({'syncedLyrics': '[00:01.00]hello\n[00:02.00]world', 'plainLyrics': 'hello\nworld'}), 200);
    });

    setUp(() async {
      calls = 0;
      db = AppDatabase(NativeDatabase.memory());
      dir = await Directory.systemTemp.createTemp('prism_lyrics_');
      final path = p.join(dir.path, 'song.mp3');
      await File(path).writeAsString('not really audio');
      await LibraryRepository(db).upsertTracks([TracksCompanion.insert(uri: path, folder: dir.path, title: 'Song')]);
      track = Track(id: 1, uri: path, title: 'Song', artist: 'Artist', durationMs: 180000);
    });
    tearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });

    test('online lookup is cached; offline never calls the network', () async {
      mode = 'found';
      final repo = LyricsRepository(db, lrclib: LrclibClient(client: client));
      expect(await repo.lyricsFor(track, online: false), isNull);
      expect(calls, 0);
      final l = await repo.lyricsFor(track, online: true);
      expect(l!.lines.map((x) => x.text), ['hello', 'world']);
      expect(l.source, 'lrclib');
      await repo.lyricsFor(track, online: true);
      expect(calls, 1, reason: 'second call served from cache');
    });

    test('a local .lrc file wins and needs no network', () async {
      await File(p.setExtension(track.uri, '.lrc')).writeAsString('[00:00.50]from file');
      final repo = LyricsRepository(db, lrclib: LrclibClient(client: client));
      final l = await repo.lyricsFor(track, online: true);
      expect((l!.source, l.lines.single.text), ('lrc-file', 'from file'));
      expect(calls, 0);
    });

    test('"not found" is cached, server errors are not', () async {
      final repo = LyricsRepository(db, lrclib: LrclibClient(client: client));
      mode = 'down';
      expect(await repo.lyricsFor(track, online: true), isNull);
      expect(await repo.lyricsFor(track, online: true), isNull);
      expect(calls, 2, reason: '502 → retried');
      mode = 'none';
      calls = 0;
      expect(await repo.lyricsFor(track, online: true), isNull);
      expect(await repo.lyricsFor(track, online: true), isNull);
      expect(calls, 4, reason: 'get + 3 searches once, then cached as none');
    });
  });
}

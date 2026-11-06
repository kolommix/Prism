import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/db/app_database.dart';
import 'package:prism/features/library/data/library_repository.dart';
import 'package:prism/features/stats/data/stats_repository.dart';
import 'package:prism/features/stats/domain/listen_accumulator.dart';
import 'package:prism/features/stats/domain/listening_stats.dart';
import 'package:prism/features/stats/domain/smart_playlist.dart';

import 'helpers.dart';

void main() {
  group('listen accumulator', () {
    final t0 = DateTime(2026, 11, 1, 12);
    DateTime at(int s) => t0.add(Duration(seconds: s));

    test('counts after 30 s, once', () {
      final a = ListenAccumulator()..setTrack(1, const Duration(minutes: 4), at(0));
      for (var s = 0; s <= 31; s++) {
        a.update(playing: true, now: at(s));
      }
      final done = a.setTrack(2, const Duration(minutes: 3), at(32));
      expect(done?.$1, 1);
      expect(done!.$3.inSeconds, 32, reason: "it kept playing until the switch at 32 s");
      expect(a.flush(at(40)), isNull, reason: 'track 2 barely played');
    });

    test('short tracks count after half their length; skips do not count', () {
      final a = ListenAccumulator()..setTrack(1, const Duration(seconds: 40), at(0));
      for (var s = 0; s <= 21; s++) {
        a.update(playing: true, now: at(s));
      }
      expect(a.flush(at(21)), isNotNull);
      final b = ListenAccumulator()..setTrack(1, const Duration(minutes: 4), at(0));
      for (var s = 0; s <= 10; s++) {
        b.update(playing: true, now: at(s));
      }
      expect(b.setTrack(2, Duration.zero, at(11)), isNull);
    });

    test('paused time and big clock jumps are ignored', () {
      final a = ListenAccumulator()..setTrack(1, const Duration(minutes: 4), at(0));
      a.update(playing: true, now: at(0));
      a.update(playing: false, now: at(4));
      a.update(playing: true, now: at(100)); // paused 96 s
      a.update(playing: true, now: at(103));
      a.update(playing: true, now: at(3600)); // laptop slept
      expect(a.flush(at(3600)), isNull, reason: 'only 7 s really listened');
    });

    test('repeat-one restart counts a second play', () {
      final a = ListenAccumulator()..setTrack(1, const Duration(seconds: 60), at(0));
      for (var s = 0; s <= 40; s++) {
        a.update(playing: true, now: at(s));
      }
      expect(a.restart(at(40))?.$1, 1);
      for (var s = 40; s <= 80; s++) {
        a.update(playing: true, now: at(s));
      }
      expect(a.flush(at(80))?.$1, 1);
    });
  });

  group('stats aggregation', () {
    test('totals, rankings, hours and streaks', () {
      final a = t(1, artist: 'A'), b = t(2, artist: 'B');
      final day = DateTime(2026, 10, 1, 22);
      final records = [
        PlayRecord(a, day, const Duration(minutes: 3)),
        PlayRecord(a, day.add(const Duration(days: 1)), const Duration(minutes: 3)),
        PlayRecord(b, day.add(const Duration(days: 2)), const Duration(minutes: 2)),
        PlayRecord(a, day.add(const Duration(days: 5)), const Duration(minutes: 1)),
      ];
      final s = computeStats(records, from: DateTime(2026, 10), to: DateTime(2026, 11));
      expect(s.plays, 4);
      expect(s.listened, const Duration(minutes: 9));
      expect(s.topTracks.first.item.id, 1);
      expect(s.topTracks.first.plays, 3);
      expect(s.topArtists.map((r) => r.item), ['A', 'B']);
      expect(s.peakHour, 22);
      expect((s.activeDays, s.longestStreakDays), (4, 3));
    });

    test('empty period', () {
      final s = computeStats(const [], from: DateTime(2026), to: DateTime(2027));
      expect((s.isEmpty, s.longestStreakDays), (true, 0));
      expect(s.topTracks, isEmpty);
    });
  });

  group('smart playlists (real SQL)', () {
    late AppDatabase db;
    late StatsRepository stats;
    late LibraryRepository lib;
    final now = DateTime.now();

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      stats = StatsRepository(db);
      lib = LibraryRepository(db);
      await lib.upsertTracks([
        for (var i = 1; i <= 5; i++)
          TracksCompanion.insert(
            uri: '/m/$i.mp3',
            folder: '/m',
            title: 'S$i',
            genre: Value(i.isEven ? 'Rock' : 'Jazz fusion'),
            year: Value(1990 + i * 5),
            addedAt: Value(now.subtract(Duration(days: i * 20))),
          ),
      ]);
      Future<void> play(int track, int daysAgo, [int times = 1]) async {
        for (var k = 0; k < times; k++) {
          await stats.recordPlay(track, now.subtract(Duration(days: daysAgo, minutes: k)), const Duration(minutes: 3));
        }
      }

      await play(1, 1, 5); // S1: 5 plays, recent
      await play(2, 100, 3); // S2: 3 plays, long ago
      await play(3, 2, 1); // S3: 1 play
    });
    tearDown(() => db.close());

    Future<List<String>> run(SmartPlaylist p) async => [for (final x in await stats.watchSmartTracks(p).first) x.title];

    test('most played, sorted by play count', () async {
      expect(await run(const SmartPlaylist(name: 'x', rules: [SmartRule.mostPlayed(minPlays: 2)])), ['S1', 'S2']);
    });

    test('play count window (last 30 days)', () async {
      expect(await run(const SmartPlaylist(name: 'x', rules: [SmartRule.mostPlayed(minPlays: 1, days: 30)])), ['S1', 'S3']);
    });

    test('recently added, genre, year, not played', () async {
      expect(await run(const SmartPlaylist(name: 'x', rules: [SmartRule.recentlyAdded(days: 45)], sort: SmartSort.recentlyAdded)),
          ['S1', 'S2']);
      expect(await run(const SmartPlaylist(name: 'x', rules: [SmartRule.genre(genre: 'jazz')], sort: SmartSort.title)),
          ['S1', 'S3', 'S5']);
      expect(await run(const SmartPlaylist(name: 'x', rules: [SmartRule.year(from: 2000, to: 2010)], sort: SmartSort.title)),
          ['S2', 'S3', 'S4']);
      expect(await run(const SmartPlaylist(name: 'x', rules: [SmartRule.notPlayedFor(days: 30)], sort: SmartSort.title)),
          ['S2', 'S4', 'S5']);
    });

    test('rules combine with AND and the limit applies', () async {
      expect(
        await run(const SmartPlaylist(
            name: 'x', rules: [SmartRule.mostPlayed(minPlays: 1), SmartRule.genre(genre: 'jazz')], limit: 1)),
        ['S1'],
      );
    });

    test('custom smart playlists are stored and listed after the built-ins', () async {
      final id = await stats.saveSmartPlaylist(const SmartPlaylist(name: 'Mine', rules: [SmartRule.year(from: 2000)]));
      final all = await stats.watchSmartPlaylists().first;
      expect(all.length, builtInSmartPlaylists.length + 1);
      expect(all.last.id, id);
      await stats.deleteSmartPlaylist(id);
      expect((await stats.watchSmartPlaylists().first).length, builtInSmartPlaylists.length);
    });

    test('stats from real play rows', () async {
      final s = await stats.stats(now.subtract(const Duration(days: 30)), now.add(const Duration(minutes: 1)));
      expect(s.plays, 6); // 5 × S1 + 1 × S3
      expect(s.topTracks.first.item.title, 'S1');
    });
  });
}

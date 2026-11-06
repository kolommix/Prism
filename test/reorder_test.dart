import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/db/app_database.dart';
import 'package:prism/features/library/data/library_repository.dart';
import 'package:prism/features/player/domain/playback_queue.dart';
import 'package:prism/features/player/domain/reorder.dart';
import 'package:prism/features/playlists/data/playlist_repository.dart';
import 'package:prism/features/playlists/presentation/playlist_page.dart';

import 'helpers.dart';

void main() {
  group('moving a group', () {
    List<String> run(List<String> items, Set<int> group, int start) => applyMoves(items, groupMoves(items.length, group, start));

    const abc = ['a', 'b', 'c', 'd', 'e', 'f'];

    test('to the top and the bottom, keeping their order', () {
      expect(run(abc, {2, 4}, 0), ['c', 'e', 'a', 'b', 'd', 'f']);
      expect(run(abc, {0, 2}, 6), ['b', 'd', 'e', 'f', 'a', 'c']);
    });

    test('to the middle', () {
      expect(run(abc, {0, 1}, 2), ['c', 'd', 'a', 'b', 'e', 'f']);
      expect(run(abc, {4, 5}, 1), ['a', 'e', 'f', 'b', 'c', 'd']);
    });

    test('nothing to do makes no moves', () {
      expect(groupMoves(6, {0, 1}, 0), isEmpty);
      expect(groupMoves(6, const {}, 2), isEmpty);
      expect(groupMoves(3, {9}, 0), isEmpty);
    });

    test('the same result in any order of selecting', () {
      expect(run(abc, {4, 2}, 0), run(abc, {2, 4}, 0));
    });

    test('dropping a dragged row of a group lands where it was dropped', () {
      // Drag "c" (selected with "a") so it ends at index 4 of the list without
      // "c": a b d e |c| f. "a" also leaves, so the group starts at 3.
      final start = groupDropStart({0, 2}, 2, 4);
      expect(start, 3);
      expect(run(abc, {0, 2}, start), ['b', 'd', 'e', 'a', 'c', 'f']);
    });

    test('dropping up works too', () {
      // Drag "e" (with "d") to the very top.
      final start = groupDropStart({3, 4}, 4, 0);
      expect(start, 0);
      expect(run(abc, {3, 4}, start), ['d', 'e', 'a', 'b', 'c', 'f']);
    });
  });

  group('queue', () {
    final tracks = [t(1), t(2), t(3), t(4), t(5)];

    test('the playing song stays current when a group moves around it', () {
      final q = const PlaybackQueue().copyWith(tracks: tracks, originalOrder: tracks, index: 2);
      final moved = q.moveMany({0, 4}, 3);
      expect(ids(moved.tracks), [2, 3, 4, 1, 5]);
      expect(moved.current?.id, 3);
    });

    test('moving the playing song itself keeps it current', () {
      final q = const PlaybackQueue().copyWith(tracks: tracks, originalOrder: tracks, index: 1);
      final moved = q.moveMany({1, 2}, 3);
      expect(moved.current?.id, 2);
    });

    test('removing several keeps the right song', () {
      final q = const PlaybackQueue().copyWith(tracks: tracks, originalOrder: tracks, index: 3);
      final out = q.removeAt(4).removeAt(0);
      expect(out.current?.id, 4);
    });
  });

  group('playlists', () {
    late AppDatabase db;
    late PlaylistRepository repo;
    late int id;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = PlaylistRepository(db);
      final lib = LibraryRepository(db);
      await lib.upsertTracks([
        for (var i = 1; i <= 5; i++)
          TracksCompanion.insert(
            uri: '/m/$i.mp3',
            title: 'Song $i',
            folder: '/m',
          ),
      ]);
      id = await repo.create('List');
      final all = await db.select(db.tracks).get();
      await repo.addTracks(id, [for (final x in all) x.id]);
    });
    tearDown(() => db.close());

    Future<List<String>> titles() async => [for (final i in await repo.watchItems(id).first) i.track.title];

    test('a group is saved in its new place', () async {
      await repo.moveMany(id, {3, 4}, 0);
      expect(await titles(), ['Song 4', 'Song 5', 'Song 1', 'Song 2', 'Song 3']);
    });

    test('several can be removed at once', () async {
      final items = await repo.watchItems(id).first;
      await repo.removeEntries(id, {items[0].entryId, items[2].entryId});
      expect(await titles(), ['Song 2', 'Song 4', 'Song 5']);
      await repo.moveMany(id, {2}, 0);
      expect(await titles(), ['Song 5', 'Song 2', 'Song 4']);
    });

    test('sort is saved per playlist; the custom order stays underneath', () async {
      await repo.moveMany(id, {4}, 0);
      expect(await repo.watchSort(id).first, PlaylistSort.custom);
      await repo.setSort(id, PlaylistSort.title);
      expect(await repo.watchSort(id).first, PlaylistSort.title);
      expect((await titles()).first, 'Song 5', reason: 'the saved order is untouched');
      final other = await repo.create('Other');
      expect(await repo.watchSort(other).first, PlaylistSort.custom);
    });

    test('"keep this order" makes a sort the custom order', () async {
      final items = await repo.watchItems(id).first;
      await repo.setOrder(id, [for (final i in items.reversed) i.entryId]);
      expect(await titles(), ['Song 5', 'Song 4', 'Song 3', 'Song 2', 'Song 1']);
    });

    test('sort modes', () async {
      final items = await repo.watchItems(id).first;
      expect(sortPlaylistItems(items, PlaylistSort.recent).first.track.title, 'Song 5');
      expect(sortPlaylistItems(items, PlaylistSort.title).first.track.title, 'Song 1');
      expect(sortPlaylistItems(items, PlaylistSort.custom).map((i) => i.entryId), items.map((i) => i.entryId));
    });
  });

  test('an unknown saved sort falls back to custom', () {
    expect(PlaylistSort.parse('nope'), PlaylistSort.custom);
    expect(PlaylistSort.parse(null), PlaylistSort.custom);
    expect(PlaylistSort.parse('longest'), PlaylistSort.longest);
  });

}

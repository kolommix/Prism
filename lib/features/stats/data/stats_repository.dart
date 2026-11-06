import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../library/data/library_repository.dart';
import '../../library/domain/track.dart';
import '../domain/listening_stats.dart';
import '../domain/smart_playlist.dart';

/// Play history, smart playlists and listening statistics.
class StatsRepository {
  StatsRepository(this._db);

  final AppDatabase _db;

  Future<void> recordPlay(int trackId, DateTime playedAt, Duration listened) => _db.into(_db.plays).insert(
        PlaysCompanion.insert(trackId: trackId, playedAt: playedAt, listenedMs: listened.inMilliseconds),
      );

  Stream<int> watchPlayCount() {
    final c = _db.plays.id.count();
    return (_db.selectOnly(_db.plays)..addColumns([c])).watchSingle().map((r) => r.read(c) ?? 0);
  }

  /// Plays in [from, to) joined with their tracks.
  Future<List<PlayRecord>> plays(DateTime from, DateTime to) async {
    final q = _db.select(_db.plays).join([innerJoin(_db.tracks, _db.tracks.id.equalsExp(_db.plays.trackId))])
      ..where(_db.plays.playedAt.isBiggerOrEqualValue(from) & _db.plays.playedAt.isSmallerThanValue(to));
    final rows = await q.get();
    return [
      for (final r in rows)
        PlayRecord(
          LibraryRepository.rowToTrack(r.readTable(_db.tracks)),
          r.readTable(_db.plays).playedAt,
          Duration(milliseconds: r.readTable(_db.plays).listenedMs),
        ),
    ];
  }

  Future<ListeningStats> stats(DateTime from, DateTime to) async =>
      computeStats(await plays(from, to), from: from, to: to);

  // --------------------------------------------------------- smart playlists

  Stream<List<SmartPlaylist>> watchSmartPlaylists() => _db.select(_db.smartPlaylists).watch().map((rows) => [
        ...builtInSmartPlaylists,
        for (final r in rows)
          if (_parse(r.json) case final p?) p.copyWith(id: r.id),
      ]);

  SmartPlaylist? _parse(String json) {
    try {
      return SmartPlaylist.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<int> saveSmartPlaylist(SmartPlaylist p) async {
    final json = jsonEncode(p.copyWith(id: 0).toJson());
    if (p.id > 0) {
      await (_db.update(_db.smartPlaylists)..where((s) => s.id.equals(p.id)))
          .write(SmartPlaylistsCompanion(json: Value(json)));
      return p.id;
    }
    return _db.into(_db.smartPlaylists).insert(SmartPlaylistsCompanion.insert(json: json));
  }

  Future<void> deleteSmartPlaylist(int id) => (_db.delete(_db.smartPlaylists)..where((s) => s.id.equals(id))).go();

  /// Live track list of a smart playlist (re-runs when tracks or plays change).
  Stream<List<Track>> watchSmartTracks(SmartPlaylist p) {
    final q = buildSmartQuery(p, DateTime.now());
    return _db
        .customSelect(
          q.sql,
          variables: [
            for (final a in q.args)
              if (a is int) Variable.withInt(a) else Variable.withString(a as String),
          ],
          readsFrom: {_db.tracks, _db.plays},
        )
        .watch()
        .map((rows) => [for (final r in rows) LibraryRepository.rowToTrack(_db.tracks.map(r.data))]);
  }
}

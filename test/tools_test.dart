import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/db/app_database.dart';
import 'package:prism/core/theme/theme_config.dart';
import 'package:prism/features/audio_fx/application/eq_controller.dart';
import 'package:prism/features/audio_fx/domain/eq_settings.dart';
import 'package:prism/features/editor/data/edit_repository.dart';
import 'package:prism/features/editor/domain/edit_decision_list.dart';
import 'package:prism/features/library/data/library_repository.dart';
import 'package:prism/features/library/data/search_text.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/playlists/data/playlist_repository.dart';
import 'package:prism/features/settings/application/settings_controller.dart';
import 'package:prism/features/settings/domain/app_settings.dart';
import 'package:prism/features/stats/data/stats_repository.dart';
import 'package:prism/features/stats/domain/smart_playlist.dart';
import 'package:prism/features/tools/data/backup_service.dart';
import 'package:prism/features/tools/data/tag_writer.dart';
import 'package:prism/features/tools/domain/track_matching.dart';
import 'package:drift/drift.dart' show Value;

import 'support/wav.dart';

Track tr(int id, String title, String artist, int ms, {String? uri}) =>
    Track(id: id, uri: uri ?? '/m/$id.mp3', title: title, artist: artist, durationMs: ms);

void main() {
  group('duplicates', () {
    test('same song across formats/case; different lengths stay apart', () {
      final groups = findDuplicates([
        tr(1, 'Song', 'Band', 200000),
        tr(2, 'song', 'BAND', 201000, uri: '/m/2.flac'),
        tr(3, 'Song', 'Band', 260000), // extended version
        tr(4, 'Other', 'Band', 200000),
        tr(5, 'Café', 'Band', 100000),
        tr(6, 'Cafe', 'Band', 100500),
      ]);
      expect(groups.map((g) => g.map((t) => t.id).toList()), [
        [5, 6],
        [1, 2],
      ]);
    });

    test('web files: "Artist - Title (Official Video)" without tags is the tagged song', () {
      final groups = findDuplicates([
        tr(1, 'BUTCHER VANITY', 'Yi Xi', 185000, uri: '/m/a.m4a'),
        tr(2, 'Yi Xi - BUTCHER VANITY (Official Video)', '', 186500, uri: '/m/b.mp3'),
        tr(3, 'BUTCHER_VANITY', '', 184000, uri: '/m/c.mp3'),
        tr(4, 'Streetcat', 'FLAVOR FOLEY', 214000, uri: '/m/d.m4a'),
        tr(5, 'Streetcat', 'VILLIAN, FLAVOR FOLEY', 213000, uri: '/m/e.m4a'),
      ]);
      expect(groups.map((g) => g.map((t) => t.id).toSet()), [
        {1, 2, 3},
        {4, 5},
      ]);
    });

    test('a song without an artist never joins two different artists', () {
      final groups = findDuplicates([
        tr(1, 'Home', 'Band A', 200000),
        tr(2, 'Home', 'Band B', 200500),
        tr(3, 'Home', '', 200200),
        tr(4, 'Home (Live)', 'Band A', 200000),
      ]);
      expect(groups, isEmpty, reason: 'unknown fits both, so it joins neither; live is another recording');
    });

    test('keeps the best copy: lossless, then bitrate, then cover and tags', () {
      final mp3 = tr(1, 'S', 'A', 200000, uri: '/m/s.mp3');
      final flac = tr(2, 'S', 'A', 200000, uri: '/m/s.flac');
      final m4a = tr(3, 'S', 'A', 200000, uri: '/m/s.m4a');
      final sizes = {1: 8000000, 2: 20000000, 3: 3200000};
      expect(bestCopy([mp3, flac, m4a], (t) => sizes[t.id]!).id, 2);
      expect(bestCopy([m4a, mp3], (t) => sizes[t.id]!).id, 1, reason: '320 kbps beats 128');
      final tagged = mp3.copyWith(id: 9, artworkPath: '/c.jpg');
      expect(bestCopy([mp3, tagged], (_) => 8000000).id, 9);
    });
  });

  group('track matching', () {
    final lib = [tr(1, 'A', 'X', 100000, uri: 'C:/Music/a.mp3'), tr(2, 'B', 'Y', 200000, uri: 'C:/Music/b.mp3')];
    final m = TrackMatcher(lib);

    test('by path, then by title/artist/length', () {
      expect(m.match(const TrackRef(uri: 'C:/Music/a.mp3', title: '?', artist: '?', durationMs: 0))?.id, 1);
      expect(m.match(const TrackRef(uri: '/storage/Music/b.mp3', title: 'b', artist: 'y', durationMs: 201500))?.id, 2);
      expect(m.match(const TrackRef(uri: '/x', title: 'B', artist: 'Y', durationMs: 260000)), isNull, reason: 'length differs');
    });
  });

  group('backup → restore on another device', () {
    test('playlists, favorites, themes, smart playlists and edits survive different paths', () async {
      // Device 1.
      final db1 = AppDatabase(NativeDatabase.memory());
      final lib1 = LibraryRepository(db1);
      TracksCompanion row(String uri, String title, String artist) => TracksCompanion.insert(
            uri: uri,
            folder: p.dirname(uri),
            title: title,
            artist: Value(artist),
            durationMs: const Value(180000),
            searchText: Value(buildSearchText(title: title, artist: artist)),
          );
      await lib1.upsertTracks([row('C:/M/a.mp3', 'Alpha', 'Band'), row('C:/M/b.mp3', 'Beta', 'Band')]);
      final pl1 = PlaylistRepository(db1);
      final id = await pl1.create('Road trip');
      await pl1.addTracks(id, [2, 1]);
      await lib1.toggleFavorite(2);
      await SavedThemesRepository(db1).save(const ThemeConfig(name: 'Friend theme'));
      await StatsRepository(db1).saveSmartPlaylist(const SmartPlaylist(name: 'Old', rules: [SmartRule.year(to: 1999)]));
      await EditRepository(db1).save(
        1,
        const EditDecisionList(sourceUri: 'C:/M/a.mp3', sourceDurationMs: 180000, ops: [EditOp.fadeIn(durationMs: 500)]),
        livePreset: true,
      );
      final json = await BackupService(
        library: lib1,
        playlists: pl1,
        themes: SavedThemesRepository(db1),
        stats: StatsRepository(db1),
        edits: EditRepository(db1),
      ).export(settings: const AppSettings(crossfadeSeconds: 5), eq: const EqState(settings: EqSettings(enabled: true)));

      // Device 2: same songs, other paths, other order.
      final db2 = AppDatabase(NativeDatabase.memory());
      final lib2 = LibraryRepository(db2);
      await lib2.upsertTracks([row('/storage/Music/beta.mp3', 'Beta', 'Band'), row('/storage/Music/alpha.mp3', 'Alpha', 'Band')]);
      final pl2 = PlaylistRepository(db2);
      final report = await BackupService(
        library: lib2,
        playlists: pl2,
        themes: SavedThemesRepository(db2),
        stats: StatsRepository(db2),
        edits: EditRepository(db2),
      ).restore(json);

      expect(report.settings?.crossfadeSeconds, 5);
      expect(report.eq?.settings.enabled, isTrue);
      expect((report.playlists, report.playlistSongs, report.missingSongs), (1, 2, 0));
      final lists = await pl2.watchPlaylists().first;
      final items = await pl2.watchItems(lists.single.id).first;
      expect(items.map((i) => i.track.title), ['Beta', 'Alpha'], reason: 'order kept');
      expect((await lib2.watchFavoriteTracks().first).single.title, 'Beta');
      expect((await SavedThemesRepository(db2).watchAll().first).single.$2.name, 'Friend theme');
      expect((await StatsRepository(db2).watchSmartPlaylists().first).last.name, 'Old');
      final alpha = (await lib2.search('alpha')).single;
      final edit = await EditRepository(db2).load(alpha.id);
      expect(edit!.livePreset, isTrue);
      expect(edit.edl.sourceUri, '/storage/Music/alpha.mp3', reason: 'edit re-pointed to the local file');
      await db1.close();
      await db2.close();
    });

    test('rejects other files', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final s = BackupService(
        library: LibraryRepository(db),
        playlists: PlaylistRepository(db),
        themes: SavedThemesRepository(db),
        stats: StatsRepository(db),
        edits: EditRepository(db),
      );
      expect(() => s.restore('{"format":"other"}'), throwsFormatException);
      expect(() => s.restore('nope'), throwsFormatException);
      await db.close();
    });
  });

  test('tag writer edits a real MP3 and keeps a backup', () async {
    final exe = p.absolute('windows/third_party/ffmpeg/ffmpeg.exe');
    final dir = await Directory.systemTemp.createTemp('prism_tags_');
    try {
      final wav = p.join(dir.path, 'in.wav');
      writeWav(wav, tones([440], seconds: 1));
      final mp3 = p.join(dir.path, 'song.mp3');
      final r = await Process.run(exe, ['-y', '-i', wav, '-metadata', 'title=Old', '-c:a', 'libmp3lame', mp3]);
      expect(r.exitCode, 0, reason: '${r.stderr}');
      final writer = TagWriter(Directory(p.join(dir.path, 'backups')));
      await writer.write(mp3, const TagEdit(title: 'New title', artist: 'New artist', album: 'LP', year: 2001));
      final m = readMetadata(File(mp3));
      expect((m.title, m.artist, m.album, m.year?.year), ('New title', 'New artist', 'LP', 2001));
      final backups = Directory(p.join(dir.path, 'backups')).listSync();
      expect(backups.length, 1);
      expect(readMetadata(File(backups.single.path)).title, 'Old');
      expect(() => writer.write(p.join(dir.path, 'x.ogg'), const TagEdit(title: 'x')), throwsA(isA<TagWriteException>()));
    } finally {
      await dir.delete(recursive: true);
    }
  }, tags: ['audio'], skip: File('windows/third_party/ffmpeg/ffmpeg.exe').existsSync() ? null : 'needs ffmpeg.exe');
}

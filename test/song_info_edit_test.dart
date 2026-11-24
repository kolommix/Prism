@Tags(['audio'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/db/app_database.dart';
import 'package:prism/core/ffmpeg/ffmpeg_runner.dart';
import 'package:prism/core/providers.dart';
import 'package:prism/features/audio_fx/application/loudness_controller.dart';
import 'package:prism/features/library/application/auto_tagger.dart';
import 'package:prism/features/library/application/library_providers.dart';
import 'package:prism/features/library/data/library_repository.dart';
import 'package:prism/features/settings/application/settings_controller.dart';
import 'package:prism/features/settings/domain/app_settings.dart';
import 'package:prism/features/tools/application/song_info_saver.dart';
import 'package:prism/features/tools/application/tools_providers.dart';
import 'package:prism/features/tools/data/tag_writer.dart';

/// Friends renamed imported songs and after the next start the old name was
/// back. Imported files had no tags: the editor wrote only the new title,
/// the file was read again (artist, album, cover gone), and 8 s after the
/// next start the background search filled the "missing" artist and put the
/// catalogue's title back.
void main() {
  final ffmpeg = FfmpegRunner.forPlatform()!;
  late AppDatabase db;
  late LibraryRepository repo;
  late Directory dir;
  late ProviderContainer c;
  late File song;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = LibraryRepository(db);
    dir = await Directory.systemTemp.createTemp('prism_edit_');
    final music = Directory(p.join(dir.path, 'imported_music'))..createSync();
    song = File(p.join(music.path, 'Band - Old Name [abcdefghijk].m4a'));
    final r = await ffmpeg.run([
      '-y', '-v', 'error', '-f', 'lavfi', '-i', 'sine=frequency=440:duration=4', '-c:a', 'aac', '-map_metadata', '-1', song.path,
    ]);
    expect(r.ok, isTrue, reason: r.log);
    c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        artworkDirProvider.overrideWithValue(Directory(p.join(dir.path, 'art'))),
        ffmpegRunnerProvider.overrideWithValue(ffmpeg),
        tagWriterProvider.overrideWith((ref) async => TagWriter(Directory(p.join(dir.path, 'backups')))),
        initialSettingsProvider.overrideWithValue(const AppSettings(autoFindInfo: false)),
      ],
    );
  });

  tearDown(() async {
    c.dispose();
    await db.close();
    await dir.delete(recursive: true);
  });

  test('renaming an imported song keeps everything else, through a rescan and the info search', () async {
    // As the import saves it: names in the library, nothing in the file.
    final id = await repo.addDownloadedFile(
      song,
      title: 'Old Name',
      artist: 'Band',
      album: 'Record',
      durationMs: 4000,
      artwork: 'https://i.ytimg.com/vi/abcdefghijk/mqdefault.jpg',
    );
    final before = (await repo.tracksByIds([id])).single;

    await c.read(songInfoSaverProvider).save(before, const TagEdit(title: 'New Name'));
    var t = (await repo.tracksByIds([id])).single;
    expect((t.title, t.artist, t.album), ('New Name', 'Band', 'Record'));
    expect(t.artworkPath, before.artworkPath, reason: 'the file has no picture: the cover stays');

    expect(await repo.uncheckedTrack(id), isNull, reason: 'an edit counts as checked');

    // Later the file changes on disk (another program): the library reads it
    // again and the info search may look at it again.
    await song.setLastModified(DateTime.now().add(const Duration(minutes: 1)));
    await c.read(libraryScannerProvider).scanFiles([song.path]).drain<void>();
    t = (await repo.tracksByIds([id])).single;
    expect((t.title, t.artist, t.album), ('New Name', 'Band', 'Record'), reason: 'the file says the same now');
    expect(t.artworkPath, before.artworkPath, reason: 'no picture in the file: the cover stays');

    // The catalogue knows the song under its old name: the search must not bring it back.
    final catalogue = MockClient((req) async {
      if (!req.url.host.contains('itunes')) return http.Response('{"data":[]}', 200);
      return http.Response(
        jsonEncode({
          'results': [
            {'trackName': 'Old Name', 'artistName': 'Band', 'collectionName': 'Record', 'trackTimeMillis': 4000},
          ],
        }),
        200,
      );
    });
    await c.read(autoTaggerProvider.notifier).start(client: catalogue, pace: Duration.zero);
    t = (await repo.tracksByIds([id])).single;
    expect((t.title, t.artist), ('New Name', 'Band'));
  });

  test('the info search never writes over an edit made while it was running', () async {
    final id = await repo.addDownloadedFile(song, title: 'old name', artist: '', album: '', durationMs: 4000);
    final asked = Completer<void>();
    final answer = Completer<void>();
    final client = MockClient((req) async {
      if (!req.url.host.contains('itunes')) return http.Response('{"data":[]}', 200);
      if (!asked.isCompleted) asked.complete();
      await answer.future;
      return http.Response(
        jsonEncode({
          'results': [
            {'trackName': 'Old Name', 'artistName': 'Catalogue Band', 'collectionName': 'LP', 'trackTimeMillis': 4000},
          ],
        }),
        200,
      );
    });
    final run = c.read(autoTaggerProvider.notifier).start(client: client, pace: Duration.zero);
    await asked.future;
    // The user renames it while the search waits for its answer.
    final t = (await repo.tracksByIds([id])).single;
    await c.read(songInfoSaverProvider).save(t, const TagEdit(title: 'Mine', artist: 'My Band'));
    answer.complete();
    await run;
    final after = (await repo.tracksByIds([id])).single;
    expect((after.title, after.artist), ('Mine', 'My Band'));
  });

  test('formats without tags keep the edit in the library', () async {
    final opus = File(p.join(dir.path, 'imported_music', 'x [abcdefghijk].opus'))..writeAsBytesSync(List.filled(2048, 1));
    final id = await repo.addDownloadedFile(opus, title: 'Old', artist: 'A', album: '', durationMs: 4000);
    final t = (await repo.tracksByIds([id])).single;
    final wrote = await c.read(songInfoSaverProvider).save(t, const TagEdit(title: 'New'));
    expect(wrote, isFalse);
    final after = (await repo.tracksByIds([id])).single;
    expect((after.title, after.artist), ('New', 'A'));
    expect(await repo.uncheckedTrack(id), isNull);
  });
}

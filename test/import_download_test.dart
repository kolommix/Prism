import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/db/app_database.dart';
import 'package:prism/core/providers.dart';
import 'package:prism/features/library/application/library_providers.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/online/application/import_downloader.dart';
import 'package:prism/features/online/application/online_hub.dart';
import 'package:prism/features/online/application/online_providers.dart';
import 'package:prism/features/online/data/import_repository.dart';
import 'package:prism/features/online/data/oauth.dart';
import 'package:prism/features/online/data/online_config.dart';
import 'package:prism/features/online/data/online_http.dart';
import 'package:prism/features/online/data/remote_track_store.dart';
import 'package:prism/features/online/data/stream_cache.dart';
import 'package:prism/features/online/domain/external_track.dart';
import 'package:prism/features/online/domain/online_error.dart';
import 'package:prism/features/online/services/music_service_module.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Writes a small file instead of asking YouTube.
class _FakeYoutube extends MusicServiceModule {
  int calls = 0;
  bool refuse = false;

  /// Video ids YouTube won't let us save.
  final blocked = <String>{};
  List<Track> results = const [];
  final saved = <String>[];

  @override
  OnlineService get service => OnlineService.youtube;
  @override
  Set<ModuleFeature> get features => const {ModuleFeature.stream, ModuleFeature.search};

  @override
  Future<String> download(Track track, String targetPathWithoutExt) async {
    calls++;
    if (refuse) throw OnlineException(OnlineErrorKind.rateLimited, service: service);
    final id = Uri.parse(track.uri).queryParameters['v']!;
    if (blocked.contains(id)) throw OnlineException(OnlineErrorKind.notFound, service: service);
    saved.add(id);
    await File('$targetPathWithoutExt.m4a').writeAsString('audio');
    return 'm4a';
  }

  @override
  Future<List<Track>> search(String query, {int limit = 20}) async => results;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('file names are safe and keep the video id', () {
    expect(importFileName('AC/DC', 'Back: In "Black"?', 'abc'), 'AC DC - Back In Black [abc]');
    expect(importFileName('', 'Song', 'x'), 'Song [x]');
    expect(importFileName('A', 'y' * 300, 'x').length, lessThan(140));
  });

  test('waits longer after each refusal, and never gives up for good', () {
    expect([for (var i = 0; i < 7; i++) importRetryDelay(i).inMinutes], [2, 5, 10, 20, 30, 30, 30]);
  });

  test('old saved flags load with downloads off', () {
    expect(OnlineFlags.fromJson(const {'youtube': true}).importDownload, isFalse);
    expect(OnlineFlags.fromJson(const OnlineFlags(importDownload: true).toJson()).importDownload, isTrue);
  });

  group('downloads', () {
    late AppDatabase db;
    late Directory dir;
    late ProviderContainer c;
    late _FakeYoutube yt;
    late ImportRepository repo;

    setUp(() async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      db = AppDatabase(NativeDatabase.memory());
      dir = await Directory.systemTemp.createTemp('prism_dl_');
      yt = _FakeYoutube();
      final hub = OnlineHub(
        configLoader: OnlineConfigLoader(dir),
        prefs: SharedPreferencesAsync(),
        tokens: MemoryTokenStore(),
        http: OnlineHttp(),
        launch: (_) async => true,
        cache: StreamCache(Directory('${dir.path}/stream_cache')),
      );
      await hub.init();
      c = ProviderContainer(overrides: [
        appDatabaseProvider.overrideWithValue(db),
        onlineHubProvider.overrideWithValue(hub),
        importDownloadModuleProvider.overrideWithValue(yt),
      ]);
      repo = c.read(importRepositoryProvider);
    });
    tearDown(() async {
      c.dispose();
      await db.close();
      await dir.delete(recursive: true);
    });

    Future<Track> remote(String id) => RemoteTrackStore(db).ensure(Track(
          id: 0,
          sourceId: 'youtube',
          uri: 'https://www.youtube.com/watch?v=$id',
          title: 'Band - Song $id (Official Video)',
          artist: 'BandVEVO',
          durationMs: 200000,
        ));

    Future<int> job(int songs) => repo.createJob(ImportedList(
          name: 'Mix',
          origin: OnlineService.spotify,
          tracks: [
            for (var i = 0; i < songs; i++)
              ExternalTrack(service: OnlineService.spotify, title: 'Song $i', artists: const ['Band'], album: 'LP', externalId: '$i'),
          ],
        ));

    Future<void> finished() async {
      for (var i = 0; i < 400; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (c.read(importDownloaderProvider)?.running == false) return;
      }
      fail('never finished');
    }

    test('a found song becomes a real library song with the imported names', () async {
      final id = await job(1);
      final item = (await repo.watchItems(id).first).single;
      await repo.saveMatch(item.id, trackId: (await remote('aaa')).id, confidence: 0.9, source: 'youtube');

      c.read(importDownloaderProvider.notifier).poke(id);
      await finished();

      final library = await c.read(libraryRepositoryProvider).watchTracks().first;
      expect(library.single.title, 'Song 0');
      expect(library.single.artist, 'Band');
      expect(library.single.album, 'LP');
      expect(library.single.durationMs, 200000);
      expect(library.single.uri, contains('[aaa]'));
      expect(File(library.single.uri).existsSync(), isTrue);

      final now = (await repo.watchItems(id).first).single;
      expect(now.track?.sourceId, 'local');
      expect(now.confidence, 0.9, reason: 'same match');
      final saved = (await repo.watchJob(id).first)!;
      final entries = await (db.select(db.playlistEntries)..where((e) => e.playlistId.equals(saved.playlistId!))).get();
      expect(entries.single.trackId, library.single.id, reason: 'the playlist plays the file');
      expect(c.read(importDownloaderProvider)!.done, 1);
    });

    test('a song that only streams stays out of the library until it is saved', () async {
      final id = await job(1);
      final item = (await repo.watchItems(id).first).single;
      await repo.saveMatch(item.id, trackId: (await remote('str')).id, confidence: 0.9, source: 'youtube');
      expect(await c.read(libraryRepositoryProvider).watchTracks().first, isEmpty);
    });

    test('uncertain matches are saved too, nothing waits for a check', () async {
      final id = await job(1);
      final item = (await repo.watchItems(id).first).single;
      await repo.saveMatch(item.id, trackId: (await remote('bbb')).id, confidence: 0.55, source: 'youtube');
      c.read(importDownloaderProvider.notifier).poke(id);
      await finished();
      expect(yt.calls, 1);
      expect(await c.read(libraryRepositoryProvider).watchTracks().first, hasLength(1));
    });

    test('a blocked upload is replaced by another upload of the same song', () async {
      yt.blocked.add('blk');
      yt.results = [
        Track(id: 0, sourceId: 'youtube', uri: 'https://www.youtube.com/watch?v=blk', title: 'Song 0', artist: 'Band', durationMs: 200000),
        Track(id: 0, sourceId: 'youtube', uri: 'https://www.youtube.com/watch?v=zzz', title: 'Other thing', artist: 'Nobody', durationMs: 50000),
        Track(id: 0, sourceId: 'youtube', uri: 'https://www.youtube.com/watch?v=alt', title: 'Band - Song 0', artist: 'Band - Topic', durationMs: 200000),
      ];
      final id = await job(1);
      final item = (await repo.watchItems(id).first).single;
      await repo.saveMatch(item.id, trackId: (await remote('blk')).id, confidence: 0.9, source: 'youtube');
      c.read(importDownloaderProvider.notifier).poke(id);
      await finished();
      expect(yt.saved, ['alt'], reason: 'the unrelated result is not taken');
      final library = await c.read(libraryRepositoryProvider).watchTracks().first;
      expect(library.single.title, 'Song 0', reason: 'keeps the imported names');
      expect((await repo.watchItems(id).first).single.track?.sourceId, 'local');
    });

    test('blocked songs do not stop the others, cut-off files are cleaned up', () async {
      final folder = c.read(importDownloadDirProvider);
      await folder.create(recursive: true);
      final stale = File('${folder.path}/Old [x].webm.part')..writeAsStringSync('');
      // yt-dlp's leftovers of a cut-off save of 'ok': not "already saved".
      final frag = File('${folder.path}/Song [ok].m4a.part-Frag3')..writeAsStringSync('');
      final ytdl = File('${folder.path}/Song [ok].m4a.ytdl')..writeAsStringSync('');
      final id = await job(6);
      final items = await repo.watchItems(id).first;
      for (var i = 0; i < items.length; i++) {
        if (i < 5) yt.blocked.add('b$i');
        await repo.saveMatch(items[i].id, trackId: (await remote(i < 5 ? 'b$i' : 'ok')).id, confidence: 0.9, source: 'youtube');
      }
      c.read(importDownloaderProvider.notifier).poke(id);
      await finished();
      expect(stale.existsSync(), isFalse);
      expect(frag.existsSync() || ytdl.existsSync(), isFalse);
      expect(yt.saved, ['ok'], reason: 'five blocked in a row is not a refusing service');
      expect(c.read(importDownloaderProvider)!.failed, 5);
    });

    test('the same video is not downloaded twice', () async {
      final id = await job(2);
      final items = await repo.watchItems(id).first;
      final t = await remote('ccc');
      await repo.saveMatch(items[0].id, trackId: t.id, confidence: 0.9, source: 'youtube');
      c.read(importDownloaderProvider.notifier).poke(id);
      await finished();
      final first = yt.calls;
      await repo.saveMatch(items[1].id, trackId: t.id, confidence: 0.9, source: 'youtube');
      c.read(importDownloaderProvider.notifier).poke(id);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await finished();
      expect(yt.calls, first);
    });

    test('stops when the service keeps refusing, the song keeps streaming, retry works', () async {
      yt.refuse = true;
      final id = await job(8);
      final items = await repo.watchItems(id).first;
      for (var i = 0; i < items.length; i++) {
        await repo.saveMatch(items[i].id, trackId: (await remote('v$i')).id, confidence: 0.9, source: 'youtube');
      }
      c.read(importDownloaderProvider.notifier).poke(id);
      await finished();
      final d = c.read(importDownloaderProvider)!;
      expect(d.failed, greaterThanOrEqualTo(ImportDownloader.giveUpAfter));
      expect(d.failed, lessThan(8), reason: 'gives up instead of hammering the service');
      expect(d.message, isNotNull);
      expect((await repo.watchItems(id).first).first.track?.sourceId, 'youtube');

      yt.refuse = false;
      c.read(importDownloaderProvider.notifier).retry(id);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await finished();
      expect((await c.read(libraryRepositoryProvider).watchTracks().first), hasLength(8));
    });
  });
}

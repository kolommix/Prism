@Tags(['network'])
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/db/app_database.dart';
import 'package:prism/core/providers.dart';
import 'package:prism/features/online/application/import_flow.dart';
import 'package:prism/features/online/application/online_hub.dart';
import 'package:prism/features/online/application/online_providers.dart';
import 'package:prism/features/online/data/oauth.dart';
import 'package:prism/features/online/data/online_config.dart';
import 'package:prism/features/online/data/stream_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:prism/features/online/data/online_http.dart';
import 'package:prism/features/online/domain/external_track.dart';
import 'package:prism/features/online/domain/link_parser.dart';
import 'package:prism/features/online/services/link_only/link_modules.dart';
import 'package:prism/features/online/services/public_links/public_readers.dart';

/// Reads real public links with no key, login or switch, the way the Import
/// screen does.
///
/// Run: flutter test --tags network test/platform/public_links_live_test.dart
void main() {
  final http = OnlineHttp();

  Future<ImportedList> read(dynamic module, String url) async {
    final list = await module.openLink(parseMusicLink(url)!) as ImportedList;
    // ignore: avoid_print
    print('$url: "${list.name}", ${list.tracks.length} songs, first: ${list.tracks.first}');
    return list;
  }

  test('Spotify playlist, album and song', () async {
    final reader = SpotifyPublicReader(http);
    final playlist = await read(reader, 'https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M?si=abc');
    expect(playlist.tracks.length, greaterThan(10));
    expect(playlist.tracks.first.artists, isNotEmpty);
    expect(playlist.tracks.first.durationMs, greaterThan(0));
    expect((await read(reader, 'https://open.spotify.com/album/4aawyAB9vmqN3uQ7FjRGTy')).tracks.length, greaterThan(5));
    expect((await read(reader, 'https://open.spotify.com/track/11dFghVXANMlKmJXsNCbNl')).tracks, hasLength(1));
  });

  test('the whole flow with no key: link, job, matching, review, re-sync', () async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final dir = await Directory.systemTemp.createTemp('prism_flow_');
    final db = AppDatabase(NativeDatabase.memory());
    final hub = OnlineHub(
      configLoader: OnlineConfigLoader(dir),
      prefs: SharedPreferencesAsync(),
      tokens: MemoryTokenStore(),
      http: http,
      launch: (_) async => true,
      cache: StreamCache(Directory('${dir.path}/cache')),
    );
    await hub.init();
    final c = ProviderContainer(overrides: [appDatabaseProvider.overrideWithValue(db), onlineHubProvider.overrideWithValue(hub)]);
    addTearDown(() async {
      c.dispose();
      await db.close();
      await dir.delete(recursive: true);
    });
    final flow = c.read(importFlowProvider);
    final repo = c.read(importRepositoryProvider);
    final link = parseMusicLink('https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M?si=abc')!;
    final ids = await flow.start(await flow.readLink(link));
    while (c.read(importRunnerProvider) == null || c.read(importRunnerProvider)!.running) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    var job = (await repo.watchJob(ids.single).first)!;
    expect(job.pending, 0);
    expect(job.total, greaterThan(10));
    // Nothing is on but the (empty) library, so all wait in Review.
    expect((await repo.watchReview().first).length, job.total);
    expect(job.sourceUrl, link.canonicalUrl);
    // The same link again syncs the same job instead of copying it.
    final again = await flow.start(await flow.readLink(parseMusicLink('https://open.spotify.com/intl-de/playlist/37i9dQZF1DXcBWIGoYBM5M?si=zzz')!));
    expect(again.single, ids.single);
    await flow.resync(job);
    job = (await repo.watchJob(ids.single).first)!;
    expect(job.total, greaterThan(10));
    expect((await repo.watchJobs().first), hasLength(1));
    // ignore: avoid_print
    print('flow: ${job.name}, ${job.total} songs, source ${job.sourceUrl}');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('YouTube one video', () async {
    final list = await read(YoutubePublicReader(http), 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
    expect(list.tracks.single.title, isNotEmpty);
  });

  test('Deezer playlist', () async {
    expect((await read(DeezerModule(http), 'https://www.deezer.com/playlist/908622995')).tracks.length, greaterThan(5));
  });

  test('Apple Music album', () async {
    expect((await read(AppleMusicModule(http), 'https://music.apple.com/us/album/thriller/269572838')).tracks.length, greaterThan(5));
  });
}

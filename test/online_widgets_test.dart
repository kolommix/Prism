import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/db/app_database.dart';
import 'package:prism/core/providers.dart';
import 'package:prism/core/theme/theme_builder.dart';
import 'package:prism/core/theme/theme_config.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/library/application/library_providers.dart';
import 'package:prism/features/library/presentation/search_page.dart';
import 'package:prism/features/online/application/online_hub.dart';
import 'package:prism/features/online/application/online_providers.dart';
import 'package:prism/features/online/data/import_repository.dart';
import 'package:prism/features/online/data/oauth.dart';
import 'package:prism/features/online/data/online_config.dart';
import 'package:prism/features/online/data/online_http.dart';
import 'package:prism/features/online/data/remote_track_store.dart';
import 'package:prism/features/online/data/stream_cache.dart';
import 'package:prism/features/online/domain/external_track.dart';
import 'package:prism/features/online/presentation/import_job_page.dart';
import 'package:prism/features/online/presentation/import_page.dart';
import 'package:prism/features/online/presentation/import_review_page.dart';
import 'package:prism/features/online/presentation/online_settings_page.dart';
import 'package:prism/features/player/application/player_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// The new screens render with real repositories (in-memory SQLite) and a
/// real OnlineHub (no network: nothing here triggers a request).
void main() {
  late AppDatabase db;
  late Directory dir;
  late OnlineHub hub;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    db = AppDatabase(NativeDatabase.memory());
    dir = await Directory.systemTemp.createTemp('prism_online_ui_');
    hub = OnlineHub(
      configLoader: OnlineConfigLoader(dir),
      prefs: SharedPreferencesAsync(),
      tokens: MemoryTokenStore(),
      http: OnlineHttp(),
      launch: (_) async => true,
      cache: StreamCache(Directory('${dir.path}/cache')),
    );
    await hub.init();
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  Widget app(Widget child, {List<dynamic> extra = const []}) => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      onlineHubProvider.overrideWithValue(hub),
      currentTrackProvider.overrideWithValue(null),
      isPlayingProvider.overrideWithValue(false),
      ...extra.cast(),
    ],
    child: MaterialApp(
      theme: buildPrismTheme(const ThemeConfig(), platformBrightness: Brightness.dark, reduceMotion: true),
      home: child,
    ),
  );

  /// Lets database work started by a tap finish (real IO), then rebuilds.
  Future<void> settleDb(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pumpAndSettle();
  }

  /// Unmounts and lets drift's stream-cleanup timers run.
  Future<void> finish(WidgetTester tester) async {
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  void bigScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('online settings: statuses, flags, extractor needs a confirmation', (tester) async {
    bigScreen(tester);
    await tester.pumpWidget(app(const OnlineSettingsPage()));
    await tester.pumpAndSettle();
    // No keys file → services that need keys say so; Deezer works without.
    expect(find.textContaining('spotify.clientId'), findsOneWidget);
    expect(find.textContaining('soundcloud.clientId'), findsOneWidget);
    expect(hub.module(OnlineService.deezer), isNotNull);
    expect(hub.module(OnlineService.appleMusic), isNull, reason: 'off by default');

    // Turning the extractor on asks first; "Cancel" keeps it off.
    await tester.tap(find.text('YouTube extractor'));
    await tester.pumpAndSettle();
    expect(find.text('Turn on the YouTube extractor?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(hub.flags.youtubeExtractor, isFalse);
    await tester.tap(find.text('YouTube extractor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I understand, turn on'));
    await tester.pumpAndSettle();
    expect(hub.flags.youtubeExtractor, isTrue);
    expect(hub.module(OnlineService.youtube), isNotNull);
    expect(hub.playable.map((m) => m.service), [OnlineService.youtube]);
    expect(find.text('What each service allows'), findsOneWidget);
    await finish(tester);
  });

  /// What the system clipboard holds in these tests.
  void clipboard(WidgetTester tester, String? text) {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
      if (c.method == 'Clipboard.getData') return text == null ? null : {'text': text};
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
  }

  testWidgets('import box: works out the service, public links need no set-up', (tester) async {
    bigScreen(tester);
    clipboard(tester, null);
    await tester.pumpWidget(app(const ImportPage()));
    await tester.pumpAndSettle();
    final import = find.widgetWithText(FilledButton, 'Import');
    expect(tester.widget<FilledButton>(import).onPressed, isNull, reason: 'nothing pasted yet');
    expect(find.textContaining('Public links work with no account'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'hello');
    await tester.pump();
    expect(find.text('Not a link Prism can read'), findsOneWidget);
    expect(tester.widget<FilledButton>(import).onPressed, isNull);

    for (final (url, label) in [
      ('https://www.deezer.com/playlist/908622995', 'Deezer playlist'),
      ('https://music.apple.com/us/album/x/1440857781', 'Apple Music album'),
      ('https://open.spotify.com/playlist/37i9', 'Spotify playlist'),
      ('https://www.youtube.com/playlist?list=PL1', 'YouTube playlist'),
      ('https://music.yandex.ru/users/me/playlists/1', 'Yandex Music playlist'),
    ]) {
      await tester.enterText(find.byType(TextField).first, 'Listen: $url');
      await tester.pump();
      expect(find.text(label), findsOneWidget, reason: url);
      expect(tester.widget<FilledButton>(import).onPressed, isNotNull, reason: url);
    }
    await finish(tester);
  });

  testWidgets('import box: a SoundCloud link without a key says what to do', (tester) async {
    bigScreen(tester);
    clipboard(tester, null);
    await tester.pumpWidget(app(const ImportPage()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'https://soundcloud.com/a/sets/b');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Import'));
    await settleDb(tester);
    expect(find.text('Set up'), findsOneWidget);
    expect(find.textContaining('links need a free key'), findsWidgets);
    await finish(tester);
  });

  testWidgets('clipboard: a copied playlist is offered, one song is not, no is remembered', (tester) async {
    bigScreen(tester);
    clipboard(tester, 'https://open.spotify.com/playlist/clip1?si=x');
    await tester.pumpWidget(app(const ImportPage()));
    await settleDb(tester);
    expect(find.text('Import this playlist?'), findsOneWidget);
    expect(find.text('Spotify playlist'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty, reason: 'offered, not pasted');

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Import this playlist?'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(const ImportPage()));
    await settleDb(tester);
    expect(find.text('Import this playlist?'), findsNothing, reason: 'said no already');
    await tester.pumpWidget(const SizedBox());

    clipboard(tester, 'https://youtu.be/one-song');
    await tester.pumpWidget(app(const ImportPage()));
    await settleDb(tester);
    expect(find.text('Import this playlist?'), findsNothing);
    await finish(tester);
  });

  testWidgets('file: starts right away, no preview, recent imports list it', (tester) async {
    bigScreen(tester);
    clipboard(tester, null);
    final repo = ImportRepository(db);
    await tester.runAsync(
      () => repo.createJob(
        const ImportedList(
          name: 'Earlier',
          origin: OnlineService.spotify,
          sourceUrl: 'https://open.spotify.com/playlist/9',
          tracks: [ExternalTrack(service: OnlineService.spotify, title: 'One', artists: ['A'])],
        ),
      ),
    );
    await tester.pumpWidget(app(const ImportPage()));
    await settleDb(tester);
    expect(find.text('Recent imports'), findsOneWidget);
    expect(find.text('Earlier'), findsOneWidget);
    expect(find.byTooltip('Sync again'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('review: one tap to accept, the list empties, the playlist follows', (tester) async {
    bigScreen(tester);
    final repo = ImportRepository(db);
    final id = (await tester.runAsync(() => _seedJob(db)))!;
    await tester.pumpWidget(app(const ImportReviewPage()));
    await settleDb(tester);
    expect(find.textContaining('Unsure'), findsOneWidget);
    expect(find.textContaining('Missing'), findsOneWidget);
    expect(find.textContaining('Good – A'), findsNothing, reason: 'sure matches are not asked about');
    expect(find.text('Accept 1'), findsOneWidget);
    expect(find.text('Skip 1 not found'), findsOneWidget);

    await tester.tap(find.byTooltip('Right song'));
    await settleDb(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('Unsure'), findsNothing);
    final job = (await tester.runAsync(() => repo.watchJob(id).first))!;
    expect(job.playlistId, isNotNull, reason: 'decisions reach the playlist right away');

    await tester.tap(find.byTooltip('No match'));
    await settleDb(tester);
    await tester.pumpAndSettle();
    expect(find.textContaining('Nothing to check'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('import job: confidence, filters, fix sheet, no save step', (tester) async {
    bigScreen(tester);
    final id = (await tester.runAsync(() => _seedJob(db)))!;
    await tester.pumpWidget(app(ImportJobPage(jobId: id)));
    await tester.pumpAndSettle();
    expect(find.textContaining('High 93%'), findsOneWidget);
    expect(find.textContaining('Low – check it 55%'), findsOneWidget);
    expect(find.text('No match'), findsOneWidget);
    // Imports from before songs went in by themselves can still be saved.
    expect(find.text('Create playlist (2 songs)'), findsOneWidget);
    expect(find.text('Download the songs'), findsOneWidget);

    await tester.tap(find.text('Check 2'));
    await tester.pumpAndSettle();
    expect(find.text('Good – A'), findsNothing);
    expect(find.text('Unsure – A'), findsOneWidget);

    // Fix sheet opens with the search prefilled (local search only here).
    await tester.tap(find.text('Fix').first);
    await tester.pumpAndSettle();
    expect(find.text('Fix match'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'A unsure'), findsOneWidget);
    await tester.tap(find.text('No match').last);
    await settleDb(tester);
    await tester.pumpAndSettle();
    expect(find.text('Unsure – A'), findsNothing, reason: 'decided');
    await finish(tester);
  });

  testWidgets('unified search: library + online sections, errors stay per service', (tester) async {
    bigScreen(tester);
    await tester.runAsync(() => hub.setFlags(hub.flags.copyWith(youtubeExtractor: true)));
    await tester.pumpWidget(
      app(
        const SearchPage(),
        extra: [
          searchResultsProvider.overrideWith((ref) async => const <Track>[]),
          onlineSearchProvider.overrideWith(
            (ref, key) async => [
              Track(
                id: 0,
                sourceId: 'youtube',
                uri: 'https://www.youtube.com/watch?v=q',
                title: 'Band - ${key.query}',
                artist: 'BandVEVO',
                durationMs: 200000,
              ),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Type to search your library and online'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'song');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Your library'), findsOneWidget);
    expect(find.text('Nothing found in your library'), findsOneWidget);
    expect(find.text('Band - song'), findsOneWidget);
    expect(find.text('BandVEVO · YouTube'), findsOneWidget);
    // Hide YouTube with its chip.
    await tester.tap(find.widgetWithText(FilterChip, 'YouTube'));
    await tester.pumpAndSettle();
    expect(find.text('Band - song'), findsNothing);
    await finish(tester);
  });
}

Future<int> _seedJob(AppDatabase db) async {
  final repo = ImportRepository(db);
  final id = await repo.createJob(
    const ImportedList(
      name: 'Mix',
      origin: OnlineService.spotify,
      tracks: [
        ExternalTrack(service: OnlineService.spotify, title: 'Good', artists: ['A']),
        ExternalTrack(service: OnlineService.spotify, title: 'Unsure', artists: ['A']),
        ExternalTrack(service: OnlineService.spotify, title: 'Missing', artists: ['A']),
      ],
    ),
  );
  final items = await repo.watchItems(id).first;
  final t1 = await RemoteTrackStore(db).ensure(
    const Track(id: 0, sourceId: 'youtube', uri: 'https://www.youtube.com/watch?v=1', title: 'A - Good', artist: 'A'),
  );
  await repo.saveMatch(items[0].id, trackId: t1.id, confidence: 0.93, source: 'youtube');
  await repo.saveMatch(items[1].id, trackId: t1.id, confidence: 0.55, source: 'youtube', note: 'live version');
  await repo.saveMatch(items[2].id, trackId: null, confidence: 0.1, note: 'Not in your library.');
  await repo.setState(id, ImportJobState.review);
  return id;
}

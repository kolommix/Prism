import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/theme/theme_builder.dart';
import 'package:prism/core/theme/theme_config.dart';
import 'package:prism/features/background/application/background_input.dart';
import 'package:prism/features/background/domain/background_config.dart';
import 'package:prism/features/background/presentation/background_effects.dart';
import 'package:prism/features/background/presentation/background_page.dart';
import 'package:prism/features/background/presentation/prism_background.dart';
import 'package:prism/features/background/presentation/live_background.dart';
import 'package:prism/features/desktop/application/desktop_extras.dart';
import 'package:prism/features/desktop/data/cover_lookup.dart';
import 'package:prism/features/desktop/data/discord_ipc.dart';
import 'package:prism/features/desktop/presentation/discord_settings.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/player/domain/seek_bar_style.dart';
import 'package:prism/features/player/engine/playback_engine.dart';
import 'package:prism/features/player/application/player_controller.dart';
import 'package:prism/features/player/application/player_providers.dart';
import 'package:prism/features/player/presentation/immersive_player_page.dart';
import 'package:prism/features/player/presentation/widgets/waveform_seek_bar.dart';
import 'package:prism/features/settings/application/settings_controller.dart';
import 'package:prism/features/settings/data/settings_store.dart';
import 'package:prism/features/settings/domain/app_settings.dart';
import 'package:prism/features/shell/presentation/prism_logo.dart';
import 'package:prism/features/stats/domain/deep_stats.dart';
import 'package:prism/features/stats/domain/listening_stats.dart';
import 'package:prism/features/stats/presentation/stats_charts.dart';
import 'package:prism/features/visualizer/presentation/visualizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:prism/features/library/application/library_providers.dart';
import 'package:prism/features/lyrics/application/lyrics_providers.dart';
import 'package:prism/features/lyrics/domain/lrc.dart';
import 'package:prism/features/player/domain/playback_queue.dart';

import 'helpers.dart';
import 'player_controller_test.dart' show FakeEngine, MemoryStore;

const _playing = EngineState(
  playing: true,
  status: EngineStatus.ready,
  position: Duration(seconds: 60),
  duration: Duration(minutes: 3),
);

Widget _app(Widget child, {AppSettings settings = const AppSettings(), List<dynamic> overrides = const []}) => ProviderScope(
      overrides: [
        initialSettingsProvider.overrideWithValue(settings),
        currentTrackProvider.overrideWithValue(t(1, title: 'Song', artist: 'Band')),
        engineStateProvider.overrideWith((ref) => Stream.value(_playing)),
        tuningProvider.overrideWith((ref) => Stream.value(const PlaybackTuning())),
        isPlayingProvider.overrideWithValue(true),
        spectrumProvider.overrideWith((ref, track) async => null),
        playerControllerProvider.overrideWithValue(PlayerController(engine: FakeEngine(), store: MemoryStore())),
        queueProvider.overrideWith((ref) => Stream.value(PlaybackQueue.empty)),
        favoriteIdsProvider.overrideWith((ref) => Stream.value(<int>{})),
        currentLyricsProvider.overrideWith((ref) async => Lyrics(lines: parseLrc('[00:01.00]a line'), source: 'test')),
        ...overrides.cast(),
      ],
      child: MaterialApp(
        theme: buildPrismTheme(const ThemeConfig(), platformBrightness: Brightness.dark, reduceMotion: false),
        home: Scaffold(body: child),
      ),
    );

/// Runs an effect for a while, off screen, into a picture.
Future<ui.Image> _render(BackgroundEffect e, Size size, {int frames = 40, void Function(int frame)? input}) async {
  await e.prepare();
  e.resize(size);
  for (var i = 0; i < frames; i++) {
    input?.call(i);
    e.step(1 / 30);
  }
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
  e.paint(canvas);
  final pic = rec.endRecording();
  final img = await pic.toImage(size.width.round(), size.height.round());
  pic.dispose();
  return img;
}

Future<int> _litPixels(ui.Image img) async {
  final data = (await img.toByteData())!.buffer.asUint8List();
  var lit = 0;
  for (var i = 0; i < data.length; i += 4) {
    if (data[i] + data[i + 1] + data[i + 2] > 40) lit++;
  }
  return lit;
}

void main() {
  group('background config', () {
    test('old settings without the new keys load with defaults', () {
      final s = AppSettings.fromJson(const {'crossfadeSeconds': 3});
      expect(s.background.current, BackgroundStyle.cover);
      expect(s.background.isLive, isFalse);
      expect(s.background.matrix.followTheme, isFalse, reason: 'Matrix is green unless you change it');
      expect(s.seekBarStyle, 'waveform');
      expect(s.togetherInternet, isTrue);
    });

    test('survives a save and load, keeps per-style settings apart', () {
      const cfg = BackgroundConfig(style: 'ripple', ripple: BgParams(speed: 2.5, shape: 'plus'), frameRate: 60);
      final back = AppSettings.fromJson(
        (AppSettings(background: cfg.withParams(BackgroundStyle.matrix, const BgParams(glyphs: 'binary')))).toJson(),
      ).background;
      expect((back.current, back.ripple.speed, back.ripple.shape, back.frameRate), (BackgroundStyle.ripple, 2.5, 'plus', 60));
      expect(back.matrix.glyphs, 'binary');
      expect(back.constellation, constellationDefaults);
    });

    test('values from a bad file are clamped', () {
      final p = const BgParams(speed: 99, brightness: -4, density: 0, size: 100, mouse: -1).sanitized();
      expect((p.speed, p.brightness, p.density, p.size, p.mouse), (3.0, 0.1, 0.3, 2.0, 0.0));
    });

    test('unknown names fall back instead of crashing', () {
      expect(BackgroundStyle.parse('nope'), BackgroundStyle.cover);
      expect(MatrixGlyphs.parse(null), MatrixGlyphs.katakana);
      expect(SeekBarStyle.parse('nope'), SeekBarStyle.waveform);
    });

    test('matrix symbols: own text, no spaces, no empties', () {
      expect(matrixSymbols(const BgParams(glyphs: 'custom', customGlyphs: 'a b a')), ['a', 'b']);
      expect(matrixSymbols(const BgParams(glyphs: 'custom', customGlyphs: '  ')), 'PRISM'.split(''));
      expect(matrixSymbols(const BgParams(glyphs: 'binary')), ['0', '1']);
    });
  });

  group('effects really draw and react', () {
    const size = Size(640, 360);
    const green = Color(0xFF35E07A), pale = Color(0xFFD9FFE6);

    testWidgets('each style paints something, more with the mouse and a click', (tester) async {
      await tester.runAsync(() async {
        for (final style in [BackgroundStyle.matrix, BackgroundStyle.constellation, BackgroundStyle.ripple]) {
          final calm = BackgroundEffect.create(style, const BgParams(), green, pale);
          final calmLit = await _litPixels(await _render(calm, size));
          expect(calmLit, greaterThan(50), reason: '$style draws');

          final poked = BackgroundEffect.create(style, const BgParams(), green, pale);
          final pokedImg = await _render(poked, size, input: (i) {
            poked.pointer = Offset(100 + i * 8.0, 180);
            if (i == 30) poked.burst(const Offset(320, 180), 1.5);
          });
          expect(await _litPixels(pokedImg), greaterThan(calmLit), reason: '$style reacts');
          calm.dispose();
          poked.dispose();
        }
      });
    });

    testWidgets('resize, odd sizes and setting changes do not crash', (tester) async {
      await tester.runAsync(() async {
        for (final style in [BackgroundStyle.matrix, BackgroundStyle.constellation, BackgroundStyle.ripple]) {
          final e = BackgroundEffect.create(style, const BgParams(density: 2, size: 0.5), green, pale);
          await _render(e, const Size(1, 1), frames: 3);
          await _render(e, const Size(1920, 1080), frames: 3);
          e.update(const BgParams(density: 0.3, size: 2, reach: 0.2, speed: 3), pale, green);
          e.bass = 2;
          await _render(e, const Size(300, 900), frames: 10);
          e.dispose();
        }
      });
    });
  });

  group('seek bar', () {
    testWidgets('every style paints, in the bar and hovered', (tester) async {
      for (final style in SeekBarStyle.values) {
        await tester.pumpWidget(_app(
          const Center(child: SizedBox(width: 600, child: WaveformSeekBar(height: 30, showTimes: false, inlineTimes: true))),
          settings: AppSettings(seekBarStyle: style.name),
        ));
        await tester.pump(const Duration(milliseconds: 50));
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: tester.getCenter(find.byType(CustomPaint).last));
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('3:00'), findsOneWidget, reason: style.name);
        expect(tester.takeException(), isNull, reason: style.name);
        await gesture.removePointer();
        await tester.pumpWidget(const SizedBox());
      }
    });

    testWidgets('right-click offers the styles and switches', (tester) async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      await tester.pumpWidget(_app(
        const Center(child: SizedBox(width: 600, child: WaveformSeekBar(height: 30, showTimes: false, inlineTimes: true))),
        // Off here: a live bar animates for ever and pumpAndSettle never ends.
        settings: const AppSettings(liveSeekBar: false),
        overrides: [settingsStoreProvider.overrideWithValue(SettingsStore(SharedPreferencesAsync()))],
      ));
      await tester.pump(const Duration(milliseconds: 50));
      final container = ProviderScope.containerOf(tester.element(find.byType(WaveformSeekBar)));
      await tester.tapAt(tester.getCenter(find.byType(WaveformSeekBar)), buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      expect(find.text('LED blocks'), findsOneWidget);
      await tester.tap(find.text('LED blocks'));
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).seekBarStyle, 'led');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('style samples for the settings page paint', (tester) async {
      await tester.pumpWidget(_app(Column(children: [
        for (final s in SeekBarStyle.values) SeekBarStylePreview(style: s),
      ])));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('logo', () {
    testWidgets('old mark is back; click sends a wave, right-click changes the background', (tester) async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      await tester.pumpWidget(_app(
        const Center(child: PrismLogo()),
        overrides: [settingsStoreProvider.overrideWithValue(SettingsStore(SharedPreferencesAsync()))],
      ));
      expect(find.byIcon(Icons.blur_on_rounded), findsOneWidget);
      expect(find.text('Prism'), findsOneWidget);
      final container = ProviderScope.containerOf(tester.element(find.byType(PrismLogo)));
      final bursts = <BackgroundBurst>[];
      final sub = container.read(backgroundInputProvider).bursts.listen(bursts.add);
      addTearDown(sub.cancel);

      await tester.tap(find.byType(PrismLogo));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(bursts.length, 1);

      await tester.tap(find.byType(PrismLogo), buttons: kSecondaryButton);
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).background.current, BackgroundStyle.mesh);

      // Hovering tilts it without errors.
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: tester.getTopLeft(find.byType(PrismLogo)));
      await gesture.moveTo(tester.getCenter(find.byIcon(Icons.blur_on_rounded)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await gesture.removePointer();
    });
  });

  group('live background widget', () {
    testWidgets('runs under the app, stops for reduced motion, is gone with Cover', (tester) async {
      const child = Text('content');
      await tester.pumpWidget(_app(
        const PrismBackground(artworkPath: null, child: child),
        settings: const AppSettings(background: BackgroundConfig(style: 'ripple')),
      ));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LiveBackground), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100)); // its timer is cancelled

      await tester.pumpWidget(_app(const PrismBackground(artworkPath: null, child: child)));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(LiveBackground), findsNothing, reason: 'Cover runs no timer');
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('nested backgrounds let the live one show through', (tester) async {
      await tester.pumpWidget(_app(
        const PrismBackground(artworkPath: null, nested: true, child: Text('album')),
        settings: const AppSettings(background: BackgroundConfig(style: 'matrix')),
      ));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(LiveBackground), findsNothing);
      expect(find.text('album'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('settings page: all styles, every control', (tester) async {
      tester.view.physicalSize = const Size(1100, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      await tester.pumpWidget(_app(
        const BackgroundPage(),
        settings: const AppSettings(background: BackgroundConfig(style: 'matrix')),
        overrides: [settingsStoreProvider.overrideWithValue(SettingsStore(SharedPreferencesAsync()))],
      ));
      await tester.pump(const Duration(milliseconds: 100));
      final container = ProviderScope.containerOf(tester.element(find.byType(BackgroundPage)));
      expect(find.text('Katakana'), findsOneWidget);
      expect(find.text('Trail length'), findsOneWidget);
      expect(find.text('Solid panels'), findsOneWidget);

      await tester.tap(find.text('Constellation'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(settingsProvider).background.current, BackgroundStyle.constellation);
      expect(find.text('Line length'), findsOneWidget);

      await tester.tap(find.text('Ripple'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Plus signs'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(settingsProvider).background.ripple.shape, 'plus');

      await tester.tap(find.text('Reset Ripple'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(container.read(settingsProvider).background.ripple.shape, 'dots');

      await tester.tap(find.text('Cover'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Solid panels'), findsNothing, reason: 'Cover has nothing to tune');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('"Try it" keeps Close below the window buttons / status bar', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      // What the Windows title strip (or a phone's status bar) gives the pages.
      tester.view.padding = const FakeViewPadding(top: 32);
      addTearDown(tester.view.reset);
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      await tester.pumpWidget(_app(
        const BackgroundPage(),
        settings: const AppSettings(background: BackgroundConfig(style: 'blobs')),
        overrides: [settingsStoreProvider.overrideWithValue(SettingsStore(SharedPreferencesAsync()))],
      ));
      await tester.pump(const Duration(milliseconds: 100));
      unawaited(showBackgroundPreview(tester.element(find.byType(BackgroundPage))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.getTopLeft(find.byIcon(Icons.close_rounded)).dy, greaterThan(32 + 12));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('in-app full size', () {
    testWidgets('cover click: window stays; the bar button asks for full screen', (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final calls = <String>[];
      const channel = MethodChannel('prism/window');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (c) async {
        calls.add(c.method);
        return c.method == 'isFullScreen' ? false : null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

      await tester.pumpWidget(_app(const ImmersivePlayerPage()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(calls, isNot(contains('setFullScreen')), reason: 'cover click keeps the window as it is');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(_app(const ImmersivePlayerPage(windowFullScreen: true)));
      await tester.pump(const Duration(milliseconds: 100));
      if (Platform.isWindows) expect(calls, contains('setFullScreen'));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('deep stats', () {
    final now = DateTime(2026, 11, 6, 12);
    Track song(int id, {String artist = 'A', String album = 'LP', int? year}) =>
        Track(id: id, uri: '/m/$id.mp3', title: 'S$id', artist: artist, album: album, durationMs: 200000, year: year);
    PlayRecord play(Track s, DateTime at, [int minutes = 2]) => PlayRecord(s, at, Duration(minutes: minutes));

    test('period numbers, comparison, firsts, streak, sessions and records', () {
      final a = song(1, year: 1994), b = song(2, artist: 'B', album: 'Other', year: 2021), c = song(3, artist: 'C');
      final history = [
        // Last month: only for the comparison and "first listen".
        play(a, DateTime(2026, 10, 20, 20), 10),
        // This month.
        play(a, DateTime(2026, 11, 4, 20)),
        play(a, DateTime(2026, 11, 4, 20, 3)),
        play(a, DateTime(2026, 11, 4, 20, 6)),
        play(b, DateTime(2026, 11, 5, 9)),
        play(c, DateTime(2026, 11, 6, 1)), // night
        play(b, DateTime(2026, 11, 6, 11)),
      ];
      final s = computeDeepStats(history, from: DateTime(2026, 11), to: now, now: now, previousFrom: DateTime(2026, 10));
      expect((s.base.plays, s.base.listened), (6, const Duration(minutes: 12)));
      expect(s.previousListened, const Duration(minutes: 10));
      expect(s.listenedChange, closeTo(0.2, 1e-9));
      expect(s.newSongs, 2, reason: 'a was first heard last month');
      expect(s.newArtists, 2);
      expect(s.currentStreak, 3);
      expect(s.topAlbums.first.item, ('LP', 'A'));
      expect(s.onRepeat?.$1.id, 1);
      expect(s.onRepeat?.$3, 3);
      expect(s.oneHitWonders, 1);
      expect(s.topArtistShare, closeTo(0.5, 1e-9));
      expect(s.sessions, 4, reason: 'four separate listening stretches');
      expect(s.longestSession?.plays, 3);
      expect(s.biggestDay?.$2, const Duration(minutes: 6));
      expect(s.dayParts[DayPart.night], const Duration(minutes: 2));
      expect(s.dayParts[DayPart.evening], const Duration(minutes: 6));
      expect(s.decades[1990], const Duration(minutes: 6));
      expect(s.weekHour[(DateTime(2026, 11, 4).weekday - 1) * 24 + 20], closeTo(6, 1e-9));
      expect(s.completion, closeTo(120 / 200, 1e-9));
      expect(s.recent.first.track.id, 2, reason: 'newest first');
      expect(s.activity.length, 6, reason: 'one bar per day of the month so far');
      expect(s.activity[3].listened, const Duration(minutes: 6));
    });

    test('streak still counts when today has no listens yet, and stops at a gap', () {
      final x = song(1);
      expect(
        computeDeepStats([play(x, DateTime(2026, 11, 5, 9)), play(x, DateTime(2026, 11, 4, 9))], from: DateTime(2026), to: now, now: now).currentStreak,
        2,
      );
      expect(computeDeepStats([play(x, DateTime(2026, 11, 3, 9))], from: DateTime(2026), to: now, now: now).currentStreak, 0);
    });

    test('long periods chart months; nothing played is handled', () {
      final x = song(1);
      final long = computeDeepStats([
        play(x, DateTime(2025, 1, 5)),
        play(x, DateTime(2026, 3, 5)),
      ], from: DateTime(2000), to: now, now: now);
      expect(long.activity.length, greaterThan(20));
      expect(long.activity.first.start, DateTime(2025));
      final none = computeDeepStats(const [], from: DateTime(2026, 11), to: now, now: now);
      expect(none.activity, isEmpty);
      expect((none.base.isEmpty, none.currentStreak, none.completion, none.onRepeat), (true, 0, null, null));
    });

    test('library numbers', () {
      final tracks = [
        const Track(id: 1, uri: '/a.mp3', title: 'A', artist: 'X', album: 'L', durationMs: 100000, genre: 'Rock', year: 1995, artworkPath: '/c.jpg'),
        const Track(id: 2, uri: '/b.flac', title: 'B', artist: 'X', album: 'L', durationMs: 300000, genre: 'Rock', year: 2001),
        const Track(id: 3, uri: '/c.mp3', title: 'C', durationMs: 0),
      ];
      final s = computeLibraryStats(tracks, playedIds: {1}, favoriteIds: {2});
      expect((s.songs, s.artists, s.albums, s.neverPlayed, s.favorites), (3, 2, 1, 2, 1));
      expect(s.totalLength, const Duration(seconds: 400));
      expect(s.formats.first.key, 'mp3');
      expect(s.longest?.id, 2);
      expect(s.shortest?.id, 1, reason: 'unknown lengths do not count');
      expect(s.decades.map((e) => e.key), [1990, 2000]);
      expect((s.withCover, s.withTags), (1, 2));
    });

    testWidgets('charts paint and answer the mouse', (tester) async {
      await tester.pumpWidget(_app(
        SizedBox(
          width: 700,
          child: Column(children: [
            BarChart(values: const [1, 5, 0, 3], tooltip: (i) => 'bar $i', axisLabel: (i) => '$i'),
            WeekHourHeatmap(minutes: List.generate(168, (i) => (i % 9).toDouble())),
            CalendarHeatmap(byDay: {DateTime(2026, 11, 2): const Duration(minutes: 30)}, today: DateTime(2026, 11, 6)),
          ]),
        ),
      ));
      await tester.pumpAndSettle();
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getTopLeft(find.byType(BarChart)) + const Offset(300, 80));
      await tester.pump();
      expect(find.textContaining('bar '), findsOneWidget);
      await gesture.moveTo(tester.getTopLeft(find.byType(WeekHourHeatmap)) + const Offset(300, 60));
      await tester.pump();
      expect(find.textContaining(' min'), findsWidgets);
      expect(tester.takeException(), isNull);
      await gesture.removePointer();
    });
  });

  group('Discord settings', () {
    testWidgets('nothing to set up: the app id is built in, the status line shows who', (tester) async {
      expect(prismDiscordClientId, isNotEmpty);
      await tester.pumpWidget(_app(
        const SingleChildScrollView(child: DiscordSettings()),
        settings: const AppSettings(discordPresence: true),
      ));
      await tester.pump();
      expect(find.text('Open the Discord page'), findsNothing);
      expect(find.text('Use my own application'), findsOneWidget);
      final c = ProviderScope.containerOf(tester.element(find.byType(DiscordSettings)));
      expect(discordIdOf(c.read(settingsProvider)), prismDiscordClientId);
      c.read(discordStatusProvider.notifier).set(const DiscordStatus(DiscordLink.connected, user: 'kolommix'));
      await tester.pump();
      expect(find.text('Connected as kolommix'), findsOneWidget);
      c.read(discordStatusProvider.notifier).set(const DiscordStatus(DiscordLink.notRunning));
      await tester.pump();
      expect(find.textContaining('running'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Discord helpers', () {
    test('file names become song names', () {
      expect(cleanSongTitle('19_Sunset_of_Seven_Suns_Toby_Fox'), 'Sunset of Seven Suns Toby Fox');
      expect(cleanSongTitle('Song.mp3'), 'Song');
      expect(cleanSongTitle('Normal Title'), 'Normal Title');
      expect(cleanSongTitle('1979'), '1979', reason: 'a song called just a number stays');
    });

    test('songs without tags: only safe guesses reach a public profile', () {
      Track c(String title, String artist, [int ms = 120000]) => Track(id: 0, uri: '', title: title, artist: artist, durationMs: ms);
      const file = 'Black Knife DELTARUNE Chapter 3+4 Soundtrack Toby Fox';
      expect(fileNameMatches(file, 120000, c('Black Knife', 'Toby Fox')), isTrue);
      expect(fileNameMatches(file, 120000, c('Black Knife', 'Some Fan Band')), isFalse, reason: 'artist not in the name');
      expect(fileNameMatches(file, 200000, c('Black Knife', 'Toby Fox')), isFalse, reason: 'another version: length differs');
      expect(
        fileNameMatches('HARD DRIVE UNDERTALE METTATON SONG', 185000, c('Hard Drive (UNDERTALE METTATON SONG) - Versão Brasileira', 'Devil Fandubs', 185000)),
        isFalse,
        reason: 'a fan version',
      );
      expect(fileNameMatches('Bohemian Rhapsody', 354000, c('Bohemian Rhapsody', 'Queen', 354000)), isTrue, reason: 'exact title');
      expect(shortQuery('TV WORLD (DELTARUNE Chapter 3+4 Soundtrack) - Toby Fox'), 'TV WORLD DELTARUNE Chapter');
    });

    test('tries a shorter search for long file names, and asks only once per song', () async {
      final asked = <String>[];
      final lookup = CoverLookup(
        client: MockClient((req) async {
          final q = req.url.queryParameters['term'] ?? req.url.queryParameters['q'] ?? '';
          asked.add('${req.url.host} $q');
          if (req.url.host.contains('itunes') && q == 'Black Knife DELTARUNE Chapter') {
            return http.Response(
              '{"results":[{"trackName":"Black Knife","artistName":"Toby Fox","trackTimeMillis":121000,'
              '"artworkUrl100":"https://x/100x100bb.jpg"}]}',
              200,
            );
          }
          return http.Response(req.url.host.contains('itunes') ? '{"results":[]}' : '{"data":[]}', 200);
        }),
      );
      const song = Track(id: 7, uri: 'x', title: '30_Black_Knife_DELTARUNE_Chapter_3+4_Soundtrack_Toby_Fox', durationMs: 121000);
      final info = await lookup.find(song);
      expect((info?.title, info?.artist, info?.coverUrl), ('Black Knife', 'Toby Fox', 'https://x/1200x1200bb.jpg'));
      expect(asked.length, 3, reason: 'Apple + Deezer with the full name, then Apple with the short one');
      await lookup.find(song);
      expect(asked.length, 3, reason: 'cached');
      expect(lookup.isSettled(song), isTrue);
    });

    test('reads Apple and Deezer answers', () {
      final apple = parseITunes(
        '{"results":[{"trackName":"Song","artistName":"Band","collectionName":"LP","trackTimeMillis":1000,'
        '"artworkUrl100":"https://x/100x100bb.jpg","trackViewUrl":"https://music.apple.com/s"},{"wrapperType":"other"}]}',
      );
      expect(apple.length, 1);
      expect(apple.first.$2.coverUrl, 'https://x/1200x1200bb.jpg');
      final deezer = parseDeezer('{"data":[{"title":"Song","duration":10,"artist":{"name":"Band"},'
          '"album":{"title":"LP","cover_big":"https://y/c.jpg"},"link":"https://deezer.com/t"}]}');
      expect((deezer.first.$1.artist, deezer.first.$1.durationMs, deezer.first.$2.coverUrl), ('Band', 10000, 'https://y/c.jpg'));
      expect(parseITunes('{}'), isEmpty);
      expect(parseDeezer('{"data":"x"}'), isEmpty);
    });
  });
}

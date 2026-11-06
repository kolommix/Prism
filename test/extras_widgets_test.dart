import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/theme/theme_builder.dart';
import 'package:prism/core/theme/theme_config.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/lyrics/application/lyrics_providers.dart';
import 'package:prism/features/lyrics/domain/lrc.dart';
import 'package:prism/features/lyrics/presentation/lyrics_view.dart';
import 'package:prism/features/player/application/player_controller.dart';
import 'package:prism/features/player/application/player_providers.dart';
import 'package:prism/features/player/engine/playback_engine.dart';
import 'package:prism/features/stats/application/stats_providers.dart';
import 'package:prism/features/stats/domain/listening_stats.dart';
import 'package:prism/features/stats/presentation/stats_page.dart';
import 'package:prism/features/together/presentation/together_sheet.dart';
import 'package:prism/features/visualizer/domain/spectrum.dart';
import 'package:prism/features/visualizer/presentation/visualizer.dart';

import 'package:prism/core/widgets/ambient_backdrop.dart';
import 'package:prism/features/library/presentation/widgets/library_widgets.dart';

import 'helpers.dart';

Widget app(Widget child, List<dynamic> overrides) => ProviderScope(
      overrides: [...overrides.cast()],
      child: MaterialApp(
        theme: buildPrismTheme(const ThemeConfig(), platformBrightness: Brightness.dark, reduceMotion: false),
        home: Scaffold(body: child),
      ),
    );

final song = t(1, title: 'Song', artist: 'Band');
final playing = EngineState(playing: true, status: EngineStatus.ready, position: const Duration(seconds: 3), duration: const Duration(minutes: 3));

List<dynamic> nowPlaying(Track track) => [
      currentTrackProvider.overrideWithValue(track),
      engineStateProvider.overrideWith((ref) => Stream.value(playing)),
      tuningProvider.overrideWith((ref) => Stream.value(const PlaybackTuning())),
      isPlayingProvider.overrideWithValue(true),
    ];

void main() {
  testWidgets('Wrapped cards render and swipe through', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final now = DateTime(2026, 11, 1, 21);
    final stats = computeStats([
      for (var i = 0; i < 12; i++) PlayRecord(t(i % 3 + 1, artist: 'Artist ${i % 2}'), now.subtract(Duration(days: i)), const Duration(minutes: 3)),
    ], from: DateTime(2026, 10), to: now);
    await tester.pumpWidget(app(const WrappedCards(period: StatsPeriod.month), [
      statsProvider.overrideWith((ref, period) async => stats),
    ]));
    await tester.pumpAndSettle();
    expect(find.text('minutes'), findsOneWidget);
    expect(find.textContaining('12 plays'), findsOneWidget);
    for (final next in ['Your top song', 'Top artists', 'When you listen', 'Longest listening streak']) {
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();
      expect(find.text(next), findsOneWidget, reason: next);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('synced lyrics highlight the current line', (tester) async {
    final lyrics = Lyrics(lines: parseLrc('[00:01.00]first line\n[00:02.50]current line\n[00:06.00]next line'), source: 'test');
    await tester.pumpWidget(app(const LyricsView(), [
      ...nowPlaying(song),
      currentLyricsProvider.overrideWith((ref) async => lyrics),
    ]));
    // Lyrics future, engine stream, post-frame sync, then the index setState.
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('current line'), findsOneWidget);
    // The current line is the karaoke one.
    expect(find.ancestor(of: find.text('current line'), matching: find.byType(KaraokeLine)), findsOneWidget);
    expect(find.ancestor(of: find.text('next line'), matching: find.byType(KaraokeLine)), findsNothing);
  });

  testWidgets('every visualizer style paints', (tester) async {
    final rnd = math.Random(1);
    final spectrum = Spectrum(data: Uint8List.fromList(List.generate(48 * 300, (_) => rnd.nextInt(256))), bands: 48, fps: 30);
    for (final style in VisualizerStyle.values) {
      await tester.pumpWidget(app(SizedBox(width: 400, height: 300, child: Visualizer(style: style)), [
        ...nowPlaying(song),
        spectrumProvider.overrideWith((ref, track) async => spectrum),
      ]));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(CustomPaint), findsWidgets, reason: style.name);
      expect(tester.takeException(), isNull, reason: style.name);
    }
  });

  testWidgets('cover pulses with the bass while playing', (tester) async {
    // Loud lows in every frame: the cover must grow, the halo must paint.
    final data = Uint8List(48 * 300);
    for (var f = 0; f < 300; f++) {
      for (var b = 0; b < 48; b++) {
        data[f * 48 + b] = b < 6 ? 250 : 120;
      }
    }
    final spectrum = Spectrum(data: data, bands: 48, fps: 30);
    await tester.pumpWidget(app(
      const Center(child: SizedBox.square(dimension: 200, child: BeatPulse(radius: BorderRadius.zero, child: ColoredBox(color: Colors.white)))),
      [...nowPlaying(song), spectrumProvider.overrideWith((ref, track) async => spectrum)],
    ));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final scale = tester.widget<Transform>(find.descendant(of: find.byType(BeatPulse), matching: find.byType(Transform)).first);
    expect(scale.transform.getMaxScaleOnAxis(), greaterThan(1.02));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('black & white backdrop + cover card hover play', (tester) async {
    var played = 0;
    await tester.pumpWidget(app(
      AmbientBackdrop(
        artworkPath: 'does/not/exist.jpg',
        child: Center(
          child: SizedBox(
            width: 180,
            height: 240,
            child: CoverCard(title: 'Album', subtitle: 'Band', onTap: () {}, onPlay: () => played++),
          ),
        ),
      ),
      const [],
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.text('Album'), findsOneWidget);
    // Play button only reacts while hovered.
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: tester.getCenter(find.byType(CoverCard)));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();
    expect(played, 1);
    expect(tester.takeException(), isNull);
    await gesture.removePointer();
  });

  testWidgets('listen-together sheet offers host and join', (tester) async {
    await tester.pumpWidget(app(Builder(builder: (context) {
      return TextButton(onPressed: () => showTogetherSheet(context), child: const Text('open'));
    }), const []));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Start a session'), findsOneWidget);
    expect(find.text('Join'), findsOneWidget);
  });
}

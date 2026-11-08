import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/theme/theme_builder.dart';
import 'package:prism/core/theme/theme_config.dart';
import 'package:prism/features/library/application/library_providers.dart';
import 'package:prism/features/lyrics/application/lyrics_providers.dart';
import 'package:prism/features/lyrics/domain/lrc.dart';
import 'package:prism/features/player/application/player_controller.dart';
import 'package:prism/features/player/application/player_providers.dart';
import 'package:prism/features/player/application/sleep_timer.dart';
import 'package:prism/features/player/domain/playback_queue.dart';
import 'package:prism/features/player/engine/playback_engine.dart';
import 'package:prism/features/player/presentation/immersive_player_page.dart';
import 'package:prism/features/player/presentation/player_extras.dart';
import 'package:prism/features/player/presentation/widgets/waveform_seek_bar.dart';
import 'package:prism/features/visualizer/presentation/visualizer.dart';

import 'helpers.dart';
import 'player_controller_test.dart' show FakeEngine, MemoryStore;

final song = t(1, title: 'Song', artist: 'Band');
const playing = EngineState(
  playing: true,
  status: EngineStatus.ready,
  position: Duration(seconds: 3),
  duration: Duration(minutes: 3),
);

List<dynamic> overrides() => [
      playerControllerProvider.overrideWithValue(PlayerController(engine: FakeEngine(), store: MemoryStore())),
      currentTrackProvider.overrideWithValue(song),
      engineStateProvider.overrideWith((ref) => Stream.value(playing)),
      tuningProvider.overrideWith((ref) => Stream.value(const PlaybackTuning())),
      queueProvider.overrideWith((ref) => Stream.value(PlaybackQueue.empty)),
      isPlayingProvider.overrideWithValue(true),
      favoriteIdsProvider.overrideWith((ref) => Stream.value(<int>{})),
      sleepTimerStateProvider.overrideWith((ref) => Stream.value(const SleepTimerState())),
      spectrumProvider.overrideWith((ref, track) async => null),
      currentLyricsProvider.overrideWith(
        (ref) async => Lyrics(lines: parseLrc('[00:01.00]first line\n[00:02.50]current line\n[00:06.00]next'), source: 'test'),
      ),
    ];

Widget app(Widget child) => ProviderScope(
      overrides: [...overrides().cast()],
      child: MaterialApp(
        theme: buildPrismTheme(const ThemeConfig(), platformBrightness: Brightness.dark, reduceMotion: false),
        home: child,
      ),
    );

void main() {
  testWidgets('full-screen view: lyrics left, cover + controls right', (tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(const ImmersivePlayerPage()));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('current line'), findsOneWidget);
    expect(find.byType(BeatPulse), findsOneWidget);
    expect(find.byType(WaveformSeekBar), findsOneWidget);
    // Lyrics are on the left half, the cover on the right half.
    expect(tester.getCenter(find.text('current line')).dx, lessThan(800));
    expect(tester.getCenter(find.byType(BeatPulse)).dx, greaterThan(800));
    // Esc is handled (closing needs a router; here it must just not throw).
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('volume: wheel and mute go through one remembered value', (tester) async {
    await tester.pumpWidget(app(const Scaffold(body: Center(child: VolumeSlider()))));
    await tester.pump();
    final container = ProviderScope.containerOf(tester.element(find.byType(VolumeSlider)));
    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pump();
    expect(container.read(playerVolumeProvider), 0);
    expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.volume_off_rounded));
    await tester.pump();
    expect(container.read(playerVolumeProvider), 1, reason: 'unmute restores the level');
    container.read(playerVolumeProvider.notifier).set(0.4);
    await tester.pumpAndSettle();
    VolumeBarsPainter bars() => tester
        .widgetList<CustomPaint>(find.descendant(of: find.byType(VolumeSlider), matching: find.byType(CustomPaint)))
        .map((p) => p.painter)
        .whereType<VolumeBarsPainter>()
        .single;
    expect(bars().value, closeTo(0.4, 1e-9));

    // Click and drag on the bars set it; arrow keys nudge it.
    final box = tester.getRect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is VolumeBarsPainter));
    await tester.tapAt(Offset(box.left + box.width * 0.75, box.center.dy));
    await tester.pumpAndSettle();
    expect(container.read(playerVolumeProvider), closeTo(0.75, 0.02));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(container.read(playerVolumeProvider), closeTo(0.70, 0.02));
    await tester.dragFrom(Offset(box.left + box.width * 0.7, box.center.dy), Offset(-box.width, 0));
    await tester.pumpAndSettle();
    expect(container.read(playerVolumeProvider), 0, reason: 'dragging past the start mutes');
    expect(tester.takeException(), isNull);
  });

  testWidgets('seek bar hover shows the time bubble without errors', (tester) async {
    await tester.pumpWidget(app(const Scaffold(
      body: Center(child: SizedBox(width: 600, child: WaveformSeekBar(height: 30, showTimes: false, inlineTimes: true))),
    )));
    await tester.pump();
    expect(find.text('3:00'), findsOneWidget, reason: 'total time on the right');
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: tester.getCenter(find.byType(CustomPaint).last));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await gesture.removePointer();
    await tester.pumpWidget(const SizedBox());
  });
}

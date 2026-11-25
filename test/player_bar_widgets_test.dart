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

import 'package:prism/features/player/application/song_volumes.dart';
import 'package:prism/features/player/domain/volume_style.dart';
import 'package:prism/features/settings/application/settings_controller.dart';
import 'package:prism/features/settings/domain/app_settings.dart';
import 'package:prism/features/library/domain/track.dart';

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

  for (final style in VolumeStyle.values) {
    testWidgets('volume (${style.name}): click, drag, keys, wheel and mute', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          ...overrides().cast(),
          initialSettingsProvider.overrideWithValue(AppSettings(volumeStyle: style.name)),
        ],
        child: MaterialApp(
          theme: buildPrismTheme(const ThemeConfig(), platformBrightness: Brightness.dark, reduceMotion: false),
          home: const Scaffold(body: Center(child: VolumeSlider())),
        ),
      ));
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
      final level = find.byWidgetPredicate(
          (w) => w is CustomPaint && (w.painter is VolumeBarsPainter || w.painter is VolumeLinePainter));
      double shown() => switch (tester.widget<CustomPaint>(level).painter) {
            final VolumeBarsPainter p => p.value,
            final VolumeLinePainter p => p.value,
            _ => -1,
          };
      expect(shown(), closeTo(0.4, 1e-9));

      // Click and drag set it (the ends inside the box are 0 and 100 %).
      final box = tester.getRect(level);
      final pad = style == VolumeStyle.bars ? 0.0 : 8.0;
      Offset at(double v) => Offset(box.left + pad + (box.width - pad * 2) * v, box.center.dy);
      await tester.tapAt(at(0.75));
      await tester.pumpAndSettle();
      expect(container.read(playerVolumeProvider), closeTo(0.75, 0.01));
      await tester.tapAt(at(1) - const Offset(0.5, 0));
      await tester.pumpAndSettle();
      expect(container.read(playerVolumeProvider), closeTo(1, 0.01), reason: 'the far end is reachable');
      await tester.tapAt(at(0.75));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(container.read(playerVolumeProvider), closeTo(0.70, 0.01));
      // The wheel: 5 % a notch, onto round numbers.
      container.read(playerVolumeProvider.notifier).set(0.37);
      await tester.sendEventToBinding(const PointerScrollEvent(position: Offset.zero, scrollDelta: Offset(0, -100)).copyWith(position: box.center));
      await tester.pumpAndSettle();
      expect(container.read(playerVolumeProvider), closeTo(0.40, 1e-6));
      await tester.sendEventToBinding(const PointerScrollEvent(position: Offset.zero, scrollDelta: Offset(0, 100)).copyWith(position: box.center));
      await tester.pumpAndSettle();
      expect(container.read(playerVolumeProvider), closeTo(0.35, 1e-6));
      await tester.dragFrom(at(0.7), Offset(-box.width, 0));
      await tester.pumpAndSettle();
      expect(container.read(playerVolumeProvider), 0, reason: 'dragging past the start mutes');
      expect(tester.takeException(), isNull);
    });
  }

  test('volume of each song: comes back when the song starts, only when on', () async {
    final a = t(1, title: 'A'), b = t(2, title: 'B');
    final memory = SongVolumes();
    ProviderContainer make(bool on) => ProviderContainer(overrides: [
          playerControllerProvider.overrideWithValue(PlayerController(engine: FakeEngine(), store: MemoryStore())),
          initialSettingsProvider.overrideWithValue(AppSettings(volumePerSong: on)),
          songVolumesProvider.overrideWithValue(memory),
          currentTrackProvider.overrideWith((ref) => ref.watch(_songProvider)),
        ]);
    final c = make(true);
    addTearDown(c.dispose);
    c.listen(songVolumeFollowerProvider, (_, _) {});
    final volume = c.read(playerVolumeProvider.notifier);
    c.read(_songProvider.notifier).play(a);
    await pumpEventQueue();
    volume.set(0.3); // A is quiet for me
    c.read(_songProvider.notifier).play(b);
    await pumpEventQueue();
    expect(c.read(playerVolumeProvider), 0.3, reason: 'a song with no volume of its own keeps it');
    volume.set(0.9);
    c.read(_songProvider.notifier).play(a);
    await pumpEventQueue();
    expect(c.read(playerVolumeProvider), 0.3);
    expect(c.read(playerControllerProvider).volume, 0.3, reason: 'the player plays it too');
    c.read(_songProvider.notifier).play(b);
    await pumpEventQueue();
    expect(c.read(playerVolumeProvider), 0.9);
    volume.toggleMute();
    expect(memory.of(b.id), 0.9, reason: 'muting is not remembered');

    // Off: nothing is remembered or applied.
    final off = make(false);
    addTearDown(off.dispose);
    off.listen(songVolumeFollowerProvider, (_, _) {});
    off.read(_songProvider.notifier).play(t(3, title: 'C'));
    off.read(playerVolumeProvider.notifier).set(0.5);
    off.read(_songProvider.notifier).play(a);
    await pumpEventQueue();
    expect(off.read(playerVolumeProvider), 0.5);
    expect(memory.of(3), isNull);
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

class _Song extends Notifier<Track?> {
  @override
  Track? build() => null;
  void play(Track t) => state = t;
}

final _songProvider = NotifierProvider<_Song, Track?>(_Song.new);

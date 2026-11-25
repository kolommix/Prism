// ignore_for_file: avoid_print, invalid_use_of_protected_member
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prism/core/router/app_router.dart';
import 'package:prism/features/player/application/player_providers.dart';
import 'package:prism/features/player/presentation/now_playing_page.dart';
import 'package:prism/features/player/presentation/player_extras.dart';
import 'package:prism/features/player/presentation/widgets/transport_controls.dart';
import 'package:prism/main.dart' as app;
import 'package:window_manager/window_manager.dart';

/// The full player on the real window at several sizes, each stage (cover,
/// lyrics, visualizer): the controls and the row under them must be inside
/// the window whenever it is tall enough, and nothing may overflow. Plays the
/// song that is up (silent, a few seconds) so the visualizer moves.
///
/// flutter test integration_test/player_layout_test.dart -d windows [--dart-define=SHOTS=folder]
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  const out = String.fromEnvironment('SHOTS');

  testWidgets('full player fits the window', (tester) async {
    Future<void> wait(int ms) async {
      final end = DateTime.now().add(Duration(milliseconds: ms));
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    Future<void> shot(String name) async {
      if (out.isEmpty) return;
      final view = tester.binding.renderViews.first;
      final layer = view.layer! as OffsetLayer;
      await tester.runAsync(() async {
        final img = await layer.toImage(Offset.zero & view.size, pixelRatio: 1);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        await File('$out/$name.png').writeAsBytes(png!.buffer.asUint8List());
      });
    }

    if (out.isNotEmpty) await Directory(out).create(recursive: true);
    app.main();
    await wait(6000);

    BuildContext ctx() => tester.element(find.byType(Scaffold).first);
    ProviderContainer c() => ProviderScope.containerOf(ctx());
    final player = c().read(playerControllerProvider);
    final track = c().read(currentTrackProvider);
    expect(track, isNotNull, reason: 'needs a song in the queue (the last session is restored at start)');

    // Silent: the sleep-timer fade is never saved, the user's volume stays.
    await tester.runAsync(() => player.setFade(0));
    addTearDown(() => player.setFade(1));
    GoRouter.of(ctx()).push(Routes.player);
    await wait(1500);
    await tester.runAsync(player.play);
    await wait(500);

    final failures = <String>[];
    for (final (w, h) in const [(1345.0, 812.0), (1400.0, 860.0), (1100.0, 720.0), (720.0, 800.0), (1000.0, 600.0)]) {
      await tester.runAsync(() => windowManager.setSize(Size(w, h)));
      await wait(700);
      for (final stage in PlayerStage.values) {
        c().read(playerStageProvider.notifier).set(stage);
        await wait(1800);
        final view = tester.binding.renderViews.first.size;
        final error = tester.takeException();
        if (error != null) failures.add('${w}x$h ${stage.name}: $error');
        final transport = tester.getRect(find.descendant(of: find.byType(NowPlayingPage), matching: find.byType(TransportControls)));
        final row = tester.getRect(find.descendant(of: find.byType(NowPlayingPage), matching: find.byType(SleepTimerButton)));
        print('${w.round()}x${h.round()} ${stage.name}: view ${view.height.round()}, '
            'transport bottom ${transport.bottom.round()}, row bottom ${row.bottom.round()}');
        // A really short window may scroll instead; anything from ~700 up fits.
        if (view.height >= 680 && row.bottom > view.height) {
          failures.add('${w.round()}x${h.round()} ${stage.name}: the row under the controls ends at '
              '${row.bottom.round()}, below the window (${view.height.round()})');
        }
        await shot('player-${w.round()}x${h.round()}-${stage.name}');
      }
    }
    await tester.runAsync(player.pause);
    c().read(playerStageProvider.notifier).set(PlayerStage.cover);
    await tester.runAsync(() => windowManager.setSize(const Size(1400, 860)));
    expect(failures, isEmpty);
  });
}

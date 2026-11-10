import 'dart:async';
import 'dart:developer' as dev;
import 'dart:isolate' as iso;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prism/features/player/application/player_providers.dart';
import 'package:prism/main.dart' as app;
import 'package:vm_service/vm_service.dart' as vm;
import 'package:vm_service/vm_service_io.dart';

/// Switching songs on the real app (real library), silent. Reports how long the
/// UI thread was blocked around each switch and, for every block over 150 ms,
/// the Dart functions the CPU profiler saw most during it.
///
/// flutter drive --profile -d windows --dart-define=SKIP=40 --driver=test_driver/perf_driver.dart --target=integration_test/track_switch_perf_test.dart
/// SKIP moves that far into the queue first: songs played before are cached
/// (lyrics, spectrum, covers) and hide first-play costs.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> wait(WidgetTester tester, int ms) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('track switch', (tester) async {
    app.main();
    await wait(tester, 6000);
    final c = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final player = c.read(playerControllerProvider);
    // Silent and not saved: the fade the sleep timer uses.
    await player.setFade(0);
    addTearDown(() => player.setFade(1));
    if (player.queue.tracks.length < 3) {
      debugPrint('STALL no queue to switch through');
      return;
    }
    // Put the user's place in the queue back afterwards.
    final startIndex = player.queue.index;
    final startPos = player.state.position;
    addTearDown(() async {
      await player.jumpTo(startIndex);
      await player.pause();
      await player.seek(startPos);
      await player.saveSession();
    });
    const skip = int.fromEnvironment('SKIP');
    if (skip > 0) await player.jumpTo((startIndex + skip) % player.queue.length);
    await player.play();
    await wait(tester, 2000);

    // Gaps in the event loop: a blocked UI thread shows up here even when no
    // frame was asked for. Timeline clock, to ask the profiler about them.
    final gaps = <int>[];
    final windows = <(int, int)>[];
    var last = dev.Timeline.now;
    final probe = Timer.periodic(const Duration(milliseconds: 4), (_) {
      final now = dev.Timeline.now;
      final gap = (now - last) ~/ 1000;
      if (gap > 40) gaps.add(gap);
      if (gap > 150) windows.add((last, now - last));
      last = now;
    });
    final calls = <int>[];
    await binding.watchPerformance(() async {
      for (var i = 0; i < 8; i++) {
        final sw = Stopwatch()..start();
        await player.skipNext();
        calls.add(sw.elapsedMilliseconds);
        await wait(tester, 1500);
      }
    }, reportKey: 'track_switch');
    probe.cancel();
    await player.pause();
    debugPrint('STALL next() ms: $calls');
    debugPrint('STALL event-loop gaps >40 ms: $gaps');

    final info = await dev.Service.getInfo();
    final uri = info.serverWebSocketUri;
    if (uri == null || windows.isEmpty) return;
    final service = await vmServiceConnectUri(uri.toString());
    try {
      final isolateId = dev.Service.getIsolateId(iso.Isolate.current)!;
      for (final (start, extent) in windows) {
        final s = await service.getCpuSamples(isolateId, start, extent);
        final fns = s.functions ?? const <vm.ProfileFunction>[];
        String name(int i) {
          final f = fns[i].function;
          final owner = f is vm.FuncRef ? f.owner : null;
          final cls = owner is vm.ClassRef ? '${owner.name}.' : '';
          final lib = fns[i].resolvedUrl ?? '';
          return '$cls${f is vm.FuncRef ? f.name : f?.toString() ?? '?'} (${lib.split('/').skip(lib.split('/').length > 2 ? lib.split('/').length - 2 : 0).join('/')})';
        }

        final self = <String, int>{}, incl = <String, int>{};
        for (final sample in s.samples ?? const <vm.CpuSample>[]) {
          final stack = sample.stack ?? const <int>[];
          if (stack.isEmpty) continue;
          self.update(name(stack.first), (v) => v + 1, ifAbsent: () => 1);
          for (final n in {for (final i in stack) name(i)}) {
            incl.update(n, (v) => v + 1, ifAbsent: () => 1);
          }
        }
        String top(Map<String, int> m, int n) =>
            (m.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(n).map((e) => '${e.value} ${e.key}').join('\n    ');
        debugPrint('STALL window ${extent ~/ 1000} ms, ${s.sampleCount} samples\n  self:\n    ${top(self, 8)}\n  inclusive:\n    ${top(incl, 25)}');
      }
    } finally {
      await service.dispose();
    }
  });
}

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Measures how evenly frames really arrive on screen, in the real app.
///
/// The perf benchmark says how long a frame takes to make; this says how often
/// one is delivered, which is what "feels like 30 fps" is about.
///
/// flutter build windows --profile --dart-define=PRISM_FPS_PROBE=build/perf/fps.txt
///
/// Normal builds have an empty define, so this is compiled out.
abstract final class FrameProbe {
  static const _path = String.fromEnvironment('PRISM_FPS_PROBE');

  static void startIfAsked() {
    if (_path.isNotEmpty) _run();
  }

  static Future<void> _run() async {
    await Future<void>.delayed(const Duration(seconds: 6)); // startup and library load
    final lines = <String>[];
    for (final repaint in [false, true]) {
      lines.add(await _measure(repaint: repaint));
    }
    final file = File(_path);
    await file.parent.create(recursive: true);
    await file.writeAsString('${lines.join('\n')}\n');
    exit(0);
  }

  static Future<String> _measure({required bool repaint}) async {
    final wall = <int>[];
    final raster = <int>[];
    void onTimings(List<FrameTiming> t) => raster.addAll(t.map((x) => x.rasterDuration.inMicroseconds));
    SchedulerBinding.instance.addTimingsCallback(onTimings);
    final clock = Stopwatch()..start();
    var last = 0;
    var running = true;
    void frame(Duration _) {
      final now = clock.elapsedMicroseconds;
      if (last != 0) wall.add(now - last);
      last = now;
      if (repaint) {
        // The whole window is painted again, like a full-window animation.
        for (final view in WidgetsBinding.instance.renderViews) {
          view.child?.markNeedsPaint();
        }
      }
      if (running) SchedulerBinding.instance.scheduleFrameCallback(frame, rescheduling: true);
      SchedulerBinding.instance.scheduleFrame();
    }

    SchedulerBinding.instance.scheduleFrameCallback(frame);
    await Future<void>.delayed(const Duration(seconds: 5));
    running = false;
    SchedulerBinding.instance.removeTimingsCallback(onTimings);
    wall.sort();
    if (wall.isEmpty) return '${repaint ? 'repaint' : 'empty  '}: no frames';
    int at(double p) => wall[math.min(wall.length - 1, (wall.length * p).floor())];
    final avg = wall.reduce((a, b) => a + b) / wall.length;
    final late_ = wall.where((w) => w > wall[wall.length ~/ 2] * 1.5).length;
    final rasterAvg = raster.isEmpty ? 0 : raster.reduce((a, b) => a + b) / raster.length;
    return '${repaint ? 'repaint' : 'empty  '}: ${(1e6 / avg).toStringAsFixed(1)} fps, interval '
        'p50 ${(at(0.5) / 1000).toStringAsFixed(1)} p90 ${(at(0.9) / 1000).toStringAsFixed(1)} '
        'p99 ${(at(0.99) / 1000).toStringAsFixed(1)} ms, late frames $late_/${wall.length}, '
        'raster avg ${(rasterAvg / 1000).toStringAsFixed(2)} ms';
  }
}

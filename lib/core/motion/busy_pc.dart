import 'dart:ffi';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notices when the computer is too busy for Prism to keep up (games, a
/// browser with many tabs, a build), so Prism can lighten itself instead of
/// stuttering: while busy, theme colors snap instead of gliding (a glide
/// rebuilds the whole app every frame), animated backgrounds run at 30 fps and
/// the visualizer uses its light mode. Judged from the app's own frame times:
/// busy when a quarter of the frames in the last 3 s came at least a whole
/// screen refresh late; calm again after 8 s with almost none late.
class BusyMeter {
  BusyMeter({this.window = const Duration(seconds: 3), this.calmAfter = const Duration(seconds: 8)});

  final Duration window;
  final Duration calmAfter;

  final _frames = <(int atUs, bool late)>[];
  bool busy = false;
  int _calmSinceUs = -1;

  /// Fewest frames to judge from (an idle app draws almost nothing).
  static const minFrames = 24;
  static const busyShare = 0.25;
  static const calmShare = 0.05;

  /// Adds frames (`at` = when the frame started, `spanUs` = start to on
  /// screen). Returns true when [busy] changed.
  bool add(Iterable<({int atUs, int spanUs})> frames, {required int budgetUs}) {
    var last = -1;
    for (final f in frames) {
      _frames.add((f.atUs, f.spanUs > 2 * budgetUs));
      last = f.atUs;
    }
    if (last < 0) return false;
    _frames.removeWhere((f) => f.$1 < last - window.inMicroseconds);
    if (_frames.length < minFrames) return false;
    final share = _frames.where((f) => f.$2).length / _frames.length;
    if (!busy) {
      if (share >= busyShare) {
        busy = true;
        _calmSinceUs = -1;
        return true;
      }
      return false;
    }
    if (share > calmShare) {
      _calmSinceUs = -1;
      return false;
    }
    if (_calmSinceUs < 0) _calmSinceUs = last;
    if (last - _calmSinceUs >= calmAfter.inMicroseconds) {
      busy = false;
      return true;
    }
    return false;
  }

  /// Nothing was drawn for a while: nothing to lighten either.
  bool idle() {
    _frames.clear();
    if (!busy) return false;
    busy = false;
    return true;
  }
}

/// True while the computer is too busy (see [BusyMeter]).
class BusyPc extends Notifier<bool> {
  final _meter = BusyMeter();
  DateTime _lastFrames = DateTime(0);

  @override
  bool build() {
    void onTimings(List<FrameTiming> timings) {
      _lastFrames = DateTime.now();
      final hz = PlatformDispatcher.instance.views.firstOrNull?.display.refreshRate ?? 60;
      final budget = (1e6 / (hz <= 0 ? 60 : hz)).round();
      final changed = _meter.add(
        [
          for (final t in timings)
            (atUs: t.timestampInMicroseconds(FramePhase.vsyncStart), spanUs: t.totalSpan.inMicroseconds),
        ],
        budgetUs: budget,
      );
      if (changed) state = _meter.busy;
    }

    SchedulerBinding.instance.addTimingsCallback(onTimings);
    // Frame times only come while something is drawn.
    final idleCheck = Stream<void>.periodic(const Duration(seconds: 10)).listen((_) {
      if (DateTime.now().difference(_lastFrames) > const Duration(seconds: 10) && _meter.idle()) state = false;
    });
    ref.onDispose(() {
      SchedulerBinding.instance.removeTimingsCallback(onTimings);
      idleCheck.cancel();
    });
    return false;
  }
}

final busyPcProvider = NotifierProvider<BusyPc, bool>(BusyPc.new);

/// Windows: Prism asks for a little more processor time than normal programs
/// ("above normal"), so the music and the screen keep going when something
/// else loads the PC. Games and other programs still run; Prism itself uses
/// little. Off in Settings → Windows.
class ProcessPriority {
  static const _normal = 0x00000020;
  static const _aboveNormal = 0x00008000;

  static bool apply({required bool high}) {
    if (!Platform.isWindows) return false;
    try {
      final k = DynamicLibrary.open('kernel32.dll');
      final current = k.lookupFunction<IntPtr Function(), int Function()>('GetCurrentProcess');
      final set = k.lookupFunction<Int32 Function(IntPtr, Uint32), int Function(int, int)>('SetPriorityClass');
      return set(current(), high ? _aboveNormal : _normal) != 0;
    } on Object {
      return false;
    }
  }

  /// The class Windows reports for this process (for tests).
  static int? current() {
    if (!Platform.isWindows) return null;
    final k = DynamicLibrary.open('kernel32.dll');
    final cur = k.lookupFunction<IntPtr Function(), int Function()>('GetCurrentProcess');
    final get = k.lookupFunction<Uint32 Function(IntPtr), int Function(int)>('GetPriorityClass');
    return get(cur());
  }

  static const aboveNormal = _aboveNormal;
  static const normal = _normal;
}

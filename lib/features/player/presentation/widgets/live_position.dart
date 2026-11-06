import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../../domain/playhead_estimator.dart';
import '../../engine/playback_engine.dart';

/// Smooth playback position for per-frame visuals (lyrics wipe, visualizer).
///
/// The engine reports the position ~4×/s; [PlayheadEstimator] fills in between
/// the reports without jitter, on a [Ticker] that only runs while playing (no
/// idle frames).
class LivePosition extends ValueNotifier<Duration> {
  LivePosition(TickerProvider vsync) : super(Duration.zero) {
    _ticker = vsync.createTicker((_) => _tick());
    _clock.start();
  }

  late final Ticker _ticker;
  final _estimator = PlayheadEstimator();
  final _clock = Stopwatch();
  bool _hasReport = false;
  Duration _lastReport = Duration.zero;
  bool _lastPlaying = false;
  double _lastSpeed = 1;

  /// Feed the latest engine snapshot (call from a listener). The same snapshot
  /// twice changes nothing.
  void sync(EngineState s, {double speed = 1}) {
    final playing = s.playing && s.status != EngineStatus.loading;
    if (_hasReport && s.position == _lastReport && playing == _lastPlaying && speed == _lastSpeed) return;
    _hasReport = true;
    _lastReport = s.position;
    _lastPlaying = playing;
    _lastSpeed = speed;
    _estimator.report(s.position.inMicroseconds.toDouble(), playing: playing, speed: speed, nowUs: _clock.elapsedMicroseconds);
    if (playing && !_ticker.isActive) {
      _ticker.start();
    } else if (!playing && _ticker.isActive) {
      _ticker.stop();
    }
    _tick();
  }

  void _tick() {
    value = Duration(microseconds: _estimator.at(_clock.elapsedMicroseconds).round());
  }

  bool get playing => _lastPlaying;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

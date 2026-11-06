/// Turns the engine's coarse, slightly noisy position reports (about 4 per
/// second, each off by up to ~50 ms) into a position that moves evenly on every
/// frame.
///
/// Taking every report at face value makes visuals hop back and forth four
/// times a second, which was the jitter in the lyrics. Instead the difference is
/// worked off by running a little fast or slow for a moment, so the position
/// never runs backwards while playing. A big difference is a real jump (seek,
/// new song): that one is taken right away.
class PlayheadEstimator {
  /// Further off than this is a jump, not noise.
  static const jumpUs = 300000;

  /// A small error is worked off over this long.
  static const slewUs = 500000;

  double _baseUs = 0;
  int _baseAtUs = 0;
  double _rate = 1;
  double _pendingUs = 0;
  bool _playing = false;

  bool get playing => _playing;

  /// Position at [nowUs] (any clock in microseconds).
  double at(int nowUs) {
    if (!_playing) return _baseUs;
    final dt = nowUs - _baseAtUs;
    if (dt <= 0) return _baseUs;
    final slew = _pendingUs * (dt >= slewUs ? 1.0 : dt / slewUs);
    return _baseUs + dt * _rate + slew;
  }

  /// A new report from the engine.
  void report(double positionUs, {required bool playing, required double speed, required int nowUs}) {
    final predicted = at(nowUs);
    final error = positionUs - predicted;
    final wasPlaying = _playing;
    _playing = playing;
    _rate = speed;
    _baseAtUs = nowUs;
    if (!playing || !wasPlaying || error.abs() >= jumpUs) {
      _baseUs = positionUs;
      _pendingUs = 0;
    } else {
      // Half of it: one noisy report shouldn't pull the position its whole way.
      _baseUs = predicted;
      _pendingUs = error * 0.5;
    }
  }
}

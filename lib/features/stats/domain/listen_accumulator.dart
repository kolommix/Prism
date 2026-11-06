/// Decides when a listen counts as a "play" (Last.fm-style rule): at least
/// 30 seconds, or half the track for short tracks. Pure, driven by the caller
/// with wall-clock timestamps so it is easy to test.
class ListenAccumulator {
  ListenAccumulator({this.minListen = const Duration(seconds: 30)});

  final Duration minListen;

  int? _trackId;
  Duration _trackLength = Duration.zero;
  Duration _listened = Duration.zero;
  DateTime? _since;
  DateTime? _startedAt;
  bool _counted = false;


  /// Starts tracking a new track (flushes the previous one).
  (int, DateTime, Duration)? setTrack(int? trackId, Duration length, DateTime now) {
    final done = _finish(now);
    _trackId = trackId;
    _trackLength = length;
    _listened = Duration.zero;
    _since = null;
    _startedAt = null;
    _counted = false;
    return done;
  }

  /// Report play/pause changes (and periodic ticks while playing).
  void update({required bool playing, required DateTime now}) {
    if (_trackId == null) return;
    if (_since != null) {
      final delta = now.difference(_since!);
      // Ignore jumps (sleep, debugger) bigger than a few seconds.
      if (delta > Duration.zero && delta < const Duration(seconds: 5)) _listened += delta;
    }
    _since = playing ? now : null;
    if (playing) _startedAt ??= now;
  }

  bool get _qualifies {
    final half = Duration(microseconds: _trackLength.inMicroseconds ~/ 2);
    final need = _trackLength > Duration.zero && half < minListen ? half : minListen;
    return _listened >= need;
  }

  (int, DateTime, Duration)? _finish(DateTime now) {
    update(playing: false, now: now);
    final id = _trackId;
    if (id == null || _counted || !_qualifies) return null;
    _counted = true;
    return (id, _startedAt ?? now, _listened);
  }

  /// Flushes the current listen (e.g. app closing). Returns it once.
  (int, DateTime, Duration)? flush(DateTime now) => _finish(now);

  /// Repeat-one or a restart of the same track counts as a new listen.
  (int, DateTime, Duration)? restart(DateTime now) {
    final id = _trackId;
    final len = _trackLength;
    return setTrack(id, len, now);
  }
}

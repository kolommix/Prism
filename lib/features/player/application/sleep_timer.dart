import 'dart:async';

/// State of the sleep timer shown in the UI.
class SleepTimerState {
  const SleepTimerState({this.endsAt, this.endOfTrack = false});

  /// Wall-clock time when playback will stop (null = timer off).
  final DateTime? endsAt;

  /// Stop when the current track ends instead of at a time.
  final bool endOfTrack;

  bool get isActive => endsAt != null || endOfTrack;

  Duration remaining(DateTime now) =>
      endsAt == null ? Duration.zero : (endsAt!.difference(now).isNegative ? Duration.zero : endsAt!.difference(now));
}

/// Pauses playback after a delay, with a short volume fade at the end.
///
/// Pure Dart with injected callbacks, so it can be tested with fake async.
class SleepTimer {
  SleepTimer({
    required this.onFire,
    required this.setVolume,
    this.fadeOut = const Duration(seconds: 8),
  });

  /// Called when time is up (normally pauses the player).
  final Future<void> Function() onFire;

  /// Used for the fade-out; volume is restored to 1 after firing.
  final Future<void> Function(double volume) setVolume;
  final Duration fadeOut;

  final _ctrl = StreamController<SleepTimerState>.broadcast();
  SleepTimerState _state = const SleepTimerState();
  Timer? _timer;
  Timer? _fadeTimer;

  SleepTimerState get state => _state;
  Stream<SleepTimerState> get stream => _ctrl.stream;

  void start(Duration duration) {
    cancel();
    final end = DateTime.now().add(duration);
    _set(SleepTimerState(endsAt: end));
    final fadeStart = duration - fadeOut;
    _timer = Timer(fadeStart.isNegative ? Duration.zero : fadeStart, _beginFade);
  }

  /// Stop when the current track ends; the controller calls [trackEnded].
  void startEndOfTrack() {
    cancel();
    _set(const SleepTimerState(endOfTrack: true));
  }

  /// Notify that a track finished/advanced.
  Future<void> trackEnded() async {
    if (_state.endOfTrack) await _fire();
  }

  void cancel() {
    _timer?.cancel();
    _fadeTimer?.cancel();
    _timer = null;
    _fadeTimer = null;
    if (_state.isActive) {
      unawaited(setVolume(1));
      _set(const SleepTimerState());
    }
  }

  void _beginFade() {
    final sw = Stopwatch()..start();
    final total = fadeOut.inMilliseconds;
    if (total <= 0) {
      unawaited(_fire());
      return;
    }
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      final f = (sw.elapsedMilliseconds / total).clamp(0.0, 1.0);
      unawaited(setVolume(1 - f));
      if (f >= 1) {
        t.cancel();
        unawaited(_fire());
      }
    });
  }

  Future<void> _fire() async {
    _timer?.cancel();
    _fadeTimer?.cancel();
    _set(const SleepTimerState());
    await onFire();
    await setVolume(1);
  }

  void _set(SleepTimerState s) {
    _state = s;
    if (!_ctrl.isClosed) _ctrl.add(s);
  }

  void dispose() {
    _timer?.cancel();
    _fadeTimer?.cancel();
    _ctrl.close();
  }
}

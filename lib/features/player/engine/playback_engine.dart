import '../../library/domain/track.dart';

/// Coarse engine status, independent of the audio library.
enum EngineStatus { idle, loading, buffering, ready, completed }

/// Snapshot of what the engine is doing right now.
///
/// [position]/[duration] are *output* times: for a track with a live edit
/// preset they describe the edited version (what the user hears).
class EngineState {
  const EngineState({
    this.playing = false,
    this.status = EngineStatus.idle,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.duration,
  });

  final bool playing;
  final EngineStatus status;
  final Duration position;
  final Duration bufferedPosition;
  final Duration? duration;

  EngineState copyWith({
    bool? playing,
    EngineStatus? status,
    Duration? position,
    Duration? bufferedPosition,
    Duration? duration,
  }) =>
      EngineState(
        playing: playing ?? this.playing,
        status: status ?? this.status,
        position: position ?? this.position,
        bufferedPosition: bufferedPosition ?? this.bufferedPosition,
        duration: duration ?? this.duration,
      );
}

/// Things the engine reports back to the controller.
enum EngineEvent {
  /// The engine moved on to the "next" track by itself (gapless switch or
  /// start of a crossfade). The controller should advance the queue and send
  /// a new [PlaybackEngine.setNext].
  advancedToNext,

  /// The last track finished and there was no next track.
  ended,

  /// The current track could not be opened (missing file, bad codec…).
  /// The controller usually skips to the next track.
  failed,
}

/// Abstraction over the audio backend.
///
/// The engine knows only *two* tracks: the current one and the one after it.
/// The queue itself lives in `PlaybackQueue`; the controller keeps the engine
/// fed. This is what lets us do true gapless playback (the backend pre-buffers
/// the next item) and crossfade with the same simple contract.
///
/// Audio effects (EQ, pitch, extra gain) live behind `AudioEffectsBackend`;
/// the engine hands its players to it and drives speed/pitch/gain per clip.
abstract class PlaybackEngine {
  Stream<EngineState> get stateStream;
  EngineState get state;
  Stream<EngineEvent> get events;

  /// Why the last [EngineEvent.failed] happened (null if unknown).
  Object? get lastError;

  /// Loads [current] (and pre-buffers [next]) and optionally starts playing.
  /// [position] is an output position.
  Future<void> load(Track current, {Track? next, Duration position = Duration.zero, bool play = true});

  /// Replaces the pre-buffered next track without interrupting playback.
  Future<void> setNext(Track? next);

  /// Re-resolves the current track's plan (e.g. a live edit preset was
  /// applied or removed) and continues at the same output position.
  Future<void> reloadCurrent();

  Future<void> play();
  Future<void> pause();

  /// Seeks to an output position.
  Future<void> seek(Duration position);
  Future<void> stop();

  /// 0..1 master volume.
  Future<void> setVolume(double volume);

  /// [Duration.zero] = gapless mode, otherwise crossfade length.
  Future<void> setCrossfade(Duration duration);

  /// Loop the current track (repeat-one).
  Future<void> setRepeatOne(bool enabled);

  /// Playback speed (pitch preserved), 0.25..4.
  Future<void> setSpeed(double speed);

  /// Pitch shift in semitones (speed unchanged).
  Future<void> setPitchSemitones(double semitones);

  /// Global gain added to every track (EQ preamp), in dB.
  Future<void> setPreampDb(double db);

  /// A-B loop in output time of the current track; null clears it.
  Future<void> setAbLoop(Duration? a, Duration? b);

  /// Pushes this engine's pitch/gain to the effects backend again (after
  /// another engine – the editor preview – used the shared backend).
  Future<void> reapplyEffects();

  Future<void> dispose();
}

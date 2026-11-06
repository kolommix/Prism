import 'package:just_audio/just_audio.dart';

import '../domain/eq_settings.dart';
import '../../../l10n/l10n.dart';

/// Platform-specific DSP behind one interface.
///
/// The playback engine owns the `just_audio` players and hands them to the
/// backend with [attach]. Everything else (EQ UI, live edit presets, loudness
/// normalisation) talks to this interface only:
///
/// * Windows → `MpvAudioEffects`: FFmpeg biquads + rubberband inside libmpv.
/// * Android → `AndroidAudioEffects`: native `Equalizer`, `BassBoost` and
///   `LoudnessEnhancer` on each player's audio session.
abstract class AudioEffectsBackend {
  /// Called once with the engine's players (both crossfade decks).
  Future<void> attach(List<AudioPlayer> players);

  /// Stops managing [players] (a short-lived engine, e.g. the editor preview,
  /// is being disposed).
  Future<void> detach(List<AudioPlayer> players);

  Future<void> setEq(EqSettings eq);

  /// Pitch shift without changing speed. 1.0 = original pitch.
  Future<void> setPitchRatio(double ratio);

  /// Positive gain the player volume cannot provide (volume is capped at
  /// [maxLinearVolume]). Negative gains are done with the player volume.
  Future<void> setExtraGainDb(double db);

  /// Highest linear volume the player itself accepts.
  double get maxLinearVolume;

  /// Human readable limitations shown in the EQ screen.
  List<String> get limitations;

  Future<void> dispose();
}

/// Backend that does nothing (tests, unsupported platforms).
class NoAudioEffects implements AudioEffectsBackend {
  @override
  Future<void> attach(List<AudioPlayer> players) async {}
  @override
  Future<void> detach(List<AudioPlayer> players) async {}
  @override
  Future<void> setEq(EqSettings eq) async {}
  @override
  Future<void> setPitchRatio(double ratio) async {}
  @override
  Future<void> setExtraGainDb(double db) async {}
  @override
  double get maxLinearVolume => 1;
  @override
  List<String> get limitations => [l10n.audioEffectsAreNotAvailableOn];
  @override
  Future<void> dispose() async {}
}

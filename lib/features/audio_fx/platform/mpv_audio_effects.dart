import 'dart:async';
import 'dart:math' as math;

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';

import '../../editor/domain/export_command.dart';
import '../domain/eq_math.dart';
import '../domain/eq_settings.dart';
import 'audio_effects_backend.dart';
import '../../../l10n/l10n.dart';

/// Builds libmpv's `af` property for the current effects: one FFmpeg graph
/// `@fx:lavfi=[...]` with
///
/// * pitch shift – `asetrate` + `aresample` + `atempo` (same filters as the
///   editor's resample export path). mpv's realtime rubberband was measured
///   16–35 dB too quiet on pitch shifts (test/platform), this route is
///   level-exact;
/// * one `equalizer` biquad per non-zero band, a `bass` low shelf and an
///   `alimiter` when the curve boosts. (The preamp is not here: the engine
///   applies it through the player volume, same as on Android.)
///
/// Returns '' when nothing needs processing (zero CPU cost, zero latency).
/// Pure function → unit tested.
String buildMpvAudioFilter(EqSettings eq, {double pitchRatio = 1.0}) {
  final graph = <String>[];
  if ((pitchRatio - 1).abs() > 0.001) {
    graph.addAll(pitchFilters(12 * math.log(pitchRatio) / math.ln2, PitchEngine.resample));
  }
  if (!eq.isNeutral) {
    graph.addAll([
      for (var i = 0; i < eqBandFrequencies.length; i++)
        if (eq.gainsDb[i].abs() >= 0.05)
          'equalizer=f=${_n(eqBandFrequencies[i])}:t=q:w=$eqBandQ:g=${_n(eq.gainsDb[i])}',
      if (eq.bassBoostDb >= 0.05) 'bass=g=${_n(eq.bassBoostDb)}:f=${_n(bassBoostFrequency)}:t=q:w=$bassShelfQ',
    ]);
    // Soft-limit only when the curve can push peaks over full scale.
    if (eqPeakBoostDb(eq) > 0.5) graph.add('alimiter=limit=0.97:level=disabled:attack=5:release=60');
  }
  return graph.isEmpty ? '' : '@fx:lavfi=[${graph.join(',')}]';
}

String _n(double v) => v.toStringAsFixed(2);

/// Windows backend: FFmpeg filters inside the full libmpv build.
///
/// Changing `af` makes mpv rebuild the filter chain, which can cause a tiny
/// click; EQ slider drags are therefore debounced. Pitch changes (player
/// slider, live-preset clip boundaries) apply immediately.
class MpvAudioEffects implements AudioEffectsBackend {
  EqSettings _eq = const EqSettings();
  double _pitch = 1;
  String _applied = '';
  Timer? _debounce;

  @override
  Future<void> attach(List<AudioPlayer> players) async {
    // Positive gains (+12 dB = 4x linear) go through the player volume; the
    // patched plugin maps linear volume to mpv's cubic scale (4x → 159 %).
    await JustAudioMediaKit.setGlobalProperty('volume-max', '200');
    await _apply(force: true);
  }

  /// Filters are global for all mpv players, nothing per player to undo.
  @override
  Future<void> detach(List<AudioPlayer> players) async {}

  @override
  Future<void> setEq(EqSettings eq) async {
    _eq = eq;
    _schedule();
  }

  @override
  Future<void> setPitchRatio(double ratio) async {
    _pitch = ratio;
    _debounce?.cancel();
    await _apply();
  }

  /// Positive gain is handled by the player volume (up to +12 dB).
  @override
  Future<void> setExtraGainDb(double db) async {}

  @override
  double get maxLinearVolume => 4.0;

  @override
  List<String> get limitations => [
        l10n.changingEqBandsRebuildsTheLibmpv,
        l10n.livePitchShiftUsesResamplingTime,
      ];

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 80), _apply);
  }

  Future<void> _apply({bool force = false}) async {
    final af = buildMpvAudioFilter(_eq, pitchRatio: _pitch);
    if (!force && af == _applied) return;
    _applied = af;
    await JustAudioMediaKit.setGlobalProperty('af', af);
  }

  /// The filter string currently applied (for diagnostics / tests).
  String get currentFilter => _applied;

  @override
  Future<void> dispose() async => _debounce?.cancel();
}

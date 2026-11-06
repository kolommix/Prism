import 'package:freezed_annotation/freezed_annotation.dart';

part 'eq_settings.freezed.dart';
part 'eq_settings.g.dart';

/// Centre frequencies (Hz) of the 10-band graphic EQ (ISO octave bands).
const eqBandFrequencies = <double>[31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];

/// Q of every peaking band. 1.41 ≈ one-octave bandwidth, so neighbouring
/// bands overlap smoothly like a classic hardware graphic EQ.
const eqBandQ = 1.41;

/// Limits shown in the UI and enforced when importing presets.
const eqMaxGainDb = 12.0;
const eqMaxPreampDb = 12.0;

/// Bass boost is a low shelf at [bassBoostFrequency]; 100 % = [bassBoostMaxDb].
const bassBoostFrequency = 100.0;
const bassBoostMaxDb = 12.0;

/// The one shared EQ model for every platform.
///
/// Windows turns it into an FFmpeg biquad chain inside libmpv, Android maps
/// the resulting curve onto the device's native `Equalizer` bands. The UI curve
/// and both backends use the same math (`eq_math.dart`), so what you see is
/// what you hear.
@freezed
abstract class EqSettings with _$EqSettings {
  const EqSettings._();

  const factory EqSettings({
    @Default(false) bool enabled,

    /// Gain per band in dB, same order as [eqBandFrequencies].
    @Default([0, 0, 0, 0, 0, 0, 0, 0, 0, 0]) List<double> gainsDb,

    /// Overall gain before the bands, in dB (usually ≤ 0 to avoid clipping).
    @Default(0.0) double preampDb,

    /// 0..1 strength of the bass shelf.
    @Default(0.0) double bassBoost,

    /// Name of the preset the values came from ("Custom" once edited).
    @Default('Flat') String presetName,
  }) = _EqSettings;

  factory EqSettings.fromJson(Map<String, dynamic> json) => _$EqSettingsFromJson(json);

  /// True when the EQ would not change the sound at all.
  bool get isNeutral =>
      !enabled || (gainsDb.every((g) => g.abs() < 0.05) && preampDb.abs() < 0.05 && bassBoost < 0.005);

  double get bassBoostDb => bassBoost * bassBoostMaxDb;

  /// Copy with every value clamped into its range and exactly 10 bands.
  EqSettings sanitized() => copyWith(
        gainsDb: List.generate(
          eqBandFrequencies.length,
          (i) => i < gainsDb.length ? gainsDb[i].clamp(-eqMaxGainDb, eqMaxGainDb).toDouble() : 0.0,
        ),
        preampDb: preampDb.clamp(-eqMaxPreampDb, eqMaxPreampDb),
        bassBoost: bassBoost.clamp(0.0, 1.0),
      );

  EqSettings withBand(int index, double gainDb) {
    final g = [...gainsDb];
    g[index] = gainDb.clamp(-eqMaxGainDb, eqMaxGainDb);
    return copyWith(gainsDb: g, presetName: 'Custom');
  }

  EqSettings applyPreset(EqPreset p) =>
      copyWith(gainsDb: [...p.gainsDb], preampDb: p.preampDb, bassBoost: p.bassBoost, presetName: p.name, enabled: true);
}

/// A named set of band gains.
@freezed
abstract class EqPreset with _$EqPreset {
  const factory EqPreset({
    required String name,
    required List<double> gainsDb,
    @Default(0.0) double preampDb,
    @Default(0.0) double bassBoost,
    @Default(false) bool builtIn,
  }) = _EqPreset;

  factory EqPreset.fromJson(Map<String, dynamic> json) => _$EqPresetFromJson(json);
}

/// Presets every user gets. Preamps compensate the biggest boosts so the
/// result does not clip.
const builtInEqPresets = <EqPreset>[
  EqPreset(name: 'Flat', gainsDb: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0], builtIn: true),
  EqPreset(name: 'Bass Boost', gainsDb: [6, 5.5, 4.5, 2.5, 1, 0, 0, 0, 0, 0], preampDb: -4, builtIn: true),
  EqPreset(name: 'Vocal', gainsDb: [-2, -2, -1, 1, 3, 4, 3.5, 2, 0, -1], preampDb: -3, builtIn: true),
  EqPreset(name: 'Treble', gainsDb: [0, 0, 0, 0, 0, 1, 2.5, 4, 5, 6], preampDb: -4, builtIn: true),
  EqPreset(name: 'Rock', gainsDb: [4.5, 3.5, 2, 0.5, -1, -0.5, 1.5, 3, 4, 4.5], preampDb: -3, builtIn: true),
  EqPreset(name: 'Electronic', gainsDb: [5, 4, 1.5, 0, -2, 1.5, 1, 2, 4, 5], preampDb: -4, builtIn: true),
  EqPreset(name: 'Pop', gainsDb: [-1, -0.5, 0.5, 2, 3.5, 3.5, 2, 0.5, -0.5, -1], preampDb: -2.5, builtIn: true),
  EqPreset(name: 'Hip-Hop', gainsDb: [5, 4.5, 2, 3, -1, -1, 1, -0.5, 1.5, 3], preampDb: -4, builtIn: true),
  EqPreset(name: 'Jazz', gainsDb: [3, 2, 1, 1.5, -1, -1, 0, 1, 2, 3], preampDb: -2, builtIn: true),
  EqPreset(name: 'Classical', gainsDb: [4, 3, 2, 1.5, -1, -1, 0, 2, 3, 4], preampDb: -3, builtIn: true),
  EqPreset(name: 'Acoustic', gainsDb: [4, 4, 3, 1, 2, 1.5, 3, 3.5, 3, 2], preampDb: -3.5, builtIn: true),
  EqPreset(name: 'Speech', gainsDb: [-4, -3, -1, 1, 3, 4, 3, 1, -1, -3], preampDb: -3, builtIn: true),
];

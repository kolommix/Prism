import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';
import '../../player/application/player_providers.dart';
import '../domain/eq_math.dart';
import '../domain/eq_settings.dart';
import '../platform/audio_effects_backend.dart';

/// The platform DSP backend, created in bootstrap together with the engine.
final audioEffectsProvider = Provider<AudioEffectsBackend>((ref) => NoAudioEffects());

/// EQ settings + the user's own presets.
class EqState {
  const EqState({this.settings = const EqSettings(), this.customPresets = const []});

  final EqSettings settings;
  final List<EqPreset> customPresets;

  List<EqPreset> get allPresets => [...builtInEqPresets, ...customPresets];

  EqState copyWith({EqSettings? settings, List<EqPreset>? customPresets}) =>
      EqState(settings: settings ?? this.settings, customPresets: customPresets ?? this.customPresets);
}

/// Loads/saves EQ state in shared preferences.
class EqStore {
  EqStore(this._prefs);

  static const _settingsKey = 'eq.settings.v1';
  static const _presetsKey = 'eq.presets.v1';
  final SharedPreferencesAsync _prefs;

  Future<EqState> load() async {
    var settings = const EqSettings();
    var presets = <EqPreset>[];
    try {
      final s = await _prefs.getString(_settingsKey);
      if (s != null) settings = EqSettings.fromJson(jsonDecode(s) as Map<String, dynamic>).sanitized();
      final p = await _prefs.getString(_presetsKey);
      if (p != null) {
        presets = [for (final j in jsonDecode(p) as List) EqPreset.fromJson(j as Map<String, dynamic>)];
      }
    } on Object {
      // Corrupt prefs: start flat.
    }
    return EqState(settings: settings, customPresets: presets);
  }

  Future<void> save(EqState s) async {
    await _prefs.setString(_settingsKey, jsonEncode(s.settings.toJson()));
    await _prefs.setString(_presetsKey, jsonEncode([for (final p in s.customPresets) p.toJson()]));
  }
}

final eqStoreProvider = Provider<EqStore>((ref) => EqStore(ref.watch(prefsProvider)));

/// EQ loaded before runApp (overridden in bootstrap).
final initialEqProvider = Provider<EqState>((ref) => const EqState());

/// Owns the EQ, persists it and pushes every change to the DSP backend and
/// the engine (preamp goes through the engine's gain path).
class EqController extends Notifier<EqState> {
  Timer? _saveDebounce;

  @override
  EqState build() {
    final initial = ref.read(initialEqProvider);
    Future.microtask(() => _push(initial.settings));
    ref.onDispose(() => _saveDebounce?.cancel());
    return initial;
  }

  void _set(EqState s) {
    state = s;
    _push(s.settings);
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 400), () => ref.read(eqStoreProvider).save(state));
  }

  void _push(EqSettings eq) {
    ref.read(audioEffectsProvider).setEq(eq);
    try {
      ref.read(playerControllerProvider).setPreampDb(eq.enabled ? eq.preampDb : 0);
    } on Object {
      // No player in widget tests (Riverpod 3 wraps the error in a ProviderException).
    }
  }

  void setEnabled(bool v) => _set(state.copyWith(settings: state.settings.copyWith(enabled: v)));

  void setBand(int index, double db) =>
      _set(state.copyWith(settings: state.settings.withBand(index, db).copyWith(enabled: true)));

  void setPreamp(double db) => _set(state.copyWith(
      settings: state.settings.copyWith(preampDb: db.clamp(-eqMaxPreampDb, eqMaxPreampDb), presetName: 'Custom')));

  void setBassBoost(double v) => _set(state.copyWith(
      settings: state.settings.copyWith(bassBoost: v.clamp(0.0, 1.0), enabled: true, presetName: 'Custom')));

  /// Simple view: Bass, Mids or Treble to [level] dB (see [eqWithTone]).
  void setTone(EqTone tone, double level) {
    final s = state.settings;
    _set(state.copyWith(
      settings: s.copyWith(gainsDb: eqWithTone(s.gainsDb, tone, level), presetName: 'Custom', enabled: true),
    ));
  }

  /// Preamp just low enough that the loudest point of the curve stays at 0 dB.
  void autoPreamp() => setPreamp(eqAutoPreampDb(state.settings));

  /// "Hold to compare": the sound without the EQ while held, nothing saved.
  void compare(bool without) => _push(without ? state.settings.copyWith(enabled: false) : state.settings);

  void applyPreset(EqPreset p) => _set(state.copyWith(settings: state.settings.applyPreset(p)));

  void reset() => applyPreset(builtInEqPresets.first);

  /// Replaces everything (backup restore).
  void restore(EqState s) => _set(s);

  /// Saves the current values as a custom preset (replaces same name).
  void savePreset(String name) {
    final n = name.trim().isEmpty ? 'My preset' : name.trim();
    final s = state.settings;
    final preset = EqPreset(name: n, gainsDb: [...s.gainsDb], preampDb: s.preampDb, bassBoost: s.bassBoost);
    _set(state.copyWith(
      customPresets: [...state.customPresets.where((p) => p.name != n), preset],
      settings: s.copyWith(presetName: n),
    ));
  }

  void deletePreset(String name) =>
      _set(state.copyWith(customPresets: state.customPresets.where((p) => p.name != name).toList()));
}

final eqControllerProvider = NotifierProvider<EqController, EqState>(EqController.new);

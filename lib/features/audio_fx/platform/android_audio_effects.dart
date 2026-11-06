import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../domain/eq_math.dart';
import '../domain/eq_settings.dart';
import 'audio_effects_backend.dart';

import '../../visualizer/data/live_fft.dart';
/// Native band layout reported by the device's `android.media.audiofx.Equalizer`.
class AndroidEqInfo {
  const AndroidEqInfo({required this.centerFreqsHz, required this.minMb, required this.maxMb});

  final List<double> centerFreqsHz;
  final int minMb;
  final int maxMb;

  factory AndroidEqInfo.fromMap(Map<Object?, Object?> m) => AndroidEqInfo(
        centerFreqsHz: [for (final v in (m['centerFreqsMilliHz'] as List? ?? const [])) (v as int) / 1000.0],
        minMb: m['minMb'] as int? ?? -1500,
        maxMb: m['maxMb'] as int? ?? 1500,
      );
}

/// Maps the shared 10-band curve onto the device's native bands: the curve is
/// evaluated at each native centre frequency (so a 5-band phone still follows
/// the 10-band shape as closely as its hardware allows). Values in millibels.
List<int> mapEqToNativeBands(EqSettings eq, AndroidEqInfo info) => [
      for (final f in info.centerFreqsHz)
        (eqResponseDb(eq, f, includePreamp: false) * 100).round().clamp(info.minMb, info.maxMb),
    ];

/// Android backend: native audio effects attached to each player's audio
/// session through the `prism/audiofx` channel (see `AudioFxPlugin.kt`).
class AndroidAudioEffects implements AudioEffectsBackend {
  static const _channel = MethodChannel('prism/audiofx');

  final _players = <AudioPlayer>[];
  final _sessions = <AudioPlayer, int>{};
  final _subs = <StreamSubscription<int?>>[];
  EqSettings _eq = const EqSettings();
  double _extraGainDb = 0;
  double _pitch = 1;
  AndroidEqInfo? _info;

  AndroidEqInfo? get info => _info;

  @override
  Future<void> attach(List<AudioPlayer> players) async {
    _players.addAll(players);
    for (final p in players) {
      _subs.add(p.androidAudioSessionIdStream.listen((id) => _onSession(p, id)));
    }
  }

  @override
  Future<void> detach(List<AudioPlayer> players) async {
    for (final p in players) {
      _players.remove(p);
      final id = _sessions.remove(p);
      if (id != null) await _invoke('release', {'session': id});
    }
  }

  Future<void> _onSession(AudioPlayer player, int? id) async {
    if (!_players.contains(player)) return;
    final old = _sessions[player];
    if (old == id) return;
    // The live visualizer listens to the newest session.
    if (id != null) LiveFft.sessionId = id;
    if (old != null) await _invoke('release', {'session': old});
    if (id == null) {
      _sessions.remove(player);
      return;
    }
    _sessions[player] = id;
    final res = await _invoke('attach', {'session': id});
    if (res is Map) _info = AndroidEqInfo.fromMap(res);
    await _pushAll();
  }

  @override
  Future<void> setEq(EqSettings eq) async {
    _eq = eq;
    await _pushEq();
  }

  @override
  Future<void> setPitchRatio(double ratio) async {
    _pitch = ratio;
    for (final p in _players) {
      await p.setPitch(ratio);
    }
  }

  @override
  Future<void> setExtraGainDb(double db) async {
    _extraGainDb = math.max(0, db);
    await _invoke('setGain', {'mB': (_extraGainDb * 100).round()});
  }

  @override
  double get maxLinearVolume => 1.0;

  @override
  List<String> get limitations => [
        if (_info != null)
          'This device\'s Equalizer has ${_info!.centerFreqsHz.length} bands '
              '(${_info!.centerFreqsHz.map((f) => f >= 1000 ? '${(f / 1000).toStringAsFixed(1)}k' : f.round().toString()).join(', ')} Hz, '
              '±${(_info!.maxMb / 100).round()} dB); the 10-band curve is sampled at those frequencies.',
        'Bass boost uses the system BassBoost effect; its exact curve depends on the phone.',
        'Some phones (or other EQ apps like Wavelet) can override or block audio effects.',
      ];

  Future<void> _pushAll() async {
    await _pushEq();
    await setExtraGainDb(_extraGainDb);
    for (final p in _players) {
      await p.setPitch(_pitch);
    }
  }

  Future<void> _pushEq() async {
    final info = _info;
    final enabled = _eq.enabled && !_eq.isNeutral;
    await _invoke('setEq', {
      'enabled': enabled,
      'levelsMb': info == null ? const <int>[] : mapEqToNativeBands(_eq, info),
    });
    await _invoke('setBass', {
      'enabled': enabled && _eq.bassBoost > 0.005,
      'strength': (_eq.bassBoost * 1000).round().clamp(0, 1000),
    });
  }

  Future<Object?> _invoke(String method, Map<String, Object?> args) async {
    try {
      return await _channel.invokeMethod<Object?>(method, args);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
    for (final id in _sessions.values) {
      await _invoke('release', {'session': id});
    }
  }
}

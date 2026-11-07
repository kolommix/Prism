import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import '../../../core/platform/android_permissions.dart';

import '../domain/beat_detector.dart';
import '../domain/spectrum.dart';

/// Android's Visualizer API on the player's own audio session: real FFT of what
/// is actually playing, with EQ and speed, and it works for streamed songs too.
/// The catch: Android asks for the microphone permission for it (Prism never
/// records anything), so this stays off until the user turns it on.
class LiveFft implements BandSource {
  LiveFft({this.bandCount = 48}) : _levels = Float32List(bandCount);

  static const _method = MethodChannel('prism/visualizer');
  static const _events = EventChannel('prism/visualizer/fft');

  /// Set by the audio backend when the player gets its audio session.
  static int? sessionId;

  static bool get supported => Platform.isAndroid;

  final int bandCount;
  final Float32List _levels;
  StreamSubscription<dynamic>? _sub;
  int _hz = 44100;
  bool _running = false;

  @override
  int get bands => bandCount;

  @override
  void sample(Duration t, Float32List out) {
    for (var i = 0; i < bandCount && i < out.length; i++) {
      out[i] = _levels[i];
    }
  }

  bool get running => _running;

  static Future<bool> hasPermission() => AndroidPermissions.hasMicrophone();

  /// Asks for the permission; false = refused.
  static Future<bool> requestPermission() => AndroidPermissions.requestMicrophone();

  /// False when there is no session yet or Android refused.
  Future<bool> start() async {
    final session = sessionId;
    if (session == null || _running) return _running;
    try {
      final res = await _method.invokeMapMethod<String, dynamic>('start', {'session': session});
      _hz = (res?['samplingHz'] as int?) ?? 44100;
      _running = true;
      _sub = _events.receiveBroadcastStream().listen((data) {
        if (data is Uint8List) {
          bandsFromAndroidFft(Int8List.sublistView(data), _hz, _levels);
        }
      });
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    if (_running) {
      _running = false;
      try {
        await _method.invokeMethod<void>('stop');
      } on Object {
        // Already gone.
      }
    }
  }
}

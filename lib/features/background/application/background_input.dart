import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A click somewhere in the app that the background should answer.
class BackgroundBurst {
  const BackgroundBurst(this.at, this.strength);
  final Offset at;
  final double strength;
}

/// Where the mouse is (global coordinates) and the clicks. Filled by one
/// `Listener` around the whole app in `app.dart`; no rebuilds, no cost when
/// no animated background is running. The background reads it when it steps.
class BackgroundInput {
  Offset? pointer;
  final _bursts = StreamController<BackgroundBurst>.broadcast();

  Stream<BackgroundBurst> get bursts => _bursts.stream;

  void burst(Offset at, {double strength = 1}) {
    if (_bursts.hasListener) _bursts.add(BackgroundBurst(at, strength));
  }

  void dispose() => _bursts.close();
}

final backgroundInputProvider = Provider<BackgroundInput>((ref) {
  final input = BackgroundInput();
  ref.onDispose(input.dispose);
  return input;
});

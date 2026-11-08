import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Real full screen on Windows, in `flutter_window.cpp`. window_manager's own
/// keeps the title bar and loses part of the screen when the window was
/// maximized first (measured in integration_test/fullscreen_test.dart).
class WindowsFullScreen {
  const WindowsFullScreen._();
  static const _channel = MethodChannel('prism/window');

  /// True while full screen; the in-app window caption hides then.
  static final active = ValueNotifier<bool>(false);

  static Future<void> set(bool on) async {
    await _channel.invokeMethod<void>('setFullScreen', on);
    active.value = on;
  }

  static Future<bool> isOn() async => await _channel.invokeMethod<bool>('isFullScreen') ?? false;
}

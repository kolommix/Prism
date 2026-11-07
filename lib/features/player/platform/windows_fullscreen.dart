import 'package:flutter/services.dart';

/// Real full screen on Windows, in `flutter_window.cpp`. window_manager's own
/// keeps the title bar and loses part of the screen when the window was
/// maximized first (measured in integration_test/fullscreen_test.dart).
class WindowsFullScreen {
  const WindowsFullScreen._();
  static const _channel = MethodChannel('prism/window');

  static Future<void> set(bool on) => _channel.invokeMethod<void>('setFullScreen', on);
  static Future<bool> isOn() async => await _channel.invokeMethod<bool>('isFullScreen') ?? false;
}

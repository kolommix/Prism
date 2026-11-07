// ignore_for_file: avoid_print
import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prism/features/player/platform/windows_fullscreen.dart';
import 'package:window_manager/window_manager.dart';

final _user32 = DynamicLibrary.open('user32.dll');
final _findWindowEx = _user32.lookupFunction<IntPtr Function(IntPtr, IntPtr, Pointer<Utf16>, Pointer<Utf16>),
    int Function(int, int, Pointer<Utf16>, Pointer<Utf16>)>('FindWindowExW');
final _threadProcess = _user32.lookupFunction<Uint32 Function(IntPtr, Pointer<Uint32>), int Function(int, Pointer<Uint32>)>(
    'GetWindowThreadProcessId');
final _getRect = _user32.lookupFunction<Int32 Function(IntPtr, Pointer<Int32>), int Function(int, Pointer<Int32>)>('GetWindowRect');
final _clientRect = _user32.lookupFunction<Int32 Function(IntPtr, Pointer<Int32>), int Function(int, Pointer<Int32>)>('GetClientRect');
final _monitorFrom = _user32.lookupFunction<IntPtr Function(IntPtr, Uint32), int Function(int, int)>('MonitorFromWindow');
final _monitorInfo = _user32.lookupFunction<Int32 Function(IntPtr, Pointer<Int32>), int Function(int, Pointer<Int32>)>('GetMonitorInfoW');
final _style = _user32.lookupFunction<Int32 Function(IntPtr, Int32), int Function(int, int)>('GetWindowLongW');
final _zoomed = _user32.lookupFunction<Int32 Function(IntPtr), int Function(int)>('IsZoomed');

const _wsCaption = 0x00C00000;
const _wsThickFrame = 0x00040000;

int _hwnd() {
  final cls = 'FLUTTER_RUNNER_WIN32_WINDOW'.toNativeUtf16();
  final pidOut = calloc<Uint32>();
  try {
    var h = 0;
    while (true) {
      h = _findWindowEx(0, h, cls, nullptr);
      if (h == 0) throw StateError('window not found');
      _threadProcess(h, pidOut);
      if (pidOut.value == pid) return h;
    }
  } finally {
    calloc.free(cls);
    calloc.free(pidOut);
  }
}

List<int> _rect(int Function(int, Pointer<Int32>) get, int h) {
  final r = calloc<Int32>(4);
  try {
    get(h, r);
    return [r[0], r[1], r[2], r[3]];
  } finally {
    calloc.free(r);
  }
}

List<int> _monitor(int h) {
  final info = calloc<Int32>(10);
  try {
    info[0] = 40;
    _monitorInfo(_monitorFrom(h, 2), info);
    return [info[1], info[2], info[3], info[4]];
  } finally {
    calloc.free(info);
  }
}

/// Real window, real Windows calls: does full screen cover the whole monitor,
/// and does leaving it put the window back? Starts from a normal and from a
/// maximized window, since the two go through different code.
///
/// flutter test integration_test/fullscreen_test.dart -d windows
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('full screen covers the monitor and restores', (tester) async {
    await windowManager.ensureInitialized();
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ColoredBox(color: Colors.black))));
    final h = _hwnd();

    Future<void> settle() => tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));

    Future<void> check(String tag, {required bool maximized}) async {
      if (maximized) {
        await tester.runAsync(windowManager.maximize);
      } else {
        await tester.runAsync(windowManager.unmaximize);
        await tester.runAsync(() => windowManager.setSize(const Size(900, 700)));
      }
      await settle();
      final before = _rect(_getRect, h);
      final zoomedBefore = _zoomed(h) != 0;
      final styleBefore = _style(h, -16);

      await tester.runAsync(() => WindowsFullScreen.set(true));
      await settle();
      final mon = _monitor(h);
      final win = _rect(_getRect, h);
      final client = _rect(_clientRect, h);
      final style = _style(h, -16);
      print('$tag on: monitor=$mon window=$win client=$client '
          'caption=${style & _wsCaption == _wsCaption} frame=${style & _wsThickFrame != 0}');
      expect(win, mon, reason: '$tag: window must be exactly the monitor');
      expect(client[2], mon[2] - mon[0], reason: '$tag: content must be as wide as the monitor');
      expect(client[3], mon[3] - mon[1], reason: '$tag: content must be as tall as the monitor (no title bar)');
      expect(style & _wsCaption == _wsCaption, isFalse, reason: '$tag: no title bar');
      expect(await tester.runAsync(WindowsFullScreen.isOn), isTrue);

      await tester.runAsync(() => WindowsFullScreen.set(false));
      await settle();
      final after = _rect(_getRect, h);
      print('$tag off: before=$before after=$after zoomed=${_zoomed(h) != 0}');
      expect(_zoomed(h) != 0, zoomedBefore, reason: '$tag: maximized state comes back');
      expect(after, before, reason: '$tag: window comes back to where it was');
      expect(_style(h, -16), styleBefore, reason: '$tag: title bar and frame come back');
      expect(await tester.runAsync(WindowsFullScreen.isOn), isFalse);
    }

    await check('normal', maximized: false);
    await check('maximized', maximized: true);
    await check('normal again', maximized: false);
  });
}

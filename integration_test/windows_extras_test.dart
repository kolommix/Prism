// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:ffi' hide Size;
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:prism/features/online/data/photo_reader.dart';
import 'package:prism/features/online/domain/photo_songs.dart';
import 'package:window_manager/window_manager.dart';

final _user32 = DynamicLibrary.open('user32.dll');
final _findWindowEx = _user32.lookupFunction<IntPtr Function(IntPtr, IntPtr, Pointer<Utf16>, Pointer<Utf16>),
    int Function(int, int, Pointer<Utf16>, Pointer<Utf16>)>('FindWindowExW');
final _threadProcess = _user32.lookupFunction<Uint32 Function(IntPtr, Pointer<Uint32>), int Function(int, Pointer<Uint32>)>(
    'GetWindowThreadProcessId');
final _getRect = _user32.lookupFunction<Int32 Function(IntPtr, Pointer<Int32>), int Function(int, Pointer<Int32>)>('GetWindowRect');
final _exStyle = _user32.lookupFunction<Int32 Function(IntPtr, Int32), int Function(int, int)>('GetWindowLongW');
final _visible = _user32.lookupFunction<Int32 Function(IntPtr), int Function(int)>('IsWindowVisible');
final _keybd = _user32.lookupFunction<Void Function(Uint8, Uint8, Uint32, IntPtr), void Function(int, int, int, int)>('keybd_event');
final _foreground = _user32.lookupFunction<IntPtr Function(), int Function()>('GetForegroundWindow');

int? _window(String cls) {
  final name = cls.toNativeUtf16();
  final pidOut = calloc<Uint32>();
  try {
    var h = 0;
    while (true) {
      h = _findWindowEx(0, h, name, nullptr);
      if (h == 0) return null;
      _threadProcess(h, pidOut);
      if (pidOut.value == pid) return h;
    }
  } finally {
    calloc.free(name);
    calloc.free(pidOut);
  }
}

List<int> _rect(int h) {
  final r = calloc<Int32>(4);
  try {
    _getRect(h, r);
    return [r[0], r[1], r[2], r[3]];
  } finally {
    calloc.free(r);
  }
}

const _wsExTopmost = 0x8, _wsExTransparent = 0x20, _wsExLayered = 0x80000, _wsExNoActivate = 0x08000000;

/// The Windows-only parts on the real system: reading a screenshot with
/// Windows' text recognition, the floating lyrics window, a global hotkey.
///
/// flutter test integration_test/windows_extras_test.dart -d windows
/// (with `--dart-define=SHOT_RECT=file`: the lyrics window's place is written
/// there and it stays up 5 s, for a screen capture.)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot of a playlist: real text recognition finds the songs', (tester) async {
    final path = p.absolute('test/fixtures/photo/phone_dark.png');
    Object? error;
    final page = await tester.runAsync(() async {
      try {
        return await const PhotoReader().read(path);
      } on Object catch (e) {
        error = e;
        return null;
      }
    });
    expect(error, isNull, reason: path);
    final names = [for (final s in songsFromPhoto(page!)) '${s.artist} - ${s.title}'];
    print('photo: $names');
    expect(names, hasLength(10));
    expect(names, contains('Король и Шут - Кукла колдуна'));
    expect(names, contains('Nirvana - Smells Like Teen Spirit'));
    expect(names, contains('Ed Sheeran - Shape of You'));
  });

  testWidgets('floating lyrics window: on top, see-through, never takes the focus, locks', (tester) async {
    await windowManager.ensureInitialized();
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ColoredBox(color: Colors.black))));
    const ch = MethodChannel('prism/lyricswindow');
    Future<void> call(String m, [Object? a]) => tester.runAsync(() => ch.invokeMethod<void>(m, a));
    Future<void> settle([int ms = 300]) => tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));

    final before = _foreground();
    await call('show', {'fontSize': 30.0, 'opacity': 0.45, 'locked': false, 'x': null, 'y': null, 'w': 0, 'labels': <String>[]});
    await call('text', {'current': 'Every song has words, they rise in as they are sung', 'next': 'Кукла колдуна'});
    await settle();
    final h = _window('PRISM_LYRICS_WINDOW');
    expect(h, isNotNull, reason: 'window exists');
    final ex = _exStyle(h!, -20);
    final r = _rect(h);
    print('lyrics window rect=$r exStyle=0x${ex.toRadixString(16)}');
    expect(_visible(h), isNot(0));
    expect(ex & _wsExTopmost, isNot(0), reason: 'always on top');
    expect(ex & _wsExLayered, isNot(0), reason: 'see-through');
    expect(ex & _wsExNoActivate, isNot(0), reason: 'never takes the focus');
    expect(ex & _wsExTransparent, 0, reason: 'not locked: can be dragged');
    expect(r[2] - r[0], greaterThan(200));
    expect(r[3] - r[1], greaterThan(40));
    expect(_foreground(), before, reason: 'showing it did not steal the focus');

    const shotFile = String.fromEnvironment('SHOT_RECT');
    if (shotFile.isNotEmpty) {
      File(shotFile).writeAsStringSync(r.join(','));
      await settle(5000);
    }

    await call('style', {'fontSize': 30.0, 'opacity': 0.0, 'locked': true});
    await settle();
    expect(_exStyle(h, -20) & _wsExTransparent, isNot(0), reason: 'locked: clicks go through');
    await call('hide');
    await settle();
    expect(_visible(h), 0);
  });

  testWidgets('a global hotkey reaches Prism', (tester) async {
    await windowManager.ensureInitialized();
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ColoredBox(color: Colors.black))));
    // Keys go to the window in front: make sure that is this test's window.
    await tester.runAsync(windowManager.focus);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
    final me = _window('FLUTTER_RUNNER_WIN32_WINDOW');
    if (_foreground() != me) {
      print('skipped: the test window is not in front, keys would go to another app');
      return;
    }
    const ch = MethodChannel('prism/hotkeys');
    final pressed = Completer<int>();
    ch.setMethodCallHandler((call) async {
      if (call.method == 'pressed' && !pressed.isCompleted) pressed.complete(call.arguments as int);
      return null;
    });
    // Ctrl + Alt + Shift + F12, id 3.
    final refused = await tester.runAsync(() => ch.invokeMethod<List<Object?>>('set', [
          {'id': 3, 'mods': 7, 'vk': 0x7B, 'repeat': false},
        ]));
    expect(refused, isEmpty, reason: 'Windows took the hotkey');
    const up = 0x2;
    for (final vk in [0x11, 0x12, 0x10, 0x7B]) {
      _keybd(vk, 0, 0, 0);
    }
    for (final vk in [0x7B, 0x10, 0x12, 0x11]) {
      _keybd(vk, 0, up, 0);
    }
    final id = await tester.runAsync(() => pressed.future.timeout(const Duration(seconds: 3)));
    expect(id, 3);
    await tester.runAsync(() => ch.invokeMethod<List<Object?>>('set', const []));
  });
}

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Remembers which animated background was being drawn, so a phone whose
/// graphics driver kills the app on it doesn't crash again at every start.
///
/// A note is written when a background starts drawing and removed once it has
/// run for a while. A note still there at the next start means Prism died while
/// drawing it: that background is switched off and the user is told which one.
/// Android only (Windows never crashed on these).
class BackgroundCrashGuard {
  BackgroundCrashGuard._();

  static File? _file;
  static Timer? _clear;

  /// What [start] found (shown once in the app).
  static String? crashed;

  /// Off in tests and on Windows.
  static bool enabled = false;

  /// The style that was drawing when Prism died last time, or null.
  static String? start(Directory supportDir, {bool enable = true}) {
    enabled = enable;
    if (!enable) return null;
    final f = File(p.join(supportDir.path, 'bg_drawing.txt'));
    _file = f;
    try {
      if (!f.existsSync()) return null;
      final style = f.readAsStringSync().trim();
      f.deleteSync();
      return crashed = style.isEmpty ? null : style;
    } on Object {
      return null;
    }
  }

  /// [style] is about to be drawn for the first time.
  static void drawing(String style) {
    final f = _file;
    if (!enabled || f == null) return;
    try {
      f.writeAsStringSync(style, flush: true);
    } on Object {
      return;
    }
    _clear?.cancel();
    // Drivers that can't take it crash on the first frames, not minutes later.
    _clear = Timer(const Duration(seconds: 6), () {
      try {
        if (f.existsSync()) f.deleteSync();
      } on Object {
        // Next start checks again.
      }
    });
  }
}

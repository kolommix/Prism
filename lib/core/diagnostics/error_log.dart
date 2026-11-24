import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'dart:ui' show ErrorCallback, PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../app_version.dart';

/// How serious an entry is.
enum ErrorLevel {
  /// Crashed code: an error nothing caught.
  crash,

  /// Something the user saw fail (a song that didn't play, an import that
  /// couldn't save, tags that didn't write).
  error,

  /// Prism's own notes about what it did (a file refused, a retry).
  note,
}

class ErrorEntry {
  ErrorEntry({required this.time, required this.level, required this.where, required this.message, this.details});

  final DateTime time;
  final ErrorLevel level;

  /// Which part of Prism (import, player, tags…).
  final String where;
  final String message;

  /// Error type, the stack and anything else that helps finding the bug.
  final String? details;

  /// Same thing again within a short while: counted, not repeated.
  int repeats = 1;

  String get text {
    final b = StringBuffer()
      ..write('[${_stamp(time)}] ${level.name.toUpperCase()} $where: $message');
    if (repeats > 1) b.write(' (x$repeats)');
    if (details != null && details!.trim().isNotEmpty) {
      b
        ..writeln()
        ..write(details!.trimRight().split('\n').map((l) => '    $l').join('\n'));
    }
    return b.toString();
  }

  static String _stamp(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}

/// Everything that went wrong, in one place friends can copy from
/// (Settings → About → Error log) and paste to the developer.
///
/// Kept on this device only: a text file in Prism's data folder
/// (`logs/prism-errors.txt`) plus the latest entries in memory. Nothing is
/// sent anywhere. The user's home folder is written as `~` so a copied report
/// doesn't carry the Windows user name.
class ErrorLog {
  ErrorLog._();

  static final ErrorLog instance = ErrorLog._();

  /// Entries kept in memory (the file keeps more).
  static const keep = 300;

  /// The file is cut back to its newer half above this size.
  static const maxFileBytes = 768 * 1024;

  /// The same message from the same place within this long counts as a repeat.
  static const repeatWindow = Duration(seconds: 20);

  final entries = ValueNotifier<List<ErrorEntry>>(const []);

  /// Fires for every new crash/error (not notes): the app shows a message.
  final _shown = StreamController<ErrorEntry>.broadcast();
  Stream<ErrorEntry> get onError => _shown.stream;

  File? _file;
  bool _hooked = false;
  FlutterExceptionHandler? _flutterOnError;
  ErrorCallback? _platformOnError;
  DebugPrintCallback? _debugPrint;
  File? get file => _file;
  Future<void> _writing = Future.value();
  final _pending = StringBuffer();
  String? _home;

  /// Starts writing to `<supportDir>/logs/prism-errors.txt` and catches every
  /// error nothing else caught (Flutter, the zone, other isolates).
  Future<void> start(Directory supportDir) async {
    final dir = Directory(p.join(supportDir.path, 'logs'));
    try {
      await dir.create(recursive: true);
      _file = File(p.join(dir.path, 'prism-errors.txt'));
    } on Object {
      _file = null;
    }
    _home = Platform.environment[Platform.isWindows ? 'USERPROFILE' : 'HOME'];
    _write('\n=== Prism $appVersion started ${ErrorEntry._stamp(DateTime.now())} · ${platformLine()} ===\n');

    if (_hooked) return;
    _hooked = true;
    final previous = _flutterOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      record(details.exception, details.stack, where: details.library ?? 'flutter', level: ErrorLevel.crash, context: details.context?.toString());
      previous?.call(details);
    };
    final previousPlatform = _platformOnError = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      record(error, stack, where: 'app', level: ErrorLevel.crash);
      return previousPlatform?.call(error, stack) ?? true;
    };
    final port = RawReceivePort((Object? pair) {
      if (pair is List && pair.length == 2) {
        record(pair[0] ?? 'unknown', StackTrace.fromString('${pair[1]}'), where: 'isolate', level: ErrorLevel.crash);
      }
    });
    Isolate.current.addErrorListener(port.sendPort);
    // Prism's own diagnostic lines ("Prism import: … refused") go in as notes.
    final original = _debugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      original(message, wrapWidth: wrapWidth);
      if (message != null && message.startsWith('Prism')) note('log', message);
    };
  }

  static String platformLine() {
    final os = Platform.isWindows ? 'Windows' : (Platform.isAndroid ? 'Android' : Platform.operatingSystem);
    return '$os ${Platform.operatingSystemVersion} · ${Platform.localeName}';
  }

  /// An error with its stack. [where] is the part of Prism (import, player…).
  ErrorEntry record(
    Object error,
    StackTrace? stack, {
    required String where,
    ErrorLevel level = ErrorLevel.error,
    String? message,
    String? context,
  }) {
    final details = StringBuffer();
    if (context != null) details.writeln(context);
    details.writeln('${error.runtimeType}: ${_firstLines('$error', 12)}');
    if (stack != null && stack != StackTrace.empty) details.writeln(_firstLines('$stack', 18));
    return _add(level, where, message ?? _firstLines('$error', 3), details.toString());
  }

  /// A failure the user was told about, without a stack.
  ErrorEntry failed(String where, String message, {String? details}) => _add(ErrorLevel.error, where, message, details);

  /// One of Prism's own notes.
  ErrorEntry note(String where, String message) => _add(ErrorLevel.note, where, message, null);

  ErrorEntry _add(ErrorLevel level, String where, String message, String? details) {
    final msg = _private(message.trim());
    final det = details == null ? null : _private(details);
    final now = DateTime.now();
    final list = entries.value;
    final last = list.isEmpty ? null : list.last;
    if (last != null && last.where == where && last.message == msg && now.difference(last.time) < repeatWindow) {
      last.repeats++;
      entries.value = List.of(list);
      return last;
    }
    final e = ErrorEntry(time: now, level: level, where: where, message: msg, details: det);
    entries.value = [...(list.length >= keep ? list.sublist(list.length - keep + 1) : list), e];
    _write('${e.text}\n');
    if (level != ErrorLevel.note && !_shown.isClosed) _shown.add(e);
    return e;
  }

  String _private(String s) {
    final home = _home;
    if (home == null || home.isEmpty) return s;
    return s.replaceAll(home, '~').replaceAll(home.replaceAll(r'\', '/'), '~');
  }

  static String _firstLines(String s, int n) {
    final lines = s.trimRight().split('\n');
    return lines.length <= n ? lines.join('\n') : '${lines.take(n).join('\n')}\n…';
  }

  void _write(String text) {
    final f = _file;
    if (f == null) return;
    _pending.write(text);
    _writing = _writing.then((_) async {
      if (_pending.isEmpty) return;
      final chunk = _pending.toString();
      _pending.clear();
      try {
        await f.writeAsString(chunk, mode: FileMode.append, flush: true);
        if (await f.length() > maxFileBytes) {
          final all = await f.readAsString();
          await f.writeAsString(all.substring(all.length ~/ 2), flush: true);
        }
      } on Object {
        // A log that can't be written must not break anything.
      }
    });
  }

  /// Waits for everything recorded so far to reach the file (tests).
  Future<void> flush() => _writing;

  /// The report friends copy: a header with the version and system, then
  /// [only] (one entry) or every entry, oldest first.
  String report({ErrorEntry? only, bool withNotes = true}) {
    final b = StringBuffer()
      ..writeln('Prism $appVersion · ${platformLine()}')
      ..writeln('---');
    final list = only != null ? [only] : [for (final e in entries.value) if (withNotes || e.level != ErrorLevel.note) e];
    if (list.isEmpty) b.writeln('(no errors)');
    for (final e in list) {
      b.writeln(e.text);
    }
    return b.toString();
  }

  /// The whole file (earlier starts too), or what's in memory without one.
  Future<String> fileText() async {
    await _writing;
    final f = _file;
    if (f == null || !await f.exists()) return report();
    try {
      return 'Prism $appVersion · ${platformLine()}\n${await f.readAsString()}';
    } on Object {
      return report();
    }
  }

  Future<void> clear() async {
    entries.value = const [];
    await _writing;
    try {
      await _file?.writeAsString('');
    } on Object {
      // Nothing to clear.
    }
  }

  @visibleForTesting
  void resetForTest() {
    if (_hooked) {
      FlutterError.onError = _flutterOnError;
      PlatformDispatcher.instance.onError = _platformOnError;
      if (_debugPrint != null) debugPrint = _debugPrint!;
      _hooked = false;
    }
    entries.value = const [];
    _file = null;
    _home = null;
  }
}

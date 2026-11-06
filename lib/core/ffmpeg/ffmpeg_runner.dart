import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:path/path.dart' as p;

/// Result of one FFmpeg run.
class FfmpegResult {
  const FfmpegResult(this.exitCode, this.log);
  final int exitCode;

  /// FFmpeg's stderr/log output (used for parsing loudness, errors).
  final String log;

  bool get ok => exitCode == 0;

  /// Last few log lines, for error messages.
  String get tail => log.trim().split('\n').reversed.take(4).toList().reversed.join('\n');
}

/// Stops a running FFmpeg job when [cancel] is called.
class FfmpegCancel {
  void Function()? _stop;
  bool _cancelled = false;
  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
    _stop?.call();
  }
}

/// Runs FFmpeg with a list of arguments (no shell, no quoting issues).
///
/// * Windows: [ProcessFfmpegRunner] – the `ffmpeg.exe` bundled next to
///   `prism.exe` (full build: rubberband, lame, AAC…).
/// * Android: [FfmpegKitRunner] – `ffmpeg_kit_flutter_new_audio`, the
///   maintained fork of the retired FFmpegKit (lame + AAC, no rubberband).
abstract class FfmpegRunner {
  String get name;

  /// Runs ffmpeg. [onProgress] receives the processed output time.
  Future<FfmpegResult> run(List<String> args, {void Function(Duration processed)? onProgress, FfmpegCancel? cancel});

  /// Names of the filters this build supports (cached).
  Future<Set<String>> filters();

  Future<bool> hasFilter(String name) async => (await filters()).contains(name);

  /// Picks the platform implementation; null when FFmpeg is unavailable.
  static FfmpegRunner? forPlatform() {
    if (Platform.isWindows) {
      final exe = ProcessFfmpegRunner.bundledExecutable();
      return exe == null ? null : ProcessFfmpegRunner(exe);
    }
    if (Platform.isAndroid) return FfmpegKitRunner();
    return null;
  }
}

final _timeRe = RegExp(r'time=(\d+):(\d+):(\d+(?:\.\d+)?)');

/// Parses `time=00:01:02.50` progress fragments from FFmpeg's log.
Duration? parseFfmpegTime(String line) {
  final m = _timeRe.allMatches(line).lastOrNull;
  if (m == null) return null;
  final h = int.parse(m.group(1)!), min = int.parse(m.group(2)!);
  final s = double.parse(m.group(3)!);
  return Duration(microseconds: ((h * 3600 + min * 60 + s) * 1e6).round());
}

Set<String> _parseFilterList(String log) => {
      for (final line in const LineSplitter().convert(log))
        if (RegExp(r'^\s*[TSC.]{2,3}\s+(\w+)\s').firstMatch(line) case final m?) m.group(1)!,
    };

/// Windows: runs an `ffmpeg.exe` process.
class ProcessFfmpegRunner extends FfmpegRunner {
  ProcessFfmpegRunner(this.executable);

  final String executable;
  Set<String>? _filters;

  @override
  String get name => 'ffmpeg.exe';

  /// `ffmpeg.exe` next to the running app (or PRISM_FFMPEG for tests/dev).
  static String? bundledExecutable() {
    final env = Platform.environment['PRISM_FFMPEG'];
    if (env != null && File(env).existsSync()) return env;
    final candidates = [
      p.join(File(Platform.resolvedExecutable).parent.path, 'ffmpeg.exe'),
      p.join(Directory.current.path, 'windows', 'third_party', 'ffmpeg', 'ffmpeg.exe'),
    ];
    return candidates.where((c) => File(c).existsSync()).firstOrNull;
  }

  @override
  Future<FfmpegResult> run(List<String> args, {void Function(Duration processed)? onProgress, FfmpegCancel? cancel}) async {
    final proc = await Process.start(executable, ['-hide_banner', '-nostdin', ...args]);
    cancel?._stop = () => proc.kill();
    if (cancel?.isCancelled ?? false) proc.kill();
    final log = StringBuffer();
    final errDone = proc.stderr.transform(const Utf8Decoder(allowMalformed: true)).listen((chunk) {
      log.write(chunk);
      if (onProgress != null) {
        final t = parseFfmpegTime(chunk);
        if (t != null) onProgress(t);
      }
    }).asFuture<void>();
    await proc.stdout.drain<void>();
    final code = await proc.exitCode;
    await errDone;
    return FfmpegResult(code, log.toString());
  }

  @override
  Future<Set<String>> filters() async {
    if (_filters != null) return _filters!;
    final proc = await Process.run(executable, ['-hide_banner', '-filters']);
    return _filters = _parseFilterList('${proc.stdout}');
  }
}

/// Android: FFmpegKit (in-process library).
class FfmpegKitRunner extends FfmpegRunner {
  Set<String>? _filters;

  @override
  String get name => 'FFmpegKit';

  @override
  Future<FfmpegResult> run(List<String> args, {void Function(Duration processed)? onProgress, FfmpegCancel? cancel}) async {
    final done = Completer<FfmpegResult>();
    final session = await FFmpegKit.executeWithArgumentsAsync(
      ['-hide_banner', ...args],
      (session) async {
        final rc = await session.getReturnCode();
        final log = await session.getAllLogsAsString() ?? '';
        done.complete(FfmpegResult(ReturnCode.isSuccess(rc) ? 0 : (rc?.getValue() ?? -1), log));
      },
      null,
      onProgress == null ? null : (stats) => onProgress(Duration(milliseconds: stats.getTime().round())),
    );
    final id = session.getSessionId();
    cancel?._stop = () => FFmpegKit.cancel(id);
    if (cancel?.isCancelled ?? false) await FFmpegKit.cancel(id);
    return done.future;
  }

  @override
  Future<Set<String>> filters() async {
    if (_filters != null) return _filters!;
    final session = await FFmpegKit.executeWithArguments(['-hide_banner', '-filters']);
    return _filters = _parseFilterList(await session.getAllLogsAsString() ?? '');
  }
}

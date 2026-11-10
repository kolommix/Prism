import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ffmpeg/ffmpeg_runner.dart';

/// What a saved song really holds.
class SavedAudio {
  const SavedAudio({required this.ok, this.durationMs = 0, this.reason});

  final bool ok;

  /// Length FFmpeg could decode (0 = not measured).
  final int durationMs;

  /// Why it was refused, for the log and tests.
  final String? reason;
}

/// Checks a downloaded song before it goes into the library.
///
/// Friends got "empty" songs: files of the right size that held only the
/// first megabyte of audio and zeros after it (YouTube stops serving a file
/// part way, and an old reader wrote the missing pieces as holes), or files
/// that were cut off. Such a file shows the full length in the library and
/// plays a few seconds of sound, or none. Two checks:
///
/// 1. no long run of zero bytes (compressed audio never has one), pure Dart,
///    works everywhere;
/// 2. FFmpeg decodes the whole file: the decoded length must be close to the
///    length the service gave, and the decoder must not stumble all the way.
class ImportFileCheck {
  const ImportFileCheck({this.ffmpeg});

  final FfmpegRunner? ffmpeg;

  /// Smallest real song file.
  static const minBytes = 16 * 1024;

  /// A run of zeros this long means a hole.
  static const zeroRun = 64 * 1024;

  /// Tags at the start may carry zero padding; holes come after the first
  /// piece anyway (that one was always served).
  static const skipStart = 256 * 1024;

  /// Decoder errors tolerated (a glitch here and there is fine).
  static const maxDecodeErrors = 12;

  Future<SavedAudio> check(File file, {int expectedMs = 0}) async {
    final int size;
    try {
      size = await file.length();
    } on FileSystemException {
      return const SavedAudio(ok: false, reason: 'missing');
    }
    if (size < minBytes) return SavedAudio(ok: false, reason: 'tiny ($size bytes)');
    final path = file.path;
    // Off the UI isolate: a few million bytes to look at.
    if (await Isolate.run(() => hasZeroHole(File(path)))) return const SavedAudio(ok: false, reason: 'zero hole');
    final runner = ffmpeg;
    if (runner == null) return const SavedAudio(ok: true);
    return decodeCheck(runner, file, expectedMs: expectedMs);
  }

  /// True when the file has [zeroRun] zero bytes in a row after [skipStart].
  static Future<bool> hasZeroHole(File file) async {
    var run = 0;
    final size = await file.length();
    await for (final chunk in file.openRead(size > skipStart * 2 ? skipStart : 0)) {
      final bytes = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
      for (var i = 0; i < bytes.length; i++) {
        if (bytes[i] == 0) {
          if (++run >= zeroRun) return true;
        } else {
          run = 0;
        }
      }
    }
    return false;
  }

  static Future<SavedAudio> decodeCheck(FfmpegRunner runner, File file, {int expectedMs = 0}) async {
    var decoded = Duration.zero;
    final r = await runner.run(
      ['-v', 'error', '-stats', '-i', file.path, '-map', '0:a:0', '-f', 'null', '-'],
      onProgress: (t) {
        if (t > decoded) decoded = t;
      },
    );
    final fromLog = parseFfmpegTime(r.log);
    if (fromLog != null && fromLog > decoded) decoded = fromLog;
    final ms = decoded.inMilliseconds;
    if (!r.ok && ms == 0) return SavedAudio(ok: false, reason: 'ffmpeg ${r.exitCode}: ${r.tail}');
    if (ms < 1000) return const SavedAudio(ok: false, reason: 'no sound');
    final errors = decodeErrors(r.log);
    if (errors > maxDecodeErrors) return SavedAudio(ok: false, durationMs: ms, reason: '$errors decode errors');
    if (!lengthFits(ms, expectedMs)) return SavedAudio(ok: false, durationMs: ms, reason: 'cut off at ${ms}ms of ${expectedMs}ms');
    return SavedAudio(ok: true, durationMs: ms);
  }

  /// The decoded length is close enough to what the service said.
  static bool lengthFits(int decodedMs, int expectedMs) {
    if (expectedMs <= 0) return true;
    return decodedMs >= expectedMs * 0.9 || expectedMs - decodedMs <= 5000;
  }

  /// Error lines in FFmpeg's `-v error` output (progress lines aside).
  static int decodeErrors(String log) => [
        for (final line in log.split(RegExp(r'[\r\n]+')))
          if (line.trim().isNotEmpty && !line.contains('time=') && !line.startsWith('size=')) line,
      ].length;
}

final importFileCheckProvider = Provider<ImportFileCheck>((ref) => ImportFileCheck(ffmpeg: FfmpegRunner.forPlatform()));

@Tags(['audio'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/ffmpeg/ffmpeg_runner.dart';
import 'package:prism/features/online/application/import_file_check.dart';

/// The saved-song check against real files made by the bundled ffmpeg.exe:
/// a whole song passes with its real length, a cut-off one and one with a
/// hole of zeros (what friends got) are refused.
/// Run: flutter test --tags audio test/platform/import_file_check_audio_test.dart
void main() {
  final exe = p.absolute('windows/third_party/ffmpeg/ffmpeg.exe');
  final skip = File(exe).existsSync() ? null : 'needs windows/third_party/ffmpeg/ffmpeg.exe';
  final ff = ProcessFfmpegRunner(exe);
  late Directory dir;
  late File song;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('prism_check_');
    song = File(p.join(dir.path, 'song.m4a'));
    // 3 minutes of music-like noise as AAC, like a YouTube m4a.
    final r = await ff.run([
      '-f', 'lavfi', '-i', 'anoisesrc=d=180:c=pink:r=44100:a=0.3',
      '-c:a', 'aac', '-b:a', '128k', '-y', song.path,
    ]);
    expect(r.ok, isTrue, reason: r.tail);
  });
  tearDownAll(() => dir.delete(recursive: true));

  test('a whole song passes and its real length is measured', () async {
    final r = await ImportFileCheck(ffmpeg: ff).check(song, expectedMs: 180000);
    expect(r.ok, isTrue, reason: r.reason);
    expect(r.durationMs, closeTo(180000, 1500));
  }, skip: skip);

  test('a song cut off after the first megabyte is refused', () async {
    final bytes = await song.readAsBytes();
    final cut = File(p.join(dir.path, 'cut.m4a'))..writeAsBytesSync(bytes.sublist(0, 1024 * 1024));
    final r = await ImportFileCheck(ffmpeg: ff).check(cut, expectedMs: 180000);
    expect(r.ok, isFalse);
  }, skip: skip);

  test('a song with a hole of zeros is refused', () async {
    final bytes = Uint8List.fromList(await song.readAsBytes());
    bytes.fillRange(1024 * 1024, 1024 * 1024 + 512 * 1024, 0);
    final holey = File(p.join(dir.path, 'holey.m4a'))..writeAsBytesSync(bytes);
    final r = await ImportFileCheck(ffmpeg: ff).check(holey, expectedMs: 180000);
    expect(r.ok, isFalse);
    // Even without the zero scan, the decoder notices.
    final decoded = await ImportFileCheck.decodeCheck(ff, holey, expectedMs: 180000);
    expect(decoded.ok, isFalse, reason: 'decoded ${decoded.durationMs} ms, ${decoded.reason}');
  }, skip: skip);
}

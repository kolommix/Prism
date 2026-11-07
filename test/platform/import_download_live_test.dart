@Tags(['audio', 'network'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/online/services/youtube/explode_backend.dart';

/// Really saves one song the way an import does, and has FFmpeg read it back.
///
/// Run: flutter test --tags network test/platform/import_download_live_test.dart
void main() {
  test('a real YouTube song saves as a playable file', () async {
    final dir = await Directory.systemTemp.createTemp('prism_live_dl_');
    addTearDown(() => dir.delete(recursive: true));
    final backend = ExplodeBackend();
    addTearDown(backend.close);
    final base = '${dir.path}${Platform.pathSeparator}song';
    final sw = Stopwatch()..start();
    final ext = await backend.download('dQw4w9WgXcQ', base);
    final file = File('$base.$ext');
    // ignore: avoid_print
    print('saved .$ext, ${file.lengthSync() ~/ 1024} KB in ${sw.elapsed.inSeconds} s');
    expect(file.lengthSync(), greaterThan(500 * 1024));
    final ffmpeg = r'windows\third_party\ffmpeg\ffmpeg.exe';
    final probe = await Process.run(ffmpeg, ['-hide_banner', '-i', file.path]);
    final info = '${probe.stderr}';
    final duration = RegExp(r'Duration: (\d+):(\d+):(\d+)').firstMatch(info);
    // ignore: avoid_print
    print('ffmpeg: ${duration?[0]}, ${RegExp(r'Audio: [^\n]*').firstMatch(info)?[0]}');
    expect(duration, isNotNull);
    expect(int.parse(duration![2]!) * 60 + int.parse(duration[3]!), greaterThan(200), reason: 'the whole song');
  }, timeout: const Timeout(Duration(minutes: 3)));
}

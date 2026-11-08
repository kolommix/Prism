@Tags(['audio', 'network'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/online/domain/online_error.dart';
import 'package:prism/features/online/services/youtube/explode_backend.dart';
import 'package:prism/features/online/services/youtube/ytdlp.dart';

/// Really saves songs the way an import does on Windows (yt-dlp first), and has
/// FFmpeg read them back. The last three are uploads YouTube refuses to
/// Prism's own reader (they left 0-byte `.part` files before).
///
/// Run: flutter test --tags network test/platform/import_download_live_test.dart
void main() {
  const ffmpeg = r'windows\third_party\ffmpeg\ffmpeg.exe';
  for (final id in ['dQw4w9WgXcQ', 'jbZT-bwZD3c', 'N9ZjkSrsZRA', 'fFflOUZxDxs']) {
    test('YouTube $id saves as a whole, playable file', () async {
      final dir = await Directory.systemTemp.createTemp('prism_live_dl_');
      addTearDown(() => dir.delete(recursive: true));
      final backend = ExplodeBackend(saver: YtDlp(toolsDir: Directory('${dir.path}/tools'), ffmpeg: ffmpeg));
      addTearDown(backend.close);
      final base = '${dir.path}${Platform.pathSeparator}song';
      final sw = Stopwatch()..start();
      final String ext;
      try {
        ext = await backend.download(id, base);
      } on OnlineException catch (e) {
        // ignore: avoid_print
        print('$id: ${e.kind} ${e.message} after ${sw.elapsed.inSeconds} s');
        rethrow;
      }
      final file = File('$base.$ext');
      // ignore: avoid_print
      print('$id saved .$ext, ${file.lengthSync() ~/ 1024} KB in ${sw.elapsedMilliseconds} ms');
      final probe = await Process.run(ffmpeg, ['-hide_banner', '-v', 'error', '-i', file.path, '-f', 'null', '-']);
      expect('${probe.stderr}'.trim(), isEmpty, reason: 'decodes to the end without errors');
      final info = '${(await Process.run(ffmpeg, ['-hide_banner', '-i', file.path])).stderr}';
      final d = RegExp(r'Duration: (\d+):(\d+):(\d+)').firstMatch(info)!;
      expect(int.parse(d[2]!) * 60 + int.parse(d[3]!), greaterThan(100), reason: 'the whole song');
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
}

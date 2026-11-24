@Tags(['network'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/ffmpeg/dash_fix.dart';
import 'package:prism/core/ffmpeg/ffmpeg_runner.dart';
import 'package:prism/features/library/data/audio_metadata_tag_reader.dart';
import 'package:prism/features/online/application/import_file_check.dart';
import 'package:prism/features/online/services/youtube/explode_backend.dart';
import 'package:prism/features/online/services/youtube/innertube_audio.dart';
import 'package:prism/features/tools/data/tag_writer.dart';

/// Music uploads YouTube refuses the Android/web clients (the first megabyte,
/// then 403) since late 2026. The visionOS client gets them whole: streaming
/// and saving work again, also on Android (no yt-dlp there).
void main() {
  const ids = ['46JG3ZpRaRc', 'HoEqOZhKazw', 'Uu3dshFseaU'];

  test('visionOS gives whole audio links for music uploads', () async {
    final tube = InnertubeAudio();
    addTearDown(tube.close);
    for (final id in ids) {
      final formats = await tube.audioFormats(id);
      expect(formats, isNotEmpty, reason: id);
      expect(formats.first.container, 'mp4');
      expect(formats.first.length, greaterThan(500000));
    }
  });

  test('the own reader streams and saves them whole, tags can be written', () async {
    final yt = ExplodeBackend(); // no yt-dlp: the Android way
    addTearDown(yt.close);
    final dir = await Directory.systemTemp.createTemp('prism_vos');
    addTearDown(() => dir.delete(recursive: true));
    final ffmpeg = FfmpegRunner.forPlatform();
    for (final id in ids.take(2)) {
      final s = await yt.audioStream(id);
      expect(s.length, greaterThan(500000));
      final base = p.join(dir.path, 'song [$id]');
      final sw = Stopwatch()..start();
      final ext = await yt.download(id, base);
      final file = File('$base.$ext');
      // ignore: avoid_print
      print('$id saved as .$ext, ${await file.length()} bytes in ${sw.elapsedMilliseconds} ms');
      expect(await file.length(), s.length);
      expect(await fixDashM4a(file, ffmpeg), ffmpeg != null);
      final check = await ImportFileCheck(ffmpeg: ffmpeg).check(file);
      expect(check.ok, isTrue, reason: check.reason);
      expect(await TagWriter.tagNewFile(file.path, const TagEdit(title: 'Song', artist: 'Artist', album: 'Album')), isTrue);
      final tags = await AudioMetadataTagReader().read(file.path);
      expect(tags.title, 'Song');
      expect(tags.artist, 'Artist');
      expect(tags.duration!.inSeconds, greaterThan(100));
    }
  });
}

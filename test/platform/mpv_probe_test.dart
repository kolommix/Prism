@Tags(['audio'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;

import '../support/wav.dart';

/// Probe: which FFmpeg audio filters does the shipped libmpv accept?
/// Run with: flutter test --tags audio test/platform/mpv_probe_test.dart
void main() {
  final dll = p.absolute('windows/third_party/libmpv/libmpv-2.dll');
  final skip = !Platform.isWindows || !File(dll).existsSync() ? 'needs a Windows build first' : null;

  test('probe lavfi filters', () async {
    MediaKit.ensureInitialized(libmpv: dll);
    final dir = await Directory.systemTemp.createTemp('prism_probe_');
    final input = p.join(dir.path, 'in.wav');
    writeWav(input, tones([100, 1000, 8000], seconds: 2));
    const probeFreqs = [100.0, 1000.0, 1250.0, 8000.0];

    Future<String> render(String af) async {
      final out = p.join(dir.path, 'out_${af.hashCode}.wav');
      final player = Player(configuration: const PlayerConfiguration(logLevel: MPVLogLevel.v));
      final finished = Completer<void>();
      final logs = <String>[];
      final sub = player.stream.log.listen((l) {
        logs.add('${l.prefix}: ${l.text.trim()}');
        // media_kit uses keep-open, so EOF is signalled by the AO, not "finished playback".
        final end = l.text.contains('AO signaled EOF') || l.text.contains('finished playback');
        if (end && !finished.isCompleted) finished.complete();
      });
      final native = player.platform as NativePlayer;
      await native.setProperty('ao', 'pcm');
      await native.setProperty('ao-pcm-file', out);
      if (af.isNotEmpty) await native.setProperty('af', af);
      final done = finished.future.timeout(const Duration(seconds: 20));
      await player.open(Media(input));
      await done;
      await sub.cancel();
      await player.dispose();
      final level = File(out).existsSync()
          ? probeFreqs.map((f) => toneDb(readWav(out), f).toStringAsFixed(1)).join(' / ')
          : 'no output';
      final detail = logs.where((l) => l.startsWith('lavfi') || l.startsWith('ffmpeg') || l.startsWith('af:'));
      return '$af => $level\n    ${detail.take(12).join('\n    ')}';
    }

    final results = [
      await render(''),
      await render('lavfi=[equalizer=f=100:t=q:w=1.4:g=12,equalizer=f=8000:t=q:w=1.4:g=-12]'),
      await render('lavfi=[bass=g=10:f=100]'),
      await render('lavfi=[volume=volume=-6dB]'),
      await render('rubberband=pitch-scale=1.25'),
      await render('lavfi=[rubberband=pitch=1.25]'),
    ];
    for (final r in results) {
      // ignore: avoid_print
      print(r);
    }
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}

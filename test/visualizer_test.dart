import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/ffmpeg/ffmpeg_runner.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/visualizer/data/spectrum_service.dart';
import 'package:prism/features/visualizer/domain/spectrum.dart';

import 'support/wav.dart';

/// 16-bit PCM of a sine that switches from [f1] to [f2] halfway.
Uint8List twoTones(double f1, double f2, {double seconds = 2, int rate = 22050}) {
  final n = (seconds * rate).round();
  final b = ByteData(n * 2);
  for (var i = 0; i < n; i++) {
    final f = i < n / 2 ? f1 : f2;
    b.setInt16(i * 2, (math.sin(2 * math.pi * f * i / rate) * 0.5 * 32767).round(), Endian.little);
  }
  return b.buffer.asUint8List();
}

int loudestBand(Spectrum s, Duration t) {
  final v = Float32List(s.bands);
  s.sample(t, v);
  var best = 0;
  for (var i = 1; i < v.length; i++) {
    if (v[i] > v[best]) best = i;
  }
  return best;
}

/// Band index (log scale 40 Hz…16 kHz or Nyquist) that contains [hz].
int bandOf(double hz, {int bands = 64, double nyquist = 11025}) =>
    (math.log(hz / 40) / math.log(nyquist / 40) * bands).floor();

void main() {
  test('FFT finds a pure sine in the right bin', () {
    const n = 1024;
    final re = Float64List.fromList(List.generate(n, (i) => math.cos(2 * math.pi * 64 * i / n)));
    final im = Float64List(n);
    fft(re, im);
    final mags = List.generate(n ~/ 2, (k) => math.sqrt(re[k] * re[k] + im[k] * im[k]));
    expect(mags.indexOf(mags.reduce(math.max)), 64);
    expect(mags[64], closeTo(n / 2, 1e-6));
  });

  test('spectrum follows the music over time', () {
    final s = SpectrumService.analyze(twoTones(200, 3000));
    expect(s.fps, 30);
    expect(s.frames, closeTo(60, 1));
    expect(loudestBand(s, const Duration(milliseconds: 400)), closeTo(bandOf(200), 1));
    expect(loudestBand(s, const Duration(milliseconds: 1600)), closeTo(bandOf(3000), 1));
  });

  test('a quiet high sound still moves its band fully (levelled per band)', () {
    // Loud 100 Hz all the time; a 6 kHz tone 30 dB quieter in the second half.
    const rate = 22050, n = rate * 4;
    final b = ByteData(n * 2);
    for (var i = 0; i < n; i++) {
      var v = math.sin(2 * math.pi * 100 * i / rate) * 0.5;
      if (i > n / 2) v += math.sin(2 * math.pi * 6000 * i / rate) * 0.5 * 0.0316;
      b.setInt16(i * 2, (v * 32767).round(), Endian.little);
    }
    final s = SpectrumService.analyze(b.buffer.asUint8List());
    final v = Float32List(s.bands);
    s.sample(const Duration(milliseconds: 3000), v);
    final high = v[bandOf(6000)];
    final bass = v[bandOf(100)];
    s.sample(const Duration(milliseconds: 1000), v);
    expect(high, greaterThan(0.6), reason: 'the quiet tone reaches near the top of its band');
    expect(v[bandOf(6000)], lessThan(0.15), reason: 'and is low when it is not there');
    expect(bass, greaterThan(0.6));
  });

  test('silence is all zeros, encode/decode round trip', () {
    final s = SpectrumService.analyze(Uint8List(22050 * 2));
    expect(s.data.every((v) => v == 0), isTrue);
    final back = Spectrum.decode(s.encode())!;
    expect((back.bands, back.fps), (s.bands, s.fps));
    expect(back.data, orderedEquals(s.data));
    expect(Spectrum.decode(Uint8List.fromList([1, 2, 3])), isNull);
  });

  test('real decode through ffmpeg.exe + cache', () async {
    final exe = p.absolute('windows/third_party/ffmpeg/ffmpeg.exe');
    final dir = await Directory.systemTemp.createTemp('prism_viz_');
    try {
      final wav = p.join(dir.path, 'a.wav');
      writeWav(wav, tones([440], seconds: 3, sampleRate: 44100));
      final service = SpectrumService(ffmpeg: ProcessFfmpegRunner(exe), cacheDir: Directory(p.join(dir.path, 'cache')));
      final t = Track(id: 1, uri: wav, title: 'a');
      final s = await service.spectrumFor(t);
      expect(s!.frames, closeTo(90, 2));
      expect(loudestBand(s, const Duration(seconds: 1)), closeTo(bandOf(440), 1));
      final sw = Stopwatch()..start();
      await service.spectrumFor(t); // cached
      expect(sw.elapsedMilliseconds, lessThan(200));
    } finally {
      await dir.delete(recursive: true);
    }
  }, tags: ['audio'], skip: File('windows/third_party/ffmpeg/ffmpeg.exe').existsSync() ? null : 'needs ffmpeg.exe');
}

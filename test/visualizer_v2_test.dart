import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/visualizer/domain/beat_detector.dart';

void main() {
  group('beats', () {
    test('a steady kick is found at its tempo, at any frame rate', () {
      for (final fps in [30, 60, 120]) {
        final d = BeatDetector();
        final dt = 1 / fps;
        var found = 0;
        const bpm = 120, seconds = 10;
        for (var f = 0; f < seconds * fps; f++) {
          final t = f * dt;
          final inBeat = (t * bpm / 60) % 1;
          final bass = inBeat < 0.1 ? 0.9 : 0.2;
          if (d.update(bass, dt)) found++;
        }
        expect(found, inInclusiveRange(17, 21), reason: 'at $fps fps');
      }
    });

    test('a constant level has no beats', () {
      final d = BeatDetector();
      var found = 0;
      for (var f = 0; f < 600; f++) {
        if (f > 60 && d.update(0.6, 1 / 60)) found++;
        if (f <= 60) d.update(0.6, 1 / 60);
      }
      expect(found, 0);
    });

    test('silence has no beats', () {
      final d = BeatDetector();
      for (var f = 0; f < 600; f++) {
        expect(d.update(0, 1 / 60), isFalse);
      }
    });

    test('the pulse fades by time, not by frames', () {
      double after(int fps) {
        final d = BeatDetector()..pulse = 1;
        for (var f = 0; f < fps; f++) {
          d.update(0, 1 / fps);
        }
        return d.pulse;
      }

      expect(after(60), closeTo(after(120), 1e-6));
      expect(after(60), lessThan(0.05));
    });
  });

  group('levels', () {
    test('up fast, down slow, same at any frame rate', () {
      double run(int fps, double seconds, double from, double to) {
        final level = Float32List(1)..[0] = from;
        final target = Float32List(1)..[0] = to;
        for (var f = 0; f < seconds * fps; f++) {
          smoothLevels(level, target, 1 / fps);
        }
        return level[0];
      }

      expect(run(60, 0.05, 0, 1), greaterThan(0.9));
      expect(run(60, 0.05, 1, 0), greaterThan(0.6));
      expect(run(60, 0.5, 1, 0), closeTo(run(120, 0.5, 1, 0), 0.02));
    });

    test('sensitivity scales and stays in range', () {
      expect(applySensitivity(0.4, 2), closeTo(0.8, 1e-9));
      expect(applySensitivity(0.8, 2), 1);
      expect(applySensitivity(0.4, 0.5), closeTo(0.2, 1e-9));
    });
  });

  group('Android FFT bytes to bands', () {
    Int8List fftWithBin(int bins, int bin, int amplitude) {
      final b = Int8List(bins * 2);
      b[bin * 2] = amplitude;
      return b;
    }

    test('energy lands in the band of its frequency', () {
      final bands = Float32List(24);
      const hz = 44100, bins = 512;
      // Bin 12 is about 516 Hz.
      bandsFromAndroidFft(fftWithBin(bins, 12, 100), hz, bands);
      final loudest = bands.indexOf(bands.reduce(math.max));
      final expected = (math.log(516 / 40) / math.log((hz / 2) / 40) * 24).floor();
      expect((loudest - expected).abs(), lessThanOrEqualTo(1));
      expect(bands[loudest], greaterThan(0.8));
      expect(bands.last, lessThan(0.05));
    });

    test('silence is all zero', () {
      final bands = Float32List(24);
      bandsFromAndroidFft(Int8List(1024), 44100, bands);
      expect(bands.every((v) => v == 0), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/lyrics/presentation/lyrics_view.dart';
import 'package:prism/features/player/domain/playhead_estimator.dart';

void main() {
  group('playhead', () {
    const s = 1000000;

    test('moves at the song speed between reports', () {
      final e = PlayheadEstimator()..report(10.0 * s, playing: true, speed: 1, nowUs: 0);
      expect(e.at(s), closeTo(11.0 * s, 1));
      final fast = PlayheadEstimator()..report(10.0 * s, playing: true, speed: 2, nowUs: 0);
      expect(fast.at(s), closeTo(12.0 * s, 1));
    });

    test('never runs backwards on noisy reports, at 120 fps', () {
      final e = PlayheadEstimator()..report(0, playing: true, speed: 1, nowUs: 0);
      var last = -1.0;
      var next = 250000;
      // Reports every 250 ms, each off by up to 60 ms.
      final noise = [40000, -60000, 20000, -30000, 60000, -50000];
      var n = 0;
      for (var now = 0; now < 5 * s; now += 8333) {
        if (now >= next) {
          e.report((now + noise[n++ % noise.length]).toDouble(), playing: true, speed: 1, nowUs: now);
          next += 250000;
        }
        final p = e.at(now);
        expect(p, greaterThanOrEqualTo(last), reason: 'at $now');
        last = p;
      }
      // And it stays close to the true time.
      expect((last - 5 * s).abs(), lessThan(80000));
    });

    test('per-frame steps stay even', () {
      final e = PlayheadEstimator()..report(0, playing: true, speed: 1, nowUs: 0);
      var last = 0.0;
      for (var now = 8333; now < 2 * s; now += 8333) {
        if (now % 250000 < 8333) e.report(now + 50000.0, playing: true, speed: 1, nowUs: now);
        final p = e.at(now);
        expect(p - last, inInclusiveRange(0, 8333 * 1.6), reason: 'at $now');
        last = p;
      }
    });

    test('a seek is taken at once, also backwards', () {
      final e = PlayheadEstimator()..report(60.0 * s, playing: true, speed: 1, nowUs: 0);
      e.report(10.0 * s, playing: true, speed: 1, nowUs: s);
      expect(e.at(s), 10.0 * s);
    });

    test('holds still while paused', () {
      final e = PlayheadEstimator()..report(5.0 * s, playing: false, speed: 1, nowUs: 0);
      expect(e.at(9 * s), 5.0 * s);
    });

    test('resuming starts from the report', () {
      final e = PlayheadEstimator()
        ..report(5.0 * s, playing: false, speed: 1, nowUs: 0)
        ..report(5.0 * s, playing: true, speed: 1, nowUs: 9 * s);
      expect(e.at(10 * s), closeTo(6.0 * s, 1));
    });
  });

  group('scroll spring', () {
    (double, double) run(double x, double target, double dt, int steps) {
      var v = 0.0;
      for (var i = 0; i < steps; i++) {
        final n = stepSpring(x, v, target, dt);
        x = n.$1;
        v = n.$2;
      }
      return (x, v);
    }

    test('arrives without overshoot', () {
      var x = 0.0, v = 0.0;
      for (var i = 0; i < 240; i++) {
        final n = stepSpring(x, v, 1000, 1 / 120);
        x = n.$1;
        v = n.$2;
        expect(x, lessThanOrEqualTo(1000.001));
      }
      expect(x, closeTo(1000, 1));
    });

    test('same motion at 60 and 120 fps', () {
      final a = run(0, 1000, 1 / 60, 30);
      final b = run(0, 1000, 1 / 120, 60);
      expect(a.$1, closeTo(b.$1, 1));
    });
  });
}

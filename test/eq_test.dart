import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/audio_fx/domain/eq_math.dart';
import 'package:prism/features/audio_fx/domain/eq_settings.dart';
import 'package:prism/features/audio_fx/platform/android_audio_effects.dart';
import 'package:prism/features/audio_fx/platform/mpv_audio_effects.dart';

void main() {
  group('biquad response', () {
    test('peaking filter hits its gain at the centre and is ~flat far away', () {
      final f = Biquad.peaking(freq: 1000, gainDb: 9, q: eqBandQ, sampleRate: 48000);
      expect(f.magnitudeDb(1000, 48000), closeTo(9, 0.01));
      expect(f.magnitudeDb(20, 48000), closeTo(0, 0.1));
      expect(f.magnitudeDb(18000, 48000), closeTo(0, 0.2));
    });

    test('low shelf boosts lows and leaves highs alone', () {
      final f = Biquad.lowShelf(freq: 100, gainDb: 10, q: bassShelfQ, sampleRate: 48000);
      expect(f.magnitudeDb(20, 48000), closeTo(10, 0.5));
      expect(f.magnitudeDb(5000, 48000), closeTo(0, 0.1));
    });

    test('flat or disabled EQ is exactly 0 dB everywhere', () {
      for (final hz in logFrequencies(30)) {
        expect(eqResponseDb(const EqSettings(enabled: true), hz), 0);
        expect(eqResponseDb(EqSettings(gainsDb: List.filled(10, 6)), hz), 0, reason: 'disabled');
      }
    });

    test('preamp shifts the whole curve', () {
      const eq = EqSettings(enabled: true, preampDb: -4);
      expect(eqResponseDb(eq, 1000), closeTo(-4, 1e-9));
      expect(eqResponseDb(eq, 1000, includePreamp: false), 0);
    });

    test('semitones and dB helpers', () {
      expect(semitonesToRatio(12), closeTo(2, 1e-12));
      expect(semitonesToRatio(-12), closeTo(0.5, 1e-12));
      expect(dbToLinear(-6.0206), closeTo(0.5, 1e-4));
    });
  });

  group('settings', () {
    test('sanitize clamps and pads to 10 bands', () {
      final s = const EqSettings(gainsDb: [40, -40], preampDb: 99, bassBoost: 3).sanitized();
      expect(s.gainsDb.length, 10);
      expect(s.gainsDb.take(2), [eqMaxGainDb, -eqMaxGainDb]);
      expect(s.preampDb, eqMaxPreampDb);
      expect(s.bassBoost, 1);
    });

    test('built-in presets have 10 bands within range', () {
      for (final p in builtInEqPresets) {
        expect(p.gainsDb.length, 10, reason: p.name);
        expect(p.gainsDb.every((g) => g.abs() <= eqMaxGainDb), isTrue, reason: p.name);
      }
    });

    test('JSON round trip', () {
      final s = const EqSettings(enabled: true, preampDb: -3, bassBoost: 0.4).withBand(3, 5.5);
      expect(EqSettings.fromJson(s.toJson()), s);
      expect(s.presetName, 'Custom');
    });
  });

  group('Windows mpv filter chain', () {
    test('neutral settings produce no filter at all', () {
      expect(buildMpvAudioFilter(const EqSettings()), '');
      expect(buildMpvAudioFilter(const EqSettings(enabled: true)), '');
    });

    test('only non-zero bands are emitted, with the shared Q', () {
      final eq = const EqSettings(enabled: true).withBand(0, 3).withBand(9, -4);
      final af = buildMpvAudioFilter(eq);
      expect(af, startsWith('@fx:lavfi=['));
      expect('equalizer='.allMatches(af).length, 2);
      expect(af, contains('equalizer=f=31.00:t=q:w=1.41:g=3.00'));
      expect(af, contains('equalizer=f=16000.00:t=q:w=1.41:g=-4.00'));
      expect(af, contains('alimiter'), reason: 'boost present → limiter');
    });

    test('cuts only → no limiter; bass boost adds a shelf', () {
      final cuts = const EqSettings(enabled: true).withBand(4, -6);
      expect(buildMpvAudioFilter(cuts), isNot(contains('alimiter')));
      final bass = const EqSettings(enabled: true, bassBoost: 0.5);
      expect(buildMpvAudioFilter(bass), contains('bass=g=6.00:f=100.00:t=q:w=0.707'));
    });

    test('pitch comes first in the same graph (resample + atempo, not rubberband)', () {
      final af = buildMpvAudioFilter(const EqSettings(enabled: true).withBand(2, 2), pitchRatio: 2);
      expect(af, startsWith('@fx:lavfi=[aresample=48000,asetrate=96000,aresample=48000,atempo=0.5,equalizer='));
      expect(af, isNot(contains('rubberband')));
      expect(buildMpvAudioFilter(const EqSettings(), pitchRatio: 1), '');
    });
  });

  group('Android band mapping', () {
    // Typical 5-band phone equalizer.
    const info = AndroidEqInfo(centerFreqsHz: [60, 230, 910, 3600, 14000], minMb: -1500, maxMb: 1500);

    test('curve is sampled at the native centres (millibels)', () {
      final eq = const EqSettings(enabled: true).withBand(1, 6); // 62 Hz band
      final mb = mapEqToNativeBands(eq, info);
      expect(mb.length, 5);
      expect(mb[0], closeTo(600, 40)); // 60 Hz ≈ the 62 Hz band
      expect(mb[4], 0);
    });

    test('values are clamped to the device range', () {
      final eq = EqSettings(enabled: true, gainsDb: List.filled(10, 12));
      // Overlapping +12 dB bands sum above 15 dB in places.
      for (final v in mapEqToNativeBands(eq, info)) {
        expect(v, inInclusiveRange(-1500, 1500));
      }
    });
  });
}

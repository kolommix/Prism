import 'dart:math' as math;

import 'eq_settings.dart';

/// Biquad math shared by the UI curve, the Windows filter chain and the
/// Android band mapping.
///
/// Filters are the classic RBJ "Audio EQ Cookbook" designs – exactly what
/// FFmpeg's `equalizer` (peaking, width type q) and `bass` (low shelf)
/// filters implement, so the drawn curve matches the processed audio.

/// Normalised biquad coefficients (a0 = 1).
class Biquad {
  const Biquad(this.b0, this.b1, this.b2, this.a1, this.a2);

  final double b0, b1, b2, a1, a2;

  /// RBJ peaking EQ.
  factory Biquad.peaking({required double freq, required double gainDb, required double q, required double sampleRate}) {
    final a = math.pow(10, gainDb / 40).toDouble();
    final w0 = 2 * math.pi * freq / sampleRate;
    final alpha = math.sin(w0) / (2 * q);
    final cosw = math.cos(w0);
    final a0 = 1 + alpha / a;
    return Biquad(
      (1 + alpha * a) / a0,
      (-2 * cosw) / a0,
      (1 - alpha * a) / a0,
      (-2 * cosw) / a0,
      (1 - alpha / a) / a0,
    );
  }

  /// RBJ low shelf.
  factory Biquad.lowShelf({required double freq, required double gainDb, required double q, required double sampleRate}) {
    final a = math.pow(10, gainDb / 40).toDouble();
    final w0 = 2 * math.pi * freq / sampleRate;
    final cosw = math.cos(w0);
    final alpha = math.sin(w0) / (2 * q);
    final sq = 2 * math.sqrt(a) * alpha;
    final a0 = (a + 1) + (a - 1) * cosw + sq;
    return Biquad(
      a * ((a + 1) - (a - 1) * cosw + sq) / a0,
      2 * a * ((a - 1) - (a + 1) * cosw) / a0,
      a * ((a + 1) - (a - 1) * cosw - sq) / a0,
      -2 * ((a - 1) + (a + 1) * cosw) / a0,
      ((a + 1) + (a - 1) * cosw - sq) / a0,
    );
  }

  /// Magnitude response in dB at [freq].
  double magnitudeDb(double freq, double sampleRate) {
    final w = 2 * math.pi * freq / sampleRate;
    // H(e^jw) = (b0 + b1 z^-1 + b2 z^-2) / (1 + a1 z^-1 + a2 z^-2)
    final c1 = math.cos(w), s1 = math.sin(w), c2 = math.cos(2 * w), s2 = math.sin(2 * w);
    final nr = b0 + b1 * c1 + b2 * c2, ni = -(b1 * s1 + b2 * s2);
    final dr = 1 + a1 * c1 + a2 * c2, di = -(a1 * s1 + a2 * s2);
    final mag2 = (nr * nr + ni * ni) / (dr * dr + di * di);
    return 10 * math.log(mag2) / math.ln10;
  }
}

/// Sample rate used for drawing / mapping (typical output rate).
const eqReferenceSampleRate = 48000.0;

/// Q of the bass shelf (Butterworth).
const bassShelfQ = 0.707;

/// All filters an [EqSettings] turns into (bands with ~0 dB are skipped).
List<Biquad> eqFilters(EqSettings eq, {double sampleRate = eqReferenceSampleRate}) => [
      for (var i = 0; i < eqBandFrequencies.length; i++)
        if (eq.gainsDb[i].abs() >= 0.05)
          Biquad.peaking(freq: eqBandFrequencies[i], gainDb: eq.gainsDb[i], q: eqBandQ, sampleRate: sampleRate),
      if (eq.bassBoostDb >= 0.05)
        Biquad.lowShelf(freq: bassBoostFrequency, gainDb: eq.bassBoostDb, q: bassShelfQ, sampleRate: sampleRate),
    ];

/// Total EQ response in dB at [freq] (bands + bass, optionally + preamp).
double eqResponseDb(EqSettings eq, double freq, {bool includePreamp = true, double sampleRate = eqReferenceSampleRate}) {
  if (!eq.enabled) return 0;
  var db = includePreamp ? eq.preampDb : 0.0;
  for (final f in eqFilters(eq, sampleRate: sampleRate)) {
    db += f.magnitudeDb(freq, sampleRate);
  }
  return db;
}

/// Log-spaced frequencies from 20 Hz to 20 kHz, for drawing the curve.
List<double> logFrequencies(int count, {double from = 20, double to = 20000}) => [
      for (var i = 0; i < count; i++) from * math.pow(to / from, i / (count - 1)).toDouble(),
    ];

/// Highest point of the curve (without preamp) – used to warn about clipping.
double eqPeakBoostDb(EqSettings eq) =>
    logFrequencies(120).map((f) => eqResponseDb(eq, f, includePreamp: false)).fold(-999.0, math.max);

/// Semitones → playback-rate ratio (12 semitones = 2x).
double semitonesToRatio(double semitones) => math.pow(2, semitones / 12).toDouble();

/// dB → linear gain.
double dbToLinear(double db) => math.pow(10, db / 20).toDouble();

// ------------------------------------------------------------- simple mode

/// The three "simple" controls and how much each moves every band: Bass,
/// Mids and Treble overlap softly, like the tone knobs of an amplifier.
enum EqTone {
  bass([1.0, 1.0, 0.8, 0.4, 0.1, 0, 0, 0, 0, 0]),
  mids([0, 0, 0.1, 0.4, 0.8, 1.0, 0.8, 0.4, 0.1, 0]),
  treble([0, 0, 0, 0, 0, 0.1, 0.4, 0.8, 1.0, 1.0]);

  const EqTone(this.weights);
  final List<double> weights;
}

/// Where the three tone controls stand for these band gains (least-squares
/// fit, so a curve made in the detailed view still shows sensible values).
Map<EqTone, double> eqToneLevels(List<double> gains) {
  final w = [for (final t in EqTone.values) t.weights];
  // Normal equations: (WᵀW) x = Wᵀg, 3 × 3.
  final a = List.generate(3, (i) => List.generate(3, (j) {
        var s = 0.0;
        for (var k = 0; k < gains.length; k++) {
          s += w[i][k] * w[j][k];
        }
        return s;
      }));
  final b = List.generate(3, (i) {
    var s = 0.0;
    for (var k = 0; k < gains.length; k++) {
      s += w[i][k] * gains[k];
    }
    return s;
  });
  final x = _solve3(a, b);
  return {for (var i = 0; i < 3; i++) EqTone.values[i]: x[i].clamp(-eqMaxGainDb, eqMaxGainDb).toDouble()};
}

/// Moves one tone control to [level]: every band shifts by the change times
/// its weight, so whatever was shaped in the detailed view stays.
List<double> eqWithTone(List<double> gains, EqTone tone, double level) {
  final delta = level - eqToneLevels(gains)[tone]!;
  return [
    for (var i = 0; i < gains.length; i++)
      (gains[i] + delta * tone.weights[i]).clamp(-eqMaxGainDb, eqMaxGainDb).toDouble(),
  ];
}

List<double> _solve3(List<List<double>> a, List<double> b) {
  double det(List<List<double>> m) =>
      m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) -
      m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) +
      m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
  final d = det(a);
  if (d.abs() < 1e-9) return [0, 0, 0];
  return [
    for (var c = 0; c < 3; c++)
      det([
            for (var r = 0; r < 3; r++) [for (var k = 0; k < 3; k++) k == c ? b[r] : a[r][k]],
          ]) /
          d,
  ];
}

/// The preamp that keeps the loudest point of the curve at 0 dB (rounded to
/// half a dB, never above 0).
double eqAutoPreampDb(EqSettings eq) {
  final peak = eqPeakBoostDb(eq.copyWith(enabled: true));
  if (peak <= 0.05) return 0;
  return (-(peak * 2).ceil() / 2).clamp(-eqMaxPreampDb, 0.0).toDouble();
}

/// What part of the sound a frequency is, for the labels under the curve.
enum EqRegion {
  subBass(20, 60),
  bass(60, 250),
  lowMids(250, 500),
  mids(500, 2000),
  presence(2000, 6000),
  brilliance(6000, 20000);

  const EqRegion(this.from, this.to);
  final double from, to;
}

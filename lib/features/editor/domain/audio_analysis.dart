import 'dart:math' as math;
import 'dart:typed_data';

/// Precomputed waveform: level 0 has [basePps] values per second (0..255 =
/// loudest sample in the bucket), every next level is 4 times coarser. Drawing
/// picks the coarsest level that still has detail for the zoom, so a whole song
/// and a 1-second close-up both cost about one read per pixel.
class PeakPyramid {
  PeakPyramid(this.basePps, Uint8List base) : levels = _build(base);

  static const factor = 4;

  final int basePps;
  final List<Uint8List> levels;

  static const empty = _Empty();

  static List<Uint8List> _build(Uint8List base) {
    final out = [base];
    while (out.last.length > 256) {
      final prev = out.last;
      final next = Uint8List((prev.length + factor - 1) ~/ factor);
      for (var i = 0; i < prev.length; i++) {
        final j = i ~/ factor;
        if (prev[i] > next[j]) next[j] = prev[i];
      }
      out.add(next);
    }
    return out;
  }

  Duration get duration => Duration(microseconds: (levels.first.length * 1e6 / basePps).round());

  /// Loudest value (0..1) between two source times.
  double peak(double fromSec, double toSec) {
    if (toSec <= fromSec) toSec = fromSec + 1 / basePps;
    final span = (toSec - fromSec) * basePps;
    var level = 0;
    var width = 1.0;
    while (level + 1 < levels.length && width * factor <= span) {
      level++;
      width *= factor;
    }
    final data = levels[level];
    final pps = basePps / width;
    final a = (fromSec * pps).floor().clamp(0, data.length - 1);
    final b = (toSec * pps).ceil().clamp(a + 1, data.length);
    var m = 0;
    for (var i = a; i < b; i++) {
      if (data[i] > m) m = data[i];
    }
    return m / 255;
  }
}

class _Empty implements PeakPyramid {
  const _Empty();
  @override
  int get basePps => 100;
  @override
  List<Uint8List> get levels => [Uint8List(1)];
  @override
  Duration get duration => Duration.zero;
  @override
  double peak(double fromSec, double toSec) => 0;
}

/// Bucket peaks from 16-bit LE mono PCM.
Uint8List peaksFromPcmBytes(Uint8List bytes, int samplesPerBucket) {
  final data = ByteData.sublistView(bytes);
  final n = bytes.length ~/ 2;
  final out = Uint8List((n + samplesPerBucket - 1) ~/ samplesPerBucket);
  for (var i = 0; i < n; i++) {
    final v = data.getInt16(i * 2, Endian.little).abs();
    final scaled = v >= 32640 ? 255 : v >> 7;
    final b = i ~/ samplesPerBucket;
    if (scaled > out[b]) out[b] = scaled;
  }
  return out;
}

/// Parts of the source quieter than [thresholdDb] for at least [minLength],
/// as (start, end) in source time.
List<(Duration, Duration)> detectSilences(
  Uint8List peaks,
  int pps, {
  double thresholdDb = -45,
  Duration minLength = const Duration(milliseconds: 400),
}) {
  final limit = (math.pow(10, thresholdDb / 20) * 255).ceil();
  final minBuckets = (minLength.inMicroseconds * pps / 1e6).ceil();
  Duration at(int i) => Duration(microseconds: (i * 1e6 / pps).round());
  final out = <(Duration, Duration)>[];
  int? start;
  for (var i = 0; i <= peaks.length; i++) {
    final quiet = i < peaks.length && peaks[i] <= limit;
    if (quiet) {
      start ??= i;
    } else if (start != null) {
      if (i - start >= minBuckets) out.add((at(start), at(i)));
      start = null;
    }
  }
  return out;
}

/// Beat grid from the waveform's energy: tempo by autocorrelation of the onset
/// strength (60-180 BPM), phase by the strongest offset. Good enough to snap
/// cuts to; a song with no steady pulse returns nothing.
List<Duration> detectBeats(Uint8List peaks, int pps) {
  // Work at about 50 Hz whatever the source resolution.
  final hop = math.max(1, pps ~/ 50);
  final rate = pps / hop;
  final n = peaks.length ~/ hop;
  if (n < rate * 8) return const [];
  final env = Float64List(n);
  for (var i = 0; i < n; i++) {
    var m = 0;
    for (var j = i * hop; j < (i + 1) * hop; j++) {
      if (peaks[j] > m) m = peaks[j];
    }
    env[i] = m.toDouble();
  }
  // Onset strength: positive change of the envelope.
  final onset = Float64List(n);
  var mean = 0.0;
  for (var i = 1; i < n; i++) {
    final d = env[i] - env[i - 1];
    onset[i] = d > 0 ? d : 0;
    mean += onset[i];
  }
  mean /= n;
  if (mean <= 0) return const [];
  final minLag = (rate * 60 / 180).floor();
  final maxLag = (rate * 60 / 60).ceil();
  var bestLag = 0;
  var best = 0.0;
  var total = 0.0;
  var count = 0;
  for (var lag = minLag; lag <= maxLag && lag < n ~/ 2; lag++) {
    var sum = 0.0;
    for (var i = lag; i < n; i++) {
      sum += onset[i] * onset[i - lag];
    }
    sum /= n - lag;
    total += sum;
    count++;
    if (sum > best) {
      best = sum;
      bestLag = lag;
    }
  }
  // No clear pulse: the best lag barely beats the average one.
  if (bestLag == 0 || count == 0 || best < total / count * 1.15) return const [];
  var bestPhase = 0;
  var bestScore = -1.0;
  for (var phase = 0; phase < bestLag; phase++) {
    var score = 0.0;
    for (var i = phase; i < n; i += bestLag) {
      score += onset[i];
    }
    if (score > bestScore) {
      bestScore = score;
      bestPhase = phase;
    }
  }
  return [
    for (var i = bestPhase; i < n; i += bestLag) Duration(microseconds: (i / rate * 1e6).round()),
  ];
}

/// Index of the zero crossing nearest to [center] (16-bit mono samples), or
/// [center] when there is none in reach.
int nearestZeroCrossing(Int16List samples, int center, {int? reach}) {
  if (samples.length < 2) return center;
  final c = center.clamp(0, samples.length - 2);
  final limit = reach ?? samples.length;
  bool crosses(int i) => (samples[i] <= 0 && samples[i + 1] > 0) || (samples[i] >= 0 && samples[i + 1] < 0);
  for (var d = 0; d <= limit; d++) {
    final a = c - d, b = c + d;
    if (a >= 0 && crosses(a)) return a;
    if (b < samples.length - 1 && crosses(b)) return b;
    if (a < 0 && b >= samples.length - 1) break;
  }
  return center;
}

/// Nearest of [points] (sorted) to [t], if closer than [tolerance].
Duration? nearestSnap(List<Duration> points, Duration t, Duration tolerance) {
  if (points.isEmpty) return null;
  var lo = 0, hi = points.length - 1;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (points[mid] < t) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  final after = points[lo];
  final before = lo > 0 ? points[lo - 1] : after;
  final best = (t - before).abs() < (after - t).abs() ? before : after;
  return (best - t).abs() <= tolerance ? best : null;
}

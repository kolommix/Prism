import 'dart:math' as math;
import 'dart:typed_data';

/// Finds beats in the bass level as it plays: a beat is a jump well above the
/// recent average, at most one per [minGap]. [pulse] is 1 on a beat and fades by
/// real time, so it looks the same at 60 and 120 fps.
class BeatDetector {
  BeatDetector({this.minGap = 0.18, this.sensitivity = 1.35});

  /// Seconds between beats, at least.
  final double minGap;

  /// How far above the average counts as a beat.
  final double sensitivity;

  static const _historySeconds = 1.2;
  static const _slots = 48;
  final _history = Float32List(_slots);
  int _head = 0;
  double _slotTime = 0;
  double _sum = 0;
  double _sinceBeat = 10;
  double _last = 0;
  double pulse = 0;
  int beats = 0;

  /// Feed the bass level (0..1) and the seconds since the last call. Returns
  /// true on a beat.
  bool update(double bass, double dt) {
    final d = dt.clamp(0.0, 0.1);
    _sinceBeat += d;
    pulse *= math.exp(-d * 6);
    _slotTime += d;
    final slot = _historySeconds / _slots;
    while (_slotTime >= slot) {
      _slotTime -= slot;
      _sum += bass - _history[_head];
      _history[_head] = bass;
      _head = (_head + 1) % _slots;
    }
    final average = _sum / _slots;
    final rising = bass > _last;
    _last = bass;
    if (rising && _sinceBeat >= minGap && bass > average * sensitivity + 0.04 && bass > 0.15) {
      _sinceBeat = 0;
      pulse = 1;
      beats++;
      return true;
    }
    return false;
  }

  void reset() {
    _history.fillRange(0, _slots, 0);
    _sum = 0;
    _slotTime = 0;
    _sinceBeat = 10;
    _last = 0;
    pulse = 0;
  }
}

/// Levels that move like a real analyser, by real time: quick up ([attack]
/// seconds), slower down ([decay] seconds).
void smoothLevels(Float32List level, Float32List target, double dt, {double attack = 0.012, double decay = 0.16}) {
  final up = 1 - math.exp(-dt / attack);
  final down = 1 - math.exp(-dt / decay);
  for (var i = 0; i < level.length && i < target.length; i++) {
    final v = target[i];
    level[i] += (v - level[i]) * (v > level[i] ? up : down);
  }
}

/// Band levels from Android's `Visualizer.getFft` bytes (DC, Nyquist, then
/// re/im pairs of signed bytes) into log-spaced bands, 0..1 over [floorDb]..0 dB.
void bandsFromAndroidFft(Int8List fft, int samplingHz, Float32List out, {double floorDb = -60}) {
  final n = fft.length;
  if (n < 4) return;
  final bins = n ~/ 2;
  final nyquist = samplingHz / 2;
  final bands = out.length;
  for (var b = 0; b < bands; b++) {
    final loHz = 40 * math.pow(nyquist / 40, b / bands);
    final hiHz = 40 * math.pow(nyquist / 40, (b + 1) / bands);
    final lo = (loHz / nyquist * bins).floor().clamp(1, bins - 1);
    final hi = math.max(lo + 1, (hiHz / nyquist * bins).ceil().clamp(1, bins));
    var peak = 0.0;
    for (var k = lo; k < hi; k++) {
      final re = fft[k * 2].toDouble();
      final im = fft[k * 2 + 1].toDouble();
      final m = re * re + im * im;
      if (m > peak) peak = m;
    }
    // A full-scale byte is 128.
    final db = 10 * math.log(peak / (128.0 * 128.0) + 1e-9) / math.ln10;
    out[b] = ((db - floorDb) / -floorDb).clamp(0.0, 1.0);
  }
}

/// Applies the sensitivity slider: above 1 lifts quiet parts, under 1 calms it.
double applySensitivity(double v, double sensitivity) => (v * sensitivity).clamp(0.0, 1.0);

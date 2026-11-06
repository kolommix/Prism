import 'dart:math' as math;
import 'dart:typed_data';

/// Anything that gives band levels for a moment of the song.
abstract interface class BandSource {
  int get bands;

  /// Band levels (0..1) at [t].
  void sample(Duration t, Float32List out);
}

/// Pre-computed spectrum of a song: [frames] × [bands] values 0..255.
class Spectrum implements BandSource {
  const Spectrum({required this.data, required this.bands, required this.fps});

  final Uint8List data;
  @override
  final int bands;
  final int fps;

  int get frames => bands == 0 ? 0 : data.length ~/ bands;

  /// Band levels (0..1) at [t], linearly interpolated between frames.
  @override
  void sample(Duration t, Float32List out) {
    final f = t.inMicroseconds * fps / 1e6;
    final i = f.floor().clamp(0, math.max(0, frames - 1)).toInt();
    final j = math.min(i + 1, math.max(0, frames - 1));
    final w = (f - i).clamp(0.0, 1.0);
    for (var b = 0; b < bands && b < out.length; b++) {
      out[b] = (data[i * bands + b] * (1 - w) + data[j * bands + b] * w) / 255.0;
    }
  }

  /// File format: 'PSPC' magic, version, bands, fps, then raw frames.
  Uint8List encode() {
    final header = ByteData(16)
      ..setUint32(0, 0x50535043)
      ..setUint32(4, 1)
      ..setUint32(8, bands)
      ..setUint32(12, fps);
    return Uint8List.fromList([...header.buffer.asUint8List(), ...data]);
  }

  static Spectrum? decode(Uint8List bytes) {
    if (bytes.length < 16) return null;
    final h = ByteData.sublistView(bytes, 0, 16);
    if (h.getUint32(0) != 0x50535043 || h.getUint32(4) != 1) return null;
    return Spectrum(data: Uint8List.sublistView(bytes, 16), bands: h.getUint32(8), fps: h.getUint32(12));
  }
}

/// In-place iterative radix-2 FFT ([re]/[im] length must be a power of 2).
void fft(Float64List re, Float64List im) {
  final n = re.length;
  for (var i = 1, j = 0; i < n; i++) {
    var bit = n >> 1;
    for (; j & bit != 0; bit >>= 1) {
      j ^= bit;
    }
    j ^= bit;
    if (i < j) {
      var t = re[i];
      re[i] = re[j];
      re[j] = t;
      t = im[i];
      im[i] = im[j];
      im[j] = t;
    }
  }
  for (var len = 2; len <= n; len <<= 1) {
    final ang = -2 * math.pi / len;
    final wr = math.cos(ang), wi = math.sin(ang);
    for (var i = 0; i < n; i += len) {
      var cr = 1.0, ci = 0.0;
      for (var k = 0; k < len ~/ 2; k++) {
        final ar = re[i + k + len ~/ 2], ai = im[i + k + len ~/ 2];
        final tr = ar * cr - ai * ci, ti = ar * ci + ai * cr;
        re[i + k + len ~/ 2] = re[i + k] - tr;
        im[i + k + len ~/ 2] = im[i + k] - ti;
        re[i + k] += tr;
        im[i + k] += ti;
        final ncr = cr * wr - ci * wi;
        ci = cr * wi + ci * wr;
        cr = ncr;
      }
    }
  }
}

/// Analyses mono 16-bit PCM into log-spaced bands (pure; run in an isolate).
///
/// Window 2048 (Hann), [fps] frames per second, bands from 40 Hz to Nyquist,
/// levels mapped from −70..−10 dBFS to 0..255.
Spectrum analyzePcm16(Uint8List pcm, {required int sampleRate, int bands = 48, int fps = 30}) {
  const n = 2048;
  final samples = Int16List.sublistView(pcm, 0, pcm.length ~/ 2 * 2);
  final hop = sampleRate ~/ fps;
  final frames = math.max(0, (samples.length - 1) ~/ hop + 1);
  final out = Uint8List(frames * bands);
  final window = Float64List.fromList(List.generate(n, (i) => 0.5 - 0.5 * math.cos(2 * math.pi * i / (n - 1))));
  final re = Float64List(n), im = Float64List(n);
  // Band edges in FFT bins, log-spaced.
  final nyquist = sampleRate / 2;
  final edges = List<int>.generate(bands + 1, (b) {
    final hz = 40 * math.pow(nyquist / 40, b / bands);
    return (hz / sampleRate * n).round().clamp(1, n ~/ 2);
  });
  const floorDb = -70.0, ceilDb = -10.0;
  for (var f = 0; f < frames; f++) {
    final start = f * hop - n ~/ 2;
    for (var i = 0; i < n; i++) {
      final s = start + i;
      re[i] = s >= 0 && s < samples.length ? samples[s] / 32768.0 * window[i] : 0;
      im[i] = 0;
    }
    fft(re, im);
    for (var b = 0; b < bands; b++) {
      final lo = edges[b], hi = math.max(edges[b + 1], lo + 1);
      var peak = 0.0;
      for (var k = lo; k < hi; k++) {
        final m = re[k] * re[k] + im[k] * im[k];
        if (m > peak) peak = m;
      }
      // Normalise: a full-scale sine gives |X| ≈ n/4 with a Hann window.
      final db = 10 * math.log(peak / ((n / 4) * (n / 4)) + 1e-12) / math.ln10;
      out[f * bands + b] = (((db - floorDb) / (ceilDb - floorDb)).clamp(0.0, 1.0) * 255).round();
    }
  }
  return Spectrum(data: out, bands: bands, fps: fps);
}

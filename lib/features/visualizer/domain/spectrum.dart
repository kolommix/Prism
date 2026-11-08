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

  /// Version 2: levelled per song and band (see [analyzePcm16]). Older
  /// caches are analysed again.
  static const version = 2;

  /// File format: 'PSPC' magic, version, bands, fps, then raw frames.
  Uint8List encode() {
    final header = ByteData(16)
      ..setUint32(0, 0x50535043)
      ..setUint32(4, version)
      ..setUint32(8, bands)
      ..setUint32(12, fps);
    return Uint8List.fromList([...header.buffer.asUint8List(), ...data]);
  }

  static Spectrum? decode(Uint8List bytes) {
    if (bytes.length < 16) return null;
    final h = ByteData.sublistView(bytes, 0, 16);
    if (h.getUint32(0) != 0x50535043 || h.getUint32(4) != version) return null;
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
/// Window 4096 (Hann) so the bass bands are not all the same FFT bin, [fps]
/// frames per second, bands from 40 Hz to 16 kHz (or Nyquist). Each band is
/// the mean power of its bins (narrow bass bands read the spectrum between
/// bins), tilted +3 dB per octave so highs are not always lower than lows.
///
/// Then it is levelled for this song: every band gets its own range, from
/// its loud moments (95th percentile) down 36 dB, blended half with the whole
/// song's range. So every band moves with the music instead of the bass
/// always sitting at the top and the highs at the bottom.
Spectrum analyzePcm16(Uint8List pcm, {required int sampleRate, int bands = 64, int fps = 30}) {
  const n = 4096;
  final samples = Int16List.sublistView(pcm, 0, pcm.length ~/ 2 * 2);
  final hop = sampleRate ~/ fps;
  final frames = math.max(0, (samples.length - 1) ~/ hop + 1);
  final window = Float64List.fromList(List.generate(n, (i) => 0.5 - 0.5 * math.cos(2 * math.pi * i / (n - 1))));
  final re = Float64List(n), im = Float64List(n), power = Float64List(n ~/ 2 + 1);
  final binHz = sampleRate / n;
  final top = math.min(16000.0, sampleRate / 2);
  // Band edges in Hz, log-spaced.
  final edges = List<double>.generate(bands + 1, (b) => 40 * math.pow(top / 40, b / bands).toDouble());
  final tilt = [for (var b = 0; b < bands; b++) 3 * math.log(math.sqrt(edges[b] * edges[b + 1]) / 1000) / math.ln2];
  // A full-scale sine gives |X| ≈ n/4 with a Hann window.
  final ref = (n / 4) * (n / 4);
  const silent = -200.0;
  final db = Float32List(frames * bands);

  for (var f = 0; f < frames; f++) {
    final start = f * hop - n ~/ 2;
    var energy = 0.0;
    for (var i = 0; i < n; i++) {
      final s = start + i;
      final v = s >= 0 && s < samples.length ? samples[s] / 32768.0 : 0.0;
      energy += v * v;
      re[i] = v * window[i];
      im[i] = 0;
    }
    if (energy < 1e-7) {
      // Digital silence stays silent (also after levelling).
      for (var b = 0; b < bands; b++) {
        db[f * bands + b] = silent;
      }
      continue;
    }
    fft(re, im);
    for (var k = 0; k < power.length; k++) {
      power[k] = re[k] * re[k] + im[k] * im[k];
    }
    for (var b = 0; b < bands; b++) {
      final lo = edges[b] / binHz, hi = edges[b + 1] / binHz;
      double p;
      if (hi - lo < 1) {
        // Narrower than a bin: read between the two nearest bins.
        final c = (lo + hi) / 2, k = c.floor().clamp(0, power.length - 2), w = c - k;
        p = power[k] * (1 - w) + power[k + 1] * w;
      } else {
        var sum = 0.0;
        final a = lo.ceil(), z = math.min(hi.floor(), power.length - 1);
        for (var k = a; k <= z; k++) {
          sum += power[k];
        }
        p = sum / math.max(1, z - a + 1);
      }
      db[f * bands + b] = (10 * math.log(p / ref + 1e-12) / math.ln10 + tilt[b]).toDouble();
    }
  }

  // Levelling: loud moments of each band, and of the whole song.
  const range = 36.0;
  double percentile(List<double> v, double q) {
    if (v.isEmpty) return 0;
    v.sort();
    return v[((v.length - 1) * q).round()];
  }

  final everything = <double>[];
  final bandTop = Float64List(bands);
  for (var b = 0; b < bands; b++) {
    final v = <double>[
      for (var f = 0; f < frames; f++)
        if (db[f * bands + b] > silent) db[f * bands + b],
    ];
    everything.addAll(v);
    bandTop[b] = percentile(v, 0.95);
  }
  final songTop = percentile(everything, 0.97);
  final out = Uint8List(frames * bands);
  for (var b = 0; b < bands; b++) {
    // Half the band's own range, half the song's: a band that is quiet all
    // song still moves, but stays a little lower than the loud ones.
    final ceil = (bandTop[b] + songTop) / 2 + 3;
    final floor = ceil - range;
    for (var f = 0; f < frames; f++) {
      final v = db[f * bands + b];
      if (v <= silent) continue;
      final x = ((v - floor) / range).clamp(0.0, 1.0);
      // A gentle curve: quiet stays low, hits stand out.
      out[f * bands + b] = (math.pow(x, 1.3) * 255).round();
    }
  }
  return Spectrum(data: out, bands: bands, fps: fps);
}

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Tiny PCM WAV helpers used by the audio verification tests.
///
/// The tests render real audio through the shipped backends (libmpv on
/// Windows, FFmpeg for exports) and measure tone levels with Goertzel, so
/// "the EQ changes the sound" is checked with numbers instead of ears.

/// Mono float samples + sample rate.
class Pcm {
  Pcm(this.samples, this.sampleRate);
  final Float64List samples;
  final int sampleRate;

  Duration get duration => Duration(microseconds: (samples.length * 1e6 / sampleRate).round());
}

/// Sum of equal-amplitude sines (one per frequency), [seconds] long.
Pcm tones(List<double> freqs, {double seconds = 3, int sampleRate = 44100, double amplitude = 0.15}) {
  final n = (seconds * sampleRate).round();
  final out = Float64List(n);
  for (var i = 0; i < n; i++) {
    var v = 0.0;
    for (final f in freqs) {
      v += math.sin(2 * math.pi * f * i / sampleRate);
    }
    out[i] = v * amplitude;
  }
  return Pcm(out, sampleRate);
}

/// Part of [pcm] between [from] and [to] (seconds).
Pcm slice(Pcm pcm, double from, double to) {
  final a = (from * pcm.sampleRate).round().clamp(0, pcm.samples.length);
  final b = (to * pcm.sampleRate).round().clamp(a, pcm.samples.length);
  return Pcm(Float64List.sublistView(pcm.samples, a, b), pcm.sampleRate);
}

/// Writes 16-bit mono PCM.
void writeWav(String path, Pcm pcm) {
  final n = pcm.samples.length;
  final b = BytesBuilder();
  void u32(int v) => b.add((ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List());
  void u16(int v) => b.add((ByteData(2)..setUint16(0, v, Endian.little)).buffer.asUint8List());
  b.add('RIFF'.codeUnits);
  u32(36 + n * 2);
  b.add('WAVEfmt '.codeUnits);
  u32(16);
  u16(1); // PCM
  u16(1); // mono
  u32(pcm.sampleRate);
  u32(pcm.sampleRate * 2);
  u16(2);
  u16(16);
  b.add('data'.codeUnits);
  u32(n * 2);
  final data = ByteData(n * 2);
  for (var i = 0; i < n; i++) {
    data.setInt16(i * 2, (pcm.samples[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  b.add(data.buffer.asUint8List());
  File(path).writeAsBytesSync(b.takeBytes());
}

/// Reads a PCM WAV (16-bit int or 32-bit float, any channel count) and
/// returns the first channel. Skips unknown chunks.
Pcm readWav(String path) {
  final bytes = File(path).readAsBytesSync();
  final d = ByteData.sublistView(bytes);
  var pos = 12;
  int? fmt, channels, rate, bits;
  while (pos + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(pos, pos + 4));
    var size = d.getUint32(pos + 4, Endian.little);
    final body = pos + 8;
    if (id == 'fmt ') {
      fmt = d.getUint16(body, Endian.little);
      channels = d.getUint16(body + 2, Endian.little);
      rate = d.getUint32(body + 4, Endian.little);
      bits = d.getUint16(body + 14, Endian.little);
      if (fmt == 0xFFFE) fmt = d.getUint16(body + 24, Endian.little); // WAVE_FORMAT_EXTENSIBLE
    } else if (id == 'data') {
      // Streaming writers may leave the size as 0 / 0xFFFFFFFF.
      if (size == 0 || body + size > bytes.length) size = bytes.length - body;
      final frameBytes = channels! * bits! ~/ 8;
      final frames = size ~/ frameBytes;
      final out = Float64List(frames);
      for (var i = 0; i < frames; i++) {
        final o = body + i * frameBytes;
        out[i] = switch ((fmt, bits)) {
          (1, 16) => d.getInt16(o, Endian.little) / 32768.0,
          (1, 32) => d.getInt32(o, Endian.little) / 2147483648.0,
          (3, 32) => d.getFloat32(o, Endian.little),
          _ => throw UnsupportedError('WAV format $fmt/$bits'),
        };
      }
      return Pcm(out, rate!);
    }
    pos = body + size + (size.isOdd ? 1 : 0);
  }
  throw const FormatException('No data chunk');
}

/// Amplitude of [freq] in [pcm] (Goertzel over the middle 60 % to skip
/// fades/edges), in dBFS relative to a full-scale sine.
double toneDb(Pcm pcm, double freq) {
  final s = pcm.samples;
  final start = (s.length * 0.2).floor();
  final end = (s.length * 0.8).floor();
  final n = end - start;
  if (n <= 0) return double.negativeInfinity;
  final k = 2 * math.cos(2 * math.pi * freq / pcm.sampleRate);
  var s1 = 0.0, s2 = 0.0;
  for (var i = start; i < end; i++) {
    final s0 = s[i] + k * s1 - s2;
    s2 = s1;
    s1 = s0;
  }
  final power = s1 * s1 + s2 * s2 - k * s1 * s2;
  final amplitude = 2 * math.sqrt(math.max(power, 0)) / n;
  return 20 * math.log(amplitude + 1e-12) / math.ln10;
}

/// RMS level in dBFS over the whole signal.
double rmsDb(Pcm pcm) {
  var sum = 0.0;
  for (final v in pcm.samples) {
    sum += v * v;
  }
  return 10 * math.log(sum / math.max(1, pcm.samples.length) + 1e-24) / math.ln10;
}

import 'dart:math' as math;

import '../../library/domain/track.dart';

/// Loudness normalisation mode.
enum NormalizationMode {
  off,

  /// Every track at the same loudness.
  track,

  /// Keeps loudness differences inside an album (falls back to track gain).
  album,
}

/// ReplayGain 2.0 reference level (EBU R128 based).
const referenceLufs = -18.0;

/// Keep this much headroom below the file's peak when boosting.
const peakHeadroomDb = 0.5;

/// Parses ReplayGain tag values like "-7.89 dB", "+1.2 dB", "0.987654".
double? parseReplayGain(String? value) {
  if (value == null) return null;
  final m = RegExp(r'[-+]?\d+(?:[.,]\d+)?').firstMatch(value);
  return m == null ? null : double.tryParse(m.group(0)!.replaceAll(',', '.'));
}

/// Result of FFmpeg's `ebur128=peak=true` scanner.
class LoudnessMeasurement {
  const LoudnessMeasurement({required this.integratedLufs, required this.truePeakDb});
  final double integratedLufs;
  final double truePeakDb;
}

/// Reads the "Summary" block printed by FFmpeg's ebur128 filter.
LoudnessMeasurement? parseEbur128Summary(String log) {
  final summary = log.lastIndexOf('Summary:');
  if (summary < 0) return null;
  final s = log.substring(summary);
  final i = RegExp(r'I:\s*(-?\d+(?:\.\d+)?|-inf)\s*LUFS').firstMatch(s);
  final peak = RegExp(r'Peak:\s*(-?\d+(?:\.\d+)?|-inf)\s*dBFS').firstMatch(s);
  if (i == null) return null;
  double v(String x) => x == '-inf' ? -70 : double.parse(x);
  return LoudnessMeasurement(integratedLufs: v(i.group(1)!), truePeakDb: peak == null ? 0 : v(peak.group(1)!));
}

/// Gain in dB the player should apply to [t] for [mode].
///
/// Priority: ReplayGain tags (album or track) → Prism's own EBU R128
/// measurement → 0 dB. Boosts are limited so the file's peak stays below
/// full scale, and the result is clamped to a sane range.
double normalizationGainDb(Track t, NormalizationMode mode) {
  if (mode == NormalizationMode.off) return 0;
  double? gain;
  double? peakLinear;
  if (mode == NormalizationMode.album && t.rgAlbumGain != null) {
    gain = t.rgAlbumGain;
    peakLinear = t.rgAlbumPeak;
  } else if (t.rgTrackGain != null) {
    gain = t.rgTrackGain;
    peakLinear = t.rgTrackPeak;
  } else if (t.loudnessLufs != null) {
    gain = referenceLufs - t.loudnessLufs!;
    peakLinear = t.truePeakDb == null ? null : math.pow(10, t.truePeakDb! / 20).toDouble();
  }
  if (gain == null) return 0;
  if (peakLinear != null && peakLinear > 0) {
    final maxGain = -20 * math.log(peakLinear) / math.ln10 - peakHeadroomDb;
    if (gain > maxGain) gain = math.max(maxGain, math.min(gain, 0));
  }
  return gain.clamp(-24.0, 12.0);
}

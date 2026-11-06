import 'dart:math' as math;

import 'audio_analysis.dart';
import 'edit_decision_list.dart';
import 'timeline.dart';

/// Reads the waveform for one segment: loudest value (0..1) in a source range.
typedef SegmentPeak = double Function(Segment segment, Duration from, Duration to);

/// Builds a [SegmentPeak] from the track's waveform and those of merged songs.
SegmentPeak peakReader(PeakPyramid main, Map<String, PeakPyramid> others) => (s, from, to) {
      if (s.silent) return 0;
      final pyramid = s.input == null ? main : (others[s.input] ?? PeakPyramid.empty);
      return pyramid.peak(from.inMicroseconds / 1e6, to.inMicroseconds / 1e6);
    };

const _scanStep = Duration(milliseconds: 20);

/// Quiet stretches of the edit, in output time.
List<(Duration, Duration)> quietRanges(
  Timeline t,
  SegmentPeak peak, {
  double thresholdDb = -45,
  Duration minLength = const Duration(milliseconds: 400),
}) {
  final limit = math.pow(10, thresholdDb / 20).toDouble();
  final out = <(Duration, Duration)>[];
  final starts = t.segmentStarts;
  Duration? quietFrom;
  var time = Duration.zero;
  final total = t.duration;
  for (var i = 0; i < t.segments.length; i++) {
    final s = t.segments[i];
    final end = i == t.segments.length - 1 ? total : starts[i + 1];
    while (time < end) {
      final a = s.sourceAt(time - starts[i]);
      final b = s.sourceAt(time + _scanStep - starts[i]);
      final from = a < b ? a : b, to = a < b ? b : a;
      if (peak(s, from, to) * _gainOf(s) <= limit) {
        quietFrom ??= time;
      } else if (quietFrom != null) {
        if (time - quietFrom >= minLength) out.add((quietFrom, time));
        quietFrom = null;
      }
      time += _scanStep;
    }
  }
  if (quietFrom != null && total - quietFrom >= minLength) out.add((quietFrom, total));
  return out;
}

double _gainOf(Segment s) => math.pow(10, s.gainDb / 20).toDouble();

/// Trim the silence at both ends. Null when there is none to remove.
EditOp? autoTrimOp(Timeline t, SegmentPeak peak, {double thresholdDb = -45}) {
  final quiet = quietRanges(t, peak, thresholdDb: thresholdDb, minLength: const Duration(milliseconds: 100));
  final total = t.duration;
  var start = Duration.zero, end = total;
  if (quiet.isNotEmpty && quiet.first.$1 == Duration.zero) start = quiet.first.$2;
  if (quiet.isNotEmpty && quiet.last.$2 == total) end = quiet.last.$1;
  if (start == Duration.zero && end == total) return null;
  if (end - start < minSegment) return null;
  return EditOp.trim(startMs: start.inMilliseconds, endMs: end.inMilliseconds);
}

/// Cut the long silences inside the edit, leaving [keep] on each side so the
/// music doesn't start abruptly. Null when there is nothing to cut.
EditOp? removeSilenceOp(
  Timeline t,
  SegmentPeak peak, {
  double thresholdDb = -45,
  Duration minLength = const Duration(milliseconds: 800),
  Duration keep = const Duration(milliseconds: 120),
}) {
  final total = t.duration;
  final ranges = quietRanges(t, peak, thresholdDb: thresholdDb, minLength: minLength);
  final ops = <EditOp>[];
  // Back to front: earlier times stay valid after each cut.
  for (final (a, b) in ranges.reversed) {
    if (a == Duration.zero || b == total) continue; // the ends belong to auto-trim
    final from = a + keep, to = b - keep;
    if (to - from < minSegment) continue;
    ops.add(EditOp.cut(startMs: from.inMilliseconds, endMs: to.inMilliseconds));
  }
  return ops.isEmpty ? null : EditOp.batch(ops: ops);
}

/// Gain that brings the edit's loudest peak to [targetDb]; null when silent or
/// already there.
double? normalizeGainDb(Timeline t, SegmentPeak peak, {double targetDb = -1}) {
  var loudest = 0.0;
  for (final s in t.segments) {
    final v = peak(s, s.sourceStart, s.sourceEnd) * _gainOf(s);
    if (v > loudest) loudest = v;
  }
  if (loudest <= 0) return null;
  final db = targetDb - 20 * math.log(loudest) / math.ln10;
  return db.abs() < 0.05 ? null : db;
}

/// Everything a selection needs to become a ringtone: only that part, with
/// short fades so it doesn't click when it starts and loops.
List<EditOp> ringtoneOps(Duration start, Duration end) => [
      EditOp.trim(startMs: start.inMilliseconds, endMs: end.inMilliseconds),
      const EditOp.fadeIn(durationMs: 300),
      const EditOp.fadeOut(durationMs: 500),
    ];

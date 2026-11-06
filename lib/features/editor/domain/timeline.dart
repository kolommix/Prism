import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../player/domain/playback_plan.dart';
import 'edit_decision_list.dart';

/// Shortest segment the editor will create (avoids zero-length clips).
const minSegment = Duration(milliseconds: 10);

/// Limits for segment parameters.
const minSpeed = 0.25, maxSpeed = 4.0;
const minPitch = -12.0, maxPitch = 12.0;
const minGainDb = -24.0, maxGainDb = 12.0;
const maxEqDb = 12.0;
const maxLoops = 64;

/// A ramp is played as short steady steps of about this much source audio
/// (FFmpeg has no gliding tempo filter); the timeline math uses the same steps,
/// so time mapping and the exported file agree exactly.
const _rampStep = Duration(milliseconds: 250);
const _maxRampSteps = 48;

/// Shape of a fade. The names are FFmpeg's `afade` / `acrossfade` curves.
enum FadeCurve {
  linear('tri'),
  smooth('qsin'),
  sCurve('esin'),
  fast('exp'),
  slow('log');

  const FadeCurve(this.ffmpeg);
  final String ffmpeg;

  static FadeCurve parse(String? name) => values.asNameMap()[name] ?? linear;
}

/// One steady part of a segment, in the order it is heard.
@immutable
class RampStep {
  const RampStep(this.sourceStart, this.sourceEnd, this.speed);
  final Duration sourceStart;
  final Duration sourceEnd;
  final double speed;
  Duration get sourceLength => sourceEnd - sourceStart;
  Duration get outputLength => Duration(microseconds: (sourceLength.inMicroseconds / speed).round());
}

/// A piece of a source file in the edited result.
@immutable
class Segment {
  const Segment({
    required this.sourceStart,
    required this.sourceEnd,
    this.speed = 1,
    this.speedEnd,
    this.pitchSemitones = 0,
    this.gainDb = 0,
    this.reverse = false,
    this.silent = false,
    this.input,
    this.fadeIn = Duration.zero,
    this.fadeOut = Duration.zero,
    this.curve = FadeCurve.linear,
    this.xfadeNext = Duration.zero,
    this.eqLowDb = 0,
    this.eqMidDb = 0,
    this.eqHighDb = 0,
    this.gateDb,
  });

  final Duration sourceStart;
  final Duration sourceEnd;

  /// Tempo, pitch preserved. With [speedEnd] it glides from one to the other.
  final double speed;
  final double? speedEnd;
  final double pitchSemitones;
  final double gainDb;
  final bool reverse;

  /// A gap of silence instead of audio (delete without closing the gap).
  final bool silent;

  /// Another file merged into this edit; null = the track being edited.
  final String? input;

  final Duration fadeIn;
  final Duration fadeOut;
  final FadeCurve curve;

  /// Overlap with the next segment.
  final Duration xfadeNext;
  final double eqLowDb, eqMidDb, eqHighDb;

  /// Noise gate threshold; null = off.
  final double? gateDb;

  bool get isRamp => speedEnd != null && (speedEnd! - speed).abs() > 1e-6;
  bool get hasEq => eqLowDb != 0 || eqMidDb != 0 || eqHighDb != 0;

  Duration get sourceLength => sourceEnd - sourceStart;

  /// The steady parts in the order they are heard (one unless it's a ramp).
  List<RampStep> get steps {
    if (!isRamp) {
      return [RampStep(sourceStart, sourceEnd, speed)];
    }
    final n = (sourceLength.inMicroseconds / _rampStep.inMicroseconds).round().clamp(2, _maxRampSteps);
    final out = <RampStep>[];
    final len = sourceLength.inMicroseconds;
    for (var i = 0; i < n; i++) {
      final v = speed + (speedEnd! - speed) * (i + 0.5) / n;
      final a = Duration(microseconds: len * i ~/ n);
      final b = Duration(microseconds: len * (i + 1) ~/ n);
      out.add(reverse
          ? RampStep(sourceEnd - b, sourceEnd - a, v)
          : RampStep(sourceStart + a, sourceStart + b, v));
    }
    return out;
  }

  Duration get outputLength {
    if (!isRamp) return Duration(microseconds: (sourceLength.inMicroseconds / speed).round());
    return steps.fold(Duration.zero, (d, s) => d + s.outputLength);
  }

  /// Output offset inside this segment → source position.
  Duration sourceAt(Duration inOut) {
    final us = math.max(0, inOut.inMicroseconds);
    if (!isRamp) {
      final inSrc = Duration(microseconds: (us * speed).round());
      final clamped = inSrc > sourceLength ? sourceLength : inSrc;
      return reverse ? sourceEnd - clamped : sourceStart + clamped;
    }
    var t = 0;
    for (final s in steps) {
      final len = s.outputLength.inMicroseconds;
      if (us < t + len) {
        final inSrc = Duration(microseconds: ((us - t) * s.speed).round());
        return reverse ? s.sourceEnd - inSrc : s.sourceStart + inSrc;
      }
      t += len;
    }
    return reverse ? sourceStart : sourceEnd;
  }

  /// Source position inside this segment → output offset.
  Duration outputAt(Duration src) {
    if (!isRamp) {
      final inSrc = reverse ? sourceEnd - src : src - sourceStart;
      return Duration(microseconds: (inSrc.inMicroseconds / speed).round());
    }
    var t = Duration.zero;
    for (final s in steps) {
      if (src >= s.sourceStart && src <= s.sourceEnd) {
        final inSrc = reverse ? s.sourceEnd - src : src - s.sourceStart;
        return t + Duration(microseconds: (inSrc.inMicroseconds / s.speed).round());
      }
      t += s.outputLength;
    }
    return t;
  }

  /// Speed at a point of the source, 0..1 in the order it is heard.
  double _speedAt(double f) => speed + ((speedEnd ?? speed) - speed) * f;

  /// Cuts at output offset [inOut]; returns the part heard first and second.
  (Segment, Segment) splitAt(Duration inOut) {
    final cut = sourceAt(inOut);
    final firstSrc = reverse ? sourceEnd - cut : cut - sourceStart;
    final f = sourceLength.inMicroseconds == 0 ? 0.0 : firstSrc.inMicroseconds / sourceLength.inMicroseconds;
    final mid = _speedAt(f);
    final first = copyWith(
      sourceStart: reverse ? cut : sourceStart,
      sourceEnd: reverse ? sourceEnd : cut,
      speedEnd: isRamp ? mid : speedEnd,
      fadeOut: Duration.zero,
      xfadeNext: Duration.zero,
    );
    final second = copyWith(
      sourceStart: reverse ? sourceStart : cut,
      sourceEnd: reverse ? cut : sourceEnd,
      speed: isRamp ? mid : speed,
      fadeIn: Duration.zero,
    );
    return (first, second);
  }

  /// What needs rendering: the player can only do plain clips live.
  bool get isLiveCompatible =>
      !isRamp &&
      !reverse &&
      !silent &&
      input == null &&
      fadeIn == Duration.zero &&
      fadeOut == Duration.zero &&
      xfadeNext == Duration.zero &&
      !hasEq &&
      gateDb == null;

  bool get isChanged =>
      speed != 1 ||
      isRamp ||
      pitchSemitones != 0 ||
      gainDb != 0 ||
      reverse ||
      silent ||
      fadeIn != Duration.zero ||
      fadeOut != Duration.zero ||
      hasEq ||
      gateDb != null;

  static const _unset = Object();

  Segment copyWith({
    Duration? sourceStart,
    Duration? sourceEnd,
    double? speed,
    Object? speedEnd = _unset,
    double? pitchSemitones,
    double? gainDb,
    bool? reverse,
    bool? silent,
    Duration? fadeIn,
    Duration? fadeOut,
    FadeCurve? curve,
    Duration? xfadeNext,
    double? eqLowDb,
    double? eqMidDb,
    double? eqHighDb,
    Object? gateDb = _unset,
  }) =>
      Segment(
        sourceStart: sourceStart ?? this.sourceStart,
        sourceEnd: sourceEnd ?? this.sourceEnd,
        speed: speed ?? this.speed,
        speedEnd: identical(speedEnd, _unset) ? this.speedEnd : speedEnd as double?,
        pitchSemitones: pitchSemitones ?? this.pitchSemitones,
        gainDb: gainDb ?? this.gainDb,
        reverse: reverse ?? this.reverse,
        silent: silent ?? this.silent,
        input: input,
        fadeIn: fadeIn ?? this.fadeIn,
        fadeOut: fadeOut ?? this.fadeOut,
        curve: curve ?? this.curve,
        xfadeNext: xfadeNext ?? this.xfadeNext,
        eqLowDb: eqLowDb ?? this.eqLowDb,
        eqMidDb: eqMidDb ?? this.eqMidDb,
        eqHighDb: eqHighDb ?? this.eqHighDb,
        gateDb: identical(gateDb, _unset) ? this.gateDb : gateDb as double?,
      );

  @override
  bool operator ==(Object other) =>
      other is Segment &&
      other.sourceStart == sourceStart &&
      other.sourceEnd == sourceEnd &&
      other.speed == speed &&
      other.speedEnd == speedEnd &&
      other.pitchSemitones == pitchSemitones &&
      other.gainDb == gainDb &&
      other.reverse == reverse &&
      other.silent == silent &&
      other.input == input &&
      other.fadeIn == fadeIn &&
      other.fadeOut == fadeOut &&
      other.curve == curve &&
      other.xfadeNext == xfadeNext &&
      other.eqLowDb == eqLowDb &&
      other.eqMidDb == eqMidDb &&
      other.eqHighDb == eqHighDb &&
      other.gateDb == gateDb;

  @override
  int get hashCode => Object.hash(sourceStart, sourceEnd, speed, speedEnd, pitchSemitones, gainDb, reverse, silent, input,
      fadeIn, fadeOut, curve, xfadeNext, eqLowDb, eqMidDb, eqHighDb, gateDb);

  @override
  String toString() => 'Segment(${sourceStart.inMilliseconds}-${sourceEnd.inMilliseconds}ms '
      'x$speed${speedEnd == null ? '' : '→$speedEnd'} ${pitchSemitones}st ${gainDb}dB${reverse ? ' rev' : ''}${silent ? ' silent' : ''})';
}

/// The edited result: ordered segments + fades. Immutable; every operation
/// returns a new timeline. Invalid operations (empty range, removing
/// everything) return the timeline unchanged.
@immutable
class Timeline {
  const Timeline({
    required this.segments,
    this.fadeIn = Duration.zero,
    this.fadeOut = Duration.zero,
    this.fadeCurve = FadeCurve.linear,
    this.masterGainDb = 0,
    this.loudnessLufs,
  });

  /// The untouched file.
  factory Timeline.initial(Duration source) =>
      Timeline(segments: [Segment(sourceStart: Duration.zero, sourceEnd: source)]);

  factory Timeline.fromOps(Duration source, Iterable<EditOp> ops) =>
      ops.fold(Timeline.initial(source), (t, op) => t.apply(op));

  final List<Segment> segments;
  final Duration fadeIn;
  final Duration fadeOut;
  final FadeCurve fadeCurve;

  /// Gain over the whole edit (normalize).
  final double masterGainDb;

  /// Target loudness (`loudnorm`), null = off.
  final double? loudnessLufs;

  /// Overlap between segment [i] and the next one, limited to half of each.
  Duration xfadeAfter(int i) {
    if (i >= segments.length - 1) return Duration.zero;
    final want = segments[i].xfadeNext;
    if (want == Duration.zero) return Duration.zero;
    final half = Duration(microseconds: math.min(segments[i].outputLength.inMicroseconds, segments[i + 1].outputLength.inMicroseconds) ~/ 2);
    return want > half ? half : want;
  }

  /// Output start of every segment.
  List<Duration> get segmentStarts {
    final out = <Duration>[];
    var t = Duration.zero;
    for (var i = 0; i < segments.length; i++) {
      out.add(t);
      t += segments[i].outputLength - xfadeAfter(i);
    }
    return out;
  }

  Duration get duration {
    var t = Duration.zero;
    for (var i = 0; i < segments.length; i++) {
      t += segments[i].outputLength - xfadeAfter(i);
    }
    return t;
  }

  Timeline _copy({
    List<Segment>? segments,
    Duration? fadeIn,
    Duration? fadeOut,
    FadeCurve? fadeCurve,
    double? masterGainDb,
    Object? loudnessLufs = Segment._unset,
  }) =>
      Timeline(
        segments: segments == null ? this.segments : List.unmodifiable(segments),
        fadeIn: fadeIn ?? this.fadeIn,
        fadeOut: fadeOut ?? this.fadeOut,
        fadeCurve: fadeCurve ?? this.fadeCurve,
        masterGainDb: masterGainDb ?? this.masterGainDb,
        loudnessLufs: identical(loudnessLufs, Segment._unset) ? this.loudnessLufs : loudnessLufs as double?,
      )._clampFades();

  Timeline _clampFades() {
    final half = Duration(microseconds: duration.inMicroseconds ~/ 2);
    if (fadeIn <= half && fadeOut <= half) return this;
    return Timeline(
      segments: segments,
      fadeIn: fadeIn > half ? half : fadeIn,
      fadeOut: fadeOut > half ? half : fadeOut,
      fadeCurve: fadeCurve,
      masterGainDb: masterGainDb,
      loudnessLufs: loudnessLufs,
    );
  }

  // ------------------------------------------------------------- mapping

  /// Which segment plays at output time [t], and the source position there.
  /// Inside a crossfade this is the segment that is fading in.
  (int, Duration) locate(Duration t) {
    final starts = segmentStarts;
    var i = segments.length - 1;
    while (i > 0 && t < starts[i]) {
      i--;
    }
    return (i, segments[i].sourceAt(t - starts[i]));
  }

  /// Output time → source time (for A/B switching: edited → original).
  Duration outputToSource(Duration t) => locate(t).$2;

  /// Source time → output time (original → edited). Parts that were cut map
  /// to the next kept audio (or the end).
  Duration sourceToOutput(Duration src) {
    final starts = segmentStarts;
    Duration? best;
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      if (s.silent || s.input != null) continue;
      if (src >= s.sourceStart && src < s.sourceEnd) return starts[i] + s.outputAt(src);
      if (s.sourceStart > src && best == null) best = starts[i];
    }
    return best ?? duration;
  }

  // ----------------------------------------------------------- operations

  Timeline apply(EditOp op) => switch (op) {
        SplitOp(:final atMs) => _splitAt(_ms(atMs)),
        TrimOp(:final startMs, :final endMs) => _range(startMs, endMs, (inside, _) => inside, keepInside: true),
        CutOp(:final startMs, :final endMs) => _range(startMs, endMs, (inside, _) => const []),
        SilenceOp(:final startMs, :final endMs) => _range(startMs, endMs, (inside, _) {
            final len = inside.fold(Duration.zero, (d, s) => d + s.outputLength);
            return [Segment(sourceStart: Duration.zero, sourceEnd: len, silent: true)];
          }),
        DuplicateOp(:final startMs, :final endMs) => _range(startMs, endMs, (inside, _) => [...inside, ...inside]),
        LoopOp(:final startMs, :final endMs, :final times) => _range(startMs, endMs, (inside, _) => [
              for (var i = 0; i < times.clamp(1, maxLoops); i++) ...inside,
            ]),
        MoveOp(:final from, :final to) => _move(from, to),
        MergeOp(:final uri, :final durationMs) => _copy(segments: [
            ...segments,
            Segment(sourceStart: Duration.zero, sourceEnd: _ms(durationMs), input: uri),
          ]),
        SpeedOp(:final startMs, :final endMs, :final factor) => _range(startMs, endMs,
            (inside, _) => [for (final s in inside) s.copyWith(speed: factor.clamp(minSpeed, maxSpeed), speedEnd: null)]),
        RampOp(:final startMs, :final endMs, :final from, :final to) => _ramp(startMs, endMs, from, to),
        PitchOp(:final startMs, :final endMs, :final semitones) => _range(startMs, endMs,
            (inside, _) => [for (final s in inside) s.copyWith(pitchSemitones: semitones.clamp(minPitch, maxPitch))]),
        GainOp(:final startMs, :final endMs, :final db) => _range(
            startMs, endMs, (inside, _) => [for (final s in inside) s.copyWith(gainDb: db.clamp(minGainDb, maxGainDb))]),
        ReverseOp(:final startMs, :final endMs) => _range(startMs, endMs, (inside, _) => [
              // The whole range plays backwards, so the order flips too.
              for (final s in inside.reversed) s.copyWith(reverse: !s.reverse, speedEnd: s.speedEnd == null ? null : s.speed, speed: s.speedEnd ?? s.speed),
            ]),
        SegmentFadeOp(:final startMs, :final endMs, :final inMs, :final outMs, :final curve) =>
          _range(startMs, endMs, (inside, _) {
            final out = [...inside];
            out[0] = out[0].copyWith(fadeIn: _ms(math.max(0, inMs)), curve: FadeCurve.parse(curve));
            out[out.length - 1] = out[out.length - 1].copyWith(fadeOut: _ms(math.max(0, outMs)), curve: FadeCurve.parse(curve));
            return out;
          }),
        CrossfadeOp(:final segment, :final ms, :final curve) => _crossfade(segment, ms, curve),
        SegmentEqOp(:final startMs, :final endMs, :final lowDb, :final midDb, :final highDb) => _range(startMs, endMs, (inside, _) => [
              for (final s in inside)
                s.copyWith(
                  eqLowDb: lowDb.clamp(-maxEqDb, maxEqDb),
                  eqMidDb: midDb.clamp(-maxEqDb, maxEqDb),
                  eqHighDb: highDb.clamp(-maxEqDb, maxEqDb),
                ),
            ]),
        GateOp(:final startMs, :final endMs, :final db) =>
          _range(startMs, endMs, (inside, _) => [for (final s in inside) s.copyWith(gateDb: db)]),
        FadeInOp(:final durationMs) => _copy(fadeIn: _ms(math.max(0, durationMs))),
        FadeOutOp(:final durationMs) => _copy(fadeOut: _ms(math.max(0, durationMs))),
        FadeCurveOp(:final curve) => _copy(fadeCurve: FadeCurve.parse(curve)),
        MasterGainOp(:final db) => _copy(masterGainDb: db.clamp(-48.0, 48.0)),
        LoudnessOp(:final lufs) => _copy(loudnessLufs: lufs),
        BatchOp(:final ops) => ops.fold(this, (t, o) => t.apply(o)),
      };

  static Duration _ms(int ms) => Duration(milliseconds: ms);

  Timeline _ramp(int startMs, int endMs, double from, double to) {
    final a = from.clamp(minSpeed, maxSpeed), b = to.clamp(minSpeed, maxSpeed);
    return _range(startMs, endMs, (inside, _) {
      // The ramp spans the whole range, whatever segments it covers.
      final total = inside.fold(0, (n, s) => n + s.sourceLength.inMicroseconds);
      var done = 0;
      return [
        for (final s in inside)
          () {
            final v0 = a + (b - a) * done / math.max(1, total);
            done += s.sourceLength.inMicroseconds;
            final v1 = a + (b - a) * done / math.max(1, total);
            return s.copyWith(speed: v0, speedEnd: v1);
          }(),
      ];
    });
  }

  Timeline _move(int from, int to) {
    if (from < 0 || from >= segments.length || to < 0 || to >= segments.length || from == to) return this;
    final list = [...segments];
    final s = list.removeAt(from);
    list.insert(to, s);
    return _copy(segments: list);
  }

  Timeline _crossfade(int segment, int ms, String curve) {
    if (segment < 0 || segment >= segments.length - 1) return this;
    final list = [...segments];
    list[segment] = list[segment].copyWith(xfadeNext: _ms(math.max(0, ms)), curve: FadeCurve.parse(curve));
    return _copy(segments: list);
  }

  /// Inserts a segment boundary at output time [t] (no-op at an existing
  /// boundary, the edges, or when a piece would be shorter than [minSegment]).
  Timeline _splitAt(Duration t) {
    final starts = segmentStarts;
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      final start = starts[i];
      final end = start + s.outputLength;
      if (t > start && t < end) {
        if (t - start < minSegment || end - t < minSegment) return this;
        final (a, b) = s.splitAt(t - start);
        return _copy(segments: [...segments.sublist(0, i), a, b, ...segments.sublist(i + 1)]);
      }
    }
    return this;
  }

  /// Splits at both range ends, then replaces the segments inside the range
  /// with [change]`(inside, outside)`. With [keepInside] the outside segments
  /// are dropped instead (trim).
  Timeline _range(
    int startMs,
    int endMs,
    List<Segment> Function(List<Segment> inside, List<Segment> outside) change, {
    bool keepInside = false,
  }) {
    final total = duration;
    var a = _ms(math.min(startMs, endMs));
    var b = _ms(math.max(startMs, endMs));
    if (a < Duration.zero) a = Duration.zero;
    if (b > total) b = total;
    if (b - a < minSegment) return this;

    final split = _splitAt(a)._splitAt(b);
    final before = <Segment>[], inside = <Segment>[], after = <Segment>[];
    final starts = split.segmentStarts;
    for (var i = 0; i < split.segments.length; i++) {
      final s = split.segments[i];
      final mid = starts[i] + Duration(microseconds: s.outputLength.inMicroseconds ~/ 2);
      (mid < a ? before : (mid < b ? inside : after)).add(s);
    }
    if (inside.isEmpty) return this;
    final changed = change(inside, [...before, ...after]);
    final result = keepInside ? changed : [...before, ...changed, ...after];
    if (result.isEmpty) return this; // never delete everything
    return _copy(segments: result);
  }

  // ------------------------------------------------------------ playback

  /// True when the player can play this edit as clips of the original file.
  /// Everything else (reverse, ramps, merged files, crossfades…) is rendered
  /// with FFmpeg first.
  bool get isLiveCompatible => segments.every((s) => s.isLiveCompatible) && loudnessLufs == null;

  /// The plan the player uses to play this edit live (no export).
  PlaybackPlan toPlan() => PlaybackPlan(
        clips: [
          for (final s in segments)
            PlanClip(
              sourceStart: s.sourceStart,
              sourceEnd: s.sourceEnd,
              speed: s.speed,
              pitchSemitones: s.pitchSemitones,
              gainDb: s.gainDb + masterGainDb,
            ),
        ],
        fadeIn: fadeIn,
        fadeOut: fadeOut,
      );

  bool get isUnedited =>
      segments.length == 1 &&
      segments.first.sourceStart == Duration.zero &&
      !segments.first.isChanged &&
      segments.first.input == null &&
      fadeIn == Duration.zero &&
      fadeOut == Duration.zero &&
      masterGainDb == 0 &&
      loudnessLufs == null;

  @override
  bool operator ==(Object other) =>
      other is Timeline &&
      listEquals(other.segments, segments) &&
      other.fadeIn == fadeIn &&
      other.fadeOut == fadeOut &&
      other.fadeCurve == fadeCurve &&
      other.masterGainDb == masterGainDb &&
      other.loudnessLufs == loudnessLufs;

  @override
  int get hashCode => Object.hash(Object.hashAll(segments), fadeIn, fadeOut, fadeCurve, masterGainDb, loudnessLufs);

  @override
  String toString() => 'Timeline($segments, in=$fadeIn, out=$fadeOut)';
}

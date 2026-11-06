import 'dart:math' as math;

/// One continuous piece of a source file played with fixed settings.
class PlanClip {
  const PlanClip({
    this.sourceStart = Duration.zero,
    this.sourceEnd,
    this.speed = 1.0,
    this.pitchSemitones = 0.0,
    this.gainDb = 0.0,
  });

  /// Where the clip starts in the original file.
  final Duration sourceStart;

  /// Where it ends in the original file; null = until the end of the file.
  final Duration? sourceEnd;

  /// Tempo factor (pitch preserved). 2.0 = twice as fast.
  final double speed;
  final double pitchSemitones;
  final double gainDb;

  bool get isIdentity =>
      sourceStart == Duration.zero && sourceEnd == null && speed == 1 && pitchSemitones == 0 && gainDb == 0;

  /// Source length (null when open-ended).
  Duration? get sourceLength => sourceEnd == null ? null : sourceEnd! - sourceStart;

  /// How long the clip lasts when played (null when open-ended).
  Duration? get outputLength =>
      sourceLength == null ? null : Duration(microseconds: (sourceLength!.inMicroseconds / speed).round());

  @override
  bool operator ==(Object other) =>
      other is PlanClip &&
      other.sourceStart == sourceStart &&
      other.sourceEnd == sourceEnd &&
      other.speed == speed &&
      other.pitchSemitones == pitchSemitones &&
      other.gainDb == gainDb;

  @override
  int get hashCode => Object.hash(sourceStart, sourceEnd, speed, pitchSemitones, gainDb);

  @override
  String toString() => 'PlanClip(${sourceStart.inMilliseconds}-${sourceEnd?.inMilliseconds} '
      'x$speed ${pitchSemitones}st ${gainDb}dB)';
}

/// How the engine plays one track: a list of clips (non-destructive edits),
/// output fades and a track-level gain (loudness normalisation).
///
/// A plain track is a single identity clip. Edited tracks ("live edit
/// presets") become several clips the backend plays gaplessly back to back.
/// All times in the public helpers are *output* times (what the user hears).
class PlaybackPlan {
  const PlaybackPlan({
    this.clips = const [PlanClip()],
    this.fadeIn = Duration.zero,
    this.fadeOut = Duration.zero,
    this.trackGainDb = 0,
    this.renderedFile,
  });

  /// Unedited track, no gain.
  static const plain = PlaybackPlan();

  final List<PlanClip> clips;
  final Duration fadeIn;
  final Duration fadeOut;

  /// Gain for the whole track in dB (ReplayGain / loudness normalisation).
  final double trackGainDb;

  /// Play this file instead of the track's own: a live edit with things the
  /// player can't do on the fly (reverse, ramps, merged songs) is rendered once.
  final String? renderedFile;

  bool get isEdited => clips.length != 1 || !clips.first.isIdentity || fadeIn > Duration.zero || fadeOut > Duration.zero;

  PlaybackPlan withTrackGain(double db) =>
      PlaybackPlan(clips: clips, fadeIn: fadeIn, fadeOut: fadeOut, trackGainDb: db, renderedFile: renderedFile);

  /// Output start of clip [index].
  Duration outputStartOf(int index) {
    var t = Duration.zero;
    for (var i = 0; i < index && i < clips.length; i++) {
      t += clips[i].outputLength ?? Duration.zero;
    }
    return t;
  }

  /// Total output duration; null when the last clip is open-ended and the
  /// file length is unknown. Pass [sourceDuration] to resolve it.
  Duration? outputDuration({Duration? sourceDuration}) {
    var t = Duration.zero;
    for (final c in clips) {
      final len = c.outputLength ??
          (sourceDuration == null
              ? null
              : Duration(microseconds: ((sourceDuration - c.sourceStart).inMicroseconds / c.speed).round()));
      if (len == null) return null;
      t += len;
    }
    return t;
  }

  /// Output time for a position *inside* clip [index] (position relative to
  /// the clip start in source time, which is what the player reports).
  Duration toOutput(int index, Duration inClip) {
    final c = clips[index.clamp(0, clips.length - 1)];
    return outputStartOf(index) + Duration(microseconds: (inClip.inMicroseconds / c.speed).round());
  }

  /// Inverse of [toOutput]: which clip plays at [output] and where inside it
  /// (source time relative to the clip start).
  (int, Duration) locate(Duration output) {
    var start = Duration.zero;
    for (var i = 0; i < clips.length; i++) {
      final len = clips[i].outputLength;
      if (len == null || output < start + len || i == clips.length - 1) {
        final inOut = output - start;
        final inSource = Duration(microseconds: (math.max(0, inOut.inMicroseconds) * clips[i].speed).round());
        final maxIn = clips[i].sourceLength;
        return (i, maxIn != null && inSource > maxIn ? maxIn : inSource);
      }
      start += len;
    }
    return (0, Duration.zero);
  }

  /// 0..1 fade multiplier at [output] (needs the total to place the fade out).
  double fadeFactor(Duration output, Duration? total) {
    var f = 1.0;
    if (fadeIn > Duration.zero && output < fadeIn) {
      f = math.min(f, output.inMicroseconds / fadeIn.inMicroseconds);
    }
    if (fadeOut > Duration.zero && total != null) {
      final remaining = total - output;
      if (remaining < fadeOut) f = math.min(f, math.max(0, remaining.inMicroseconds) / fadeOut.inMicroseconds);
    }
    return f.clamp(0.0, 1.0);
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';

import 'timeline.dart';

part 'edit_decision_list.freezed.dart';
part 'edit_decision_list.g.dart';

/// One editing step. Times are **output** times (milliseconds) on the timeline
/// as it looked when the step was made – exactly what the user selected on the
/// waveform. Ranges are half-open: `[startMs, endMs)`.
///
/// Operations never touch the audio file; they are replayed on top of the
/// original by [Timeline.apply] (playback, preview, export all use that).
@Freezed(unionKey: 'op')
sealed class EditOp with _$EditOp {
  /// Keep only the range, drop everything else.
  const factory EditOp.trim({required int startMs, required int endMs}) = TrimOp;

  /// Remove the range.
  const factory EditOp.cut({required int startMs, required int endMs}) = CutOp;

  /// Split the segment under [atMs] in two (segments can then be edited
  /// separately).
  const factory EditOp.split({required int atMs}) = SplitOp;

  /// Tempo of the range, pitch preserved (0.25..4).
  const factory EditOp.speed({required int startMs, required int endMs, required double factor}) = SpeedOp;

  /// Pitch shift of the range in semitones, tempo preserved (−12..12).
  const factory EditOp.pitch({required int startMs, required int endMs, required double semitones}) = PitchOp;

  /// Volume of the range in dB (−24..+12).
  const factory EditOp.gain({required int startMs, required int endMs, required double db}) = GainOp;

  /// Replace the range with silence, later audio stays where it was.
  const factory EditOp.silence({required int startMs, required int endMs}) = SilenceOp;

  /// Insert a copy of the range right after it.
  const factory EditOp.duplicate({required int startMs, required int endMs}) = DuplicateOp;

  /// Play the range [times] times in a row.
  const factory EditOp.loop({required int startMs, required int endMs, required int times}) = LoopOp;

  /// Move segment [from] to position [to] (indexes at that moment).
  const factory EditOp.move({required int from, required int to}) = MoveOp;

  /// Add another song at the end.
  const factory EditOp.merge({required String uri, required int durationMs}) = MergeOp;

  /// Tempo glides across the range, pitch preserved.
  const factory EditOp.ramp({required int startMs, required int endMs, required double from, required double to}) = RampOp;

  /// Play the range backwards.
  const factory EditOp.reverse({required int startMs, required int endMs}) = ReverseOp;

  /// Fades at the edges of the range. [curve] is a `FadeCurve` name.
  const factory EditOp.segmentFade({
    required int startMs,
    required int endMs,
    required int inMs,
    required int outMs,
    @Default('linear') String curve,
  }) = SegmentFadeOp;

  /// Overlap segment [segment] with the next one.
  const factory EditOp.crossfade({required int segment, required int ms, @Default('linear') String curve}) = CrossfadeOp;

  /// Simple three-band EQ on the range.
  const factory EditOp.segmentEq({
    required int startMs,
    required int endMs,
    required double lowDb,
    required double midDb,
    required double highDb,
  }) = SegmentEqOp;

  /// Noise gate on the range; null [db] turns it off.
  const factory EditOp.gate({required int startMs, required int endMs, double? db}) = GateOp;

  /// Curve of the start and end fades.
  const factory EditOp.fadeCurve({required String curve}) = FadeCurveOp;

  /// Gain over the whole edit.
  const factory EditOp.masterGain({required double db}) = MasterGainOp;

  /// Match a loudness target; null turns it off.
  const factory EditOp.loudness({double? lufs}) = LoudnessOp;

  /// Several steps that undo as one.
  const factory EditOp.batch({required List<EditOp> ops}) = BatchOp;

  /// Fade in from silence at the start of the edit.
  const factory EditOp.fadeIn({required int durationMs}) = FadeInOp;

  /// Fade out to silence at the end of the edit.
  const factory EditOp.fadeOut({required int durationMs}) = FadeOutOp;

  factory EditOp.fromJson(Map<String, dynamic> json) => _$EditOpFromJson(json);
}

/// The stored edit: source file + ordered list of operations, plus where the
/// user was (redo steps, cursor, zoom), so a session continues where it stopped.
@freezed
abstract class EditDecisionList with _$EditDecisionList {
  const EditDecisionList._();

  const factory EditDecisionList({
    @Default(1) int version,
    required String sourceUri,
    required int sourceDurationMs,
    @Default([]) List<EditOp> ops,
    @Default([]) List<EditOp> redoOps,
    @Default(0) int cursorMs,
    @Default(0) int viewStartMs,
    @Default(0) int viewLengthMs,
  }) = _EditDecisionList;

  factory EditDecisionList.fromJson(Map<String, dynamic> json) => _$EditDecisionListFromJson(json);

  Duration get sourceDuration => Duration(milliseconds: sourceDurationMs);

  /// Replays every operation on the untouched source.
  Timeline build() => Timeline.fromOps(sourceDuration, ops);
}

/// Undo/redo over a list of operations: `ops[0, cursor)` are applied, the
/// rest can be redone until a new operation is pushed.
@immutable
class EditHistory {
  const EditHistory({this.ops = const [], this.cursor = 0});

  factory EditHistory.of(List<EditOp> applied) => EditHistory(ops: List.unmodifiable(applied), cursor: applied.length);

  final List<EditOp> ops;
  final int cursor;

  List<EditOp> get applied => ops.sublist(0, cursor);
  bool get canUndo => cursor > 0;
  bool get canRedo => cursor < ops.length;

  /// Adds [op] after the cursor and drops anything that could be redone.
  EditHistory push(EditOp op) => EditHistory(ops: List.unmodifiable([...applied, op]), cursor: cursor + 1);

  EditHistory undo() => canUndo ? EditHistory(ops: ops, cursor: cursor - 1) : this;
  EditHistory redo() => canRedo ? EditHistory(ops: ops, cursor: cursor + 1) : this;
}

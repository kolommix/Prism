// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_decision_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TrimOp _$TrimOpFromJson(Map<String, dynamic> json) => TrimOp(
  startMs: (json['startMs'] as num).toInt(),
  endMs: (json['endMs'] as num).toInt(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$TrimOpToJson(TrimOp instance) => <String, dynamic>{
  'startMs': instance.startMs,
  'endMs': instance.endMs,
  'op': instance.$type,
};

CutOp _$CutOpFromJson(Map<String, dynamic> json) => CutOp(
  startMs: (json['startMs'] as num).toInt(),
  endMs: (json['endMs'] as num).toInt(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$CutOpToJson(CutOp instance) => <String, dynamic>{
  'startMs': instance.startMs,
  'endMs': instance.endMs,
  'op': instance.$type,
};

SplitOp _$SplitOpFromJson(Map<String, dynamic> json) =>
    SplitOp(atMs: (json['atMs'] as num).toInt(), $type: json['op'] as String?);

Map<String, dynamic> _$SplitOpToJson(SplitOp instance) => <String, dynamic>{
  'atMs': instance.atMs,
  'op': instance.$type,
};

SpeedOp _$SpeedOpFromJson(Map<String, dynamic> json) => SpeedOp(
  startMs: (json['startMs'] as num).toInt(),
  endMs: (json['endMs'] as num).toInt(),
  factor: (json['factor'] as num).toDouble(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$SpeedOpToJson(SpeedOp instance) => <String, dynamic>{
  'startMs': instance.startMs,
  'endMs': instance.endMs,
  'factor': instance.factor,
  'op': instance.$type,
};

PitchOp _$PitchOpFromJson(Map<String, dynamic> json) => PitchOp(
  startMs: (json['startMs'] as num).toInt(),
  endMs: (json['endMs'] as num).toInt(),
  semitones: (json['semitones'] as num).toDouble(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$PitchOpToJson(PitchOp instance) => <String, dynamic>{
  'startMs': instance.startMs,
  'endMs': instance.endMs,
  'semitones': instance.semitones,
  'op': instance.$type,
};

GainOp _$GainOpFromJson(Map<String, dynamic> json) => GainOp(
  startMs: (json['startMs'] as num).toInt(),
  endMs: (json['endMs'] as num).toInt(),
  db: (json['db'] as num).toDouble(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$GainOpToJson(GainOp instance) => <String, dynamic>{
  'startMs': instance.startMs,
  'endMs': instance.endMs,
  'db': instance.db,
  'op': instance.$type,
};

SilenceOp _$SilenceOpFromJson(Map<String, dynamic> json) => SilenceOp(
  startMs: (json['startMs'] as num).toInt(),
  endMs: (json['endMs'] as num).toInt(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$SilenceOpToJson(SilenceOp instance) => <String, dynamic>{
  'startMs': instance.startMs,
  'endMs': instance.endMs,
  'op': instance.$type,
};

DuplicateOp _$DuplicateOpFromJson(Map<String, dynamic> json) => DuplicateOp(
  startMs: (json['startMs'] as num).toInt(),
  endMs: (json['endMs'] as num).toInt(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$DuplicateOpToJson(DuplicateOp instance) =>
    <String, dynamic>{
      'startMs': instance.startMs,
      'endMs': instance.endMs,
      'op': instance.$type,
    };

LoopOp _$LoopOpFromJson(Map<String, dynamic> json) => LoopOp(
  startMs: (json['startMs'] as num).toInt(),
  endMs: (json['endMs'] as num).toInt(),
  times: (json['times'] as num).toInt(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$LoopOpToJson(LoopOp instance) => <String, dynamic>{
  'startMs': instance.startMs,
  'endMs': instance.endMs,
  'times': instance.times,
  'op': instance.$type,
};

MoveOp _$MoveOpFromJson(Map<String, dynamic> json) => MoveOp(
  from: (json['from'] as num).toInt(),
  to: (json['to'] as num).toInt(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$MoveOpToJson(MoveOp instance) => <String, dynamic>{
  'from': instance.from,
  'to': instance.to,
  'op': instance.$type,
};

MergeOp _$MergeOpFromJson(Map<String, dynamic> json) => MergeOp(
  uri: json['uri'] as String,
  durationMs: (json['durationMs'] as num).toInt(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$MergeOpToJson(MergeOp instance) => <String, dynamic>{
  'uri': instance.uri,
  'durationMs': instance.durationMs,
  'op': instance.$type,
};

RampOp _$RampOpFromJson(Map<String, dynamic> json) => RampOp(
  startMs: (json['startMs'] as num).toInt(),
  endMs: (json['endMs'] as num).toInt(),
  from: (json['from'] as num).toDouble(),
  to: (json['to'] as num).toDouble(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$RampOpToJson(RampOp instance) => <String, dynamic>{
  'startMs': instance.startMs,
  'endMs': instance.endMs,
  'from': instance.from,
  'to': instance.to,
  'op': instance.$type,
};

ReverseOp _$ReverseOpFromJson(Map<String, dynamic> json) => ReverseOp(
  startMs: (json['startMs'] as num).toInt(),
  endMs: (json['endMs'] as num).toInt(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$ReverseOpToJson(ReverseOp instance) => <String, dynamic>{
  'startMs': instance.startMs,
  'endMs': instance.endMs,
  'op': instance.$type,
};

SegmentFadeOp _$SegmentFadeOpFromJson(Map<String, dynamic> json) =>
    SegmentFadeOp(
      startMs: (json['startMs'] as num).toInt(),
      endMs: (json['endMs'] as num).toInt(),
      inMs: (json['inMs'] as num).toInt(),
      outMs: (json['outMs'] as num).toInt(),
      curve: json['curve'] as String? ?? 'linear',
      $type: json['op'] as String?,
    );

Map<String, dynamic> _$SegmentFadeOpToJson(SegmentFadeOp instance) =>
    <String, dynamic>{
      'startMs': instance.startMs,
      'endMs': instance.endMs,
      'inMs': instance.inMs,
      'outMs': instance.outMs,
      'curve': instance.curve,
      'op': instance.$type,
    };

CrossfadeOp _$CrossfadeOpFromJson(Map<String, dynamic> json) => CrossfadeOp(
  segment: (json['segment'] as num).toInt(),
  ms: (json['ms'] as num).toInt(),
  curve: json['curve'] as String? ?? 'linear',
  $type: json['op'] as String?,
);

Map<String, dynamic> _$CrossfadeOpToJson(CrossfadeOp instance) =>
    <String, dynamic>{
      'segment': instance.segment,
      'ms': instance.ms,
      'curve': instance.curve,
      'op': instance.$type,
    };

SegmentEqOp _$SegmentEqOpFromJson(Map<String, dynamic> json) => SegmentEqOp(
  startMs: (json['startMs'] as num).toInt(),
  endMs: (json['endMs'] as num).toInt(),
  lowDb: (json['lowDb'] as num).toDouble(),
  midDb: (json['midDb'] as num).toDouble(),
  highDb: (json['highDb'] as num).toDouble(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$SegmentEqOpToJson(SegmentEqOp instance) =>
    <String, dynamic>{
      'startMs': instance.startMs,
      'endMs': instance.endMs,
      'lowDb': instance.lowDb,
      'midDb': instance.midDb,
      'highDb': instance.highDb,
      'op': instance.$type,
    };

GateOp _$GateOpFromJson(Map<String, dynamic> json) => GateOp(
  startMs: (json['startMs'] as num).toInt(),
  endMs: (json['endMs'] as num).toInt(),
  db: (json['db'] as num?)?.toDouble(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$GateOpToJson(GateOp instance) => <String, dynamic>{
  'startMs': instance.startMs,
  'endMs': instance.endMs,
  'db': instance.db,
  'op': instance.$type,
};

FadeCurveOp _$FadeCurveOpFromJson(Map<String, dynamic> json) =>
    FadeCurveOp(curve: json['curve'] as String, $type: json['op'] as String?);

Map<String, dynamic> _$FadeCurveOpToJson(FadeCurveOp instance) =>
    <String, dynamic>{'curve': instance.curve, 'op': instance.$type};

MasterGainOp _$MasterGainOpFromJson(Map<String, dynamic> json) => MasterGainOp(
  db: (json['db'] as num).toDouble(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$MasterGainOpToJson(MasterGainOp instance) =>
    <String, dynamic>{'db': instance.db, 'op': instance.$type};

LoudnessOp _$LoudnessOpFromJson(Map<String, dynamic> json) => LoudnessOp(
  lufs: (json['lufs'] as num?)?.toDouble(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$LoudnessOpToJson(LoudnessOp instance) =>
    <String, dynamic>{'lufs': instance.lufs, 'op': instance.$type};

BatchOp _$BatchOpFromJson(Map<String, dynamic> json) => BatchOp(
  ops: (json['ops'] as List<dynamic>)
      .map((e) => EditOp.fromJson(e as Map<String, dynamic>))
      .toList(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$BatchOpToJson(BatchOp instance) => <String, dynamic>{
  'ops': instance.ops.map((e) => e.toJson()).toList(),
  'op': instance.$type,
};

FadeInOp _$FadeInOpFromJson(Map<String, dynamic> json) => FadeInOp(
  durationMs: (json['durationMs'] as num).toInt(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$FadeInOpToJson(FadeInOp instance) => <String, dynamic>{
  'durationMs': instance.durationMs,
  'op': instance.$type,
};

FadeOutOp _$FadeOutOpFromJson(Map<String, dynamic> json) => FadeOutOp(
  durationMs: (json['durationMs'] as num).toInt(),
  $type: json['op'] as String?,
);

Map<String, dynamic> _$FadeOutOpToJson(FadeOutOp instance) => <String, dynamic>{
  'durationMs': instance.durationMs,
  'op': instance.$type,
};

_EditDecisionList _$EditDecisionListFromJson(Map<String, dynamic> json) =>
    _EditDecisionList(
      version: (json['version'] as num?)?.toInt() ?? 1,
      sourceUri: json['sourceUri'] as String,
      sourceDurationMs: (json['sourceDurationMs'] as num).toInt(),
      ops:
          (json['ops'] as List<dynamic>?)
              ?.map((e) => EditOp.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      redoOps:
          (json['redoOps'] as List<dynamic>?)
              ?.map((e) => EditOp.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      cursorMs: (json['cursorMs'] as num?)?.toInt() ?? 0,
      viewStartMs: (json['viewStartMs'] as num?)?.toInt() ?? 0,
      viewLengthMs: (json['viewLengthMs'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$EditDecisionListToJson(_EditDecisionList instance) =>
    <String, dynamic>{
      'version': instance.version,
      'sourceUri': instance.sourceUri,
      'sourceDurationMs': instance.sourceDurationMs,
      'ops': instance.ops.map((e) => e.toJson()).toList(),
      'redoOps': instance.redoOps.map((e) => e.toJson()).toList(),
      'cursorMs': instance.cursorMs,
      'viewStartMs': instance.viewStartMs,
      'viewLengthMs': instance.viewLengthMs,
    };

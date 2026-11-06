// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'edit_decision_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
EditOp _$EditOpFromJson(
  Map<String, dynamic> json
) {
        switch (json['op']) {
                  case 'trim':
          return TrimOp.fromJson(
            json
          );
                case 'cut':
          return CutOp.fromJson(
            json
          );
                case 'split':
          return SplitOp.fromJson(
            json
          );
                case 'speed':
          return SpeedOp.fromJson(
            json
          );
                case 'pitch':
          return PitchOp.fromJson(
            json
          );
                case 'gain':
          return GainOp.fromJson(
            json
          );
                case 'silence':
          return SilenceOp.fromJson(
            json
          );
                case 'duplicate':
          return DuplicateOp.fromJson(
            json
          );
                case 'loop':
          return LoopOp.fromJson(
            json
          );
                case 'move':
          return MoveOp.fromJson(
            json
          );
                case 'merge':
          return MergeOp.fromJson(
            json
          );
                case 'ramp':
          return RampOp.fromJson(
            json
          );
                case 'reverse':
          return ReverseOp.fromJson(
            json
          );
                case 'segmentFade':
          return SegmentFadeOp.fromJson(
            json
          );
                case 'crossfade':
          return CrossfadeOp.fromJson(
            json
          );
                case 'segmentEq':
          return SegmentEqOp.fromJson(
            json
          );
                case 'gate':
          return GateOp.fromJson(
            json
          );
                case 'fadeCurve':
          return FadeCurveOp.fromJson(
            json
          );
                case 'masterGain':
          return MasterGainOp.fromJson(
            json
          );
                case 'loudness':
          return LoudnessOp.fromJson(
            json
          );
                case 'batch':
          return BatchOp.fromJson(
            json
          );
                case 'fadeIn':
          return FadeInOp.fromJson(
            json
          );
                case 'fadeOut':
          return FadeOutOp.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'op',
  'EditOp',
  'Invalid union type "${json['op']}"!'
);
        }
      
}

/// @nodoc
mixin _$EditOp {



  /// Serializes this EditOp to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is EditOp);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'EditOp()';
}


}

/// @nodoc
class $EditOpCopyWith<$Res>  {
$EditOpCopyWith(EditOp _, $Res Function(EditOp) __);
}


/// Adds pattern-matching-related methods to [EditOp].
extension EditOpPatterns on EditOp {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TrimOp value)?  trim,TResult Function( CutOp value)?  cut,TResult Function( SplitOp value)?  split,TResult Function( SpeedOp value)?  speed,TResult Function( PitchOp value)?  pitch,TResult Function( GainOp value)?  gain,TResult Function( SilenceOp value)?  silence,TResult Function( DuplicateOp value)?  duplicate,TResult Function( LoopOp value)?  loop,TResult Function( MoveOp value)?  move,TResult Function( MergeOp value)?  merge,TResult Function( RampOp value)?  ramp,TResult Function( ReverseOp value)?  reverse,TResult Function( SegmentFadeOp value)?  segmentFade,TResult Function( CrossfadeOp value)?  crossfade,TResult Function( SegmentEqOp value)?  segmentEq,TResult Function( GateOp value)?  gate,TResult Function( FadeCurveOp value)?  fadeCurve,TResult Function( MasterGainOp value)?  masterGain,TResult Function( LoudnessOp value)?  loudness,TResult Function( BatchOp value)?  batch,TResult Function( FadeInOp value)?  fadeIn,TResult Function( FadeOutOp value)?  fadeOut,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TrimOp() when trim != null:
return trim(_that);case CutOp() when cut != null:
return cut(_that);case SplitOp() when split != null:
return split(_that);case SpeedOp() when speed != null:
return speed(_that);case PitchOp() when pitch != null:
return pitch(_that);case GainOp() when gain != null:
return gain(_that);case SilenceOp() when silence != null:
return silence(_that);case DuplicateOp() when duplicate != null:
return duplicate(_that);case LoopOp() when loop != null:
return loop(_that);case MoveOp() when move != null:
return move(_that);case MergeOp() when merge != null:
return merge(_that);case RampOp() when ramp != null:
return ramp(_that);case ReverseOp() when reverse != null:
return reverse(_that);case SegmentFadeOp() when segmentFade != null:
return segmentFade(_that);case CrossfadeOp() when crossfade != null:
return crossfade(_that);case SegmentEqOp() when segmentEq != null:
return segmentEq(_that);case GateOp() when gate != null:
return gate(_that);case FadeCurveOp() when fadeCurve != null:
return fadeCurve(_that);case MasterGainOp() when masterGain != null:
return masterGain(_that);case LoudnessOp() when loudness != null:
return loudness(_that);case BatchOp() when batch != null:
return batch(_that);case FadeInOp() when fadeIn != null:
return fadeIn(_that);case FadeOutOp() when fadeOut != null:
return fadeOut(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TrimOp value)  trim,required TResult Function( CutOp value)  cut,required TResult Function( SplitOp value)  split,required TResult Function( SpeedOp value)  speed,required TResult Function( PitchOp value)  pitch,required TResult Function( GainOp value)  gain,required TResult Function( SilenceOp value)  silence,required TResult Function( DuplicateOp value)  duplicate,required TResult Function( LoopOp value)  loop,required TResult Function( MoveOp value)  move,required TResult Function( MergeOp value)  merge,required TResult Function( RampOp value)  ramp,required TResult Function( ReverseOp value)  reverse,required TResult Function( SegmentFadeOp value)  segmentFade,required TResult Function( CrossfadeOp value)  crossfade,required TResult Function( SegmentEqOp value)  segmentEq,required TResult Function( GateOp value)  gate,required TResult Function( FadeCurveOp value)  fadeCurve,required TResult Function( MasterGainOp value)  masterGain,required TResult Function( LoudnessOp value)  loudness,required TResult Function( BatchOp value)  batch,required TResult Function( FadeInOp value)  fadeIn,required TResult Function( FadeOutOp value)  fadeOut,}){
final _that = this;
switch (_that) {
case TrimOp():
return trim(_that);case CutOp():
return cut(_that);case SplitOp():
return split(_that);case SpeedOp():
return speed(_that);case PitchOp():
return pitch(_that);case GainOp():
return gain(_that);case SilenceOp():
return silence(_that);case DuplicateOp():
return duplicate(_that);case LoopOp():
return loop(_that);case MoveOp():
return move(_that);case MergeOp():
return merge(_that);case RampOp():
return ramp(_that);case ReverseOp():
return reverse(_that);case SegmentFadeOp():
return segmentFade(_that);case CrossfadeOp():
return crossfade(_that);case SegmentEqOp():
return segmentEq(_that);case GateOp():
return gate(_that);case FadeCurveOp():
return fadeCurve(_that);case MasterGainOp():
return masterGain(_that);case LoudnessOp():
return loudness(_that);case BatchOp():
return batch(_that);case FadeInOp():
return fadeIn(_that);case FadeOutOp():
return fadeOut(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TrimOp value)?  trim,TResult? Function( CutOp value)?  cut,TResult? Function( SplitOp value)?  split,TResult? Function( SpeedOp value)?  speed,TResult? Function( PitchOp value)?  pitch,TResult? Function( GainOp value)?  gain,TResult? Function( SilenceOp value)?  silence,TResult? Function( DuplicateOp value)?  duplicate,TResult? Function( LoopOp value)?  loop,TResult? Function( MoveOp value)?  move,TResult? Function( MergeOp value)?  merge,TResult? Function( RampOp value)?  ramp,TResult? Function( ReverseOp value)?  reverse,TResult? Function( SegmentFadeOp value)?  segmentFade,TResult? Function( CrossfadeOp value)?  crossfade,TResult? Function( SegmentEqOp value)?  segmentEq,TResult? Function( GateOp value)?  gate,TResult? Function( FadeCurveOp value)?  fadeCurve,TResult? Function( MasterGainOp value)?  masterGain,TResult? Function( LoudnessOp value)?  loudness,TResult? Function( BatchOp value)?  batch,TResult? Function( FadeInOp value)?  fadeIn,TResult? Function( FadeOutOp value)?  fadeOut,}){
final _that = this;
switch (_that) {
case TrimOp() when trim != null:
return trim(_that);case CutOp() when cut != null:
return cut(_that);case SplitOp() when split != null:
return split(_that);case SpeedOp() when speed != null:
return speed(_that);case PitchOp() when pitch != null:
return pitch(_that);case GainOp() when gain != null:
return gain(_that);case SilenceOp() when silence != null:
return silence(_that);case DuplicateOp() when duplicate != null:
return duplicate(_that);case LoopOp() when loop != null:
return loop(_that);case MoveOp() when move != null:
return move(_that);case MergeOp() when merge != null:
return merge(_that);case RampOp() when ramp != null:
return ramp(_that);case ReverseOp() when reverse != null:
return reverse(_that);case SegmentFadeOp() when segmentFade != null:
return segmentFade(_that);case CrossfadeOp() when crossfade != null:
return crossfade(_that);case SegmentEqOp() when segmentEq != null:
return segmentEq(_that);case GateOp() when gate != null:
return gate(_that);case FadeCurveOp() when fadeCurve != null:
return fadeCurve(_that);case MasterGainOp() when masterGain != null:
return masterGain(_that);case LoudnessOp() when loudness != null:
return loudness(_that);case BatchOp() when batch != null:
return batch(_that);case FadeInOp() when fadeIn != null:
return fadeIn(_that);case FadeOutOp() when fadeOut != null:
return fadeOut(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int startMs,  int endMs)?  trim,TResult Function( int startMs,  int endMs)?  cut,TResult Function( int atMs)?  split,TResult Function( int startMs,  int endMs,  double factor)?  speed,TResult Function( int startMs,  int endMs,  double semitones)?  pitch,TResult Function( int startMs,  int endMs,  double db)?  gain,TResult Function( int startMs,  int endMs)?  silence,TResult Function( int startMs,  int endMs)?  duplicate,TResult Function( int startMs,  int endMs,  int times)?  loop,TResult Function( int from,  int to)?  move,TResult Function( String uri,  int durationMs)?  merge,TResult Function( int startMs,  int endMs,  double from,  double to)?  ramp,TResult Function( int startMs,  int endMs)?  reverse,TResult Function( int startMs,  int endMs,  int inMs,  int outMs,  String curve)?  segmentFade,TResult Function( int segment,  int ms,  String curve)?  crossfade,TResult Function( int startMs,  int endMs,  double lowDb,  double midDb,  double highDb)?  segmentEq,TResult Function( int startMs,  int endMs,  double? db)?  gate,TResult Function( String curve)?  fadeCurve,TResult Function( double db)?  masterGain,TResult Function( double? lufs)?  loudness,TResult Function( List<EditOp> ops)?  batch,TResult Function( int durationMs)?  fadeIn,TResult Function( int durationMs)?  fadeOut,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TrimOp() when trim != null:
return trim(_that.startMs,_that.endMs);case CutOp() when cut != null:
return cut(_that.startMs,_that.endMs);case SplitOp() when split != null:
return split(_that.atMs);case SpeedOp() when speed != null:
return speed(_that.startMs,_that.endMs,_that.factor);case PitchOp() when pitch != null:
return pitch(_that.startMs,_that.endMs,_that.semitones);case GainOp() when gain != null:
return gain(_that.startMs,_that.endMs,_that.db);case SilenceOp() when silence != null:
return silence(_that.startMs,_that.endMs);case DuplicateOp() when duplicate != null:
return duplicate(_that.startMs,_that.endMs);case LoopOp() when loop != null:
return loop(_that.startMs,_that.endMs,_that.times);case MoveOp() when move != null:
return move(_that.from,_that.to);case MergeOp() when merge != null:
return merge(_that.uri,_that.durationMs);case RampOp() when ramp != null:
return ramp(_that.startMs,_that.endMs,_that.from,_that.to);case ReverseOp() when reverse != null:
return reverse(_that.startMs,_that.endMs);case SegmentFadeOp() when segmentFade != null:
return segmentFade(_that.startMs,_that.endMs,_that.inMs,_that.outMs,_that.curve);case CrossfadeOp() when crossfade != null:
return crossfade(_that.segment,_that.ms,_that.curve);case SegmentEqOp() when segmentEq != null:
return segmentEq(_that.startMs,_that.endMs,_that.lowDb,_that.midDb,_that.highDb);case GateOp() when gate != null:
return gate(_that.startMs,_that.endMs,_that.db);case FadeCurveOp() when fadeCurve != null:
return fadeCurve(_that.curve);case MasterGainOp() when masterGain != null:
return masterGain(_that.db);case LoudnessOp() when loudness != null:
return loudness(_that.lufs);case BatchOp() when batch != null:
return batch(_that.ops);case FadeInOp() when fadeIn != null:
return fadeIn(_that.durationMs);case FadeOutOp() when fadeOut != null:
return fadeOut(_that.durationMs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int startMs,  int endMs)  trim,required TResult Function( int startMs,  int endMs)  cut,required TResult Function( int atMs)  split,required TResult Function( int startMs,  int endMs,  double factor)  speed,required TResult Function( int startMs,  int endMs,  double semitones)  pitch,required TResult Function( int startMs,  int endMs,  double db)  gain,required TResult Function( int startMs,  int endMs)  silence,required TResult Function( int startMs,  int endMs)  duplicate,required TResult Function( int startMs,  int endMs,  int times)  loop,required TResult Function( int from,  int to)  move,required TResult Function( String uri,  int durationMs)  merge,required TResult Function( int startMs,  int endMs,  double from,  double to)  ramp,required TResult Function( int startMs,  int endMs)  reverse,required TResult Function( int startMs,  int endMs,  int inMs,  int outMs,  String curve)  segmentFade,required TResult Function( int segment,  int ms,  String curve)  crossfade,required TResult Function( int startMs,  int endMs,  double lowDb,  double midDb,  double highDb)  segmentEq,required TResult Function( int startMs,  int endMs,  double? db)  gate,required TResult Function( String curve)  fadeCurve,required TResult Function( double db)  masterGain,required TResult Function( double? lufs)  loudness,required TResult Function( List<EditOp> ops)  batch,required TResult Function( int durationMs)  fadeIn,required TResult Function( int durationMs)  fadeOut,}) {final _that = this;
switch (_that) {
case TrimOp():
return trim(_that.startMs,_that.endMs);case CutOp():
return cut(_that.startMs,_that.endMs);case SplitOp():
return split(_that.atMs);case SpeedOp():
return speed(_that.startMs,_that.endMs,_that.factor);case PitchOp():
return pitch(_that.startMs,_that.endMs,_that.semitones);case GainOp():
return gain(_that.startMs,_that.endMs,_that.db);case SilenceOp():
return silence(_that.startMs,_that.endMs);case DuplicateOp():
return duplicate(_that.startMs,_that.endMs);case LoopOp():
return loop(_that.startMs,_that.endMs,_that.times);case MoveOp():
return move(_that.from,_that.to);case MergeOp():
return merge(_that.uri,_that.durationMs);case RampOp():
return ramp(_that.startMs,_that.endMs,_that.from,_that.to);case ReverseOp():
return reverse(_that.startMs,_that.endMs);case SegmentFadeOp():
return segmentFade(_that.startMs,_that.endMs,_that.inMs,_that.outMs,_that.curve);case CrossfadeOp():
return crossfade(_that.segment,_that.ms,_that.curve);case SegmentEqOp():
return segmentEq(_that.startMs,_that.endMs,_that.lowDb,_that.midDb,_that.highDb);case GateOp():
return gate(_that.startMs,_that.endMs,_that.db);case FadeCurveOp():
return fadeCurve(_that.curve);case MasterGainOp():
return masterGain(_that.db);case LoudnessOp():
return loudness(_that.lufs);case BatchOp():
return batch(_that.ops);case FadeInOp():
return fadeIn(_that.durationMs);case FadeOutOp():
return fadeOut(_that.durationMs);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int startMs,  int endMs)?  trim,TResult? Function( int startMs,  int endMs)?  cut,TResult? Function( int atMs)?  split,TResult? Function( int startMs,  int endMs,  double factor)?  speed,TResult? Function( int startMs,  int endMs,  double semitones)?  pitch,TResult? Function( int startMs,  int endMs,  double db)?  gain,TResult? Function( int startMs,  int endMs)?  silence,TResult? Function( int startMs,  int endMs)?  duplicate,TResult? Function( int startMs,  int endMs,  int times)?  loop,TResult? Function( int from,  int to)?  move,TResult? Function( String uri,  int durationMs)?  merge,TResult? Function( int startMs,  int endMs,  double from,  double to)?  ramp,TResult? Function( int startMs,  int endMs)?  reverse,TResult? Function( int startMs,  int endMs,  int inMs,  int outMs,  String curve)?  segmentFade,TResult? Function( int segment,  int ms,  String curve)?  crossfade,TResult? Function( int startMs,  int endMs,  double lowDb,  double midDb,  double highDb)?  segmentEq,TResult? Function( int startMs,  int endMs,  double? db)?  gate,TResult? Function( String curve)?  fadeCurve,TResult? Function( double db)?  masterGain,TResult? Function( double? lufs)?  loudness,TResult? Function( List<EditOp> ops)?  batch,TResult? Function( int durationMs)?  fadeIn,TResult? Function( int durationMs)?  fadeOut,}) {final _that = this;
switch (_that) {
case TrimOp() when trim != null:
return trim(_that.startMs,_that.endMs);case CutOp() when cut != null:
return cut(_that.startMs,_that.endMs);case SplitOp() when split != null:
return split(_that.atMs);case SpeedOp() when speed != null:
return speed(_that.startMs,_that.endMs,_that.factor);case PitchOp() when pitch != null:
return pitch(_that.startMs,_that.endMs,_that.semitones);case GainOp() when gain != null:
return gain(_that.startMs,_that.endMs,_that.db);case SilenceOp() when silence != null:
return silence(_that.startMs,_that.endMs);case DuplicateOp() when duplicate != null:
return duplicate(_that.startMs,_that.endMs);case LoopOp() when loop != null:
return loop(_that.startMs,_that.endMs,_that.times);case MoveOp() when move != null:
return move(_that.from,_that.to);case MergeOp() when merge != null:
return merge(_that.uri,_that.durationMs);case RampOp() when ramp != null:
return ramp(_that.startMs,_that.endMs,_that.from,_that.to);case ReverseOp() when reverse != null:
return reverse(_that.startMs,_that.endMs);case SegmentFadeOp() when segmentFade != null:
return segmentFade(_that.startMs,_that.endMs,_that.inMs,_that.outMs,_that.curve);case CrossfadeOp() when crossfade != null:
return crossfade(_that.segment,_that.ms,_that.curve);case SegmentEqOp() when segmentEq != null:
return segmentEq(_that.startMs,_that.endMs,_that.lowDb,_that.midDb,_that.highDb);case GateOp() when gate != null:
return gate(_that.startMs,_that.endMs,_that.db);case FadeCurveOp() when fadeCurve != null:
return fadeCurve(_that.curve);case MasterGainOp() when masterGain != null:
return masterGain(_that.db);case LoudnessOp() when loudness != null:
return loudness(_that.lufs);case BatchOp() when batch != null:
return batch(_that.ops);case FadeInOp() when fadeIn != null:
return fadeIn(_that.durationMs);case FadeOutOp() when fadeOut != null:
return fadeOut(_that.durationMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class TrimOp implements EditOp {
  const TrimOp({required this.startMs, required this.endMs,  String? $type}): $type = $type ?? 'trim';
  factory TrimOp.fromJson(Map<String, dynamic> json) => _$TrimOpFromJson(json);

 final  int startMs;
 final  int endMs;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrimOpCopyWith<TrimOp> get copyWith => _$TrimOpCopyWithImpl<TrimOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrimOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is TrimOp&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startMs,endMs);
}

@override
String toString() {
    return 'EditOp.trim(startMs: $startMs, endMs: $endMs)';
}


}

/// @nodoc
abstract mixin class $TrimOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $TrimOpCopyWith(TrimOp value, $Res Function(TrimOp) _then) = _$TrimOpCopyWithImpl;
@useResult
$Res call({
 int startMs, int endMs
});




}
/// @nodoc
class _$TrimOpCopyWithImpl<$Res>
    implements $TrimOpCopyWith<$Res> {
  _$TrimOpCopyWithImpl(this._self, this._then);

  final TrimOp _self;
  final $Res Function(TrimOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startMs = null,Object? endMs = null,}) {
  return _then(TrimOp(
startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CutOp implements EditOp {
  const CutOp({required this.startMs, required this.endMs,  String? $type}): $type = $type ?? 'cut';
  factory CutOp.fromJson(Map<String, dynamic> json) => _$CutOpFromJson(json);

 final  int startMs;
 final  int endMs;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CutOpCopyWith<CutOp> get copyWith => _$CutOpCopyWithImpl<CutOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CutOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CutOp&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startMs,endMs);
}

@override
String toString() {
    return 'EditOp.cut(startMs: $startMs, endMs: $endMs)';
}


}

/// @nodoc
abstract mixin class $CutOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $CutOpCopyWith(CutOp value, $Res Function(CutOp) _then) = _$CutOpCopyWithImpl;
@useResult
$Res call({
 int startMs, int endMs
});




}
/// @nodoc
class _$CutOpCopyWithImpl<$Res>
    implements $CutOpCopyWith<$Res> {
  _$CutOpCopyWithImpl(this._self, this._then);

  final CutOp _self;
  final $Res Function(CutOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startMs = null,Object? endMs = null,}) {
  return _then(CutOp(
startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SplitOp implements EditOp {
  const SplitOp({required this.atMs,  String? $type}): $type = $type ?? 'split';
  factory SplitOp.fromJson(Map<String, dynamic> json) => _$SplitOpFromJson(json);

 final  int atMs;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SplitOpCopyWith<SplitOp> get copyWith => _$SplitOpCopyWithImpl<SplitOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SplitOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SplitOp&&(identical(other.atMs, atMs) || other.atMs == atMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,atMs);
}

@override
String toString() {
    return 'EditOp.split(atMs: $atMs)';
}


}

/// @nodoc
abstract mixin class $SplitOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $SplitOpCopyWith(SplitOp value, $Res Function(SplitOp) _then) = _$SplitOpCopyWithImpl;
@useResult
$Res call({
 int atMs
});




}
/// @nodoc
class _$SplitOpCopyWithImpl<$Res>
    implements $SplitOpCopyWith<$Res> {
  _$SplitOpCopyWithImpl(this._self, this._then);

  final SplitOp _self;
  final $Res Function(SplitOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? atMs = null,}) {
  return _then(SplitOp(
atMs: null == atMs ? _self.atMs : atMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SpeedOp implements EditOp {
  const SpeedOp({required this.startMs, required this.endMs, required this.factor,  String? $type}): $type = $type ?? 'speed';
  factory SpeedOp.fromJson(Map<String, dynamic> json) => _$SpeedOpFromJson(json);

 final  int startMs;
 final  int endMs;
 final  double factor;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SpeedOpCopyWith<SpeedOp> get copyWith => _$SpeedOpCopyWithImpl<SpeedOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SpeedOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SpeedOp&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs)&&(identical(other.factor, factor) || other.factor == factor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startMs,endMs,factor);
}

@override
String toString() {
    return 'EditOp.speed(startMs: $startMs, endMs: $endMs, factor: $factor)';
}


}

/// @nodoc
abstract mixin class $SpeedOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $SpeedOpCopyWith(SpeedOp value, $Res Function(SpeedOp) _then) = _$SpeedOpCopyWithImpl;
@useResult
$Res call({
 int startMs, int endMs, double factor
});




}
/// @nodoc
class _$SpeedOpCopyWithImpl<$Res>
    implements $SpeedOpCopyWith<$Res> {
  _$SpeedOpCopyWithImpl(this._self, this._then);

  final SpeedOp _self;
  final $Res Function(SpeedOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startMs = null,Object? endMs = null,Object? factor = null,}) {
  return _then(SpeedOp(
startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,factor: null == factor ? _self.factor : factor // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
@JsonSerializable()

class PitchOp implements EditOp {
  const PitchOp({required this.startMs, required this.endMs, required this.semitones,  String? $type}): $type = $type ?? 'pitch';
  factory PitchOp.fromJson(Map<String, dynamic> json) => _$PitchOpFromJson(json);

 final  int startMs;
 final  int endMs;
 final  double semitones;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PitchOpCopyWith<PitchOp> get copyWith => _$PitchOpCopyWithImpl<PitchOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PitchOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PitchOp&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs)&&(identical(other.semitones, semitones) || other.semitones == semitones));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startMs,endMs,semitones);
}

@override
String toString() {
    return 'EditOp.pitch(startMs: $startMs, endMs: $endMs, semitones: $semitones)';
}


}

/// @nodoc
abstract mixin class $PitchOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $PitchOpCopyWith(PitchOp value, $Res Function(PitchOp) _then) = _$PitchOpCopyWithImpl;
@useResult
$Res call({
 int startMs, int endMs, double semitones
});




}
/// @nodoc
class _$PitchOpCopyWithImpl<$Res>
    implements $PitchOpCopyWith<$Res> {
  _$PitchOpCopyWithImpl(this._self, this._then);

  final PitchOp _self;
  final $Res Function(PitchOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startMs = null,Object? endMs = null,Object? semitones = null,}) {
  return _then(PitchOp(
startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,semitones: null == semitones ? _self.semitones : semitones // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
@JsonSerializable()

class GainOp implements EditOp {
  const GainOp({required this.startMs, required this.endMs, required this.db,  String? $type}): $type = $type ?? 'gain';
  factory GainOp.fromJson(Map<String, dynamic> json) => _$GainOpFromJson(json);

 final  int startMs;
 final  int endMs;
 final  double db;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GainOpCopyWith<GainOp> get copyWith => _$GainOpCopyWithImpl<GainOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GainOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GainOp&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs)&&(identical(other.db, db) || other.db == db));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startMs,endMs,db);
}

@override
String toString() {
    return 'EditOp.gain(startMs: $startMs, endMs: $endMs, db: $db)';
}


}

/// @nodoc
abstract mixin class $GainOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $GainOpCopyWith(GainOp value, $Res Function(GainOp) _then) = _$GainOpCopyWithImpl;
@useResult
$Res call({
 int startMs, int endMs, double db
});




}
/// @nodoc
class _$GainOpCopyWithImpl<$Res>
    implements $GainOpCopyWith<$Res> {
  _$GainOpCopyWithImpl(this._self, this._then);

  final GainOp _self;
  final $Res Function(GainOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startMs = null,Object? endMs = null,Object? db = null,}) {
  return _then(GainOp(
startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,db: null == db ? _self.db : db // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SilenceOp implements EditOp {
  const SilenceOp({required this.startMs, required this.endMs,  String? $type}): $type = $type ?? 'silence';
  factory SilenceOp.fromJson(Map<String, dynamic> json) => _$SilenceOpFromJson(json);

 final  int startMs;
 final  int endMs;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SilenceOpCopyWith<SilenceOp> get copyWith => _$SilenceOpCopyWithImpl<SilenceOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SilenceOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SilenceOp&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startMs,endMs);
}

@override
String toString() {
    return 'EditOp.silence(startMs: $startMs, endMs: $endMs)';
}


}

/// @nodoc
abstract mixin class $SilenceOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $SilenceOpCopyWith(SilenceOp value, $Res Function(SilenceOp) _then) = _$SilenceOpCopyWithImpl;
@useResult
$Res call({
 int startMs, int endMs
});




}
/// @nodoc
class _$SilenceOpCopyWithImpl<$Res>
    implements $SilenceOpCopyWith<$Res> {
  _$SilenceOpCopyWithImpl(this._self, this._then);

  final SilenceOp _self;
  final $Res Function(SilenceOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startMs = null,Object? endMs = null,}) {
  return _then(SilenceOp(
startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class DuplicateOp implements EditOp {
  const DuplicateOp({required this.startMs, required this.endMs,  String? $type}): $type = $type ?? 'duplicate';
  factory DuplicateOp.fromJson(Map<String, dynamic> json) => _$DuplicateOpFromJson(json);

 final  int startMs;
 final  int endMs;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DuplicateOpCopyWith<DuplicateOp> get copyWith => _$DuplicateOpCopyWithImpl<DuplicateOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DuplicateOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DuplicateOp&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startMs,endMs);
}

@override
String toString() {
    return 'EditOp.duplicate(startMs: $startMs, endMs: $endMs)';
}


}

/// @nodoc
abstract mixin class $DuplicateOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $DuplicateOpCopyWith(DuplicateOp value, $Res Function(DuplicateOp) _then) = _$DuplicateOpCopyWithImpl;
@useResult
$Res call({
 int startMs, int endMs
});




}
/// @nodoc
class _$DuplicateOpCopyWithImpl<$Res>
    implements $DuplicateOpCopyWith<$Res> {
  _$DuplicateOpCopyWithImpl(this._self, this._then);

  final DuplicateOp _self;
  final $Res Function(DuplicateOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startMs = null,Object? endMs = null,}) {
  return _then(DuplicateOp(
startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class LoopOp implements EditOp {
  const LoopOp({required this.startMs, required this.endMs, required this.times,  String? $type}): $type = $type ?? 'loop';
  factory LoopOp.fromJson(Map<String, dynamic> json) => _$LoopOpFromJson(json);

 final  int startMs;
 final  int endMs;
 final  int times;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoopOpCopyWith<LoopOp> get copyWith => _$LoopOpCopyWithImpl<LoopOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LoopOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LoopOp&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs)&&(identical(other.times, times) || other.times == times));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startMs,endMs,times);
}

@override
String toString() {
    return 'EditOp.loop(startMs: $startMs, endMs: $endMs, times: $times)';
}


}

/// @nodoc
abstract mixin class $LoopOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $LoopOpCopyWith(LoopOp value, $Res Function(LoopOp) _then) = _$LoopOpCopyWithImpl;
@useResult
$Res call({
 int startMs, int endMs, int times
});




}
/// @nodoc
class _$LoopOpCopyWithImpl<$Res>
    implements $LoopOpCopyWith<$Res> {
  _$LoopOpCopyWithImpl(this._self, this._then);

  final LoopOp _self;
  final $Res Function(LoopOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startMs = null,Object? endMs = null,Object? times = null,}) {
  return _then(LoopOp(
startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,times: null == times ? _self.times : times // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class MoveOp implements EditOp {
  const MoveOp({required this.from, required this.to,  String? $type}): $type = $type ?? 'move';
  factory MoveOp.fromJson(Map<String, dynamic> json) => _$MoveOpFromJson(json);

 final  int from;
 final  int to;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoveOpCopyWith<MoveOp> get copyWith => _$MoveOpCopyWithImpl<MoveOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MoveOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MoveOp&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,from,to);
}

@override
String toString() {
    return 'EditOp.move(from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class $MoveOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $MoveOpCopyWith(MoveOp value, $Res Function(MoveOp) _then) = _$MoveOpCopyWithImpl;
@useResult
$Res call({
 int from, int to
});




}
/// @nodoc
class _$MoveOpCopyWithImpl<$Res>
    implements $MoveOpCopyWith<$Res> {
  _$MoveOpCopyWithImpl(this._self, this._then);

  final MoveOp _self;
  final $Res Function(MoveOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,}) {
  return _then(MoveOp(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as int,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class MergeOp implements EditOp {
  const MergeOp({required this.uri, required this.durationMs,  String? $type}): $type = $type ?? 'merge';
  factory MergeOp.fromJson(Map<String, dynamic> json) => _$MergeOpFromJson(json);

 final  String uri;
 final  int durationMs;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MergeOpCopyWith<MergeOp> get copyWith => _$MergeOpCopyWithImpl<MergeOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MergeOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MergeOp&&(identical(other.uri, uri) || other.uri == uri)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,uri,durationMs);
}

@override
String toString() {
    return 'EditOp.merge(uri: $uri, durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class $MergeOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $MergeOpCopyWith(MergeOp value, $Res Function(MergeOp) _then) = _$MergeOpCopyWithImpl;
@useResult
$Res call({
 String uri, int durationMs
});




}
/// @nodoc
class _$MergeOpCopyWithImpl<$Res>
    implements $MergeOpCopyWith<$Res> {
  _$MergeOpCopyWithImpl(this._self, this._then);

  final MergeOp _self;
  final $Res Function(MergeOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? uri = null,Object? durationMs = null,}) {
  return _then(MergeOp(
uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class RampOp implements EditOp {
  const RampOp({required this.startMs, required this.endMs, required this.from, required this.to,  String? $type}): $type = $type ?? 'ramp';
  factory RampOp.fromJson(Map<String, dynamic> json) => _$RampOpFromJson(json);

 final  int startMs;
 final  int endMs;
 final  double from;
 final  double to;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RampOpCopyWith<RampOp> get copyWith => _$RampOpCopyWithImpl<RampOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RampOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RampOp&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs)&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startMs,endMs,from,to);
}

@override
String toString() {
    return 'EditOp.ramp(startMs: $startMs, endMs: $endMs, from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class $RampOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $RampOpCopyWith(RampOp value, $Res Function(RampOp) _then) = _$RampOpCopyWithImpl;
@useResult
$Res call({
 int startMs, int endMs, double from, double to
});




}
/// @nodoc
class _$RampOpCopyWithImpl<$Res>
    implements $RampOpCopyWith<$Res> {
  _$RampOpCopyWithImpl(this._self, this._then);

  final RampOp _self;
  final $Res Function(RampOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startMs = null,Object? endMs = null,Object? from = null,Object? to = null,}) {
  return _then(RampOp(
startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as double,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ReverseOp implements EditOp {
  const ReverseOp({required this.startMs, required this.endMs,  String? $type}): $type = $type ?? 'reverse';
  factory ReverseOp.fromJson(Map<String, dynamic> json) => _$ReverseOpFromJson(json);

 final  int startMs;
 final  int endMs;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReverseOpCopyWith<ReverseOp> get copyWith => _$ReverseOpCopyWithImpl<ReverseOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReverseOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ReverseOp&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startMs,endMs);
}

@override
String toString() {
    return 'EditOp.reverse(startMs: $startMs, endMs: $endMs)';
}


}

/// @nodoc
abstract mixin class $ReverseOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $ReverseOpCopyWith(ReverseOp value, $Res Function(ReverseOp) _then) = _$ReverseOpCopyWithImpl;
@useResult
$Res call({
 int startMs, int endMs
});




}
/// @nodoc
class _$ReverseOpCopyWithImpl<$Res>
    implements $ReverseOpCopyWith<$Res> {
  _$ReverseOpCopyWithImpl(this._self, this._then);

  final ReverseOp _self;
  final $Res Function(ReverseOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startMs = null,Object? endMs = null,}) {
  return _then(ReverseOp(
startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SegmentFadeOp implements EditOp {
  const SegmentFadeOp({required this.startMs, required this.endMs, required this.inMs, required this.outMs, this.curve = 'linear',  String? $type}): $type = $type ?? 'segmentFade';
  factory SegmentFadeOp.fromJson(Map<String, dynamic> json) => _$SegmentFadeOpFromJson(json);

 final  int startMs;
 final  int endMs;
 final  int inMs;
 final  int outMs;
@JsonKey() final  String curve;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SegmentFadeOpCopyWith<SegmentFadeOp> get copyWith => _$SegmentFadeOpCopyWithImpl<SegmentFadeOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SegmentFadeOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SegmentFadeOp&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs)&&(identical(other.inMs, inMs) || other.inMs == inMs)&&(identical(other.outMs, outMs) || other.outMs == outMs)&&(identical(other.curve, curve) || other.curve == curve));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startMs,endMs,inMs,outMs,curve);
}

@override
String toString() {
    return 'EditOp.segmentFade(startMs: $startMs, endMs: $endMs, inMs: $inMs, outMs: $outMs, curve: $curve)';
}


}

/// @nodoc
abstract mixin class $SegmentFadeOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $SegmentFadeOpCopyWith(SegmentFadeOp value, $Res Function(SegmentFadeOp) _then) = _$SegmentFadeOpCopyWithImpl;
@useResult
$Res call({
 int startMs, int endMs, int inMs, int outMs, String curve
});




}
/// @nodoc
class _$SegmentFadeOpCopyWithImpl<$Res>
    implements $SegmentFadeOpCopyWith<$Res> {
  _$SegmentFadeOpCopyWithImpl(this._self, this._then);

  final SegmentFadeOp _self;
  final $Res Function(SegmentFadeOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startMs = null,Object? endMs = null,Object? inMs = null,Object? outMs = null,Object? curve = null,}) {
  return _then(SegmentFadeOp(
startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,inMs: null == inMs ? _self.inMs : inMs // ignore: cast_nullable_to_non_nullable
as int,outMs: null == outMs ? _self.outMs : outMs // ignore: cast_nullable_to_non_nullable
as int,curve: null == curve ? _self.curve : curve // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class CrossfadeOp implements EditOp {
  const CrossfadeOp({required this.segment, required this.ms, this.curve = 'linear',  String? $type}): $type = $type ?? 'crossfade';
  factory CrossfadeOp.fromJson(Map<String, dynamic> json) => _$CrossfadeOpFromJson(json);

 final  int segment;
 final  int ms;
@JsonKey() final  String curve;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CrossfadeOpCopyWith<CrossfadeOp> get copyWith => _$CrossfadeOpCopyWithImpl<CrossfadeOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CrossfadeOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CrossfadeOp&&(identical(other.segment, segment) || other.segment == segment)&&(identical(other.ms, ms) || other.ms == ms)&&(identical(other.curve, curve) || other.curve == curve));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,segment,ms,curve);
}

@override
String toString() {
    return 'EditOp.crossfade(segment: $segment, ms: $ms, curve: $curve)';
}


}

/// @nodoc
abstract mixin class $CrossfadeOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $CrossfadeOpCopyWith(CrossfadeOp value, $Res Function(CrossfadeOp) _then) = _$CrossfadeOpCopyWithImpl;
@useResult
$Res call({
 int segment, int ms, String curve
});




}
/// @nodoc
class _$CrossfadeOpCopyWithImpl<$Res>
    implements $CrossfadeOpCopyWith<$Res> {
  _$CrossfadeOpCopyWithImpl(this._self, this._then);

  final CrossfadeOp _self;
  final $Res Function(CrossfadeOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? segment = null,Object? ms = null,Object? curve = null,}) {
  return _then(CrossfadeOp(
segment: null == segment ? _self.segment : segment // ignore: cast_nullable_to_non_nullable
as int,ms: null == ms ? _self.ms : ms // ignore: cast_nullable_to_non_nullable
as int,curve: null == curve ? _self.curve : curve // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SegmentEqOp implements EditOp {
  const SegmentEqOp({required this.startMs, required this.endMs, required this.lowDb, required this.midDb, required this.highDb,  String? $type}): $type = $type ?? 'segmentEq';
  factory SegmentEqOp.fromJson(Map<String, dynamic> json) => _$SegmentEqOpFromJson(json);

 final  int startMs;
 final  int endMs;
 final  double lowDb;
 final  double midDb;
 final  double highDb;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SegmentEqOpCopyWith<SegmentEqOp> get copyWith => _$SegmentEqOpCopyWithImpl<SegmentEqOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SegmentEqOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SegmentEqOp&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs)&&(identical(other.lowDb, lowDb) || other.lowDb == lowDb)&&(identical(other.midDb, midDb) || other.midDb == midDb)&&(identical(other.highDb, highDb) || other.highDb == highDb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startMs,endMs,lowDb,midDb,highDb);
}

@override
String toString() {
    return 'EditOp.segmentEq(startMs: $startMs, endMs: $endMs, lowDb: $lowDb, midDb: $midDb, highDb: $highDb)';
}


}

/// @nodoc
abstract mixin class $SegmentEqOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $SegmentEqOpCopyWith(SegmentEqOp value, $Res Function(SegmentEqOp) _then) = _$SegmentEqOpCopyWithImpl;
@useResult
$Res call({
 int startMs, int endMs, double lowDb, double midDb, double highDb
});




}
/// @nodoc
class _$SegmentEqOpCopyWithImpl<$Res>
    implements $SegmentEqOpCopyWith<$Res> {
  _$SegmentEqOpCopyWithImpl(this._self, this._then);

  final SegmentEqOp _self;
  final $Res Function(SegmentEqOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startMs = null,Object? endMs = null,Object? lowDb = null,Object? midDb = null,Object? highDb = null,}) {
  return _then(SegmentEqOp(
startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,lowDb: null == lowDb ? _self.lowDb : lowDb // ignore: cast_nullable_to_non_nullable
as double,midDb: null == midDb ? _self.midDb : midDb // ignore: cast_nullable_to_non_nullable
as double,highDb: null == highDb ? _self.highDb : highDb // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
@JsonSerializable()

class GateOp implements EditOp {
  const GateOp({required this.startMs, required this.endMs, this.db,  String? $type}): $type = $type ?? 'gate';
  factory GateOp.fromJson(Map<String, dynamic> json) => _$GateOpFromJson(json);

 final  int startMs;
 final  int endMs;
 final  double? db;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GateOpCopyWith<GateOp> get copyWith => _$GateOpCopyWithImpl<GateOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GateOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GateOp&&(identical(other.startMs, startMs) || other.startMs == startMs)&&(identical(other.endMs, endMs) || other.endMs == endMs)&&(identical(other.db, db) || other.db == db));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,startMs,endMs,db);
}

@override
String toString() {
    return 'EditOp.gate(startMs: $startMs, endMs: $endMs, db: $db)';
}


}

/// @nodoc
abstract mixin class $GateOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $GateOpCopyWith(GateOp value, $Res Function(GateOp) _then) = _$GateOpCopyWithImpl;
@useResult
$Res call({
 int startMs, int endMs, double? db
});




}
/// @nodoc
class _$GateOpCopyWithImpl<$Res>
    implements $GateOpCopyWith<$Res> {
  _$GateOpCopyWithImpl(this._self, this._then);

  final GateOp _self;
  final $Res Function(GateOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startMs = null,Object? endMs = null,Object? db = freezed,}) {
  return _then(GateOp(
startMs: null == startMs ? _self.startMs : startMs // ignore: cast_nullable_to_non_nullable
as int,endMs: null == endMs ? _self.endMs : endMs // ignore: cast_nullable_to_non_nullable
as int,db: freezed == db ? _self.db : db // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class FadeCurveOp implements EditOp {
  const FadeCurveOp({required this.curve,  String? $type}): $type = $type ?? 'fadeCurve';
  factory FadeCurveOp.fromJson(Map<String, dynamic> json) => _$FadeCurveOpFromJson(json);

 final  String curve;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FadeCurveOpCopyWith<FadeCurveOp> get copyWith => _$FadeCurveOpCopyWithImpl<FadeCurveOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FadeCurveOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FadeCurveOp&&(identical(other.curve, curve) || other.curve == curve));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,curve);
}

@override
String toString() {
    return 'EditOp.fadeCurve(curve: $curve)';
}


}

/// @nodoc
abstract mixin class $FadeCurveOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $FadeCurveOpCopyWith(FadeCurveOp value, $Res Function(FadeCurveOp) _then) = _$FadeCurveOpCopyWithImpl;
@useResult
$Res call({
 String curve
});




}
/// @nodoc
class _$FadeCurveOpCopyWithImpl<$Res>
    implements $FadeCurveOpCopyWith<$Res> {
  _$FadeCurveOpCopyWithImpl(this._self, this._then);

  final FadeCurveOp _self;
  final $Res Function(FadeCurveOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? curve = null,}) {
  return _then(FadeCurveOp(
curve: null == curve ? _self.curve : curve // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class MasterGainOp implements EditOp {
  const MasterGainOp({required this.db,  String? $type}): $type = $type ?? 'masterGain';
  factory MasterGainOp.fromJson(Map<String, dynamic> json) => _$MasterGainOpFromJson(json);

 final  double db;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MasterGainOpCopyWith<MasterGainOp> get copyWith => _$MasterGainOpCopyWithImpl<MasterGainOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MasterGainOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MasterGainOp&&(identical(other.db, db) || other.db == db));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,db);
}

@override
String toString() {
    return 'EditOp.masterGain(db: $db)';
}


}

/// @nodoc
abstract mixin class $MasterGainOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $MasterGainOpCopyWith(MasterGainOp value, $Res Function(MasterGainOp) _then) = _$MasterGainOpCopyWithImpl;
@useResult
$Res call({
 double db
});




}
/// @nodoc
class _$MasterGainOpCopyWithImpl<$Res>
    implements $MasterGainOpCopyWith<$Res> {
  _$MasterGainOpCopyWithImpl(this._self, this._then);

  final MasterGainOp _self;
  final $Res Function(MasterGainOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? db = null,}) {
  return _then(MasterGainOp(
db: null == db ? _self.db : db // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
@JsonSerializable()

class LoudnessOp implements EditOp {
  const LoudnessOp({this.lufs,  String? $type}): $type = $type ?? 'loudness';
  factory LoudnessOp.fromJson(Map<String, dynamic> json) => _$LoudnessOpFromJson(json);

 final  double? lufs;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LoudnessOpCopyWith<LoudnessOp> get copyWith => _$LoudnessOpCopyWithImpl<LoudnessOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LoudnessOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is LoudnessOp&&(identical(other.lufs, lufs) || other.lufs == lufs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,lufs);
}

@override
String toString() {
    return 'EditOp.loudness(lufs: $lufs)';
}


}

/// @nodoc
abstract mixin class $LoudnessOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $LoudnessOpCopyWith(LoudnessOp value, $Res Function(LoudnessOp) _then) = _$LoudnessOpCopyWithImpl;
@useResult
$Res call({
 double? lufs
});




}
/// @nodoc
class _$LoudnessOpCopyWithImpl<$Res>
    implements $LoudnessOpCopyWith<$Res> {
  _$LoudnessOpCopyWithImpl(this._self, this._then);

  final LoudnessOp _self;
  final $Res Function(LoudnessOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? lufs = freezed,}) {
  return _then(LoudnessOp(
lufs: freezed == lufs ? _self.lufs : lufs // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BatchOp implements EditOp {
  const BatchOp({required  List<EditOp> ops,  String? $type}): _ops = ops,$type = $type ?? 'batch';
  factory BatchOp.fromJson(Map<String, dynamic> json) => _$BatchOpFromJson(json);

 final  List<EditOp> _ops;
 List<EditOp> get ops {
  if (_ops is EqualUnmodifiableListView) return _ops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ops);
}


@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BatchOpCopyWith<BatchOp> get copyWith => _$BatchOpCopyWithImpl<BatchOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BatchOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is BatchOp&&const DeepCollectionEquality().equals(other.ops, _ops));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_ops));
}

@override
String toString() {
    return 'EditOp.batch(ops: $ops)';
}


}

/// @nodoc
abstract mixin class $BatchOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $BatchOpCopyWith(BatchOp value, $Res Function(BatchOp) _then) = _$BatchOpCopyWithImpl;
@useResult
$Res call({
 List<EditOp> ops
});




}
/// @nodoc
class _$BatchOpCopyWithImpl<$Res>
    implements $BatchOpCopyWith<$Res> {
  _$BatchOpCopyWithImpl(this._self, this._then);

  final BatchOp _self;
  final $Res Function(BatchOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? ops = null,}) {
  return _then(BatchOp(
ops: null == ops ? _self._ops : ops // ignore: cast_nullable_to_non_nullable
as List<EditOp>,
  ));
}


}

/// @nodoc
@JsonSerializable()

class FadeInOp implements EditOp {
  const FadeInOp({required this.durationMs,  String? $type}): $type = $type ?? 'fadeIn';
  factory FadeInOp.fromJson(Map<String, dynamic> json) => _$FadeInOpFromJson(json);

 final  int durationMs;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FadeInOpCopyWith<FadeInOp> get copyWith => _$FadeInOpCopyWithImpl<FadeInOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FadeInOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FadeInOp&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,durationMs);
}

@override
String toString() {
    return 'EditOp.fadeIn(durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class $FadeInOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $FadeInOpCopyWith(FadeInOp value, $Res Function(FadeInOp) _then) = _$FadeInOpCopyWithImpl;
@useResult
$Res call({
 int durationMs
});




}
/// @nodoc
class _$FadeInOpCopyWithImpl<$Res>
    implements $FadeInOpCopyWith<$Res> {
  _$FadeInOpCopyWithImpl(this._self, this._then);

  final FadeInOp _self;
  final $Res Function(FadeInOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? durationMs = null,}) {
  return _then(FadeInOp(
durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class FadeOutOp implements EditOp {
  const FadeOutOp({required this.durationMs,  String? $type}): $type = $type ?? 'fadeOut';
  factory FadeOutOp.fromJson(Map<String, dynamic> json) => _$FadeOutOpFromJson(json);

 final  int durationMs;

@JsonKey(name: 'op')
final String $type;


/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FadeOutOpCopyWith<FadeOutOp> get copyWith => _$FadeOutOpCopyWithImpl<FadeOutOp>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FadeOutOpToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is FadeOutOp&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,durationMs);
}

@override
String toString() {
    return 'EditOp.fadeOut(durationMs: $durationMs)';
}


}

/// @nodoc
abstract mixin class $FadeOutOpCopyWith<$Res> implements $EditOpCopyWith<$Res> {
  factory $FadeOutOpCopyWith(FadeOutOp value, $Res Function(FadeOutOp) _then) = _$FadeOutOpCopyWithImpl;
@useResult
$Res call({
 int durationMs
});




}
/// @nodoc
class _$FadeOutOpCopyWithImpl<$Res>
    implements $FadeOutOpCopyWith<$Res> {
  _$FadeOutOpCopyWithImpl(this._self, this._then);

  final FadeOutOp _self;
  final $Res Function(FadeOutOp) _then;

/// Create a copy of EditOp
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? durationMs = null,}) {
  return _then(FadeOutOp(
durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$EditDecisionList {

 int get version; String get sourceUri; int get sourceDurationMs; List<EditOp> get ops; List<EditOp> get redoOps; int get cursorMs; int get viewStartMs; int get viewLengthMs;
/// Create a copy of EditDecisionList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EditDecisionListCopyWith<EditDecisionList> get copyWith => _$EditDecisionListCopyWithImpl<EditDecisionList>(this as EditDecisionList, _$identity);

  /// Serializes this EditDecisionList to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EditDecisionList;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EditDecisionList&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.sourceUri, _this.sourceUri) || other.sourceUri == _this.sourceUri)&&(identical(other.sourceDurationMs, _this.sourceDurationMs) || other.sourceDurationMs == _this.sourceDurationMs)&&const DeepCollectionEquality().equals(other.ops, _this.ops)&&const DeepCollectionEquality().equals(other.redoOps, _this.redoOps)&&(identical(other.cursorMs, _this.cursorMs) || other.cursorMs == _this.cursorMs)&&(identical(other.viewStartMs, _this.viewStartMs) || other.viewStartMs == _this.viewStartMs)&&(identical(other.viewLengthMs, _this.viewLengthMs) || other.viewLengthMs == _this.viewLengthMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EditDecisionList;
  return Object.hash(runtimeType,_this.version,_this.sourceUri,_this.sourceDurationMs,const DeepCollectionEquality().hash(_this.ops),const DeepCollectionEquality().hash(_this.redoOps),_this.cursorMs,_this.viewStartMs,_this.viewLengthMs);
}

@override
String toString() {
  final _this = this as EditDecisionList;
  return 'EditDecisionList(version: ${_this.version}, sourceUri: ${_this.sourceUri}, sourceDurationMs: ${_this.sourceDurationMs}, ops: ${_this.ops}, redoOps: ${_this.redoOps}, cursorMs: ${_this.cursorMs}, viewStartMs: ${_this.viewStartMs}, viewLengthMs: ${_this.viewLengthMs})';
}


}

/// @nodoc
abstract mixin class $EditDecisionListCopyWith<$Res>  {
  factory $EditDecisionListCopyWith(EditDecisionList value, $Res Function(EditDecisionList) _then) = _$EditDecisionListCopyWithImpl;
@useResult
$Res call({
 int version, String sourceUri, int sourceDurationMs, List<EditOp> ops, List<EditOp> redoOps, int cursorMs, int viewStartMs, int viewLengthMs
});




}
/// @nodoc
class _$EditDecisionListCopyWithImpl<$Res>
    implements $EditDecisionListCopyWith<$Res> {
  _$EditDecisionListCopyWithImpl(this._self, this._then);

  final EditDecisionList _self;
  final $Res Function(EditDecisionList) _then;

/// Create a copy of EditDecisionList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? sourceUri = null,Object? sourceDurationMs = null,Object? ops = null,Object? redoOps = null,Object? cursorMs = null,Object? viewStartMs = null,Object? viewLengthMs = null,}) {
  return _then(EditDecisionList(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,sourceUri: null == sourceUri ? _self.sourceUri : sourceUri // ignore: cast_nullable_to_non_nullable
as String,sourceDurationMs: null == sourceDurationMs ? _self.sourceDurationMs : sourceDurationMs // ignore: cast_nullable_to_non_nullable
as int,ops: null == ops ? _self.ops : ops // ignore: cast_nullable_to_non_nullable
as List<EditOp>,redoOps: null == redoOps ? _self.redoOps : redoOps // ignore: cast_nullable_to_non_nullable
as List<EditOp>,cursorMs: null == cursorMs ? _self.cursorMs : cursorMs // ignore: cast_nullable_to_non_nullable
as int,viewStartMs: null == viewStartMs ? _self.viewStartMs : viewStartMs // ignore: cast_nullable_to_non_nullable
as int,viewLengthMs: null == viewLengthMs ? _self.viewLengthMs : viewLengthMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [EditDecisionList].
extension EditDecisionListPatterns on EditDecisionList {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EditDecisionList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EditDecisionList() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EditDecisionList value)  $default,){
final _that = this;
switch (_that) {
case _EditDecisionList():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EditDecisionList value)?  $default,){
final _that = this;
switch (_that) {
case _EditDecisionList() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int version,  String sourceUri,  int sourceDurationMs,  List<EditOp> ops,  List<EditOp> redoOps,  int cursorMs,  int viewStartMs,  int viewLengthMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EditDecisionList() when $default != null:
return $default(_that.version,_that.sourceUri,_that.sourceDurationMs,_that.ops,_that.redoOps,_that.cursorMs,_that.viewStartMs,_that.viewLengthMs);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int version,  String sourceUri,  int sourceDurationMs,  List<EditOp> ops,  List<EditOp> redoOps,  int cursorMs,  int viewStartMs,  int viewLengthMs)  $default,) {final _that = this;
switch (_that) {
case _EditDecisionList():
return $default(_that.version,_that.sourceUri,_that.sourceDurationMs,_that.ops,_that.redoOps,_that.cursorMs,_that.viewStartMs,_that.viewLengthMs);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int version,  String sourceUri,  int sourceDurationMs,  List<EditOp> ops,  List<EditOp> redoOps,  int cursorMs,  int viewStartMs,  int viewLengthMs)?  $default,) {final _that = this;
switch (_that) {
case _EditDecisionList() when $default != null:
return $default(_that.version,_that.sourceUri,_that.sourceDurationMs,_that.ops,_that.redoOps,_that.cursorMs,_that.viewStartMs,_that.viewLengthMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EditDecisionList extends EditDecisionList {
  const _EditDecisionList({this.version = 1, required this.sourceUri, required this.sourceDurationMs,  List<EditOp> ops = const [],  List<EditOp> redoOps = const [], this.cursorMs = 0, this.viewStartMs = 0, this.viewLengthMs = 0}): _ops = ops,_redoOps = redoOps,super._();
  factory _EditDecisionList.fromJson(Map<String, dynamic> json) => _$EditDecisionListFromJson(json);

@override@JsonKey() final  int version;
@override final  String sourceUri;
@override final  int sourceDurationMs;
 final  List<EditOp> _ops;
@override@JsonKey() List<EditOp> get ops {
  if (_ops is EqualUnmodifiableListView) return _ops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ops);
}

 final  List<EditOp> _redoOps;
@override@JsonKey() List<EditOp> get redoOps {
  if (_redoOps is EqualUnmodifiableListView) return _redoOps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_redoOps);
}

@override@JsonKey() final  int cursorMs;
@override@JsonKey() final  int viewStartMs;
@override@JsonKey() final  int viewLengthMs;

/// Create a copy of EditDecisionList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EditDecisionListCopyWith<_EditDecisionList> get copyWith => __$EditDecisionListCopyWithImpl<_EditDecisionList>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EditDecisionListToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EditDecisionList&&(identical(other.version, version) || other.version == version)&&(identical(other.sourceUri, sourceUri) || other.sourceUri == sourceUri)&&(identical(other.sourceDurationMs, sourceDurationMs) || other.sourceDurationMs == sourceDurationMs)&&const DeepCollectionEquality().equals(other.ops, _ops)&&const DeepCollectionEquality().equals(other.redoOps, _redoOps)&&(identical(other.cursorMs, cursorMs) || other.cursorMs == cursorMs)&&(identical(other.viewStartMs, viewStartMs) || other.viewStartMs == viewStartMs)&&(identical(other.viewLengthMs, viewLengthMs) || other.viewLengthMs == viewLengthMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,version,sourceUri,sourceDurationMs,const DeepCollectionEquality().hash(_ops),const DeepCollectionEquality().hash(_redoOps),cursorMs,viewStartMs,viewLengthMs);
}

@override
String toString() {
    return 'EditDecisionList(version: $version, sourceUri: $sourceUri, sourceDurationMs: $sourceDurationMs, ops: $ops, redoOps: $redoOps, cursorMs: $cursorMs, viewStartMs: $viewStartMs, viewLengthMs: $viewLengthMs)';
}


}

/// @nodoc
abstract mixin class _$EditDecisionListCopyWith<$Res> implements $EditDecisionListCopyWith<$Res> {
  factory _$EditDecisionListCopyWith(_EditDecisionList value, $Res Function(_EditDecisionList) _then) = __$EditDecisionListCopyWithImpl;
@override @useResult
$Res call({
 int version, String sourceUri, int sourceDurationMs, List<EditOp> ops, List<EditOp> redoOps, int cursorMs, int viewStartMs, int viewLengthMs
});




}
/// @nodoc
class __$EditDecisionListCopyWithImpl<$Res>
    implements _$EditDecisionListCopyWith<$Res> {
  __$EditDecisionListCopyWithImpl(this._self, this._then);

  final _EditDecisionList _self;
  final $Res Function(_EditDecisionList) _then;

/// Create a copy of EditDecisionList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? sourceUri = null,Object? sourceDurationMs = null,Object? ops = null,Object? redoOps = null,Object? cursorMs = null,Object? viewStartMs = null,Object? viewLengthMs = null,}) {
  return _then(_EditDecisionList(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,sourceUri: null == sourceUri ? _self.sourceUri : sourceUri // ignore: cast_nullable_to_non_nullable
as String,sourceDurationMs: null == sourceDurationMs ? _self.sourceDurationMs : sourceDurationMs // ignore: cast_nullable_to_non_nullable
as int,ops: null == ops ? _self._ops : ops // ignore: cast_nullable_to_non_nullable
as List<EditOp>,redoOps: null == redoOps ? _self._redoOps : redoOps // ignore: cast_nullable_to_non_nullable
as List<EditOp>,cursorMs: null == cursorMs ? _self.cursorMs : cursorMs // ignore: cast_nullable_to_non_nullable
as int,viewStartMs: null == viewStartMs ? _self.viewStartMs : viewStartMs // ignore: cast_nullable_to_non_nullable
as int,viewLengthMs: null == viewLengthMs ? _self.viewLengthMs : viewLengthMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

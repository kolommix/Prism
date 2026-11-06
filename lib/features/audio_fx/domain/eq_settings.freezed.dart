// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'eq_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EqSettings {

 bool get enabled;/// Gain per band in dB, same order as [eqBandFrequencies].
 List<double> get gainsDb;/// Overall gain before the bands, in dB (usually ≤ 0 to avoid clipping).
 double get preampDb;/// 0..1 strength of the bass shelf.
 double get bassBoost;/// Name of the preset the values came from ("Custom" once edited).
 String get presetName;
/// Create a copy of EqSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EqSettingsCopyWith<EqSettings> get copyWith => _$EqSettingsCopyWithImpl<EqSettings>(this as EqSettings, _$identity);

  /// Serializes this EqSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EqSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EqSettings&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&const DeepCollectionEquality().equals(other.gainsDb, _this.gainsDb)&&(identical(other.preampDb, _this.preampDb) || other.preampDb == _this.preampDb)&&(identical(other.bassBoost, _this.bassBoost) || other.bassBoost == _this.bassBoost)&&(identical(other.presetName, _this.presetName) || other.presetName == _this.presetName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EqSettings;
  return Object.hash(runtimeType,_this.enabled,const DeepCollectionEquality().hash(_this.gainsDb),_this.preampDb,_this.bassBoost,_this.presetName);
}

@override
String toString() {
  final _this = this as EqSettings;
  return 'EqSettings(enabled: ${_this.enabled}, gainsDb: ${_this.gainsDb}, preampDb: ${_this.preampDb}, bassBoost: ${_this.bassBoost}, presetName: ${_this.presetName})';
}


}

/// @nodoc
abstract mixin class $EqSettingsCopyWith<$Res>  {
  factory $EqSettingsCopyWith(EqSettings value, $Res Function(EqSettings) _then) = _$EqSettingsCopyWithImpl;
@useResult
$Res call({
 bool enabled, List<double> gainsDb, double preampDb, double bassBoost, String presetName
});




}
/// @nodoc
class _$EqSettingsCopyWithImpl<$Res>
    implements $EqSettingsCopyWith<$Res> {
  _$EqSettingsCopyWithImpl(this._self, this._then);

  final EqSettings _self;
  final $Res Function(EqSettings) _then;

/// Create a copy of EqSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? gainsDb = null,Object? preampDb = null,Object? bassBoost = null,Object? presetName = null,}) {
  return _then(EqSettings(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,gainsDb: null == gainsDb ? _self.gainsDb : gainsDb // ignore: cast_nullable_to_non_nullable
as List<double>,preampDb: null == preampDb ? _self.preampDb : preampDb // ignore: cast_nullable_to_non_nullable
as double,bassBoost: null == bassBoost ? _self.bassBoost : bassBoost // ignore: cast_nullable_to_non_nullable
as double,presetName: null == presetName ? _self.presetName : presetName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EqSettings].
extension EqSettingsPatterns on EqSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EqSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EqSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EqSettings value)  $default,){
final _that = this;
switch (_that) {
case _EqSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EqSettings value)?  $default,){
final _that = this;
switch (_that) {
case _EqSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  List<double> gainsDb,  double preampDb,  double bassBoost,  String presetName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EqSettings() when $default != null:
return $default(_that.enabled,_that.gainsDb,_that.preampDb,_that.bassBoost,_that.presetName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  List<double> gainsDb,  double preampDb,  double bassBoost,  String presetName)  $default,) {final _that = this;
switch (_that) {
case _EqSettings():
return $default(_that.enabled,_that.gainsDb,_that.preampDb,_that.bassBoost,_that.presetName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  List<double> gainsDb,  double preampDb,  double bassBoost,  String presetName)?  $default,) {final _that = this;
switch (_that) {
case _EqSettings() when $default != null:
return $default(_that.enabled,_that.gainsDb,_that.preampDb,_that.bassBoost,_that.presetName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EqSettings extends EqSettings {
  const _EqSettings({this.enabled = false,  List<double> gainsDb = const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0], this.preampDb = 0.0, this.bassBoost = 0.0, this.presetName = 'Flat'}): _gainsDb = gainsDb,super._();
  factory _EqSettings.fromJson(Map<String, dynamic> json) => _$EqSettingsFromJson(json);

@override@JsonKey() final  bool enabled;
/// Gain per band in dB, same order as [eqBandFrequencies].
 final  List<double> _gainsDb;
/// Gain per band in dB, same order as [eqBandFrequencies].
@override@JsonKey() List<double> get gainsDb {
  if (_gainsDb is EqualUnmodifiableListView) return _gainsDb;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_gainsDb);
}

/// Overall gain before the bands, in dB (usually ≤ 0 to avoid clipping).
@override@JsonKey() final  double preampDb;
/// 0..1 strength of the bass shelf.
@override@JsonKey() final  double bassBoost;
/// Name of the preset the values came from ("Custom" once edited).
@override@JsonKey() final  String presetName;

/// Create a copy of EqSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EqSettingsCopyWith<_EqSettings> get copyWith => __$EqSettingsCopyWithImpl<_EqSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EqSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EqSettings&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other.gainsDb, _gainsDb)&&(identical(other.preampDb, preampDb) || other.preampDb == preampDb)&&(identical(other.bassBoost, bassBoost) || other.bassBoost == bassBoost)&&(identical(other.presetName, presetName) || other.presetName == presetName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,enabled,const DeepCollectionEquality().hash(_gainsDb),preampDb,bassBoost,presetName);
}

@override
String toString() {
    return 'EqSettings(enabled: $enabled, gainsDb: $gainsDb, preampDb: $preampDb, bassBoost: $bassBoost, presetName: $presetName)';
}


}

/// @nodoc
abstract mixin class _$EqSettingsCopyWith<$Res> implements $EqSettingsCopyWith<$Res> {
  factory _$EqSettingsCopyWith(_EqSettings value, $Res Function(_EqSettings) _then) = __$EqSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, List<double> gainsDb, double preampDb, double bassBoost, String presetName
});




}
/// @nodoc
class __$EqSettingsCopyWithImpl<$Res>
    implements _$EqSettingsCopyWith<$Res> {
  __$EqSettingsCopyWithImpl(this._self, this._then);

  final _EqSettings _self;
  final $Res Function(_EqSettings) _then;

/// Create a copy of EqSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? gainsDb = null,Object? preampDb = null,Object? bassBoost = null,Object? presetName = null,}) {
  return _then(_EqSettings(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,gainsDb: null == gainsDb ? _self._gainsDb : gainsDb // ignore: cast_nullable_to_non_nullable
as List<double>,preampDb: null == preampDb ? _self.preampDb : preampDb // ignore: cast_nullable_to_non_nullable
as double,bassBoost: null == bassBoost ? _self.bassBoost : bassBoost // ignore: cast_nullable_to_non_nullable
as double,presetName: null == presetName ? _self.presetName : presetName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$EqPreset {

 String get name; List<double> get gainsDb; double get preampDb; double get bassBoost; bool get builtIn;
/// Create a copy of EqPreset
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EqPresetCopyWith<EqPreset> get copyWith => _$EqPresetCopyWithImpl<EqPreset>(this as EqPreset, _$identity);

  /// Serializes this EqPreset to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EqPreset;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EqPreset&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.gainsDb, _this.gainsDb)&&(identical(other.preampDb, _this.preampDb) || other.preampDb == _this.preampDb)&&(identical(other.bassBoost, _this.bassBoost) || other.bassBoost == _this.bassBoost)&&(identical(other.builtIn, _this.builtIn) || other.builtIn == _this.builtIn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EqPreset;
  return Object.hash(runtimeType,_this.name,const DeepCollectionEquality().hash(_this.gainsDb),_this.preampDb,_this.bassBoost,_this.builtIn);
}

@override
String toString() {
  final _this = this as EqPreset;
  return 'EqPreset(name: ${_this.name}, gainsDb: ${_this.gainsDb}, preampDb: ${_this.preampDb}, bassBoost: ${_this.bassBoost}, builtIn: ${_this.builtIn})';
}


}

/// @nodoc
abstract mixin class $EqPresetCopyWith<$Res>  {
  factory $EqPresetCopyWith(EqPreset value, $Res Function(EqPreset) _then) = _$EqPresetCopyWithImpl;
@useResult
$Res call({
 String name, List<double> gainsDb, double preampDb, double bassBoost, bool builtIn
});




}
/// @nodoc
class _$EqPresetCopyWithImpl<$Res>
    implements $EqPresetCopyWith<$Res> {
  _$EqPresetCopyWithImpl(this._self, this._then);

  final EqPreset _self;
  final $Res Function(EqPreset) _then;

/// Create a copy of EqPreset
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? gainsDb = null,Object? preampDb = null,Object? bassBoost = null,Object? builtIn = null,}) {
  return _then(EqPreset(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,gainsDb: null == gainsDb ? _self.gainsDb : gainsDb // ignore: cast_nullable_to_non_nullable
as List<double>,preampDb: null == preampDb ? _self.preampDb : preampDb // ignore: cast_nullable_to_non_nullable
as double,bassBoost: null == bassBoost ? _self.bassBoost : bassBoost // ignore: cast_nullable_to_non_nullable
as double,builtIn: null == builtIn ? _self.builtIn : builtIn // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [EqPreset].
extension EqPresetPatterns on EqPreset {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EqPreset value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EqPreset() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EqPreset value)  $default,){
final _that = this;
switch (_that) {
case _EqPreset():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EqPreset value)?  $default,){
final _that = this;
switch (_that) {
case _EqPreset() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  List<double> gainsDb,  double preampDb,  double bassBoost,  bool builtIn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EqPreset() when $default != null:
return $default(_that.name,_that.gainsDb,_that.preampDb,_that.bassBoost,_that.builtIn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  List<double> gainsDb,  double preampDb,  double bassBoost,  bool builtIn)  $default,) {final _that = this;
switch (_that) {
case _EqPreset():
return $default(_that.name,_that.gainsDb,_that.preampDb,_that.bassBoost,_that.builtIn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  List<double> gainsDb,  double preampDb,  double bassBoost,  bool builtIn)?  $default,) {final _that = this;
switch (_that) {
case _EqPreset() when $default != null:
return $default(_that.name,_that.gainsDb,_that.preampDb,_that.bassBoost,_that.builtIn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EqPreset implements EqPreset {
  const _EqPreset({required this.name, required  List<double> gainsDb, this.preampDb = 0.0, this.bassBoost = 0.0, this.builtIn = false}): _gainsDb = gainsDb;
  factory _EqPreset.fromJson(Map<String, dynamic> json) => _$EqPresetFromJson(json);

@override final  String name;
 final  List<double> _gainsDb;
@override List<double> get gainsDb {
  if (_gainsDb is EqualUnmodifiableListView) return _gainsDb;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_gainsDb);
}

@override@JsonKey() final  double preampDb;
@override@JsonKey() final  double bassBoost;
@override@JsonKey() final  bool builtIn;

/// Create a copy of EqPreset
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EqPresetCopyWith<_EqPreset> get copyWith => __$EqPresetCopyWithImpl<_EqPreset>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EqPresetToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EqPreset&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.gainsDb, _gainsDb)&&(identical(other.preampDb, preampDb) || other.preampDb == preampDb)&&(identical(other.bassBoost, bassBoost) || other.bassBoost == bassBoost)&&(identical(other.builtIn, builtIn) || other.builtIn == builtIn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_gainsDb),preampDb,bassBoost,builtIn);
}

@override
String toString() {
    return 'EqPreset(name: $name, gainsDb: $gainsDb, preampDb: $preampDb, bassBoost: $bassBoost, builtIn: $builtIn)';
}


}

/// @nodoc
abstract mixin class _$EqPresetCopyWith<$Res> implements $EqPresetCopyWith<$Res> {
  factory _$EqPresetCopyWith(_EqPreset value, $Res Function(_EqPreset) _then) = __$EqPresetCopyWithImpl;
@override @useResult
$Res call({
 String name, List<double> gainsDb, double preampDb, double bassBoost, bool builtIn
});




}
/// @nodoc
class __$EqPresetCopyWithImpl<$Res>
    implements _$EqPresetCopyWith<$Res> {
  __$EqPresetCopyWithImpl(this._self, this._then);

  final _EqPreset _self;
  final $Res Function(_EqPreset) _then;

/// Create a copy of EqPreset
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? gainsDb = null,Object? preampDb = null,Object? bassBoost = null,Object? builtIn = null,}) {
  return _then(_EqPreset(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,gainsDb: null == gainsDb ? _self._gainsDb : gainsDb // ignore: cast_nullable_to_non_nullable
as List<double>,preampDb: null == preampDb ? _self.preampDb : preampDb // ignore: cast_nullable_to_non_nullable
as double,bassBoost: null == bassBoost ? _self.bassBoost : bassBoost // ignore: cast_nullable_to_non_nullable
as double,builtIn: null == builtIn ? _self.builtIn : builtIn // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on

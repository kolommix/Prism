// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'theme_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ThemeConfig {

 String get name; int get primaryColor; int get accentColor; ThemeBrightnessMode get brightness;/// Base corner radius in logical pixels (cards, sheets, buttons).
 double get cornerRadius;/// Font family name. `null` = platform default. Bundled Google Fonts
/// names (see `availableFonts`) are fetched and cached on first use.
 String? get fontFamily;/// 0 = no blur (flat), 1 = strong frosted glass.
 double get glassIntensity;/// Multiplier for every animation duration (0.5 = twice as fast).
 double get animationSpeed;/// Derive colors from the current album art instead of [primaryColor].
 bool get dynamicColor;/// Black & white UI: greys only, covers stay in color. Overrides the
/// colors above (they come back when this is turned off).
 bool get monochrome;/// The background saved with this theme, in `BackgroundFiles.toThemeJson`
/// form (kept as JSON: the theme layer doesn't know about backgrounds).
 Map<String, dynamic>? get background;
/// Create a copy of ThemeConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ThemeConfigCopyWith<ThemeConfig> get copyWith => _$ThemeConfigCopyWithImpl<ThemeConfig>(this as ThemeConfig, _$identity);

  /// Serializes this ThemeConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ThemeConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ThemeConfig&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.primaryColor, _this.primaryColor) || other.primaryColor == _this.primaryColor)&&(identical(other.accentColor, _this.accentColor) || other.accentColor == _this.accentColor)&&(identical(other.brightness, _this.brightness) || other.brightness == _this.brightness)&&(identical(other.cornerRadius, _this.cornerRadius) || other.cornerRadius == _this.cornerRadius)&&(identical(other.fontFamily, _this.fontFamily) || other.fontFamily == _this.fontFamily)&&(identical(other.glassIntensity, _this.glassIntensity) || other.glassIntensity == _this.glassIntensity)&&(identical(other.animationSpeed, _this.animationSpeed) || other.animationSpeed == _this.animationSpeed)&&(identical(other.dynamicColor, _this.dynamicColor) || other.dynamicColor == _this.dynamicColor)&&(identical(other.monochrome, _this.monochrome) || other.monochrome == _this.monochrome)&&const DeepCollectionEquality().equals(other.background, _this.background));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ThemeConfig;
  return Object.hash(runtimeType,_this.name,_this.primaryColor,_this.accentColor,_this.brightness,_this.cornerRadius,_this.fontFamily,_this.glassIntensity,_this.animationSpeed,_this.dynamicColor,_this.monochrome,const DeepCollectionEquality().hash(_this.background));
}

@override
String toString() {
  final _this = this as ThemeConfig;
  return 'ThemeConfig(name: ${_this.name}, primaryColor: ${_this.primaryColor}, accentColor: ${_this.accentColor}, brightness: ${_this.brightness}, cornerRadius: ${_this.cornerRadius}, fontFamily: ${_this.fontFamily}, glassIntensity: ${_this.glassIntensity}, animationSpeed: ${_this.animationSpeed}, dynamicColor: ${_this.dynamicColor}, monochrome: ${_this.monochrome}, background: ${_this.background})';
}


}

/// @nodoc
abstract mixin class $ThemeConfigCopyWith<$Res>  {
  factory $ThemeConfigCopyWith(ThemeConfig value, $Res Function(ThemeConfig) _then) = _$ThemeConfigCopyWithImpl;
@useResult
$Res call({
 String name, int primaryColor, int accentColor, ThemeBrightnessMode brightness, double cornerRadius, String? fontFamily, double glassIntensity, double animationSpeed, bool dynamicColor, bool monochrome, Map<String, dynamic>? background
});




}
/// @nodoc
class _$ThemeConfigCopyWithImpl<$Res>
    implements $ThemeConfigCopyWith<$Res> {
  _$ThemeConfigCopyWithImpl(this._self, this._then);

  final ThemeConfig _self;
  final $Res Function(ThemeConfig) _then;

/// Create a copy of ThemeConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? primaryColor = null,Object? accentColor = null,Object? brightness = null,Object? cornerRadius = null,Object? fontFamily = freezed,Object? glassIntensity = null,Object? animationSpeed = null,Object? dynamicColor = null,Object? monochrome = null,Object? background = freezed,}) {
  return _then(ThemeConfig(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,primaryColor: null == primaryColor ? _self.primaryColor : primaryColor // ignore: cast_nullable_to_non_nullable
as int,accentColor: null == accentColor ? _self.accentColor : accentColor // ignore: cast_nullable_to_non_nullable
as int,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as ThemeBrightnessMode,cornerRadius: null == cornerRadius ? _self.cornerRadius : cornerRadius // ignore: cast_nullable_to_non_nullable
as double,fontFamily: freezed == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String?,glassIntensity: null == glassIntensity ? _self.glassIntensity : glassIntensity // ignore: cast_nullable_to_non_nullable
as double,animationSpeed: null == animationSpeed ? _self.animationSpeed : animationSpeed // ignore: cast_nullable_to_non_nullable
as double,dynamicColor: null == dynamicColor ? _self.dynamicColor : dynamicColor // ignore: cast_nullable_to_non_nullable
as bool,monochrome: null == monochrome ? _self.monochrome : monochrome // ignore: cast_nullable_to_non_nullable
as bool,background: freezed == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ThemeConfig].
extension ThemeConfigPatterns on ThemeConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ThemeConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ThemeConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ThemeConfig value)  $default,){
final _that = this;
switch (_that) {
case _ThemeConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ThemeConfig value)?  $default,){
final _that = this;
switch (_that) {
case _ThemeConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int primaryColor,  int accentColor,  ThemeBrightnessMode brightness,  double cornerRadius,  String? fontFamily,  double glassIntensity,  double animationSpeed,  bool dynamicColor,  bool monochrome,  Map<String, dynamic>? background)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ThemeConfig() when $default != null:
return $default(_that.name,_that.primaryColor,_that.accentColor,_that.brightness,_that.cornerRadius,_that.fontFamily,_that.glassIntensity,_that.animationSpeed,_that.dynamicColor,_that.monochrome,_that.background);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int primaryColor,  int accentColor,  ThemeBrightnessMode brightness,  double cornerRadius,  String? fontFamily,  double glassIntensity,  double animationSpeed,  bool dynamicColor,  bool monochrome,  Map<String, dynamic>? background)  $default,) {final _that = this;
switch (_that) {
case _ThemeConfig():
return $default(_that.name,_that.primaryColor,_that.accentColor,_that.brightness,_that.cornerRadius,_that.fontFamily,_that.glassIntensity,_that.animationSpeed,_that.dynamicColor,_that.monochrome,_that.background);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int primaryColor,  int accentColor,  ThemeBrightnessMode brightness,  double cornerRadius,  String? fontFamily,  double glassIntensity,  double animationSpeed,  bool dynamicColor,  bool monochrome,  Map<String, dynamic>? background)?  $default,) {final _that = this;
switch (_that) {
case _ThemeConfig() when $default != null:
return $default(_that.name,_that.primaryColor,_that.accentColor,_that.brightness,_that.cornerRadius,_that.fontFamily,_that.glassIntensity,_that.animationSpeed,_that.dynamicColor,_that.monochrome,_that.background);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ThemeConfig extends ThemeConfig {
  const _ThemeConfig({this.name = 'Mono', this.primaryColor = 0xFF7C4DFF, this.accentColor = 0xFF00E5FF, this.brightness = ThemeBrightnessMode.amoled, this.cornerRadius = 16.0, this.fontFamily, this.glassIntensity = 0.5, this.animationSpeed = 1.0, this.dynamicColor = true, this.monochrome = true,  Map<String, dynamic>? background}): _background = background,super._();
  factory _ThemeConfig.fromJson(Map<String, dynamic> json) => _$ThemeConfigFromJson(json);

@override@JsonKey() final  String name;
@override@JsonKey() final  int primaryColor;
@override@JsonKey() final  int accentColor;
@override@JsonKey() final  ThemeBrightnessMode brightness;
/// Base corner radius in logical pixels (cards, sheets, buttons).
@override@JsonKey() final  double cornerRadius;
/// Font family name. `null` = platform default. Bundled Google Fonts
/// names (see `availableFonts`) are fetched and cached on first use.
@override final  String? fontFamily;
/// 0 = no blur (flat), 1 = strong frosted glass.
@override@JsonKey() final  double glassIntensity;
/// Multiplier for every animation duration (0.5 = twice as fast).
@override@JsonKey() final  double animationSpeed;
/// Derive colors from the current album art instead of [primaryColor].
@override@JsonKey() final  bool dynamicColor;
/// Black & white UI: greys only, covers stay in color. Overrides the
/// colors above (they come back when this is turned off).
@override@JsonKey() final  bool monochrome;
/// The background saved with this theme, in `BackgroundFiles.toThemeJson`
/// form (kept as JSON: the theme layer doesn't know about backgrounds).
 final  Map<String, dynamic>? _background;
/// The background saved with this theme, in `BackgroundFiles.toThemeJson`
/// form (kept as JSON: the theme layer doesn't know about backgrounds).
@override Map<String, dynamic>? get background {
  final value = _background;
  if (value == null) return null;
  if (_background is EqualUnmodifiableMapView) return _background;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of ThemeConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ThemeConfigCopyWith<_ThemeConfig> get copyWith => __$ThemeConfigCopyWithImpl<_ThemeConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ThemeConfigToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ThemeConfig&&(identical(other.name, name) || other.name == name)&&(identical(other.primaryColor, primaryColor) || other.primaryColor == primaryColor)&&(identical(other.accentColor, accentColor) || other.accentColor == accentColor)&&(identical(other.brightness, brightness) || other.brightness == brightness)&&(identical(other.cornerRadius, cornerRadius) || other.cornerRadius == cornerRadius)&&(identical(other.fontFamily, fontFamily) || other.fontFamily == fontFamily)&&(identical(other.glassIntensity, glassIntensity) || other.glassIntensity == glassIntensity)&&(identical(other.animationSpeed, animationSpeed) || other.animationSpeed == animationSpeed)&&(identical(other.dynamicColor, dynamicColor) || other.dynamicColor == dynamicColor)&&(identical(other.monochrome, monochrome) || other.monochrome == monochrome)&&const DeepCollectionEquality().equals(other.background, _background));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,name,primaryColor,accentColor,brightness,cornerRadius,fontFamily,glassIntensity,animationSpeed,dynamicColor,monochrome,const DeepCollectionEquality().hash(_background));
}

@override
String toString() {
    return 'ThemeConfig(name: $name, primaryColor: $primaryColor, accentColor: $accentColor, brightness: $brightness, cornerRadius: $cornerRadius, fontFamily: $fontFamily, glassIntensity: $glassIntensity, animationSpeed: $animationSpeed, dynamicColor: $dynamicColor, monochrome: $monochrome, background: $background)';
}


}

/// @nodoc
abstract mixin class _$ThemeConfigCopyWith<$Res> implements $ThemeConfigCopyWith<$Res> {
  factory _$ThemeConfigCopyWith(_ThemeConfig value, $Res Function(_ThemeConfig) _then) = __$ThemeConfigCopyWithImpl;
@override @useResult
$Res call({
 String name, int primaryColor, int accentColor, ThemeBrightnessMode brightness, double cornerRadius, String? fontFamily, double glassIntensity, double animationSpeed, bool dynamicColor, bool monochrome, Map<String, dynamic>? background
});




}
/// @nodoc
class __$ThemeConfigCopyWithImpl<$Res>
    implements _$ThemeConfigCopyWith<$Res> {
  __$ThemeConfigCopyWithImpl(this._self, this._then);

  final _ThemeConfig _self;
  final $Res Function(_ThemeConfig) _then;

/// Create a copy of ThemeConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? primaryColor = null,Object? accentColor = null,Object? brightness = null,Object? cornerRadius = null,Object? fontFamily = freezed,Object? glassIntensity = null,Object? animationSpeed = null,Object? dynamicColor = null,Object? monochrome = null,Object? background = freezed,}) {
  return _then(_ThemeConfig(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,primaryColor: null == primaryColor ? _self.primaryColor : primaryColor // ignore: cast_nullable_to_non_nullable
as int,accentColor: null == accentColor ? _self.accentColor : accentColor // ignore: cast_nullable_to_non_nullable
as int,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as ThemeBrightnessMode,cornerRadius: null == cornerRadius ? _self.cornerRadius : cornerRadius // ignore: cast_nullable_to_non_nullable
as double,fontFamily: freezed == fontFamily ? _self.fontFamily : fontFamily // ignore: cast_nullable_to_non_nullable
as String?,glassIntensity: null == glassIntensity ? _self.glassIntensity : glassIntensity // ignore: cast_nullable_to_non_nullable
as double,animationSpeed: null == animationSpeed ? _self.animationSpeed : animationSpeed // ignore: cast_nullable_to_non_nullable
as double,dynamicColor: null == dynamicColor ? _self.dynamicColor : dynamicColor // ignore: cast_nullable_to_non_nullable
as bool,monochrome: null == monochrome ? _self.monochrome : monochrome // ignore: cast_nullable_to_non_nullable
as bool,background: freezed == background ? _self._background : background // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}

// dart format on

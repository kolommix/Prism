// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'background_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BgParams {

/// Use the theme's colors instead of [color] and [accent].
 bool get followTheme; int get color;/// Heads of the rain, links to the mouse, wave crests.
 int get accent;/// 0.1..1
 double get brightness;/// 0.2..3
 double get speed;/// 0.3..2: how much is on screen.
 double get density;/// 0.5..2: symbol / dot size.
 double get size;/// 0.2..2: trail length (Matrix), link length (Constellation), wave width (Ripple).
 double get reach;/// 0..2: reaction to the mouse.
 double get mouse;/// 0..2: reaction to the bass (analyses each song once when above 0).
 double get music;/// Matrix: a [MatrixGlyphs] name.
 String get glyphs;/// Matrix: the symbols for [MatrixGlyphs.custom].
 String get customGlyphs;/// Ripple: a [RippleShape] name.
 String get shape;
/// Create a copy of BgParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BgParamsCopyWith<BgParams> get copyWith => _$BgParamsCopyWithImpl<BgParams>(this as BgParams, _$identity);

  /// Serializes this BgParams to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BgParams;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BgParams&&(identical(other.followTheme, _this.followTheme) || other.followTheme == _this.followTheme)&&(identical(other.color, _this.color) || other.color == _this.color)&&(identical(other.accent, _this.accent) || other.accent == _this.accent)&&(identical(other.brightness, _this.brightness) || other.brightness == _this.brightness)&&(identical(other.speed, _this.speed) || other.speed == _this.speed)&&(identical(other.density, _this.density) || other.density == _this.density)&&(identical(other.size, _this.size) || other.size == _this.size)&&(identical(other.reach, _this.reach) || other.reach == _this.reach)&&(identical(other.mouse, _this.mouse) || other.mouse == _this.mouse)&&(identical(other.music, _this.music) || other.music == _this.music)&&(identical(other.glyphs, _this.glyphs) || other.glyphs == _this.glyphs)&&(identical(other.customGlyphs, _this.customGlyphs) || other.customGlyphs == _this.customGlyphs)&&(identical(other.shape, _this.shape) || other.shape == _this.shape));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BgParams;
  return Object.hash(runtimeType,_this.followTheme,_this.color,_this.accent,_this.brightness,_this.speed,_this.density,_this.size,_this.reach,_this.mouse,_this.music,_this.glyphs,_this.customGlyphs,_this.shape);
}

@override
String toString() {
  final _this = this as BgParams;
  return 'BgParams(followTheme: ${_this.followTheme}, color: ${_this.color}, accent: ${_this.accent}, brightness: ${_this.brightness}, speed: ${_this.speed}, density: ${_this.density}, size: ${_this.size}, reach: ${_this.reach}, mouse: ${_this.mouse}, music: ${_this.music}, glyphs: ${_this.glyphs}, customGlyphs: ${_this.customGlyphs}, shape: ${_this.shape})';
}


}

/// @nodoc
abstract mixin class $BgParamsCopyWith<$Res>  {
  factory $BgParamsCopyWith(BgParams value, $Res Function(BgParams) _then) = _$BgParamsCopyWithImpl;
@useResult
$Res call({
 bool followTheme, int color, int accent, double brightness, double speed, double density, double size, double reach, double mouse, double music, String glyphs, String customGlyphs, String shape
});




}
/// @nodoc
class _$BgParamsCopyWithImpl<$Res>
    implements $BgParamsCopyWith<$Res> {
  _$BgParamsCopyWithImpl(this._self, this._then);

  final BgParams _self;
  final $Res Function(BgParams) _then;

/// Create a copy of BgParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? followTheme = null,Object? color = null,Object? accent = null,Object? brightness = null,Object? speed = null,Object? density = null,Object? size = null,Object? reach = null,Object? mouse = null,Object? music = null,Object? glyphs = null,Object? customGlyphs = null,Object? shape = null,}) {
  return _then(BgParams(
followTheme: null == followTheme ? _self.followTheme : followTheme // ignore: cast_nullable_to_non_nullable
as bool,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,accent: null == accent ? _self.accent : accent // ignore: cast_nullable_to_non_nullable
as int,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as double,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,density: null == density ? _self.density : density // ignore: cast_nullable_to_non_nullable
as double,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as double,reach: null == reach ? _self.reach : reach // ignore: cast_nullable_to_non_nullable
as double,mouse: null == mouse ? _self.mouse : mouse // ignore: cast_nullable_to_non_nullable
as double,music: null == music ? _self.music : music // ignore: cast_nullable_to_non_nullable
as double,glyphs: null == glyphs ? _self.glyphs : glyphs // ignore: cast_nullable_to_non_nullable
as String,customGlyphs: null == customGlyphs ? _self.customGlyphs : customGlyphs // ignore: cast_nullable_to_non_nullable
as String,shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BgParams].
extension BgParamsPatterns on BgParams {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BgParams value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BgParams() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BgParams value)  $default,){
final _that = this;
switch (_that) {
case _BgParams():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BgParams value)?  $default,){
final _that = this;
switch (_that) {
case _BgParams() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool followTheme,  int color,  int accent,  double brightness,  double speed,  double density,  double size,  double reach,  double mouse,  double music,  String glyphs,  String customGlyphs,  String shape)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BgParams() when $default != null:
return $default(_that.followTheme,_that.color,_that.accent,_that.brightness,_that.speed,_that.density,_that.size,_that.reach,_that.mouse,_that.music,_that.glyphs,_that.customGlyphs,_that.shape);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool followTheme,  int color,  int accent,  double brightness,  double speed,  double density,  double size,  double reach,  double mouse,  double music,  String glyphs,  String customGlyphs,  String shape)  $default,) {final _that = this;
switch (_that) {
case _BgParams():
return $default(_that.followTheme,_that.color,_that.accent,_that.brightness,_that.speed,_that.density,_that.size,_that.reach,_that.mouse,_that.music,_that.glyphs,_that.customGlyphs,_that.shape);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool followTheme,  int color,  int accent,  double brightness,  double speed,  double density,  double size,  double reach,  double mouse,  double music,  String glyphs,  String customGlyphs,  String shape)?  $default,) {final _that = this;
switch (_that) {
case _BgParams() when $default != null:
return $default(_that.followTheme,_that.color,_that.accent,_that.brightness,_that.speed,_that.density,_that.size,_that.reach,_that.mouse,_that.music,_that.glyphs,_that.customGlyphs,_that.shape);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BgParams extends BgParams {
  const _BgParams({this.followTheme = true, this.color = 0xFF35E07A, this.accent = 0xFFD9FFE6, this.brightness = 0.7, this.speed = 1.0, this.density = 1.0, this.size = 1.0, this.reach = 1.0, this.mouse = 1.0, this.music = 0.8, this.glyphs = 'katakana', this.customGlyphs = 'PRISM', this.shape = 'dots'}): super._();
  factory _BgParams.fromJson(Map<String, dynamic> json) => _$BgParamsFromJson(json);

/// Use the theme's colors instead of [color] and [accent].
@override@JsonKey() final  bool followTheme;
@override@JsonKey() final  int color;
/// Heads of the rain, links to the mouse, wave crests.
@override@JsonKey() final  int accent;
/// 0.1..1
@override@JsonKey() final  double brightness;
/// 0.2..3
@override@JsonKey() final  double speed;
/// 0.3..2: how much is on screen.
@override@JsonKey() final  double density;
/// 0.5..2: symbol / dot size.
@override@JsonKey() final  double size;
/// 0.2..2: trail length (Matrix), link length (Constellation), wave width (Ripple).
@override@JsonKey() final  double reach;
/// 0..2: reaction to the mouse.
@override@JsonKey() final  double mouse;
/// 0..2: reaction to the bass (analyses each song once when above 0).
@override@JsonKey() final  double music;
/// Matrix: a [MatrixGlyphs] name.
@override@JsonKey() final  String glyphs;
/// Matrix: the symbols for [MatrixGlyphs.custom].
@override@JsonKey() final  String customGlyphs;
/// Ripple: a [RippleShape] name.
@override@JsonKey() final  String shape;

/// Create a copy of BgParams
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BgParamsCopyWith<_BgParams> get copyWith => __$BgParamsCopyWithImpl<_BgParams>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BgParamsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BgParams&&(identical(other.followTheme, followTheme) || other.followTheme == followTheme)&&(identical(other.color, color) || other.color == color)&&(identical(other.accent, accent) || other.accent == accent)&&(identical(other.brightness, brightness) || other.brightness == brightness)&&(identical(other.speed, speed) || other.speed == speed)&&(identical(other.density, density) || other.density == density)&&(identical(other.size, size) || other.size == size)&&(identical(other.reach, reach) || other.reach == reach)&&(identical(other.mouse, mouse) || other.mouse == mouse)&&(identical(other.music, music) || other.music == music)&&(identical(other.glyphs, glyphs) || other.glyphs == glyphs)&&(identical(other.customGlyphs, customGlyphs) || other.customGlyphs == customGlyphs)&&(identical(other.shape, shape) || other.shape == shape));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,followTheme,color,accent,brightness,speed,density,size,reach,mouse,music,glyphs,customGlyphs,shape);
}

@override
String toString() {
    return 'BgParams(followTheme: $followTheme, color: $color, accent: $accent, brightness: $brightness, speed: $speed, density: $density, size: $size, reach: $reach, mouse: $mouse, music: $music, glyphs: $glyphs, customGlyphs: $customGlyphs, shape: $shape)';
}


}

/// @nodoc
abstract mixin class _$BgParamsCopyWith<$Res> implements $BgParamsCopyWith<$Res> {
  factory _$BgParamsCopyWith(_BgParams value, $Res Function(_BgParams) _then) = __$BgParamsCopyWithImpl;
@override @useResult
$Res call({
 bool followTheme, int color, int accent, double brightness, double speed, double density, double size, double reach, double mouse, double music, String glyphs, String customGlyphs, String shape
});




}
/// @nodoc
class __$BgParamsCopyWithImpl<$Res>
    implements _$BgParamsCopyWith<$Res> {
  __$BgParamsCopyWithImpl(this._self, this._then);

  final _BgParams _self;
  final $Res Function(_BgParams) _then;

/// Create a copy of BgParams
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? followTheme = null,Object? color = null,Object? accent = null,Object? brightness = null,Object? speed = null,Object? density = null,Object? size = null,Object? reach = null,Object? mouse = null,Object? music = null,Object? glyphs = null,Object? customGlyphs = null,Object? shape = null,}) {
  return _then(_BgParams(
followTheme: null == followTheme ? _self.followTheme : followTheme // ignore: cast_nullable_to_non_nullable
as bool,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,accent: null == accent ? _self.accent : accent // ignore: cast_nullable_to_non_nullable
as int,brightness: null == brightness ? _self.brightness : brightness // ignore: cast_nullable_to_non_nullable
as double,speed: null == speed ? _self.speed : speed // ignore: cast_nullable_to_non_nullable
as double,density: null == density ? _self.density : density // ignore: cast_nullable_to_non_nullable
as double,size: null == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as double,reach: null == reach ? _self.reach : reach // ignore: cast_nullable_to_non_nullable
as double,mouse: null == mouse ? _self.mouse : mouse // ignore: cast_nullable_to_non_nullable
as double,music: null == music ? _self.music : music // ignore: cast_nullable_to_non_nullable
as double,glyphs: null == glyphs ? _self.glyphs : glyphs // ignore: cast_nullable_to_non_nullable
as String,customGlyphs: null == customGlyphs ? _self.customGlyphs : customGlyphs // ignore: cast_nullable_to_non_nullable
as String,shape: null == shape ? _self.shape : shape // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BackgroundConfig {

/// A [BackgroundStyle] name.
 String get style; BgParams get matrix; BgParams get constellation; BgParams get ripple;/// 0.15..1: how solid the panels are while an animated background runs.
 double get panelOpacity;/// The blurred cover stays visible under the animation.
 bool get showCover;/// Frames per second, 0 = as fast as the screen (the smoothest).
 int get frameRate;/// Panels blur what is behind them, like frosted glass.
 bool get frosted;/// 0..1 how out of focus the animation is, so it stays in the background.
 double get softness;/// 0.2..1 how strongly the animation shows at all.
 double get strength;/// Stop the animation while the music is paused (saves power).
 bool get onlyWhilePlaying;/// Settings of the styles without a field of their own, by style name.
 Map<String, BgParams> get extra;/// A [GradientPreset] id.
 String get gradientPreset;/// Our copy of the user's picture, and the folder of their video's frames.
 String get imagePath; String get videoDir;/// 0..0.9 black over the background, so text stays readable.
 double get dim;/// The background shifts a little with the mouse.
 bool get parallax;/// 20 fps, fewer details, no blur, no frosted panels.
 bool get batterySaver;
/// Create a copy of BackgroundConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BackgroundConfigCopyWith<BackgroundConfig> get copyWith => _$BackgroundConfigCopyWithImpl<BackgroundConfig>(this as BackgroundConfig, _$identity);

  /// Serializes this BackgroundConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BackgroundConfig;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BackgroundConfig&&(identical(other.style, _this.style) || other.style == _this.style)&&(identical(other.matrix, _this.matrix) || other.matrix == _this.matrix)&&(identical(other.constellation, _this.constellation) || other.constellation == _this.constellation)&&(identical(other.ripple, _this.ripple) || other.ripple == _this.ripple)&&(identical(other.panelOpacity, _this.panelOpacity) || other.panelOpacity == _this.panelOpacity)&&(identical(other.showCover, _this.showCover) || other.showCover == _this.showCover)&&(identical(other.frameRate, _this.frameRate) || other.frameRate == _this.frameRate)&&(identical(other.frosted, _this.frosted) || other.frosted == _this.frosted)&&(identical(other.softness, _this.softness) || other.softness == _this.softness)&&(identical(other.strength, _this.strength) || other.strength == _this.strength)&&(identical(other.onlyWhilePlaying, _this.onlyWhilePlaying) || other.onlyWhilePlaying == _this.onlyWhilePlaying)&&const DeepCollectionEquality().equals(other.extra, _this.extra)&&(identical(other.gradientPreset, _this.gradientPreset) || other.gradientPreset == _this.gradientPreset)&&(identical(other.imagePath, _this.imagePath) || other.imagePath == _this.imagePath)&&(identical(other.videoDir, _this.videoDir) || other.videoDir == _this.videoDir)&&(identical(other.dim, _this.dim) || other.dim == _this.dim)&&(identical(other.parallax, _this.parallax) || other.parallax == _this.parallax)&&(identical(other.batterySaver, _this.batterySaver) || other.batterySaver == _this.batterySaver));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BackgroundConfig;
  return Object.hash(runtimeType,_this.style,_this.matrix,_this.constellation,_this.ripple,_this.panelOpacity,_this.showCover,_this.frameRate,_this.frosted,_this.softness,_this.strength,_this.onlyWhilePlaying,const DeepCollectionEquality().hash(_this.extra),_this.gradientPreset,_this.imagePath,_this.videoDir,_this.dim,_this.parallax,_this.batterySaver);
}

@override
String toString() {
  final _this = this as BackgroundConfig;
  return 'BackgroundConfig(style: ${_this.style}, matrix: ${_this.matrix}, constellation: ${_this.constellation}, ripple: ${_this.ripple}, panelOpacity: ${_this.panelOpacity}, showCover: ${_this.showCover}, frameRate: ${_this.frameRate}, frosted: ${_this.frosted}, softness: ${_this.softness}, strength: ${_this.strength}, onlyWhilePlaying: ${_this.onlyWhilePlaying}, extra: ${_this.extra}, gradientPreset: ${_this.gradientPreset}, imagePath: ${_this.imagePath}, videoDir: ${_this.videoDir}, dim: ${_this.dim}, parallax: ${_this.parallax}, batterySaver: ${_this.batterySaver})';
}


}

/// @nodoc
abstract mixin class $BackgroundConfigCopyWith<$Res>  {
  factory $BackgroundConfigCopyWith(BackgroundConfig value, $Res Function(BackgroundConfig) _then) = _$BackgroundConfigCopyWithImpl;
@useResult
$Res call({
 String style, BgParams matrix, BgParams constellation, BgParams ripple, double panelOpacity, bool showCover, int frameRate, bool frosted, double softness, double strength, bool onlyWhilePlaying, Map<String, BgParams> extra, String gradientPreset, String imagePath, String videoDir, double dim, bool parallax, bool batterySaver
});


$BgParamsCopyWith<$Res> get matrix;$BgParamsCopyWith<$Res> get constellation;$BgParamsCopyWith<$Res> get ripple;

}
/// @nodoc
class _$BackgroundConfigCopyWithImpl<$Res>
    implements $BackgroundConfigCopyWith<$Res> {
  _$BackgroundConfigCopyWithImpl(this._self, this._then);

  final BackgroundConfig _self;
  final $Res Function(BackgroundConfig) _then;

/// Create a copy of BackgroundConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? style = null,Object? matrix = null,Object? constellation = null,Object? ripple = null,Object? panelOpacity = null,Object? showCover = null,Object? frameRate = null,Object? frosted = null,Object? softness = null,Object? strength = null,Object? onlyWhilePlaying = null,Object? extra = null,Object? gradientPreset = null,Object? imagePath = null,Object? videoDir = null,Object? dim = null,Object? parallax = null,Object? batterySaver = null,}) {
  return _then(BackgroundConfig(
style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as String,matrix: null == matrix ? _self.matrix : matrix // ignore: cast_nullable_to_non_nullable
as BgParams,constellation: null == constellation ? _self.constellation : constellation // ignore: cast_nullable_to_non_nullable
as BgParams,ripple: null == ripple ? _self.ripple : ripple // ignore: cast_nullable_to_non_nullable
as BgParams,panelOpacity: null == panelOpacity ? _self.panelOpacity : panelOpacity // ignore: cast_nullable_to_non_nullable
as double,showCover: null == showCover ? _self.showCover : showCover // ignore: cast_nullable_to_non_nullable
as bool,frameRate: null == frameRate ? _self.frameRate : frameRate // ignore: cast_nullable_to_non_nullable
as int,frosted: null == frosted ? _self.frosted : frosted // ignore: cast_nullable_to_non_nullable
as bool,softness: null == softness ? _self.softness : softness // ignore: cast_nullable_to_non_nullable
as double,strength: null == strength ? _self.strength : strength // ignore: cast_nullable_to_non_nullable
as double,onlyWhilePlaying: null == onlyWhilePlaying ? _self.onlyWhilePlaying : onlyWhilePlaying // ignore: cast_nullable_to_non_nullable
as bool,extra: null == extra ? _self.extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, BgParams>,gradientPreset: null == gradientPreset ? _self.gradientPreset : gradientPreset // ignore: cast_nullable_to_non_nullable
as String,imagePath: null == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String,videoDir: null == videoDir ? _self.videoDir : videoDir // ignore: cast_nullable_to_non_nullable
as String,dim: null == dim ? _self.dim : dim // ignore: cast_nullable_to_non_nullable
as double,parallax: null == parallax ? _self.parallax : parallax // ignore: cast_nullable_to_non_nullable
as bool,batterySaver: null == batterySaver ? _self.batterySaver : batterySaver // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of BackgroundConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BgParamsCopyWith<$Res> get matrix {
  
  return $BgParamsCopyWith<$Res>(_self.matrix, (value) {
    return _then(_self.copyWith(matrix: value));
  });
}/// Create a copy of BackgroundConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BgParamsCopyWith<$Res> get constellation {
  
  return $BgParamsCopyWith<$Res>(_self.constellation, (value) {
    return _then(_self.copyWith(constellation: value));
  });
}/// Create a copy of BackgroundConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BgParamsCopyWith<$Res> get ripple {
  
  return $BgParamsCopyWith<$Res>(_self.ripple, (value) {
    return _then(_self.copyWith(ripple: value));
  });
}
}


/// Adds pattern-matching-related methods to [BackgroundConfig].
extension BackgroundConfigPatterns on BackgroundConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BackgroundConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BackgroundConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BackgroundConfig value)  $default,){
final _that = this;
switch (_that) {
case _BackgroundConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BackgroundConfig value)?  $default,){
final _that = this;
switch (_that) {
case _BackgroundConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String style,  BgParams matrix,  BgParams constellation,  BgParams ripple,  double panelOpacity,  bool showCover,  int frameRate,  bool frosted,  double softness,  double strength,  bool onlyWhilePlaying,  Map<String, BgParams> extra,  String gradientPreset,  String imagePath,  String videoDir,  double dim,  bool parallax,  bool batterySaver)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BackgroundConfig() when $default != null:
return $default(_that.style,_that.matrix,_that.constellation,_that.ripple,_that.panelOpacity,_that.showCover,_that.frameRate,_that.frosted,_that.softness,_that.strength,_that.onlyWhilePlaying,_that.extra,_that.gradientPreset,_that.imagePath,_that.videoDir,_that.dim,_that.parallax,_that.batterySaver);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String style,  BgParams matrix,  BgParams constellation,  BgParams ripple,  double panelOpacity,  bool showCover,  int frameRate,  bool frosted,  double softness,  double strength,  bool onlyWhilePlaying,  Map<String, BgParams> extra,  String gradientPreset,  String imagePath,  String videoDir,  double dim,  bool parallax,  bool batterySaver)  $default,) {final _that = this;
switch (_that) {
case _BackgroundConfig():
return $default(_that.style,_that.matrix,_that.constellation,_that.ripple,_that.panelOpacity,_that.showCover,_that.frameRate,_that.frosted,_that.softness,_that.strength,_that.onlyWhilePlaying,_that.extra,_that.gradientPreset,_that.imagePath,_that.videoDir,_that.dim,_that.parallax,_that.batterySaver);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String style,  BgParams matrix,  BgParams constellation,  BgParams ripple,  double panelOpacity,  bool showCover,  int frameRate,  bool frosted,  double softness,  double strength,  bool onlyWhilePlaying,  Map<String, BgParams> extra,  String gradientPreset,  String imagePath,  String videoDir,  double dim,  bool parallax,  bool batterySaver)?  $default,) {final _that = this;
switch (_that) {
case _BackgroundConfig() when $default != null:
return $default(_that.style,_that.matrix,_that.constellation,_that.ripple,_that.panelOpacity,_that.showCover,_that.frameRate,_that.frosted,_that.softness,_that.strength,_that.onlyWhilePlaying,_that.extra,_that.gradientPreset,_that.imagePath,_that.videoDir,_that.dim,_that.parallax,_that.batterySaver);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BackgroundConfig extends BackgroundConfig {
  const _BackgroundConfig({this.style = 'cover', this.matrix = matrixDefaults, this.constellation = constellationDefaults, this.ripple = rippleDefaults, this.panelOpacity = 0.4, this.showCover = false, this.frameRate = 0, this.frosted = true, this.softness = 0.2, this.strength = 1.0, this.onlyWhilePlaying = false,  Map<String, BgParams> extra = const <String, BgParams>{}, this.gradientPreset = 'dusk', this.imagePath = '', this.videoDir = '', this.dim = 0.0, this.parallax = false, this.batterySaver = false}): _extra = extra,super._();
  factory _BackgroundConfig.fromJson(Map<String, dynamic> json) => _$BackgroundConfigFromJson(json);

/// A [BackgroundStyle] name.
@override@JsonKey() final  String style;
@override@JsonKey() final  BgParams matrix;
@override@JsonKey() final  BgParams constellation;
@override@JsonKey() final  BgParams ripple;
/// 0.15..1: how solid the panels are while an animated background runs.
@override@JsonKey() final  double panelOpacity;
/// The blurred cover stays visible under the animation.
@override@JsonKey() final  bool showCover;
/// Frames per second, 0 = as fast as the screen (the smoothest).
@override@JsonKey() final  int frameRate;
/// Panels blur what is behind them, like frosted glass.
@override@JsonKey() final  bool frosted;
/// 0..1 how out of focus the animation is, so it stays in the background.
@override@JsonKey() final  double softness;
/// 0.2..1 how strongly the animation shows at all.
@override@JsonKey() final  double strength;
/// Stop the animation while the music is paused (saves power).
@override@JsonKey() final  bool onlyWhilePlaying;
/// Settings of the styles without a field of their own, by style name.
 final  Map<String, BgParams> _extra;
/// Settings of the styles without a field of their own, by style name.
@override@JsonKey() Map<String, BgParams> get extra {
  if (_extra is EqualUnmodifiableMapView) return _extra;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_extra);
}

/// A [GradientPreset] id.
@override@JsonKey() final  String gradientPreset;
/// Our copy of the user's picture, and the folder of their video's frames.
@override@JsonKey() final  String imagePath;
@override@JsonKey() final  String videoDir;
/// 0..0.9 black over the background, so text stays readable.
@override@JsonKey() final  double dim;
/// The background shifts a little with the mouse.
@override@JsonKey() final  bool parallax;
/// 20 fps, fewer details, no blur, no frosted panels.
@override@JsonKey() final  bool batterySaver;

/// Create a copy of BackgroundConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BackgroundConfigCopyWith<_BackgroundConfig> get copyWith => __$BackgroundConfigCopyWithImpl<_BackgroundConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BackgroundConfigToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BackgroundConfig&&(identical(other.style, style) || other.style == style)&&(identical(other.matrix, matrix) || other.matrix == matrix)&&(identical(other.constellation, constellation) || other.constellation == constellation)&&(identical(other.ripple, ripple) || other.ripple == ripple)&&(identical(other.panelOpacity, panelOpacity) || other.panelOpacity == panelOpacity)&&(identical(other.showCover, showCover) || other.showCover == showCover)&&(identical(other.frameRate, frameRate) || other.frameRate == frameRate)&&(identical(other.frosted, frosted) || other.frosted == frosted)&&(identical(other.softness, softness) || other.softness == softness)&&(identical(other.strength, strength) || other.strength == strength)&&(identical(other.onlyWhilePlaying, onlyWhilePlaying) || other.onlyWhilePlaying == onlyWhilePlaying)&&const DeepCollectionEquality().equals(other.extra, _extra)&&(identical(other.gradientPreset, gradientPreset) || other.gradientPreset == gradientPreset)&&(identical(other.imagePath, imagePath) || other.imagePath == imagePath)&&(identical(other.videoDir, videoDir) || other.videoDir == videoDir)&&(identical(other.dim, dim) || other.dim == dim)&&(identical(other.parallax, parallax) || other.parallax == parallax)&&(identical(other.batterySaver, batterySaver) || other.batterySaver == batterySaver));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,style,matrix,constellation,ripple,panelOpacity,showCover,frameRate,frosted,softness,strength,onlyWhilePlaying,const DeepCollectionEquality().hash(_extra),gradientPreset,imagePath,videoDir,dim,parallax,batterySaver);
}

@override
String toString() {
    return 'BackgroundConfig(style: $style, matrix: $matrix, constellation: $constellation, ripple: $ripple, panelOpacity: $panelOpacity, showCover: $showCover, frameRate: $frameRate, frosted: $frosted, softness: $softness, strength: $strength, onlyWhilePlaying: $onlyWhilePlaying, extra: $extra, gradientPreset: $gradientPreset, imagePath: $imagePath, videoDir: $videoDir, dim: $dim, parallax: $parallax, batterySaver: $batterySaver)';
}


}

/// @nodoc
abstract mixin class _$BackgroundConfigCopyWith<$Res> implements $BackgroundConfigCopyWith<$Res> {
  factory _$BackgroundConfigCopyWith(_BackgroundConfig value, $Res Function(_BackgroundConfig) _then) = __$BackgroundConfigCopyWithImpl;
@override @useResult
$Res call({
 String style, BgParams matrix, BgParams constellation, BgParams ripple, double panelOpacity, bool showCover, int frameRate, bool frosted, double softness, double strength, bool onlyWhilePlaying, Map<String, BgParams> extra, String gradientPreset, String imagePath, String videoDir, double dim, bool parallax, bool batterySaver
});


@override $BgParamsCopyWith<$Res> get matrix;@override $BgParamsCopyWith<$Res> get constellation;@override $BgParamsCopyWith<$Res> get ripple;

}
/// @nodoc
class __$BackgroundConfigCopyWithImpl<$Res>
    implements _$BackgroundConfigCopyWith<$Res> {
  __$BackgroundConfigCopyWithImpl(this._self, this._then);

  final _BackgroundConfig _self;
  final $Res Function(_BackgroundConfig) _then;

/// Create a copy of BackgroundConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? style = null,Object? matrix = null,Object? constellation = null,Object? ripple = null,Object? panelOpacity = null,Object? showCover = null,Object? frameRate = null,Object? frosted = null,Object? softness = null,Object? strength = null,Object? onlyWhilePlaying = null,Object? extra = null,Object? gradientPreset = null,Object? imagePath = null,Object? videoDir = null,Object? dim = null,Object? parallax = null,Object? batterySaver = null,}) {
  return _then(_BackgroundConfig(
style: null == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as String,matrix: null == matrix ? _self.matrix : matrix // ignore: cast_nullable_to_non_nullable
as BgParams,constellation: null == constellation ? _self.constellation : constellation // ignore: cast_nullable_to_non_nullable
as BgParams,ripple: null == ripple ? _self.ripple : ripple // ignore: cast_nullable_to_non_nullable
as BgParams,panelOpacity: null == panelOpacity ? _self.panelOpacity : panelOpacity // ignore: cast_nullable_to_non_nullable
as double,showCover: null == showCover ? _self.showCover : showCover // ignore: cast_nullable_to_non_nullable
as bool,frameRate: null == frameRate ? _self.frameRate : frameRate // ignore: cast_nullable_to_non_nullable
as int,frosted: null == frosted ? _self.frosted : frosted // ignore: cast_nullable_to_non_nullable
as bool,softness: null == softness ? _self.softness : softness // ignore: cast_nullable_to_non_nullable
as double,strength: null == strength ? _self.strength : strength // ignore: cast_nullable_to_non_nullable
as double,onlyWhilePlaying: null == onlyWhilePlaying ? _self.onlyWhilePlaying : onlyWhilePlaying // ignore: cast_nullable_to_non_nullable
as bool,extra: null == extra ? _self._extra : extra // ignore: cast_nullable_to_non_nullable
as Map<String, BgParams>,gradientPreset: null == gradientPreset ? _self.gradientPreset : gradientPreset // ignore: cast_nullable_to_non_nullable
as String,imagePath: null == imagePath ? _self.imagePath : imagePath // ignore: cast_nullable_to_non_nullable
as String,videoDir: null == videoDir ? _self.videoDir : videoDir // ignore: cast_nullable_to_non_nullable
as String,dim: null == dim ? _self.dim : dim // ignore: cast_nullable_to_non_nullable
as double,parallax: null == parallax ? _self.parallax : parallax // ignore: cast_nullable_to_non_nullable
as bool,batterySaver: null == batterySaver ? _self.batterySaver : batterySaver // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of BackgroundConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BgParamsCopyWith<$Res> get matrix {
  
  return $BgParamsCopyWith<$Res>(_self.matrix, (value) {
    return _then(_self.copyWith(matrix: value));
  });
}/// Create a copy of BackgroundConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BgParamsCopyWith<$Res> get constellation {
  
  return $BgParamsCopyWith<$Res>(_self.constellation, (value) {
    return _then(_self.copyWith(constellation: value));
  });
}/// Create a copy of BackgroundConfig
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BgParamsCopyWith<$Res> get ripple {
  
  return $BgParamsCopyWith<$Res>(_self.ripple, (value) {
    return _then(_self.copyWith(ripple: value));
  });
}
}

// dart format on

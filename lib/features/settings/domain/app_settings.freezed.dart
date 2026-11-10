// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppSettings {

 ThemeConfig get theme;/// Asks GitHub for a newer version when the app starts, at most once a day.
 bool get autoCheckUpdates;/// App language: '' = same as the system, 'en', 'ru'.
 String get localeCode;/// Turns most animations off (also honoured: the OS accessibility flag).
 bool get reduceMotion;/// 0 = gapless, otherwise crossfade length in seconds.
 int get crossfadeSeconds;/// Windows: closing the window keeps playing in the tray.
 bool get closeToTray;/// Windows: a little more processor time than normal programs, so music
/// and the screen don't stutter when the PC is busy (ProcessPriority).
 bool get highPriority;/// Loudness normalisation (ReplayGain tags or Prism's own measurement).
 NormalizationMode get normalization;/// Measure loudness in the background for tracks without ReplayGain tags.
 bool get autoAnalyzeLoudness;/// Look up lyrics on lrclib.net (sends title/artist/album/duration only).
 bool get onlineLyrics;/// Find missing covers, artists and albums online (sends title and artist
/// to Apple's and Deezer's public search). Files are never changed.
 bool get autoFindInfo;/// Visualizer style in the full player.
 String get visualizerStyle;/// How strongly the visualizer reacts, 0.5..2.
 double get visualizerSensitivity;/// 30 fps and fewer details.
 bool get visualizerLowPower;/// Android: real-time FFT of what is playing (needs the microphone
/// permission). Off = analysis of the file, which needs no permission.
 bool get visualizerLive;/// A `SeekBarStyle` name.
 String get seekBarStyle;/// Every seek bar style moves with the music (analyses each song once).
 bool get liveSeekBar;/// Seek bar look, for every style: own color (null = theme), size, number
/// and thickness of the bars, brightness of the unplayed part, how much
/// it moves with the music, the playhead and the time labels.
 int? get seekBarColor; double get seekBarSize; double get seekBarDensity; double get seekBarThickness; double get seekBarDim; double get seekBarReact; bool get seekBarHead; bool get seekBarTimes;/// Cover or animated background, all of its settings.
 BackgroundConfig get background;/// Listen together through your own relay: `ws://` / `wss://` URL
/// (`dart run tool/relay.dart`). Empty = the free public server.
 String get relayUrl;/// Sessions also work over the internet (song names pass through a free
/// public message server, scrambled with the session code). Off = same
/// Wi-Fi only, nothing leaves the network.
 bool get togetherInternet;/// Name friends see in a session; empty = the computer's name.
 String get togetherName;/// Listen together: friends may play, pause, skip, seek and add songs.
 bool get togetherGuestControl;/// Equalizer page: all 10 bands instead of Bass / Mids / Treble.
 bool get eqDetailed;/// Windows: show "Listening to …" on Discord.
 bool get discordPresence;/// Overrides the app id built into Prism; empty = the built-in one.
 String get discordClientId;/// Look up album art and links for the status (sends title + artist to
/// Apple's and Deezer's public search).
 bool get discordCovers;
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSettingsCopyWith<AppSettings> get copyWith => _$AppSettingsCopyWithImpl<AppSettings>(this as AppSettings, _$identity);

  /// Serializes this AppSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as AppSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSettings&&(identical(other.theme, _this.theme) || other.theme == _this.theme)&&(identical(other.autoCheckUpdates, _this.autoCheckUpdates) || other.autoCheckUpdates == _this.autoCheckUpdates)&&(identical(other.localeCode, _this.localeCode) || other.localeCode == _this.localeCode)&&(identical(other.reduceMotion, _this.reduceMotion) || other.reduceMotion == _this.reduceMotion)&&(identical(other.crossfadeSeconds, _this.crossfadeSeconds) || other.crossfadeSeconds == _this.crossfadeSeconds)&&(identical(other.closeToTray, _this.closeToTray) || other.closeToTray == _this.closeToTray)&&(identical(other.highPriority, _this.highPriority) || other.highPriority == _this.highPriority)&&(identical(other.normalization, _this.normalization) || other.normalization == _this.normalization)&&(identical(other.autoAnalyzeLoudness, _this.autoAnalyzeLoudness) || other.autoAnalyzeLoudness == _this.autoAnalyzeLoudness)&&(identical(other.onlineLyrics, _this.onlineLyrics) || other.onlineLyrics == _this.onlineLyrics)&&(identical(other.autoFindInfo, _this.autoFindInfo) || other.autoFindInfo == _this.autoFindInfo)&&(identical(other.visualizerStyle, _this.visualizerStyle) || other.visualizerStyle == _this.visualizerStyle)&&(identical(other.visualizerSensitivity, _this.visualizerSensitivity) || other.visualizerSensitivity == _this.visualizerSensitivity)&&(identical(other.visualizerLowPower, _this.visualizerLowPower) || other.visualizerLowPower == _this.visualizerLowPower)&&(identical(other.visualizerLive, _this.visualizerLive) || other.visualizerLive == _this.visualizerLive)&&(identical(other.seekBarStyle, _this.seekBarStyle) || other.seekBarStyle == _this.seekBarStyle)&&(identical(other.liveSeekBar, _this.liveSeekBar) || other.liveSeekBar == _this.liveSeekBar)&&(identical(other.seekBarColor, _this.seekBarColor) || other.seekBarColor == _this.seekBarColor)&&(identical(other.seekBarSize, _this.seekBarSize) || other.seekBarSize == _this.seekBarSize)&&(identical(other.seekBarDensity, _this.seekBarDensity) || other.seekBarDensity == _this.seekBarDensity)&&(identical(other.seekBarThickness, _this.seekBarThickness) || other.seekBarThickness == _this.seekBarThickness)&&(identical(other.seekBarDim, _this.seekBarDim) || other.seekBarDim == _this.seekBarDim)&&(identical(other.seekBarReact, _this.seekBarReact) || other.seekBarReact == _this.seekBarReact)&&(identical(other.seekBarHead, _this.seekBarHead) || other.seekBarHead == _this.seekBarHead)&&(identical(other.seekBarTimes, _this.seekBarTimes) || other.seekBarTimes == _this.seekBarTimes)&&(identical(other.background, _this.background) || other.background == _this.background)&&(identical(other.relayUrl, _this.relayUrl) || other.relayUrl == _this.relayUrl)&&(identical(other.togetherInternet, _this.togetherInternet) || other.togetherInternet == _this.togetherInternet)&&(identical(other.togetherName, _this.togetherName) || other.togetherName == _this.togetherName)&&(identical(other.togetherGuestControl, _this.togetherGuestControl) || other.togetherGuestControl == _this.togetherGuestControl)&&(identical(other.eqDetailed, _this.eqDetailed) || other.eqDetailed == _this.eqDetailed)&&(identical(other.discordPresence, _this.discordPresence) || other.discordPresence == _this.discordPresence)&&(identical(other.discordClientId, _this.discordClientId) || other.discordClientId == _this.discordClientId)&&(identical(other.discordCovers, _this.discordCovers) || other.discordCovers == _this.discordCovers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as AppSettings;
  return Object.hashAll([runtimeType,_this.theme,_this.autoCheckUpdates,_this.localeCode,_this.reduceMotion,_this.crossfadeSeconds,_this.closeToTray,_this.highPriority,_this.normalization,_this.autoAnalyzeLoudness,_this.onlineLyrics,_this.autoFindInfo,_this.visualizerStyle,_this.visualizerSensitivity,_this.visualizerLowPower,_this.visualizerLive,_this.seekBarStyle,_this.liveSeekBar,_this.seekBarColor,_this.seekBarSize,_this.seekBarDensity,_this.seekBarThickness,_this.seekBarDim,_this.seekBarReact,_this.seekBarHead,_this.seekBarTimes,_this.background,_this.relayUrl,_this.togetherInternet,_this.togetherName,_this.togetherGuestControl,_this.eqDetailed,_this.discordPresence,_this.discordClientId,_this.discordCovers]);
}

@override
String toString() {
  final _this = this as AppSettings;
  return 'AppSettings(theme: ${_this.theme}, autoCheckUpdates: ${_this.autoCheckUpdates}, localeCode: ${_this.localeCode}, reduceMotion: ${_this.reduceMotion}, crossfadeSeconds: ${_this.crossfadeSeconds}, closeToTray: ${_this.closeToTray}, highPriority: ${_this.highPriority}, normalization: ${_this.normalization}, autoAnalyzeLoudness: ${_this.autoAnalyzeLoudness}, onlineLyrics: ${_this.onlineLyrics}, autoFindInfo: ${_this.autoFindInfo}, visualizerStyle: ${_this.visualizerStyle}, visualizerSensitivity: ${_this.visualizerSensitivity}, visualizerLowPower: ${_this.visualizerLowPower}, visualizerLive: ${_this.visualizerLive}, seekBarStyle: ${_this.seekBarStyle}, liveSeekBar: ${_this.liveSeekBar}, seekBarColor: ${_this.seekBarColor}, seekBarSize: ${_this.seekBarSize}, seekBarDensity: ${_this.seekBarDensity}, seekBarThickness: ${_this.seekBarThickness}, seekBarDim: ${_this.seekBarDim}, seekBarReact: ${_this.seekBarReact}, seekBarHead: ${_this.seekBarHead}, seekBarTimes: ${_this.seekBarTimes}, background: ${_this.background}, relayUrl: ${_this.relayUrl}, togetherInternet: ${_this.togetherInternet}, togetherName: ${_this.togetherName}, togetherGuestControl: ${_this.togetherGuestControl}, eqDetailed: ${_this.eqDetailed}, discordPresence: ${_this.discordPresence}, discordClientId: ${_this.discordClientId}, discordCovers: ${_this.discordCovers})';
}


}

/// @nodoc
abstract mixin class $AppSettingsCopyWith<$Res>  {
  factory $AppSettingsCopyWith(AppSettings value, $Res Function(AppSettings) _then) = _$AppSettingsCopyWithImpl;
@useResult
$Res call({
 ThemeConfig theme, bool autoCheckUpdates, String localeCode, bool reduceMotion, int crossfadeSeconds, bool closeToTray, bool highPriority, NormalizationMode normalization, bool autoAnalyzeLoudness, bool onlineLyrics, bool autoFindInfo, String visualizerStyle, double visualizerSensitivity, bool visualizerLowPower, bool visualizerLive, String seekBarStyle, bool liveSeekBar, int? seekBarColor, double seekBarSize, double seekBarDensity, double seekBarThickness, double seekBarDim, double seekBarReact, bool seekBarHead, bool seekBarTimes, BackgroundConfig background, String relayUrl, bool togetherInternet, String togetherName, bool togetherGuestControl, bool eqDetailed, bool discordPresence, String discordClientId, bool discordCovers
});


$ThemeConfigCopyWith<$Res> get theme;$BackgroundConfigCopyWith<$Res> get background;

}
/// @nodoc
class _$AppSettingsCopyWithImpl<$Res>
    implements $AppSettingsCopyWith<$Res> {
  _$AppSettingsCopyWithImpl(this._self, this._then);

  final AppSettings _self;
  final $Res Function(AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? theme = null,Object? autoCheckUpdates = null,Object? localeCode = null,Object? reduceMotion = null,Object? crossfadeSeconds = null,Object? closeToTray = null,Object? highPriority = null,Object? normalization = null,Object? autoAnalyzeLoudness = null,Object? onlineLyrics = null,Object? autoFindInfo = null,Object? visualizerStyle = null,Object? visualizerSensitivity = null,Object? visualizerLowPower = null,Object? visualizerLive = null,Object? seekBarStyle = null,Object? liveSeekBar = null,Object? seekBarColor = freezed,Object? seekBarSize = null,Object? seekBarDensity = null,Object? seekBarThickness = null,Object? seekBarDim = null,Object? seekBarReact = null,Object? seekBarHead = null,Object? seekBarTimes = null,Object? background = null,Object? relayUrl = null,Object? togetherInternet = null,Object? togetherName = null,Object? togetherGuestControl = null,Object? eqDetailed = null,Object? discordPresence = null,Object? discordClientId = null,Object? discordCovers = null,}) {
  return _then(AppSettings(
theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as ThemeConfig,autoCheckUpdates: null == autoCheckUpdates ? _self.autoCheckUpdates : autoCheckUpdates // ignore: cast_nullable_to_non_nullable
as bool,localeCode: null == localeCode ? _self.localeCode : localeCode // ignore: cast_nullable_to_non_nullable
as String,reduceMotion: null == reduceMotion ? _self.reduceMotion : reduceMotion // ignore: cast_nullable_to_non_nullable
as bool,crossfadeSeconds: null == crossfadeSeconds ? _self.crossfadeSeconds : crossfadeSeconds // ignore: cast_nullable_to_non_nullable
as int,closeToTray: null == closeToTray ? _self.closeToTray : closeToTray // ignore: cast_nullable_to_non_nullable
as bool,highPriority: null == highPriority ? _self.highPriority : highPriority // ignore: cast_nullable_to_non_nullable
as bool,normalization: null == normalization ? _self.normalization : normalization // ignore: cast_nullable_to_non_nullable
as NormalizationMode,autoAnalyzeLoudness: null == autoAnalyzeLoudness ? _self.autoAnalyzeLoudness : autoAnalyzeLoudness // ignore: cast_nullable_to_non_nullable
as bool,onlineLyrics: null == onlineLyrics ? _self.onlineLyrics : onlineLyrics // ignore: cast_nullable_to_non_nullable
as bool,autoFindInfo: null == autoFindInfo ? _self.autoFindInfo : autoFindInfo // ignore: cast_nullable_to_non_nullable
as bool,visualizerStyle: null == visualizerStyle ? _self.visualizerStyle : visualizerStyle // ignore: cast_nullable_to_non_nullable
as String,visualizerSensitivity: null == visualizerSensitivity ? _self.visualizerSensitivity : visualizerSensitivity // ignore: cast_nullable_to_non_nullable
as double,visualizerLowPower: null == visualizerLowPower ? _self.visualizerLowPower : visualizerLowPower // ignore: cast_nullable_to_non_nullable
as bool,visualizerLive: null == visualizerLive ? _self.visualizerLive : visualizerLive // ignore: cast_nullable_to_non_nullable
as bool,seekBarStyle: null == seekBarStyle ? _self.seekBarStyle : seekBarStyle // ignore: cast_nullable_to_non_nullable
as String,liveSeekBar: null == liveSeekBar ? _self.liveSeekBar : liveSeekBar // ignore: cast_nullable_to_non_nullable
as bool,seekBarColor: freezed == seekBarColor ? _self.seekBarColor : seekBarColor // ignore: cast_nullable_to_non_nullable
as int?,seekBarSize: null == seekBarSize ? _self.seekBarSize : seekBarSize // ignore: cast_nullable_to_non_nullable
as double,seekBarDensity: null == seekBarDensity ? _self.seekBarDensity : seekBarDensity // ignore: cast_nullable_to_non_nullable
as double,seekBarThickness: null == seekBarThickness ? _self.seekBarThickness : seekBarThickness // ignore: cast_nullable_to_non_nullable
as double,seekBarDim: null == seekBarDim ? _self.seekBarDim : seekBarDim // ignore: cast_nullable_to_non_nullable
as double,seekBarReact: null == seekBarReact ? _self.seekBarReact : seekBarReact // ignore: cast_nullable_to_non_nullable
as double,seekBarHead: null == seekBarHead ? _self.seekBarHead : seekBarHead // ignore: cast_nullable_to_non_nullable
as bool,seekBarTimes: null == seekBarTimes ? _self.seekBarTimes : seekBarTimes // ignore: cast_nullable_to_non_nullable
as bool,background: null == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as BackgroundConfig,relayUrl: null == relayUrl ? _self.relayUrl : relayUrl // ignore: cast_nullable_to_non_nullable
as String,togetherInternet: null == togetherInternet ? _self.togetherInternet : togetherInternet // ignore: cast_nullable_to_non_nullable
as bool,togetherName: null == togetherName ? _self.togetherName : togetherName // ignore: cast_nullable_to_non_nullable
as String,togetherGuestControl: null == togetherGuestControl ? _self.togetherGuestControl : togetherGuestControl // ignore: cast_nullable_to_non_nullable
as bool,eqDetailed: null == eqDetailed ? _self.eqDetailed : eqDetailed // ignore: cast_nullable_to_non_nullable
as bool,discordPresence: null == discordPresence ? _self.discordPresence : discordPresence // ignore: cast_nullable_to_non_nullable
as bool,discordClientId: null == discordClientId ? _self.discordClientId : discordClientId // ignore: cast_nullable_to_non_nullable
as String,discordCovers: null == discordCovers ? _self.discordCovers : discordCovers // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThemeConfigCopyWith<$Res> get theme {
  
  return $ThemeConfigCopyWith<$Res>(_self.theme, (value) {
    return _then(_self.copyWith(theme: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BackgroundConfigCopyWith<$Res> get background {
  
  return $BackgroundConfigCopyWith<$Res>(_self.background, (value) {
    return _then(_self.copyWith(background: value));
  });
}
}


/// Adds pattern-matching-related methods to [AppSettings].
extension AppSettingsPatterns on AppSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSettings value)  $default,){
final _that = this;
switch (_that) {
case _AppSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSettings value)?  $default,){
final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ThemeConfig theme,  bool autoCheckUpdates,  String localeCode,  bool reduceMotion,  int crossfadeSeconds,  bool closeToTray,  bool highPriority,  NormalizationMode normalization,  bool autoAnalyzeLoudness,  bool onlineLyrics,  bool autoFindInfo,  String visualizerStyle,  double visualizerSensitivity,  bool visualizerLowPower,  bool visualizerLive,  String seekBarStyle,  bool liveSeekBar,  int? seekBarColor,  double seekBarSize,  double seekBarDensity,  double seekBarThickness,  double seekBarDim,  double seekBarReact,  bool seekBarHead,  bool seekBarTimes,  BackgroundConfig background,  String relayUrl,  bool togetherInternet,  String togetherName,  bool togetherGuestControl,  bool eqDetailed,  bool discordPresence,  String discordClientId,  bool discordCovers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.theme,_that.autoCheckUpdates,_that.localeCode,_that.reduceMotion,_that.crossfadeSeconds,_that.closeToTray,_that.highPriority,_that.normalization,_that.autoAnalyzeLoudness,_that.onlineLyrics,_that.autoFindInfo,_that.visualizerStyle,_that.visualizerSensitivity,_that.visualizerLowPower,_that.visualizerLive,_that.seekBarStyle,_that.liveSeekBar,_that.seekBarColor,_that.seekBarSize,_that.seekBarDensity,_that.seekBarThickness,_that.seekBarDim,_that.seekBarReact,_that.seekBarHead,_that.seekBarTimes,_that.background,_that.relayUrl,_that.togetherInternet,_that.togetherName,_that.togetherGuestControl,_that.eqDetailed,_that.discordPresence,_that.discordClientId,_that.discordCovers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ThemeConfig theme,  bool autoCheckUpdates,  String localeCode,  bool reduceMotion,  int crossfadeSeconds,  bool closeToTray,  bool highPriority,  NormalizationMode normalization,  bool autoAnalyzeLoudness,  bool onlineLyrics,  bool autoFindInfo,  String visualizerStyle,  double visualizerSensitivity,  bool visualizerLowPower,  bool visualizerLive,  String seekBarStyle,  bool liveSeekBar,  int? seekBarColor,  double seekBarSize,  double seekBarDensity,  double seekBarThickness,  double seekBarDim,  double seekBarReact,  bool seekBarHead,  bool seekBarTimes,  BackgroundConfig background,  String relayUrl,  bool togetherInternet,  String togetherName,  bool togetherGuestControl,  bool eqDetailed,  bool discordPresence,  String discordClientId,  bool discordCovers)  $default,) {final _that = this;
switch (_that) {
case _AppSettings():
return $default(_that.theme,_that.autoCheckUpdates,_that.localeCode,_that.reduceMotion,_that.crossfadeSeconds,_that.closeToTray,_that.highPriority,_that.normalization,_that.autoAnalyzeLoudness,_that.onlineLyrics,_that.autoFindInfo,_that.visualizerStyle,_that.visualizerSensitivity,_that.visualizerLowPower,_that.visualizerLive,_that.seekBarStyle,_that.liveSeekBar,_that.seekBarColor,_that.seekBarSize,_that.seekBarDensity,_that.seekBarThickness,_that.seekBarDim,_that.seekBarReact,_that.seekBarHead,_that.seekBarTimes,_that.background,_that.relayUrl,_that.togetherInternet,_that.togetherName,_that.togetherGuestControl,_that.eqDetailed,_that.discordPresence,_that.discordClientId,_that.discordCovers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ThemeConfig theme,  bool autoCheckUpdates,  String localeCode,  bool reduceMotion,  int crossfadeSeconds,  bool closeToTray,  bool highPriority,  NormalizationMode normalization,  bool autoAnalyzeLoudness,  bool onlineLyrics,  bool autoFindInfo,  String visualizerStyle,  double visualizerSensitivity,  bool visualizerLowPower,  bool visualizerLive,  String seekBarStyle,  bool liveSeekBar,  int? seekBarColor,  double seekBarSize,  double seekBarDensity,  double seekBarThickness,  double seekBarDim,  double seekBarReact,  bool seekBarHead,  bool seekBarTimes,  BackgroundConfig background,  String relayUrl,  bool togetherInternet,  String togetherName,  bool togetherGuestControl,  bool eqDetailed,  bool discordPresence,  String discordClientId,  bool discordCovers)?  $default,) {final _that = this;
switch (_that) {
case _AppSettings() when $default != null:
return $default(_that.theme,_that.autoCheckUpdates,_that.localeCode,_that.reduceMotion,_that.crossfadeSeconds,_that.closeToTray,_that.highPriority,_that.normalization,_that.autoAnalyzeLoudness,_that.onlineLyrics,_that.autoFindInfo,_that.visualizerStyle,_that.visualizerSensitivity,_that.visualizerLowPower,_that.visualizerLive,_that.seekBarStyle,_that.liveSeekBar,_that.seekBarColor,_that.seekBarSize,_that.seekBarDensity,_that.seekBarThickness,_that.seekBarDim,_that.seekBarReact,_that.seekBarHead,_that.seekBarTimes,_that.background,_that.relayUrl,_that.togetherInternet,_that.togetherName,_that.togetherGuestControl,_that.eqDetailed,_that.discordPresence,_that.discordClientId,_that.discordCovers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppSettings extends AppSettings {
  const _AppSettings({this.theme = defaultTheme, this.autoCheckUpdates = true, this.localeCode = '', this.reduceMotion = false, this.crossfadeSeconds = 0, this.closeToTray = true, this.highPriority = true, this.normalization = NormalizationMode.off, this.autoAnalyzeLoudness = true, this.onlineLyrics = true, this.autoFindInfo = true, this.visualizerStyle = 'bars', this.visualizerSensitivity = 1.0, this.visualizerLowPower = false, this.visualizerLive = false, this.seekBarStyle = 'waveform', this.liveSeekBar = true, this.seekBarColor, this.seekBarSize = 1.0, this.seekBarDensity = 1.0, this.seekBarThickness = 1.0, this.seekBarDim = 0.18, this.seekBarReact = 1.0, this.seekBarHead = true, this.seekBarTimes = true, this.background = const BackgroundConfig(), this.relayUrl = '', this.togetherInternet = true, this.togetherName = '', this.togetherGuestControl = true, this.eqDetailed = false, this.discordPresence = false, this.discordClientId = '', this.discordCovers = true}): super._();
  factory _AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);

@override@JsonKey() final  ThemeConfig theme;
/// Asks GitHub for a newer version when the app starts, at most once a day.
@override@JsonKey() final  bool autoCheckUpdates;
/// App language: '' = same as the system, 'en', 'ru'.
@override@JsonKey() final  String localeCode;
/// Turns most animations off (also honoured: the OS accessibility flag).
@override@JsonKey() final  bool reduceMotion;
/// 0 = gapless, otherwise crossfade length in seconds.
@override@JsonKey() final  int crossfadeSeconds;
/// Windows: closing the window keeps playing in the tray.
@override@JsonKey() final  bool closeToTray;
/// Windows: a little more processor time than normal programs, so music
/// and the screen don't stutter when the PC is busy (ProcessPriority).
@override@JsonKey() final  bool highPriority;
/// Loudness normalisation (ReplayGain tags or Prism's own measurement).
@override@JsonKey() final  NormalizationMode normalization;
/// Measure loudness in the background for tracks without ReplayGain tags.
@override@JsonKey() final  bool autoAnalyzeLoudness;
/// Look up lyrics on lrclib.net (sends title/artist/album/duration only).
@override@JsonKey() final  bool onlineLyrics;
/// Find missing covers, artists and albums online (sends title and artist
/// to Apple's and Deezer's public search). Files are never changed.
@override@JsonKey() final  bool autoFindInfo;
/// Visualizer style in the full player.
@override@JsonKey() final  String visualizerStyle;
/// How strongly the visualizer reacts, 0.5..2.
@override@JsonKey() final  double visualizerSensitivity;
/// 30 fps and fewer details.
@override@JsonKey() final  bool visualizerLowPower;
/// Android: real-time FFT of what is playing (needs the microphone
/// permission). Off = analysis of the file, which needs no permission.
@override@JsonKey() final  bool visualizerLive;
/// A `SeekBarStyle` name.
@override@JsonKey() final  String seekBarStyle;
/// Every seek bar style moves with the music (analyses each song once).
@override@JsonKey() final  bool liveSeekBar;
/// Seek bar look, for every style: own color (null = theme), size, number
/// and thickness of the bars, brightness of the unplayed part, how much
/// it moves with the music, the playhead and the time labels.
@override final  int? seekBarColor;
@override@JsonKey() final  double seekBarSize;
@override@JsonKey() final  double seekBarDensity;
@override@JsonKey() final  double seekBarThickness;
@override@JsonKey() final  double seekBarDim;
@override@JsonKey() final  double seekBarReact;
@override@JsonKey() final  bool seekBarHead;
@override@JsonKey() final  bool seekBarTimes;
/// Cover or animated background, all of its settings.
@override@JsonKey() final  BackgroundConfig background;
/// Listen together through your own relay: `ws://` / `wss://` URL
/// (`dart run tool/relay.dart`). Empty = the free public server.
@override@JsonKey() final  String relayUrl;
/// Sessions also work over the internet (song names pass through a free
/// public message server, scrambled with the session code). Off = same
/// Wi-Fi only, nothing leaves the network.
@override@JsonKey() final  bool togetherInternet;
/// Name friends see in a session; empty = the computer's name.
@override@JsonKey() final  String togetherName;
/// Listen together: friends may play, pause, skip, seek and add songs.
@override@JsonKey() final  bool togetherGuestControl;
/// Equalizer page: all 10 bands instead of Bass / Mids / Treble.
@override@JsonKey() final  bool eqDetailed;
/// Windows: show "Listening to …" on Discord.
@override@JsonKey() final  bool discordPresence;
/// Overrides the app id built into Prism; empty = the built-in one.
@override@JsonKey() final  String discordClientId;
/// Look up album art and links for the status (sends title + artist to
/// Apple's and Deezer's public search).
@override@JsonKey() final  bool discordCovers;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSettingsCopyWith<_AppSettings> get copyWith => __$AppSettingsCopyWithImpl<_AppSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSettings&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.autoCheckUpdates, autoCheckUpdates) || other.autoCheckUpdates == autoCheckUpdates)&&(identical(other.localeCode, localeCode) || other.localeCode == localeCode)&&(identical(other.reduceMotion, reduceMotion) || other.reduceMotion == reduceMotion)&&(identical(other.crossfadeSeconds, crossfadeSeconds) || other.crossfadeSeconds == crossfadeSeconds)&&(identical(other.closeToTray, closeToTray) || other.closeToTray == closeToTray)&&(identical(other.highPriority, highPriority) || other.highPriority == highPriority)&&(identical(other.normalization, normalization) || other.normalization == normalization)&&(identical(other.autoAnalyzeLoudness, autoAnalyzeLoudness) || other.autoAnalyzeLoudness == autoAnalyzeLoudness)&&(identical(other.onlineLyrics, onlineLyrics) || other.onlineLyrics == onlineLyrics)&&(identical(other.autoFindInfo, autoFindInfo) || other.autoFindInfo == autoFindInfo)&&(identical(other.visualizerStyle, visualizerStyle) || other.visualizerStyle == visualizerStyle)&&(identical(other.visualizerSensitivity, visualizerSensitivity) || other.visualizerSensitivity == visualizerSensitivity)&&(identical(other.visualizerLowPower, visualizerLowPower) || other.visualizerLowPower == visualizerLowPower)&&(identical(other.visualizerLive, visualizerLive) || other.visualizerLive == visualizerLive)&&(identical(other.seekBarStyle, seekBarStyle) || other.seekBarStyle == seekBarStyle)&&(identical(other.liveSeekBar, liveSeekBar) || other.liveSeekBar == liveSeekBar)&&(identical(other.seekBarColor, seekBarColor) || other.seekBarColor == seekBarColor)&&(identical(other.seekBarSize, seekBarSize) || other.seekBarSize == seekBarSize)&&(identical(other.seekBarDensity, seekBarDensity) || other.seekBarDensity == seekBarDensity)&&(identical(other.seekBarThickness, seekBarThickness) || other.seekBarThickness == seekBarThickness)&&(identical(other.seekBarDim, seekBarDim) || other.seekBarDim == seekBarDim)&&(identical(other.seekBarReact, seekBarReact) || other.seekBarReact == seekBarReact)&&(identical(other.seekBarHead, seekBarHead) || other.seekBarHead == seekBarHead)&&(identical(other.seekBarTimes, seekBarTimes) || other.seekBarTimes == seekBarTimes)&&(identical(other.background, background) || other.background == background)&&(identical(other.relayUrl, relayUrl) || other.relayUrl == relayUrl)&&(identical(other.togetherInternet, togetherInternet) || other.togetherInternet == togetherInternet)&&(identical(other.togetherName, togetherName) || other.togetherName == togetherName)&&(identical(other.togetherGuestControl, togetherGuestControl) || other.togetherGuestControl == togetherGuestControl)&&(identical(other.eqDetailed, eqDetailed) || other.eqDetailed == eqDetailed)&&(identical(other.discordPresence, discordPresence) || other.discordPresence == discordPresence)&&(identical(other.discordClientId, discordClientId) || other.discordClientId == discordClientId)&&(identical(other.discordCovers, discordCovers) || other.discordCovers == discordCovers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,theme,autoCheckUpdates,localeCode,reduceMotion,crossfadeSeconds,closeToTray,highPriority,normalization,autoAnalyzeLoudness,onlineLyrics,autoFindInfo,visualizerStyle,visualizerSensitivity,visualizerLowPower,visualizerLive,seekBarStyle,liveSeekBar,seekBarColor,seekBarSize,seekBarDensity,seekBarThickness,seekBarDim,seekBarReact,seekBarHead,seekBarTimes,background,relayUrl,togetherInternet,togetherName,togetherGuestControl,eqDetailed,discordPresence,discordClientId,discordCovers]);
}

@override
String toString() {
    return 'AppSettings(theme: $theme, autoCheckUpdates: $autoCheckUpdates, localeCode: $localeCode, reduceMotion: $reduceMotion, crossfadeSeconds: $crossfadeSeconds, closeToTray: $closeToTray, highPriority: $highPriority, normalization: $normalization, autoAnalyzeLoudness: $autoAnalyzeLoudness, onlineLyrics: $onlineLyrics, autoFindInfo: $autoFindInfo, visualizerStyle: $visualizerStyle, visualizerSensitivity: $visualizerSensitivity, visualizerLowPower: $visualizerLowPower, visualizerLive: $visualizerLive, seekBarStyle: $seekBarStyle, liveSeekBar: $liveSeekBar, seekBarColor: $seekBarColor, seekBarSize: $seekBarSize, seekBarDensity: $seekBarDensity, seekBarThickness: $seekBarThickness, seekBarDim: $seekBarDim, seekBarReact: $seekBarReact, seekBarHead: $seekBarHead, seekBarTimes: $seekBarTimes, background: $background, relayUrl: $relayUrl, togetherInternet: $togetherInternet, togetherName: $togetherName, togetherGuestControl: $togetherGuestControl, eqDetailed: $eqDetailed, discordPresence: $discordPresence, discordClientId: $discordClientId, discordCovers: $discordCovers)';
}


}

/// @nodoc
abstract mixin class _$AppSettingsCopyWith<$Res> implements $AppSettingsCopyWith<$Res> {
  factory _$AppSettingsCopyWith(_AppSettings value, $Res Function(_AppSettings) _then) = __$AppSettingsCopyWithImpl;
@override @useResult
$Res call({
 ThemeConfig theme, bool autoCheckUpdates, String localeCode, bool reduceMotion, int crossfadeSeconds, bool closeToTray, bool highPriority, NormalizationMode normalization, bool autoAnalyzeLoudness, bool onlineLyrics, bool autoFindInfo, String visualizerStyle, double visualizerSensitivity, bool visualizerLowPower, bool visualizerLive, String seekBarStyle, bool liveSeekBar, int? seekBarColor, double seekBarSize, double seekBarDensity, double seekBarThickness, double seekBarDim, double seekBarReact, bool seekBarHead, bool seekBarTimes, BackgroundConfig background, String relayUrl, bool togetherInternet, String togetherName, bool togetherGuestControl, bool eqDetailed, bool discordPresence, String discordClientId, bool discordCovers
});


@override $ThemeConfigCopyWith<$Res> get theme;@override $BackgroundConfigCopyWith<$Res> get background;

}
/// @nodoc
class __$AppSettingsCopyWithImpl<$Res>
    implements _$AppSettingsCopyWith<$Res> {
  __$AppSettingsCopyWithImpl(this._self, this._then);

  final _AppSettings _self;
  final $Res Function(_AppSettings) _then;

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? theme = null,Object? autoCheckUpdates = null,Object? localeCode = null,Object? reduceMotion = null,Object? crossfadeSeconds = null,Object? closeToTray = null,Object? highPriority = null,Object? normalization = null,Object? autoAnalyzeLoudness = null,Object? onlineLyrics = null,Object? autoFindInfo = null,Object? visualizerStyle = null,Object? visualizerSensitivity = null,Object? visualizerLowPower = null,Object? visualizerLive = null,Object? seekBarStyle = null,Object? liveSeekBar = null,Object? seekBarColor = freezed,Object? seekBarSize = null,Object? seekBarDensity = null,Object? seekBarThickness = null,Object? seekBarDim = null,Object? seekBarReact = null,Object? seekBarHead = null,Object? seekBarTimes = null,Object? background = null,Object? relayUrl = null,Object? togetherInternet = null,Object? togetherName = null,Object? togetherGuestControl = null,Object? eqDetailed = null,Object? discordPresence = null,Object? discordClientId = null,Object? discordCovers = null,}) {
  return _then(_AppSettings(
theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as ThemeConfig,autoCheckUpdates: null == autoCheckUpdates ? _self.autoCheckUpdates : autoCheckUpdates // ignore: cast_nullable_to_non_nullable
as bool,localeCode: null == localeCode ? _self.localeCode : localeCode // ignore: cast_nullable_to_non_nullable
as String,reduceMotion: null == reduceMotion ? _self.reduceMotion : reduceMotion // ignore: cast_nullable_to_non_nullable
as bool,crossfadeSeconds: null == crossfadeSeconds ? _self.crossfadeSeconds : crossfadeSeconds // ignore: cast_nullable_to_non_nullable
as int,closeToTray: null == closeToTray ? _self.closeToTray : closeToTray // ignore: cast_nullable_to_non_nullable
as bool,highPriority: null == highPriority ? _self.highPriority : highPriority // ignore: cast_nullable_to_non_nullable
as bool,normalization: null == normalization ? _self.normalization : normalization // ignore: cast_nullable_to_non_nullable
as NormalizationMode,autoAnalyzeLoudness: null == autoAnalyzeLoudness ? _self.autoAnalyzeLoudness : autoAnalyzeLoudness // ignore: cast_nullable_to_non_nullable
as bool,onlineLyrics: null == onlineLyrics ? _self.onlineLyrics : onlineLyrics // ignore: cast_nullable_to_non_nullable
as bool,autoFindInfo: null == autoFindInfo ? _self.autoFindInfo : autoFindInfo // ignore: cast_nullable_to_non_nullable
as bool,visualizerStyle: null == visualizerStyle ? _self.visualizerStyle : visualizerStyle // ignore: cast_nullable_to_non_nullable
as String,visualizerSensitivity: null == visualizerSensitivity ? _self.visualizerSensitivity : visualizerSensitivity // ignore: cast_nullable_to_non_nullable
as double,visualizerLowPower: null == visualizerLowPower ? _self.visualizerLowPower : visualizerLowPower // ignore: cast_nullable_to_non_nullable
as bool,visualizerLive: null == visualizerLive ? _self.visualizerLive : visualizerLive // ignore: cast_nullable_to_non_nullable
as bool,seekBarStyle: null == seekBarStyle ? _self.seekBarStyle : seekBarStyle // ignore: cast_nullable_to_non_nullable
as String,liveSeekBar: null == liveSeekBar ? _self.liveSeekBar : liveSeekBar // ignore: cast_nullable_to_non_nullable
as bool,seekBarColor: freezed == seekBarColor ? _self.seekBarColor : seekBarColor // ignore: cast_nullable_to_non_nullable
as int?,seekBarSize: null == seekBarSize ? _self.seekBarSize : seekBarSize // ignore: cast_nullable_to_non_nullable
as double,seekBarDensity: null == seekBarDensity ? _self.seekBarDensity : seekBarDensity // ignore: cast_nullable_to_non_nullable
as double,seekBarThickness: null == seekBarThickness ? _self.seekBarThickness : seekBarThickness // ignore: cast_nullable_to_non_nullable
as double,seekBarDim: null == seekBarDim ? _self.seekBarDim : seekBarDim // ignore: cast_nullable_to_non_nullable
as double,seekBarReact: null == seekBarReact ? _self.seekBarReact : seekBarReact // ignore: cast_nullable_to_non_nullable
as double,seekBarHead: null == seekBarHead ? _self.seekBarHead : seekBarHead // ignore: cast_nullable_to_non_nullable
as bool,seekBarTimes: null == seekBarTimes ? _self.seekBarTimes : seekBarTimes // ignore: cast_nullable_to_non_nullable
as bool,background: null == background ? _self.background : background // ignore: cast_nullable_to_non_nullable
as BackgroundConfig,relayUrl: null == relayUrl ? _self.relayUrl : relayUrl // ignore: cast_nullable_to_non_nullable
as String,togetherInternet: null == togetherInternet ? _self.togetherInternet : togetherInternet // ignore: cast_nullable_to_non_nullable
as bool,togetherName: null == togetherName ? _self.togetherName : togetherName // ignore: cast_nullable_to_non_nullable
as String,togetherGuestControl: null == togetherGuestControl ? _self.togetherGuestControl : togetherGuestControl // ignore: cast_nullable_to_non_nullable
as bool,eqDetailed: null == eqDetailed ? _self.eqDetailed : eqDetailed // ignore: cast_nullable_to_non_nullable
as bool,discordPresence: null == discordPresence ? _self.discordPresence : discordPresence // ignore: cast_nullable_to_non_nullable
as bool,discordClientId: null == discordClientId ? _self.discordClientId : discordClientId // ignore: cast_nullable_to_non_nullable
as String,discordCovers: null == discordCovers ? _self.discordCovers : discordCovers // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ThemeConfigCopyWith<$Res> get theme {
  
  return $ThemeConfigCopyWith<$Res>(_self.theme, (value) {
    return _then(_self.copyWith(theme: value));
  });
}/// Create a copy of AppSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BackgroundConfigCopyWith<$Res> get background {
  
  return $BackgroundConfigCopyWith<$Res>(_self.background, (value) {
    return _then(_self.copyWith(background: value));
  });
}
}

// dart format on

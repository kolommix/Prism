// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Track {

/// Database id (unique per library). Remote tracks may use negative ids.
 int get id;/// Id of the `TrackSource` that owns this track, e.g. `local`.
 String get sourceId;/// Source-specific location. For local files: absolute file path.
 String get uri; String get title; String get artist; String get album; String get albumArtist; String get genre; int? get year; int? get trackNumber; int? get discNumber;/// Length in milliseconds (0 when unknown).
 int get durationMs;/// Path to a cached cover image on disk, if the file had one.
 String? get artworkPath;/// ReplayGain from tags (gain in dB, peak linear) – see `loudness.dart`.
 double? get rgTrackGain; double? get rgTrackPeak; double? get rgAlbumGain; double? get rgAlbumPeak;/// Measured integrated loudness / true peak when tags are missing.
 double? get loudnessLufs; double? get truePeakDb;
/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackCopyWith<Track> get copyWith => _$TrackCopyWithImpl<Track>(this as Track, _$identity);

  /// Serializes this Track to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Track;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Track&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.sourceId, _this.sourceId) || other.sourceId == _this.sourceId)&&(identical(other.uri, _this.uri) || other.uri == _this.uri)&&(identical(other.title, _this.title) || other.title == _this.title)&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&(identical(other.album, _this.album) || other.album == _this.album)&&(identical(other.albumArtist, _this.albumArtist) || other.albumArtist == _this.albumArtist)&&(identical(other.genre, _this.genre) || other.genre == _this.genre)&&(identical(other.year, _this.year) || other.year == _this.year)&&(identical(other.trackNumber, _this.trackNumber) || other.trackNumber == _this.trackNumber)&&(identical(other.discNumber, _this.discNumber) || other.discNumber == _this.discNumber)&&(identical(other.durationMs, _this.durationMs) || other.durationMs == _this.durationMs)&&(identical(other.artworkPath, _this.artworkPath) || other.artworkPath == _this.artworkPath)&&(identical(other.rgTrackGain, _this.rgTrackGain) || other.rgTrackGain == _this.rgTrackGain)&&(identical(other.rgTrackPeak, _this.rgTrackPeak) || other.rgTrackPeak == _this.rgTrackPeak)&&(identical(other.rgAlbumGain, _this.rgAlbumGain) || other.rgAlbumGain == _this.rgAlbumGain)&&(identical(other.rgAlbumPeak, _this.rgAlbumPeak) || other.rgAlbumPeak == _this.rgAlbumPeak)&&(identical(other.loudnessLufs, _this.loudnessLufs) || other.loudnessLufs == _this.loudnessLufs)&&(identical(other.truePeakDb, _this.truePeakDb) || other.truePeakDb == _this.truePeakDb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Track;
  return Object.hashAll([runtimeType,_this.id,_this.sourceId,_this.uri,_this.title,_this.artist,_this.album,_this.albumArtist,_this.genre,_this.year,_this.trackNumber,_this.discNumber,_this.durationMs,_this.artworkPath,_this.rgTrackGain,_this.rgTrackPeak,_this.rgAlbumGain,_this.rgAlbumPeak,_this.loudnessLufs,_this.truePeakDb]);
}

@override
String toString() {
  final _this = this as Track;
  return 'Track(id: ${_this.id}, sourceId: ${_this.sourceId}, uri: ${_this.uri}, title: ${_this.title}, artist: ${_this.artist}, album: ${_this.album}, albumArtist: ${_this.albumArtist}, genre: ${_this.genre}, year: ${_this.year}, trackNumber: ${_this.trackNumber}, discNumber: ${_this.discNumber}, durationMs: ${_this.durationMs}, artworkPath: ${_this.artworkPath}, rgTrackGain: ${_this.rgTrackGain}, rgTrackPeak: ${_this.rgTrackPeak}, rgAlbumGain: ${_this.rgAlbumGain}, rgAlbumPeak: ${_this.rgAlbumPeak}, loudnessLufs: ${_this.loudnessLufs}, truePeakDb: ${_this.truePeakDb})';
}


}

/// @nodoc
abstract mixin class $TrackCopyWith<$Res>  {
  factory $TrackCopyWith(Track value, $Res Function(Track) _then) = _$TrackCopyWithImpl;
@useResult
$Res call({
 int id, String sourceId, String uri, String title, String artist, String album, String albumArtist, String genre, int? year, int? trackNumber, int? discNumber, int durationMs, String? artworkPath, double? rgTrackGain, double? rgTrackPeak, double? rgAlbumGain, double? rgAlbumPeak, double? loudnessLufs, double? truePeakDb
});




}
/// @nodoc
class _$TrackCopyWithImpl<$Res>
    implements $TrackCopyWith<$Res> {
  _$TrackCopyWithImpl(this._self, this._then);

  final Track _self;
  final $Res Function(Track) _then;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sourceId = null,Object? uri = null,Object? title = null,Object? artist = null,Object? album = null,Object? albumArtist = null,Object? genre = null,Object? year = freezed,Object? trackNumber = freezed,Object? discNumber = freezed,Object? durationMs = null,Object? artworkPath = freezed,Object? rgTrackGain = freezed,Object? rgTrackPeak = freezed,Object? rgAlbumGain = freezed,Object? rgAlbumPeak = freezed,Object? loudnessLufs = freezed,Object? truePeakDb = freezed,}) {
  return _then(Track(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,sourceId: null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String,albumArtist: null == albumArtist ? _self.albumArtist : albumArtist // ignore: cast_nullable_to_non_nullable
as String,genre: null == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,trackNumber: freezed == trackNumber ? _self.trackNumber : trackNumber // ignore: cast_nullable_to_non_nullable
as int?,discNumber: freezed == discNumber ? _self.discNumber : discNumber // ignore: cast_nullable_to_non_nullable
as int?,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,artworkPath: freezed == artworkPath ? _self.artworkPath : artworkPath // ignore: cast_nullable_to_non_nullable
as String?,rgTrackGain: freezed == rgTrackGain ? _self.rgTrackGain : rgTrackGain // ignore: cast_nullable_to_non_nullable
as double?,rgTrackPeak: freezed == rgTrackPeak ? _self.rgTrackPeak : rgTrackPeak // ignore: cast_nullable_to_non_nullable
as double?,rgAlbumGain: freezed == rgAlbumGain ? _self.rgAlbumGain : rgAlbumGain // ignore: cast_nullable_to_non_nullable
as double?,rgAlbumPeak: freezed == rgAlbumPeak ? _self.rgAlbumPeak : rgAlbumPeak // ignore: cast_nullable_to_non_nullable
as double?,loudnessLufs: freezed == loudnessLufs ? _self.loudnessLufs : loudnessLufs // ignore: cast_nullable_to_non_nullable
as double?,truePeakDb: freezed == truePeakDb ? _self.truePeakDb : truePeakDb // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [Track].
extension TrackPatterns on Track {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Track value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Track() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Track value)  $default,){
final _that = this;
switch (_that) {
case _Track():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Track value)?  $default,){
final _that = this;
switch (_that) {
case _Track() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String sourceId,  String uri,  String title,  String artist,  String album,  String albumArtist,  String genre,  int? year,  int? trackNumber,  int? discNumber,  int durationMs,  String? artworkPath,  double? rgTrackGain,  double? rgTrackPeak,  double? rgAlbumGain,  double? rgAlbumPeak,  double? loudnessLufs,  double? truePeakDb)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Track() when $default != null:
return $default(_that.id,_that.sourceId,_that.uri,_that.title,_that.artist,_that.album,_that.albumArtist,_that.genre,_that.year,_that.trackNumber,_that.discNumber,_that.durationMs,_that.artworkPath,_that.rgTrackGain,_that.rgTrackPeak,_that.rgAlbumGain,_that.rgAlbumPeak,_that.loudnessLufs,_that.truePeakDb);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String sourceId,  String uri,  String title,  String artist,  String album,  String albumArtist,  String genre,  int? year,  int? trackNumber,  int? discNumber,  int durationMs,  String? artworkPath,  double? rgTrackGain,  double? rgTrackPeak,  double? rgAlbumGain,  double? rgAlbumPeak,  double? loudnessLufs,  double? truePeakDb)  $default,) {final _that = this;
switch (_that) {
case _Track():
return $default(_that.id,_that.sourceId,_that.uri,_that.title,_that.artist,_that.album,_that.albumArtist,_that.genre,_that.year,_that.trackNumber,_that.discNumber,_that.durationMs,_that.artworkPath,_that.rgTrackGain,_that.rgTrackPeak,_that.rgAlbumGain,_that.rgAlbumPeak,_that.loudnessLufs,_that.truePeakDb);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String sourceId,  String uri,  String title,  String artist,  String album,  String albumArtist,  String genre,  int? year,  int? trackNumber,  int? discNumber,  int durationMs,  String? artworkPath,  double? rgTrackGain,  double? rgTrackPeak,  double? rgAlbumGain,  double? rgAlbumPeak,  double? loudnessLufs,  double? truePeakDb)?  $default,) {final _that = this;
switch (_that) {
case _Track() when $default != null:
return $default(_that.id,_that.sourceId,_that.uri,_that.title,_that.artist,_that.album,_that.albumArtist,_that.genre,_that.year,_that.trackNumber,_that.discNumber,_that.durationMs,_that.artworkPath,_that.rgTrackGain,_that.rgTrackPeak,_that.rgAlbumGain,_that.rgAlbumPeak,_that.loudnessLufs,_that.truePeakDb);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Track extends Track {
  const _Track({required this.id, this.sourceId = 'local', required this.uri, required this.title, this.artist = '', this.album = '', this.albumArtist = '', this.genre = '', this.year, this.trackNumber, this.discNumber, this.durationMs = 0, this.artworkPath, this.rgTrackGain, this.rgTrackPeak, this.rgAlbumGain, this.rgAlbumPeak, this.loudnessLufs, this.truePeakDb}): super._();
  factory _Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);

/// Database id (unique per library). Remote tracks may use negative ids.
@override final  int id;
/// Id of the `TrackSource` that owns this track, e.g. `local`.
@override@JsonKey() final  String sourceId;
/// Source-specific location. For local files: absolute file path.
@override final  String uri;
@override final  String title;
@override@JsonKey() final  String artist;
@override@JsonKey() final  String album;
@override@JsonKey() final  String albumArtist;
@override@JsonKey() final  String genre;
@override final  int? year;
@override final  int? trackNumber;
@override final  int? discNumber;
/// Length in milliseconds (0 when unknown).
@override@JsonKey() final  int durationMs;
/// Path to a cached cover image on disk, if the file had one.
@override final  String? artworkPath;
/// ReplayGain from tags (gain in dB, peak linear) – see `loudness.dart`.
@override final  double? rgTrackGain;
@override final  double? rgTrackPeak;
@override final  double? rgAlbumGain;
@override final  double? rgAlbumPeak;
/// Measured integrated loudness / true peak when tags are missing.
@override final  double? loudnessLufs;
@override final  double? truePeakDb;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackCopyWith<_Track> get copyWith => __$TrackCopyWithImpl<_Track>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Track&&(identical(other.id, id) || other.id == id)&&(identical(other.sourceId, sourceId) || other.sourceId == sourceId)&&(identical(other.uri, uri) || other.uri == uri)&&(identical(other.title, title) || other.title == title)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.album, album) || other.album == album)&&(identical(other.albumArtist, albumArtist) || other.albumArtist == albumArtist)&&(identical(other.genre, genre) || other.genre == genre)&&(identical(other.year, year) || other.year == year)&&(identical(other.trackNumber, trackNumber) || other.trackNumber == trackNumber)&&(identical(other.discNumber, discNumber) || other.discNumber == discNumber)&&(identical(other.durationMs, durationMs) || other.durationMs == durationMs)&&(identical(other.artworkPath, artworkPath) || other.artworkPath == artworkPath)&&(identical(other.rgTrackGain, rgTrackGain) || other.rgTrackGain == rgTrackGain)&&(identical(other.rgTrackPeak, rgTrackPeak) || other.rgTrackPeak == rgTrackPeak)&&(identical(other.rgAlbumGain, rgAlbumGain) || other.rgAlbumGain == rgAlbumGain)&&(identical(other.rgAlbumPeak, rgAlbumPeak) || other.rgAlbumPeak == rgAlbumPeak)&&(identical(other.loudnessLufs, loudnessLufs) || other.loudnessLufs == loudnessLufs)&&(identical(other.truePeakDb, truePeakDb) || other.truePeakDb == truePeakDb));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,id,sourceId,uri,title,artist,album,albumArtist,genre,year,trackNumber,discNumber,durationMs,artworkPath,rgTrackGain,rgTrackPeak,rgAlbumGain,rgAlbumPeak,loudnessLufs,truePeakDb]);
}

@override
String toString() {
    return 'Track(id: $id, sourceId: $sourceId, uri: $uri, title: $title, artist: $artist, album: $album, albumArtist: $albumArtist, genre: $genre, year: $year, trackNumber: $trackNumber, discNumber: $discNumber, durationMs: $durationMs, artworkPath: $artworkPath, rgTrackGain: $rgTrackGain, rgTrackPeak: $rgTrackPeak, rgAlbumGain: $rgAlbumGain, rgAlbumPeak: $rgAlbumPeak, loudnessLufs: $loudnessLufs, truePeakDb: $truePeakDb)';
}


}

/// @nodoc
abstract mixin class _$TrackCopyWith<$Res> implements $TrackCopyWith<$Res> {
  factory _$TrackCopyWith(_Track value, $Res Function(_Track) _then) = __$TrackCopyWithImpl;
@override @useResult
$Res call({
 int id, String sourceId, String uri, String title, String artist, String album, String albumArtist, String genre, int? year, int? trackNumber, int? discNumber, int durationMs, String? artworkPath, double? rgTrackGain, double? rgTrackPeak, double? rgAlbumGain, double? rgAlbumPeak, double? loudnessLufs, double? truePeakDb
});




}
/// @nodoc
class __$TrackCopyWithImpl<$Res>
    implements _$TrackCopyWith<$Res> {
  __$TrackCopyWithImpl(this._self, this._then);

  final _Track _self;
  final $Res Function(_Track) _then;

/// Create a copy of Track
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sourceId = null,Object? uri = null,Object? title = null,Object? artist = null,Object? album = null,Object? albumArtist = null,Object? genre = null,Object? year = freezed,Object? trackNumber = freezed,Object? discNumber = freezed,Object? durationMs = null,Object? artworkPath = freezed,Object? rgTrackGain = freezed,Object? rgTrackPeak = freezed,Object? rgAlbumGain = freezed,Object? rgAlbumPeak = freezed,Object? loudnessLufs = freezed,Object? truePeakDb = freezed,}) {
  return _then(_Track(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,sourceId: null == sourceId ? _self.sourceId : sourceId // ignore: cast_nullable_to_non_nullable
as String,uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,album: null == album ? _self.album : album // ignore: cast_nullable_to_non_nullable
as String,albumArtist: null == albumArtist ? _self.albumArtist : albumArtist // ignore: cast_nullable_to_non_nullable
as String,genre: null == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,trackNumber: freezed == trackNumber ? _self.trackNumber : trackNumber // ignore: cast_nullable_to_non_nullable
as int?,discNumber: freezed == discNumber ? _self.discNumber : discNumber // ignore: cast_nullable_to_non_nullable
as int?,durationMs: null == durationMs ? _self.durationMs : durationMs // ignore: cast_nullable_to_non_nullable
as int,artworkPath: freezed == artworkPath ? _self.artworkPath : artworkPath // ignore: cast_nullable_to_non_nullable
as String?,rgTrackGain: freezed == rgTrackGain ? _self.rgTrackGain : rgTrackGain // ignore: cast_nullable_to_non_nullable
as double?,rgTrackPeak: freezed == rgTrackPeak ? _self.rgTrackPeak : rgTrackPeak // ignore: cast_nullable_to_non_nullable
as double?,rgAlbumGain: freezed == rgAlbumGain ? _self.rgAlbumGain : rgAlbumGain // ignore: cast_nullable_to_non_nullable
as double?,rgAlbumPeak: freezed == rgAlbumPeak ? _self.rgAlbumPeak : rgAlbumPeak // ignore: cast_nullable_to_non_nullable
as double?,loudnessLufs: freezed == loudnessLufs ? _self.loudnessLufs : loudnessLufs // ignore: cast_nullable_to_non_nullable
as double?,truePeakDb: freezed == truePeakDb ? _self.truePeakDb : truePeakDb // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on

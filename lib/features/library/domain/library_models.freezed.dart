// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AlbumSummary {

 String get name; String get artist; int get trackCount; int? get year; String? get artworkPath;
/// Create a copy of AlbumSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AlbumSummaryCopyWith<AlbumSummary> get copyWith => _$AlbumSummaryCopyWithImpl<AlbumSummary>(this as AlbumSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AlbumSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AlbumSummary&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.artist, _this.artist) || other.artist == _this.artist)&&(identical(other.trackCount, _this.trackCount) || other.trackCount == _this.trackCount)&&(identical(other.year, _this.year) || other.year == _this.year)&&(identical(other.artworkPath, _this.artworkPath) || other.artworkPath == _this.artworkPath));
}


@override
int get hashCode {
  final _this = this as AlbumSummary;
  return Object.hash(runtimeType,_this.name,_this.artist,_this.trackCount,_this.year,_this.artworkPath);
}

@override
String toString() {
  final _this = this as AlbumSummary;
  return 'AlbumSummary(name: ${_this.name}, artist: ${_this.artist}, trackCount: ${_this.trackCount}, year: ${_this.year}, artworkPath: ${_this.artworkPath})';
}


}

/// @nodoc
abstract mixin class $AlbumSummaryCopyWith<$Res>  {
  factory $AlbumSummaryCopyWith(AlbumSummary value, $Res Function(AlbumSummary) _then) = _$AlbumSummaryCopyWithImpl;
@useResult
$Res call({
 String name, String artist, int trackCount, int? year, String? artworkPath
});




}
/// @nodoc
class _$AlbumSummaryCopyWithImpl<$Res>
    implements $AlbumSummaryCopyWith<$Res> {
  _$AlbumSummaryCopyWithImpl(this._self, this._then);

  final AlbumSummary _self;
  final $Res Function(AlbumSummary) _then;

/// Create a copy of AlbumSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? artist = null,Object? trackCount = null,Object? year = freezed,Object? artworkPath = freezed,}) {
  return _then(AlbumSummary(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,artworkPath: freezed == artworkPath ? _self.artworkPath : artworkPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AlbumSummary].
extension AlbumSummaryPatterns on AlbumSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AlbumSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AlbumSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AlbumSummary value)  $default,){
final _that = this;
switch (_that) {
case _AlbumSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AlbumSummary value)?  $default,){
final _that = this;
switch (_that) {
case _AlbumSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String artist,  int trackCount,  int? year,  String? artworkPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AlbumSummary() when $default != null:
return $default(_that.name,_that.artist,_that.trackCount,_that.year,_that.artworkPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String artist,  int trackCount,  int? year,  String? artworkPath)  $default,) {final _that = this;
switch (_that) {
case _AlbumSummary():
return $default(_that.name,_that.artist,_that.trackCount,_that.year,_that.artworkPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String artist,  int trackCount,  int? year,  String? artworkPath)?  $default,) {final _that = this;
switch (_that) {
case _AlbumSummary() when $default != null:
return $default(_that.name,_that.artist,_that.trackCount,_that.year,_that.artworkPath);case _:
  return null;

}
}

}

/// @nodoc


class _AlbumSummary implements AlbumSummary {
  const _AlbumSummary({required this.name, required this.artist, required this.trackCount, this.year, this.artworkPath});
  

@override final  String name;
@override final  String artist;
@override final  int trackCount;
@override final  int? year;
@override final  String? artworkPath;

/// Create a copy of AlbumSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AlbumSummaryCopyWith<_AlbumSummary> get copyWith => __$AlbumSummaryCopyWithImpl<_AlbumSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AlbumSummary&&(identical(other.name, name) || other.name == name)&&(identical(other.artist, artist) || other.artist == artist)&&(identical(other.trackCount, trackCount) || other.trackCount == trackCount)&&(identical(other.year, year) || other.year == year)&&(identical(other.artworkPath, artworkPath) || other.artworkPath == artworkPath));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,artist,trackCount,year,artworkPath);
}

@override
String toString() {
    return 'AlbumSummary(name: $name, artist: $artist, trackCount: $trackCount, year: $year, artworkPath: $artworkPath)';
}


}

/// @nodoc
abstract mixin class _$AlbumSummaryCopyWith<$Res> implements $AlbumSummaryCopyWith<$Res> {
  factory _$AlbumSummaryCopyWith(_AlbumSummary value, $Res Function(_AlbumSummary) _then) = __$AlbumSummaryCopyWithImpl;
@override @useResult
$Res call({
 String name, String artist, int trackCount, int? year, String? artworkPath
});




}
/// @nodoc
class __$AlbumSummaryCopyWithImpl<$Res>
    implements _$AlbumSummaryCopyWith<$Res> {
  __$AlbumSummaryCopyWithImpl(this._self, this._then);

  final _AlbumSummary _self;
  final $Res Function(_AlbumSummary) _then;

/// Create a copy of AlbumSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? artist = null,Object? trackCount = null,Object? year = freezed,Object? artworkPath = freezed,}) {
  return _then(_AlbumSummary(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,artist: null == artist ? _self.artist : artist // ignore: cast_nullable_to_non_nullable
as String,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,year: freezed == year ? _self.year : year // ignore: cast_nullable_to_non_nullable
as int?,artworkPath: freezed == artworkPath ? _self.artworkPath : artworkPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ArtistSummary {

 String get name; int get trackCount; int get albumCount; String? get artworkPath;
/// Create a copy of ArtistSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArtistSummaryCopyWith<ArtistSummary> get copyWith => _$ArtistSummaryCopyWithImpl<ArtistSummary>(this as ArtistSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ArtistSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArtistSummary&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.trackCount, _this.trackCount) || other.trackCount == _this.trackCount)&&(identical(other.albumCount, _this.albumCount) || other.albumCount == _this.albumCount)&&(identical(other.artworkPath, _this.artworkPath) || other.artworkPath == _this.artworkPath));
}


@override
int get hashCode {
  final _this = this as ArtistSummary;
  return Object.hash(runtimeType,_this.name,_this.trackCount,_this.albumCount,_this.artworkPath);
}

@override
String toString() {
  final _this = this as ArtistSummary;
  return 'ArtistSummary(name: ${_this.name}, trackCount: ${_this.trackCount}, albumCount: ${_this.albumCount}, artworkPath: ${_this.artworkPath})';
}


}

/// @nodoc
abstract mixin class $ArtistSummaryCopyWith<$Res>  {
  factory $ArtistSummaryCopyWith(ArtistSummary value, $Res Function(ArtistSummary) _then) = _$ArtistSummaryCopyWithImpl;
@useResult
$Res call({
 String name, int trackCount, int albumCount, String? artworkPath
});




}
/// @nodoc
class _$ArtistSummaryCopyWithImpl<$Res>
    implements $ArtistSummaryCopyWith<$Res> {
  _$ArtistSummaryCopyWithImpl(this._self, this._then);

  final ArtistSummary _self;
  final $Res Function(ArtistSummary) _then;

/// Create a copy of ArtistSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? trackCount = null,Object? albumCount = null,Object? artworkPath = freezed,}) {
  return _then(ArtistSummary(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,albumCount: null == albumCount ? _self.albumCount : albumCount // ignore: cast_nullable_to_non_nullable
as int,artworkPath: freezed == artworkPath ? _self.artworkPath : artworkPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ArtistSummary].
extension ArtistSummaryPatterns on ArtistSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArtistSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArtistSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArtistSummary value)  $default,){
final _that = this;
switch (_that) {
case _ArtistSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArtistSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ArtistSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int trackCount,  int albumCount,  String? artworkPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArtistSummary() when $default != null:
return $default(_that.name,_that.trackCount,_that.albumCount,_that.artworkPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int trackCount,  int albumCount,  String? artworkPath)  $default,) {final _that = this;
switch (_that) {
case _ArtistSummary():
return $default(_that.name,_that.trackCount,_that.albumCount,_that.artworkPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int trackCount,  int albumCount,  String? artworkPath)?  $default,) {final _that = this;
switch (_that) {
case _ArtistSummary() when $default != null:
return $default(_that.name,_that.trackCount,_that.albumCount,_that.artworkPath);case _:
  return null;

}
}

}

/// @nodoc


class _ArtistSummary implements ArtistSummary {
  const _ArtistSummary({required this.name, required this.trackCount, required this.albumCount, this.artworkPath});
  

@override final  String name;
@override final  int trackCount;
@override final  int albumCount;
@override final  String? artworkPath;

/// Create a copy of ArtistSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArtistSummaryCopyWith<_ArtistSummary> get copyWith => __$ArtistSummaryCopyWithImpl<_ArtistSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArtistSummary&&(identical(other.name, name) || other.name == name)&&(identical(other.trackCount, trackCount) || other.trackCount == trackCount)&&(identical(other.albumCount, albumCount) || other.albumCount == albumCount)&&(identical(other.artworkPath, artworkPath) || other.artworkPath == artworkPath));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,trackCount,albumCount,artworkPath);
}

@override
String toString() {
    return 'ArtistSummary(name: $name, trackCount: $trackCount, albumCount: $albumCount, artworkPath: $artworkPath)';
}


}

/// @nodoc
abstract mixin class _$ArtistSummaryCopyWith<$Res> implements $ArtistSummaryCopyWith<$Res> {
  factory _$ArtistSummaryCopyWith(_ArtistSummary value, $Res Function(_ArtistSummary) _then) = __$ArtistSummaryCopyWithImpl;
@override @useResult
$Res call({
 String name, int trackCount, int albumCount, String? artworkPath
});




}
/// @nodoc
class __$ArtistSummaryCopyWithImpl<$Res>
    implements _$ArtistSummaryCopyWith<$Res> {
  __$ArtistSummaryCopyWithImpl(this._self, this._then);

  final _ArtistSummary _self;
  final $Res Function(_ArtistSummary) _then;

/// Create a copy of ArtistSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? trackCount = null,Object? albumCount = null,Object? artworkPath = freezed,}) {
  return _then(_ArtistSummary(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,albumCount: null == albumCount ? _self.albumCount : albumCount // ignore: cast_nullable_to_non_nullable
as int,artworkPath: freezed == artworkPath ? _self.artworkPath : artworkPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$FolderSummary {

 String get path; int get trackCount;
/// Create a copy of FolderSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FolderSummaryCopyWith<FolderSummary> get copyWith => _$FolderSummaryCopyWithImpl<FolderSummary>(this as FolderSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FolderSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FolderSummary&&(identical(other.path, _this.path) || other.path == _this.path)&&(identical(other.trackCount, _this.trackCount) || other.trackCount == _this.trackCount));
}


@override
int get hashCode {
  final _this = this as FolderSummary;
  return Object.hash(runtimeType,_this.path,_this.trackCount);
}

@override
String toString() {
  final _this = this as FolderSummary;
  return 'FolderSummary(path: ${_this.path}, trackCount: ${_this.trackCount})';
}


}

/// @nodoc
abstract mixin class $FolderSummaryCopyWith<$Res>  {
  factory $FolderSummaryCopyWith(FolderSummary value, $Res Function(FolderSummary) _then) = _$FolderSummaryCopyWithImpl;
@useResult
$Res call({
 String path, int trackCount
});




}
/// @nodoc
class _$FolderSummaryCopyWithImpl<$Res>
    implements $FolderSummaryCopyWith<$Res> {
  _$FolderSummaryCopyWithImpl(this._self, this._then);

  final FolderSummary _self;
  final $Res Function(FolderSummary) _then;

/// Create a copy of FolderSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? trackCount = null,}) {
  return _then(FolderSummary(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FolderSummary].
extension FolderSummaryPatterns on FolderSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FolderSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FolderSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FolderSummary value)  $default,){
final _that = this;
switch (_that) {
case _FolderSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FolderSummary value)?  $default,){
final _that = this;
switch (_that) {
case _FolderSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  int trackCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FolderSummary() when $default != null:
return $default(_that.path,_that.trackCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  int trackCount)  $default,) {final _that = this;
switch (_that) {
case _FolderSummary():
return $default(_that.path,_that.trackCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  int trackCount)?  $default,) {final _that = this;
switch (_that) {
case _FolderSummary() when $default != null:
return $default(_that.path,_that.trackCount);case _:
  return null;

}
}

}

/// @nodoc


class _FolderSummary implements FolderSummary {
  const _FolderSummary({required this.path, required this.trackCount});
  

@override final  String path;
@override final  int trackCount;

/// Create a copy of FolderSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FolderSummaryCopyWith<_FolderSummary> get copyWith => __$FolderSummaryCopyWithImpl<_FolderSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FolderSummary&&(identical(other.path, path) || other.path == path)&&(identical(other.trackCount, trackCount) || other.trackCount == trackCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,path,trackCount);
}

@override
String toString() {
    return 'FolderSummary(path: $path, trackCount: $trackCount)';
}


}

/// @nodoc
abstract mixin class _$FolderSummaryCopyWith<$Res> implements $FolderSummaryCopyWith<$Res> {
  factory _$FolderSummaryCopyWith(_FolderSummary value, $Res Function(_FolderSummary) _then) = __$FolderSummaryCopyWithImpl;
@override @useResult
$Res call({
 String path, int trackCount
});




}
/// @nodoc
class __$FolderSummaryCopyWithImpl<$Res>
    implements _$FolderSummaryCopyWith<$Res> {
  __$FolderSummaryCopyWithImpl(this._self, this._then);

  final _FolderSummary _self;
  final $Res Function(_FolderSummary) _then;

/// Create a copy of FolderSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? trackCount = null,}) {
  return _then(_FolderSummary(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$PlaylistSummary {

 int get id; String get name; int get trackCount; DateTime get updatedAt; String? get artworkPath;
/// Create a copy of PlaylistSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlaylistSummaryCopyWith<PlaylistSummary> get copyWith => _$PlaylistSummaryCopyWithImpl<PlaylistSummary>(this as PlaylistSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PlaylistSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlaylistSummary&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.trackCount, _this.trackCount) || other.trackCount == _this.trackCount)&&(identical(other.updatedAt, _this.updatedAt) || other.updatedAt == _this.updatedAt)&&(identical(other.artworkPath, _this.artworkPath) || other.artworkPath == _this.artworkPath));
}


@override
int get hashCode {
  final _this = this as PlaylistSummary;
  return Object.hash(runtimeType,_this.id,_this.name,_this.trackCount,_this.updatedAt,_this.artworkPath);
}

@override
String toString() {
  final _this = this as PlaylistSummary;
  return 'PlaylistSummary(id: ${_this.id}, name: ${_this.name}, trackCount: ${_this.trackCount}, updatedAt: ${_this.updatedAt}, artworkPath: ${_this.artworkPath})';
}


}

/// @nodoc
abstract mixin class $PlaylistSummaryCopyWith<$Res>  {
  factory $PlaylistSummaryCopyWith(PlaylistSummary value, $Res Function(PlaylistSummary) _then) = _$PlaylistSummaryCopyWithImpl;
@useResult
$Res call({
 int id, String name, int trackCount, DateTime updatedAt, String? artworkPath
});




}
/// @nodoc
class _$PlaylistSummaryCopyWithImpl<$Res>
    implements $PlaylistSummaryCopyWith<$Res> {
  _$PlaylistSummaryCopyWithImpl(this._self, this._then);

  final PlaylistSummary _self;
  final $Res Function(PlaylistSummary) _then;

/// Create a copy of PlaylistSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? trackCount = null,Object? updatedAt = null,Object? artworkPath = freezed,}) {
  return _then(PlaylistSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,artworkPath: freezed == artworkPath ? _self.artworkPath : artworkPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlaylistSummary].
extension PlaylistSummaryPatterns on PlaylistSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlaylistSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlaylistSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlaylistSummary value)  $default,){
final _that = this;
switch (_that) {
case _PlaylistSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlaylistSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PlaylistSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  int trackCount,  DateTime updatedAt,  String? artworkPath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlaylistSummary() when $default != null:
return $default(_that.id,_that.name,_that.trackCount,_that.updatedAt,_that.artworkPath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  int trackCount,  DateTime updatedAt,  String? artworkPath)  $default,) {final _that = this;
switch (_that) {
case _PlaylistSummary():
return $default(_that.id,_that.name,_that.trackCount,_that.updatedAt,_that.artworkPath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  int trackCount,  DateTime updatedAt,  String? artworkPath)?  $default,) {final _that = this;
switch (_that) {
case _PlaylistSummary() when $default != null:
return $default(_that.id,_that.name,_that.trackCount,_that.updatedAt,_that.artworkPath);case _:
  return null;

}
}

}

/// @nodoc


class _PlaylistSummary implements PlaylistSummary {
  const _PlaylistSummary({required this.id, required this.name, required this.trackCount, required this.updatedAt, this.artworkPath});
  

@override final  int id;
@override final  String name;
@override final  int trackCount;
@override final  DateTime updatedAt;
@override final  String? artworkPath;

/// Create a copy of PlaylistSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlaylistSummaryCopyWith<_PlaylistSummary> get copyWith => __$PlaylistSummaryCopyWithImpl<_PlaylistSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlaylistSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.trackCount, trackCount) || other.trackCount == trackCount)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.artworkPath, artworkPath) || other.artworkPath == artworkPath));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,name,trackCount,updatedAt,artworkPath);
}

@override
String toString() {
    return 'PlaylistSummary(id: $id, name: $name, trackCount: $trackCount, updatedAt: $updatedAt, artworkPath: $artworkPath)';
}


}

/// @nodoc
abstract mixin class _$PlaylistSummaryCopyWith<$Res> implements $PlaylistSummaryCopyWith<$Res> {
  factory _$PlaylistSummaryCopyWith(_PlaylistSummary value, $Res Function(_PlaylistSummary) _then) = __$PlaylistSummaryCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, int trackCount, DateTime updatedAt, String? artworkPath
});




}
/// @nodoc
class __$PlaylistSummaryCopyWithImpl<$Res>
    implements _$PlaylistSummaryCopyWith<$Res> {
  __$PlaylistSummaryCopyWithImpl(this._self, this._then);

  final _PlaylistSummary _self;
  final $Res Function(_PlaylistSummary) _then;

/// Create a copy of PlaylistSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? trackCount = null,Object? updatedAt = null,Object? artworkPath = freezed,}) {
  return _then(_PlaylistSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,trackCount: null == trackCount ? _self.trackCount : trackCount // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,artworkPath: freezed == artworkPath ? _self.artworkPath : artworkPath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$ScanProgress {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanProgress);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ScanProgress()';
}


}

/// @nodoc
class $ScanProgressCopyWith<$Res>  {
$ScanProgressCopyWith(ScanProgress _, $Res Function(ScanProgress) __);
}


/// Adds pattern-matching-related methods to [ScanProgress].
extension ScanProgressPatterns on ScanProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ScanDiscovering value)?  discovering,TResult Function( ScanReading value)?  reading,TResult Function( ScanFinished value)?  finished,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ScanDiscovering() when discovering != null:
return discovering(_that);case ScanReading() when reading != null:
return reading(_that);case ScanFinished() when finished != null:
return finished(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ScanDiscovering value)  discovering,required TResult Function( ScanReading value)  reading,required TResult Function( ScanFinished value)  finished,}){
final _that = this;
switch (_that) {
case ScanDiscovering():
return discovering(_that);case ScanReading():
return reading(_that);case ScanFinished():
return finished(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ScanDiscovering value)?  discovering,TResult? Function( ScanReading value)?  reading,TResult? Function( ScanFinished value)?  finished,}){
final _that = this;
switch (_that) {
case ScanDiscovering() when discovering != null:
return discovering(_that);case ScanReading() when reading != null:
return reading(_that);case ScanFinished() when finished != null:
return finished(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int found)?  discovering,TResult Function( int done,  int total,  String currentFile)?  reading,TResult Function( int added,  int updated,  int removed,  Duration took)?  finished,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ScanDiscovering() when discovering != null:
return discovering(_that.found);case ScanReading() when reading != null:
return reading(_that.done,_that.total,_that.currentFile);case ScanFinished() when finished != null:
return finished(_that.added,_that.updated,_that.removed,_that.took);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int found)  discovering,required TResult Function( int done,  int total,  String currentFile)  reading,required TResult Function( int added,  int updated,  int removed,  Duration took)  finished,}) {final _that = this;
switch (_that) {
case ScanDiscovering():
return discovering(_that.found);case ScanReading():
return reading(_that.done,_that.total,_that.currentFile);case ScanFinished():
return finished(_that.added,_that.updated,_that.removed,_that.took);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int found)?  discovering,TResult? Function( int done,  int total,  String currentFile)?  reading,TResult? Function( int added,  int updated,  int removed,  Duration took)?  finished,}) {final _that = this;
switch (_that) {
case ScanDiscovering() when discovering != null:
return discovering(_that.found);case ScanReading() when reading != null:
return reading(_that.done,_that.total,_that.currentFile);case ScanFinished() when finished != null:
return finished(_that.added,_that.updated,_that.removed,_that.took);case _:
  return null;

}
}

}

/// @nodoc


class ScanDiscovering implements ScanProgress {
  const ScanDiscovering({required this.found});
  

 final  int found;

/// Create a copy of ScanProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanDiscoveringCopyWith<ScanDiscovering> get copyWith => _$ScanDiscoveringCopyWithImpl<ScanDiscovering>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanDiscovering&&(identical(other.found, found) || other.found == found));
}


@override
int get hashCode {
    return Object.hash(runtimeType,found);
}

@override
String toString() {
    return 'ScanProgress.discovering(found: $found)';
}


}

/// @nodoc
abstract mixin class $ScanDiscoveringCopyWith<$Res> implements $ScanProgressCopyWith<$Res> {
  factory $ScanDiscoveringCopyWith(ScanDiscovering value, $Res Function(ScanDiscovering) _then) = _$ScanDiscoveringCopyWithImpl;
@useResult
$Res call({
 int found
});




}
/// @nodoc
class _$ScanDiscoveringCopyWithImpl<$Res>
    implements $ScanDiscoveringCopyWith<$Res> {
  _$ScanDiscoveringCopyWithImpl(this._self, this._then);

  final ScanDiscovering _self;
  final $Res Function(ScanDiscovering) _then;

/// Create a copy of ScanProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? found = null,}) {
  return _then(ScanDiscovering(
found: null == found ? _self.found : found // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ScanReading implements ScanProgress {
  const ScanReading({required this.done, required this.total, required this.currentFile});
  

 final  int done;
 final  int total;
 final  String currentFile;

/// Create a copy of ScanProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanReadingCopyWith<ScanReading> get copyWith => _$ScanReadingCopyWithImpl<ScanReading>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanReading&&(identical(other.done, done) || other.done == done)&&(identical(other.total, total) || other.total == total)&&(identical(other.currentFile, currentFile) || other.currentFile == currentFile));
}


@override
int get hashCode {
    return Object.hash(runtimeType,done,total,currentFile);
}

@override
String toString() {
    return 'ScanProgress.reading(done: $done, total: $total, currentFile: $currentFile)';
}


}

/// @nodoc
abstract mixin class $ScanReadingCopyWith<$Res> implements $ScanProgressCopyWith<$Res> {
  factory $ScanReadingCopyWith(ScanReading value, $Res Function(ScanReading) _then) = _$ScanReadingCopyWithImpl;
@useResult
$Res call({
 int done, int total, String currentFile
});




}
/// @nodoc
class _$ScanReadingCopyWithImpl<$Res>
    implements $ScanReadingCopyWith<$Res> {
  _$ScanReadingCopyWithImpl(this._self, this._then);

  final ScanReading _self;
  final $Res Function(ScanReading) _then;

/// Create a copy of ScanProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? done = null,Object? total = null,Object? currentFile = null,}) {
  return _then(ScanReading(
done: null == done ? _self.done : done // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,currentFile: null == currentFile ? _self.currentFile : currentFile // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ScanFinished implements ScanProgress {
  const ScanFinished({required this.added, required this.updated, required this.removed, required this.took});
  

 final  int added;
 final  int updated;
 final  int removed;
 final  Duration took;

/// Create a copy of ScanProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanFinishedCopyWith<ScanFinished> get copyWith => _$ScanFinishedCopyWithImpl<ScanFinished>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanFinished&&(identical(other.added, added) || other.added == added)&&(identical(other.updated, updated) || other.updated == updated)&&(identical(other.removed, removed) || other.removed == removed)&&(identical(other.took, took) || other.took == took));
}


@override
int get hashCode {
    return Object.hash(runtimeType,added,updated,removed,took);
}

@override
String toString() {
    return 'ScanProgress.finished(added: $added, updated: $updated, removed: $removed, took: $took)';
}


}

/// @nodoc
abstract mixin class $ScanFinishedCopyWith<$Res> implements $ScanProgressCopyWith<$Res> {
  factory $ScanFinishedCopyWith(ScanFinished value, $Res Function(ScanFinished) _then) = _$ScanFinishedCopyWithImpl;
@useResult
$Res call({
 int added, int updated, int removed, Duration took
});




}
/// @nodoc
class _$ScanFinishedCopyWithImpl<$Res>
    implements $ScanFinishedCopyWith<$Res> {
  _$ScanFinishedCopyWithImpl(this._self, this._then);

  final ScanFinished _self;
  final $Res Function(ScanFinished) _then;

/// Create a copy of ScanProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? added = null,Object? updated = null,Object? removed = null,Object? took = null,}) {
  return _then(ScanFinished(
added: null == added ? _self.added : added // ignore: cast_nullable_to_non_nullable
as int,updated: null == updated ? _self.updated : updated // ignore: cast_nullable_to_non_nullable
as int,removed: null == removed ? _self.removed : removed // ignore: cast_nullable_to_non_nullable
as int,took: null == took ? _self.took : took // ignore: cast_nullable_to_non_nullable
as Duration,
  ));
}


}

// dart format on

// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'smart_playlist.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
SmartRule _$SmartRuleFromJson(
  Map<String, dynamic> json
) {
        switch (json['rule']) {
                  case 'mostPlayed':
          return MostPlayedRule.fromJson(
            json
          );
                case 'recentlyAdded':
          return RecentlyAddedRule.fromJson(
            json
          );
                case 'genre':
          return GenreRule.fromJson(
            json
          );
                case 'year':
          return YearRule.fromJson(
            json
          );
                case 'notPlayedFor':
          return NotPlayedForRule.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'rule',
  'SmartRule',
  'Invalid union type "${json['rule']}"!'
);
        }
      
}

/// @nodoc
mixin _$SmartRule {



  /// Serializes this SmartRule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartRule);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SmartRule()';
}


}

/// @nodoc
class $SmartRuleCopyWith<$Res>  {
$SmartRuleCopyWith(SmartRule _, $Res Function(SmartRule) __);
}


/// Adds pattern-matching-related methods to [SmartRule].
extension SmartRulePatterns on SmartRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( MostPlayedRule value)?  mostPlayed,TResult Function( RecentlyAddedRule value)?  recentlyAdded,TResult Function( GenreRule value)?  genre,TResult Function( YearRule value)?  year,TResult Function( NotPlayedForRule value)?  notPlayedFor,required TResult orElse(),}){
final _that = this;
switch (_that) {
case MostPlayedRule() when mostPlayed != null:
return mostPlayed(_that);case RecentlyAddedRule() when recentlyAdded != null:
return recentlyAdded(_that);case GenreRule() when genre != null:
return genre(_that);case YearRule() when year != null:
return year(_that);case NotPlayedForRule() when notPlayedFor != null:
return notPlayedFor(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( MostPlayedRule value)  mostPlayed,required TResult Function( RecentlyAddedRule value)  recentlyAdded,required TResult Function( GenreRule value)  genre,required TResult Function( YearRule value)  year,required TResult Function( NotPlayedForRule value)  notPlayedFor,}){
final _that = this;
switch (_that) {
case MostPlayedRule():
return mostPlayed(_that);case RecentlyAddedRule():
return recentlyAdded(_that);case GenreRule():
return genre(_that);case YearRule():
return year(_that);case NotPlayedForRule():
return notPlayedFor(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( MostPlayedRule value)?  mostPlayed,TResult? Function( RecentlyAddedRule value)?  recentlyAdded,TResult? Function( GenreRule value)?  genre,TResult? Function( YearRule value)?  year,TResult? Function( NotPlayedForRule value)?  notPlayedFor,}){
final _that = this;
switch (_that) {
case MostPlayedRule() when mostPlayed != null:
return mostPlayed(_that);case RecentlyAddedRule() when recentlyAdded != null:
return recentlyAdded(_that);case GenreRule() when genre != null:
return genre(_that);case YearRule() when year != null:
return year(_that);case NotPlayedForRule() when notPlayedFor != null:
return notPlayedFor(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int minPlays,  int? days)?  mostPlayed,TResult Function( int days)?  recentlyAdded,TResult Function( String genre)?  genre,TResult Function( int? from,  int? to)?  year,TResult Function( int days)?  notPlayedFor,required TResult orElse(),}) {final _that = this;
switch (_that) {
case MostPlayedRule() when mostPlayed != null:
return mostPlayed(_that.minPlays,_that.days);case RecentlyAddedRule() when recentlyAdded != null:
return recentlyAdded(_that.days);case GenreRule() when genre != null:
return genre(_that.genre);case YearRule() when year != null:
return year(_that.from,_that.to);case NotPlayedForRule() when notPlayedFor != null:
return notPlayedFor(_that.days);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int minPlays,  int? days)  mostPlayed,required TResult Function( int days)  recentlyAdded,required TResult Function( String genre)  genre,required TResult Function( int? from,  int? to)  year,required TResult Function( int days)  notPlayedFor,}) {final _that = this;
switch (_that) {
case MostPlayedRule():
return mostPlayed(_that.minPlays,_that.days);case RecentlyAddedRule():
return recentlyAdded(_that.days);case GenreRule():
return genre(_that.genre);case YearRule():
return year(_that.from,_that.to);case NotPlayedForRule():
return notPlayedFor(_that.days);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int minPlays,  int? days)?  mostPlayed,TResult? Function( int days)?  recentlyAdded,TResult? Function( String genre)?  genre,TResult? Function( int? from,  int? to)?  year,TResult? Function( int days)?  notPlayedFor,}) {final _that = this;
switch (_that) {
case MostPlayedRule() when mostPlayed != null:
return mostPlayed(_that.minPlays,_that.days);case RecentlyAddedRule() when recentlyAdded != null:
return recentlyAdded(_that.days);case GenreRule() when genre != null:
return genre(_that.genre);case YearRule() when year != null:
return year(_that.from,_that.to);case NotPlayedForRule() when notPlayedFor != null:
return notPlayedFor(_that.days);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class MostPlayedRule implements SmartRule {
  const MostPlayedRule({this.minPlays = 1, this.days,  String? $type}): $type = $type ?? 'mostPlayed';
  factory MostPlayedRule.fromJson(Map<String, dynamic> json) => _$MostPlayedRuleFromJson(json);

@JsonKey() final  int minPlays;
 final  int? days;

@JsonKey(name: 'rule')
final String $type;


/// Create a copy of SmartRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MostPlayedRuleCopyWith<MostPlayedRule> get copyWith => _$MostPlayedRuleCopyWithImpl<MostPlayedRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MostPlayedRuleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is MostPlayedRule&&(identical(other.minPlays, minPlays) || other.minPlays == minPlays)&&(identical(other.days, days) || other.days == days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,minPlays,days);
}

@override
String toString() {
    return 'SmartRule.mostPlayed(minPlays: $minPlays, days: $days)';
}


}

/// @nodoc
abstract mixin class $MostPlayedRuleCopyWith<$Res> implements $SmartRuleCopyWith<$Res> {
  factory $MostPlayedRuleCopyWith(MostPlayedRule value, $Res Function(MostPlayedRule) _then) = _$MostPlayedRuleCopyWithImpl;
@useResult
$Res call({
 int minPlays, int? days
});




}
/// @nodoc
class _$MostPlayedRuleCopyWithImpl<$Res>
    implements $MostPlayedRuleCopyWith<$Res> {
  _$MostPlayedRuleCopyWithImpl(this._self, this._then);

  final MostPlayedRule _self;
  final $Res Function(MostPlayedRule) _then;

/// Create a copy of SmartRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? minPlays = null,Object? days = freezed,}) {
  return _then(MostPlayedRule(
minPlays: null == minPlays ? _self.minPlays : minPlays // ignore: cast_nullable_to_non_nullable
as int,days: freezed == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class RecentlyAddedRule implements SmartRule {
  const RecentlyAddedRule({this.days = 30,  String? $type}): $type = $type ?? 'recentlyAdded';
  factory RecentlyAddedRule.fromJson(Map<String, dynamic> json) => _$RecentlyAddedRuleFromJson(json);

@JsonKey() final  int days;

@JsonKey(name: 'rule')
final String $type;


/// Create a copy of SmartRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentlyAddedRuleCopyWith<RecentlyAddedRule> get copyWith => _$RecentlyAddedRuleCopyWithImpl<RecentlyAddedRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecentlyAddedRuleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentlyAddedRule&&(identical(other.days, days) || other.days == days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,days);
}

@override
String toString() {
    return 'SmartRule.recentlyAdded(days: $days)';
}


}

/// @nodoc
abstract mixin class $RecentlyAddedRuleCopyWith<$Res> implements $SmartRuleCopyWith<$Res> {
  factory $RecentlyAddedRuleCopyWith(RecentlyAddedRule value, $Res Function(RecentlyAddedRule) _then) = _$RecentlyAddedRuleCopyWithImpl;
@useResult
$Res call({
 int days
});




}
/// @nodoc
class _$RecentlyAddedRuleCopyWithImpl<$Res>
    implements $RecentlyAddedRuleCopyWith<$Res> {
  _$RecentlyAddedRuleCopyWithImpl(this._self, this._then);

  final RecentlyAddedRule _self;
  final $Res Function(RecentlyAddedRule) _then;

/// Create a copy of SmartRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? days = null,}) {
  return _then(RecentlyAddedRule(
days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
@JsonSerializable()

class GenreRule implements SmartRule {
  const GenreRule({required this.genre,  String? $type}): $type = $type ?? 'genre';
  factory GenreRule.fromJson(Map<String, dynamic> json) => _$GenreRuleFromJson(json);

 final  String genre;

@JsonKey(name: 'rule')
final String $type;


/// Create a copy of SmartRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GenreRuleCopyWith<GenreRule> get copyWith => _$GenreRuleCopyWithImpl<GenreRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GenreRuleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is GenreRule&&(identical(other.genre, genre) || other.genre == genre));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,genre);
}

@override
String toString() {
    return 'SmartRule.genre(genre: $genre)';
}


}

/// @nodoc
abstract mixin class $GenreRuleCopyWith<$Res> implements $SmartRuleCopyWith<$Res> {
  factory $GenreRuleCopyWith(GenreRule value, $Res Function(GenreRule) _then) = _$GenreRuleCopyWithImpl;
@useResult
$Res call({
 String genre
});




}
/// @nodoc
class _$GenreRuleCopyWithImpl<$Res>
    implements $GenreRuleCopyWith<$Res> {
  _$GenreRuleCopyWithImpl(this._self, this._then);

  final GenreRule _self;
  final $Res Function(GenreRule) _then;

/// Create a copy of SmartRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? genre = null,}) {
  return _then(GenreRule(
genre: null == genre ? _self.genre : genre // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class YearRule implements SmartRule {
  const YearRule({this.from, this.to,  String? $type}): $type = $type ?? 'year';
  factory YearRule.fromJson(Map<String, dynamic> json) => _$YearRuleFromJson(json);

 final  int? from;
 final  int? to;

@JsonKey(name: 'rule')
final String $type;


/// Create a copy of SmartRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$YearRuleCopyWith<YearRule> get copyWith => _$YearRuleCopyWithImpl<YearRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$YearRuleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is YearRule&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,from,to);
}

@override
String toString() {
    return 'SmartRule.year(from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class $YearRuleCopyWith<$Res> implements $SmartRuleCopyWith<$Res> {
  factory $YearRuleCopyWith(YearRule value, $Res Function(YearRule) _then) = _$YearRuleCopyWithImpl;
@useResult
$Res call({
 int? from, int? to
});




}
/// @nodoc
class _$YearRuleCopyWithImpl<$Res>
    implements $YearRuleCopyWith<$Res> {
  _$YearRuleCopyWithImpl(this._self, this._then);

  final YearRule _self;
  final $Res Function(YearRule) _then;

/// Create a copy of SmartRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? from = freezed,Object? to = freezed,}) {
  return _then(YearRule(
from: freezed == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as int?,to: freezed == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class NotPlayedForRule implements SmartRule {
  const NotPlayedForRule({this.days = 90,  String? $type}): $type = $type ?? 'notPlayedFor';
  factory NotPlayedForRule.fromJson(Map<String, dynamic> json) => _$NotPlayedForRuleFromJson(json);

@JsonKey() final  int days;

@JsonKey(name: 'rule')
final String $type;


/// Create a copy of SmartRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NotPlayedForRuleCopyWith<NotPlayedForRule> get copyWith => _$NotPlayedForRuleCopyWithImpl<NotPlayedForRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NotPlayedForRuleToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NotPlayedForRule&&(identical(other.days, days) || other.days == days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,days);
}

@override
String toString() {
    return 'SmartRule.notPlayedFor(days: $days)';
}


}

/// @nodoc
abstract mixin class $NotPlayedForRuleCopyWith<$Res> implements $SmartRuleCopyWith<$Res> {
  factory $NotPlayedForRuleCopyWith(NotPlayedForRule value, $Res Function(NotPlayedForRule) _then) = _$NotPlayedForRuleCopyWithImpl;
@useResult
$Res call({
 int days
});




}
/// @nodoc
class _$NotPlayedForRuleCopyWithImpl<$Res>
    implements $NotPlayedForRuleCopyWith<$Res> {
  _$NotPlayedForRuleCopyWithImpl(this._self, this._then);

  final NotPlayedForRule _self;
  final $Res Function(NotPlayedForRule) _then;

/// Create a copy of SmartRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? days = null,}) {
  return _then(NotPlayedForRule(
days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$SmartPlaylist {

/// Database id; built-ins use negative ids.
 int get id; String get name; List<SmartRule> get rules; SmartSort get sort; int get limit;
/// Create a copy of SmartPlaylist
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmartPlaylistCopyWith<SmartPlaylist> get copyWith => _$SmartPlaylistCopyWithImpl<SmartPlaylist>(this as SmartPlaylist, _$identity);

  /// Serializes this SmartPlaylist to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SmartPlaylist;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmartPlaylist&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name)&&const DeepCollectionEquality().equals(other.rules, _this.rules)&&(identical(other.sort, _this.sort) || other.sort == _this.sort)&&(identical(other.limit, _this.limit) || other.limit == _this.limit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SmartPlaylist;
  return Object.hash(runtimeType,_this.id,_this.name,const DeepCollectionEquality().hash(_this.rules),_this.sort,_this.limit);
}

@override
String toString() {
  final _this = this as SmartPlaylist;
  return 'SmartPlaylist(id: ${_this.id}, name: ${_this.name}, rules: ${_this.rules}, sort: ${_this.sort}, limit: ${_this.limit})';
}


}

/// @nodoc
abstract mixin class $SmartPlaylistCopyWith<$Res>  {
  factory $SmartPlaylistCopyWith(SmartPlaylist value, $Res Function(SmartPlaylist) _then) = _$SmartPlaylistCopyWithImpl;
@useResult
$Res call({
 int id, String name, List<SmartRule> rules, SmartSort sort, int limit
});




}
/// @nodoc
class _$SmartPlaylistCopyWithImpl<$Res>
    implements $SmartPlaylistCopyWith<$Res> {
  _$SmartPlaylistCopyWithImpl(this._self, this._then);

  final SmartPlaylist _self;
  final $Res Function(SmartPlaylist) _then;

/// Create a copy of SmartPlaylist
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? rules = null,Object? sort = null,Object? limit = null,}) {
  return _then(SmartPlaylist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rules: null == rules ? _self.rules : rules // ignore: cast_nullable_to_non_nullable
as List<SmartRule>,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as SmartSort,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SmartPlaylist].
extension SmartPlaylistPatterns on SmartPlaylist {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SmartPlaylist value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SmartPlaylist() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SmartPlaylist value)  $default,){
final _that = this;
switch (_that) {
case _SmartPlaylist():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SmartPlaylist value)?  $default,){
final _that = this;
switch (_that) {
case _SmartPlaylist() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  List<SmartRule> rules,  SmartSort sort,  int limit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SmartPlaylist() when $default != null:
return $default(_that.id,_that.name,_that.rules,_that.sort,_that.limit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  List<SmartRule> rules,  SmartSort sort,  int limit)  $default,) {final _that = this;
switch (_that) {
case _SmartPlaylist():
return $default(_that.id,_that.name,_that.rules,_that.sort,_that.limit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  List<SmartRule> rules,  SmartSort sort,  int limit)?  $default,) {final _that = this;
switch (_that) {
case _SmartPlaylist() when $default != null:
return $default(_that.id,_that.name,_that.rules,_that.sort,_that.limit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SmartPlaylist implements SmartPlaylist {
  const _SmartPlaylist({this.id = 0, required this.name,  List<SmartRule> rules = const [], this.sort = SmartSort.plays, this.limit = 100}): _rules = rules;
  factory _SmartPlaylist.fromJson(Map<String, dynamic> json) => _$SmartPlaylistFromJson(json);

/// Database id; built-ins use negative ids.
@override@JsonKey() final  int id;
@override final  String name;
 final  List<SmartRule> _rules;
@override@JsonKey() List<SmartRule> get rules {
  if (_rules is EqualUnmodifiableListView) return _rules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rules);
}

@override@JsonKey() final  SmartSort sort;
@override@JsonKey() final  int limit;

/// Create a copy of SmartPlaylist
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SmartPlaylistCopyWith<_SmartPlaylist> get copyWith => __$SmartPlaylistCopyWithImpl<_SmartPlaylist>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SmartPlaylistToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SmartPlaylist&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.rules, _rules)&&(identical(other.sort, sort) || other.sort == sort)&&(identical(other.limit, limit) || other.limit == limit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_rules),sort,limit);
}

@override
String toString() {
    return 'SmartPlaylist(id: $id, name: $name, rules: $rules, sort: $sort, limit: $limit)';
}


}

/// @nodoc
abstract mixin class _$SmartPlaylistCopyWith<$Res> implements $SmartPlaylistCopyWith<$Res> {
  factory _$SmartPlaylistCopyWith(_SmartPlaylist value, $Res Function(_SmartPlaylist) _then) = __$SmartPlaylistCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, List<SmartRule> rules, SmartSort sort, int limit
});




}
/// @nodoc
class __$SmartPlaylistCopyWithImpl<$Res>
    implements _$SmartPlaylistCopyWith<$Res> {
  __$SmartPlaylistCopyWithImpl(this._self, this._then);

  final _SmartPlaylist _self;
  final $Res Function(_SmartPlaylist) _then;

/// Create a copy of SmartPlaylist
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? rules = null,Object? sort = null,Object? limit = null,}) {
  return _then(_SmartPlaylist(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rules: null == rules ? _self._rules : rules // ignore: cast_nullable_to_non_nullable
as List<SmartRule>,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as SmartSort,limit: null == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on

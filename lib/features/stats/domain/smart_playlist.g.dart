// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_playlist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MostPlayedRule _$MostPlayedRuleFromJson(Map<String, dynamic> json) =>
    MostPlayedRule(
      minPlays: (json['minPlays'] as num?)?.toInt() ?? 1,
      days: (json['days'] as num?)?.toInt(),
      $type: json['rule'] as String?,
    );

Map<String, dynamic> _$MostPlayedRuleToJson(MostPlayedRule instance) =>
    <String, dynamic>{
      'minPlays': instance.minPlays,
      'days': instance.days,
      'rule': instance.$type,
    };

RecentlyAddedRule _$RecentlyAddedRuleFromJson(Map<String, dynamic> json) =>
    RecentlyAddedRule(
      days: (json['days'] as num?)?.toInt() ?? 30,
      $type: json['rule'] as String?,
    );

Map<String, dynamic> _$RecentlyAddedRuleToJson(RecentlyAddedRule instance) =>
    <String, dynamic>{'days': instance.days, 'rule': instance.$type};

GenreRule _$GenreRuleFromJson(Map<String, dynamic> json) =>
    GenreRule(genre: json['genre'] as String, $type: json['rule'] as String?);

Map<String, dynamic> _$GenreRuleToJson(GenreRule instance) => <String, dynamic>{
  'genre': instance.genre,
  'rule': instance.$type,
};

YearRule _$YearRuleFromJson(Map<String, dynamic> json) => YearRule(
  from: (json['from'] as num?)?.toInt(),
  to: (json['to'] as num?)?.toInt(),
  $type: json['rule'] as String?,
);

Map<String, dynamic> _$YearRuleToJson(YearRule instance) => <String, dynamic>{
  'from': instance.from,
  'to': instance.to,
  'rule': instance.$type,
};

NotPlayedForRule _$NotPlayedForRuleFromJson(Map<String, dynamic> json) =>
    NotPlayedForRule(
      days: (json['days'] as num?)?.toInt() ?? 90,
      $type: json['rule'] as String?,
    );

Map<String, dynamic> _$NotPlayedForRuleToJson(NotPlayedForRule instance) =>
    <String, dynamic>{'days': instance.days, 'rule': instance.$type};

_SmartPlaylist _$SmartPlaylistFromJson(Map<String, dynamic> json) =>
    _SmartPlaylist(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String,
      rules:
          (json['rules'] as List<dynamic>?)
              ?.map((e) => SmartRule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      sort:
          $enumDecodeNullable(_$SmartSortEnumMap, json['sort']) ??
          SmartSort.plays,
      limit: (json['limit'] as num?)?.toInt() ?? 100,
    );

Map<String, dynamic> _$SmartPlaylistToJson(_SmartPlaylist instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'rules': instance.rules.map((e) => e.toJson()).toList(),
      'sort': _$SmartSortEnumMap[instance.sort]!,
      'limit': instance.limit,
    };

const _$SmartSortEnumMap = {
  SmartSort.plays: 'plays',
  SmartSort.recentlyAdded: 'recentlyAdded',
  SmartSort.title: 'title',
  SmartSort.random: 'random',
};

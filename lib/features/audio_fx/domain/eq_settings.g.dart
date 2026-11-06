// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'eq_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EqSettings _$EqSettingsFromJson(Map<String, dynamic> json) => _EqSettings(
  enabled: json['enabled'] as bool? ?? false,
  gainsDb:
      (json['gainsDb'] as List<dynamic>?)
          ?.map((e) => (e as num).toDouble())
          .toList() ??
      const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  preampDb: (json['preampDb'] as num?)?.toDouble() ?? 0.0,
  bassBoost: (json['bassBoost'] as num?)?.toDouble() ?? 0.0,
  presetName: json['presetName'] as String? ?? 'Flat',
);

Map<String, dynamic> _$EqSettingsToJson(_EqSettings instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'gainsDb': instance.gainsDb,
      'preampDb': instance.preampDb,
      'bassBoost': instance.bassBoost,
      'presetName': instance.presetName,
    };

_EqPreset _$EqPresetFromJson(Map<String, dynamic> json) => _EqPreset(
  name: json['name'] as String,
  gainsDb: (json['gainsDb'] as List<dynamic>)
      .map((e) => (e as num).toDouble())
      .toList(),
  preampDb: (json['preampDb'] as num?)?.toDouble() ?? 0.0,
  bassBoost: (json['bassBoost'] as num?)?.toDouble() ?? 0.0,
  builtIn: json['builtIn'] as bool? ?? false,
);

Map<String, dynamic> _$EqPresetToJson(_EqPreset instance) => <String, dynamic>{
  'name': instance.name,
  'gainsDb': instance.gainsDb,
  'preampDb': instance.preampDb,
  'bassBoost': instance.bassBoost,
  'builtIn': instance.builtIn,
};

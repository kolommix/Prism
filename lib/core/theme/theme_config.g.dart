// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ThemeConfig _$ThemeConfigFromJson(Map<String, dynamic> json) => _ThemeConfig(
  name: json['name'] as String? ?? 'Mono',
  primaryColor: (json['primaryColor'] as num?)?.toInt() ?? 0xFF7C4DFF,
  accentColor: (json['accentColor'] as num?)?.toInt() ?? 0xFF00E5FF,
  brightness:
      $enumDecodeNullable(_$ThemeBrightnessModeEnumMap, json['brightness']) ??
      ThemeBrightnessMode.amoled,
  cornerRadius: (json['cornerRadius'] as num?)?.toDouble() ?? 16.0,
  fontFamily: json['fontFamily'] as String?,
  glassIntensity: (json['glassIntensity'] as num?)?.toDouble() ?? 0.5,
  animationSpeed: (json['animationSpeed'] as num?)?.toDouble() ?? 1.0,
  dynamicColor: json['dynamicColor'] as bool? ?? true,
  monochrome: json['monochrome'] as bool? ?? true,
  background: json['background'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ThemeConfigToJson(_ThemeConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'primaryColor': instance.primaryColor,
      'accentColor': instance.accentColor,
      'brightness': _$ThemeBrightnessModeEnumMap[instance.brightness]!,
      'cornerRadius': instance.cornerRadius,
      'fontFamily': instance.fontFamily,
      'glassIntensity': instance.glassIntensity,
      'animationSpeed': instance.animationSpeed,
      'dynamicColor': instance.dynamicColor,
      'monochrome': instance.monochrome,
      'background': instance.background,
    };

const _$ThemeBrightnessModeEnumMap = {
  ThemeBrightnessMode.system: 'system',
  ThemeBrightnessMode.light: 'light',
  ThemeBrightnessMode.dark: 'dark',
  ThemeBrightnessMode.amoled: 'amoled',
};

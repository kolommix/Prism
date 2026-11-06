// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BgParams _$BgParamsFromJson(Map<String, dynamic> json) => _BgParams(
  followTheme: json['followTheme'] as bool? ?? true,
  color: (json['color'] as num?)?.toInt() ?? 0xFF35E07A,
  accent: (json['accent'] as num?)?.toInt() ?? 0xFFD9FFE6,
  brightness: (json['brightness'] as num?)?.toDouble() ?? 0.7,
  speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
  density: (json['density'] as num?)?.toDouble() ?? 1.0,
  size: (json['size'] as num?)?.toDouble() ?? 1.0,
  reach: (json['reach'] as num?)?.toDouble() ?? 1.0,
  mouse: (json['mouse'] as num?)?.toDouble() ?? 1.0,
  music: (json['music'] as num?)?.toDouble() ?? 0.8,
  glyphs: json['glyphs'] as String? ?? 'katakana',
  customGlyphs: json['customGlyphs'] as String? ?? 'PRISM',
  shape: json['shape'] as String? ?? 'dots',
);

Map<String, dynamic> _$BgParamsToJson(_BgParams instance) => <String, dynamic>{
  'followTheme': instance.followTheme,
  'color': instance.color,
  'accent': instance.accent,
  'brightness': instance.brightness,
  'speed': instance.speed,
  'density': instance.density,
  'size': instance.size,
  'reach': instance.reach,
  'mouse': instance.mouse,
  'music': instance.music,
  'glyphs': instance.glyphs,
  'customGlyphs': instance.customGlyphs,
  'shape': instance.shape,
};

_BackgroundConfig _$BackgroundConfigFromJson(Map<String, dynamic> json) =>
    _BackgroundConfig(
      style: json['style'] as String? ?? 'cover',
      matrix: json['matrix'] == null
          ? matrixDefaults
          : BgParams.fromJson(json['matrix'] as Map<String, dynamic>),
      constellation: json['constellation'] == null
          ? constellationDefaults
          : BgParams.fromJson(json['constellation'] as Map<String, dynamic>),
      ripple: json['ripple'] == null
          ? rippleDefaults
          : BgParams.fromJson(json['ripple'] as Map<String, dynamic>),
      panelOpacity: (json['panelOpacity'] as num?)?.toDouble() ?? 0.4,
      showCover: json['showCover'] as bool? ?? false,
      frameRate: (json['frameRate'] as num?)?.toInt() ?? 0,
      frosted: json['frosted'] as bool? ?? true,
      softness: (json['softness'] as num?)?.toDouble() ?? 0.2,
      strength: (json['strength'] as num?)?.toDouble() ?? 1.0,
      onlyWhilePlaying: json['onlyWhilePlaying'] as bool? ?? false,
      extra:
          (json['extra'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, BgParams.fromJson(e as Map<String, dynamic>)),
          ) ??
          const <String, BgParams>{},
      gradientPreset: json['gradientPreset'] as String? ?? 'dusk',
      imagePath: json['imagePath'] as String? ?? '',
      videoDir: json['videoDir'] as String? ?? '',
      dim: (json['dim'] as num?)?.toDouble() ?? 0.0,
      parallax: json['parallax'] as bool? ?? false,
      batterySaver: json['batterySaver'] as bool? ?? false,
    );

Map<String, dynamic> _$BackgroundConfigToJson(_BackgroundConfig instance) =>
    <String, dynamic>{
      'style': instance.style,
      'matrix': instance.matrix.toJson(),
      'constellation': instance.constellation.toJson(),
      'ripple': instance.ripple.toJson(),
      'panelOpacity': instance.panelOpacity,
      'showCover': instance.showCover,
      'frameRate': instance.frameRate,
      'frosted': instance.frosted,
      'softness': instance.softness,
      'strength': instance.strength,
      'onlyWhilePlaying': instance.onlyWhilePlaying,
      'extra': instance.extra.map((k, e) => MapEntry(k, e.toJson())),
      'gradientPreset': instance.gradientPreset,
      'imagePath': instance.imagePath,
      'videoDir': instance.videoDir,
      'dim': instance.dim,
      'parallax': instance.parallax,
      'batterySaver': instance.batterySaver,
    };

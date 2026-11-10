// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => _AppSettings(
  theme: json['theme'] == null
      ? defaultTheme
      : ThemeConfig.fromJson(json['theme'] as Map<String, dynamic>),
  autoCheckUpdates: json['autoCheckUpdates'] as bool? ?? true,
  localeCode: json['localeCode'] as String? ?? '',
  reduceMotion: json['reduceMotion'] as bool? ?? false,
  crossfadeSeconds: (json['crossfadeSeconds'] as num?)?.toInt() ?? 0,
  closeToTray: json['closeToTray'] as bool? ?? true,
  highPriority: json['highPriority'] as bool? ?? true,
  normalization:
      $enumDecodeNullable(_$NormalizationModeEnumMap, json['normalization']) ??
      NormalizationMode.off,
  autoAnalyzeLoudness: json['autoAnalyzeLoudness'] as bool? ?? true,
  onlineLyrics: json['onlineLyrics'] as bool? ?? true,
  autoFindInfo: json['autoFindInfo'] as bool? ?? true,
  visualizerStyle: json['visualizerStyle'] as String? ?? 'bars',
  visualizerSensitivity:
      (json['visualizerSensitivity'] as num?)?.toDouble() ?? 1.0,
  visualizerLowPower: json['visualizerLowPower'] as bool? ?? false,
  visualizerLive: json['visualizerLive'] as bool? ?? false,
  seekBarStyle: json['seekBarStyle'] as String? ?? 'waveform',
  liveSeekBar: json['liveSeekBar'] as bool? ?? true,
  seekBarColor: (json['seekBarColor'] as num?)?.toInt(),
  seekBarSize: (json['seekBarSize'] as num?)?.toDouble() ?? 1.0,
  seekBarDensity: (json['seekBarDensity'] as num?)?.toDouble() ?? 1.0,
  seekBarThickness: (json['seekBarThickness'] as num?)?.toDouble() ?? 1.0,
  seekBarDim: (json['seekBarDim'] as num?)?.toDouble() ?? 0.18,
  seekBarReact: (json['seekBarReact'] as num?)?.toDouble() ?? 1.0,
  seekBarHead: json['seekBarHead'] as bool? ?? true,
  seekBarTimes: json['seekBarTimes'] as bool? ?? true,
  background: json['background'] == null
      ? const BackgroundConfig()
      : BackgroundConfig.fromJson(json['background'] as Map<String, dynamic>),
  relayUrl: json['relayUrl'] as String? ?? '',
  togetherInternet: json['togetherInternet'] as bool? ?? true,
  togetherName: json['togetherName'] as String? ?? '',
  togetherGuestControl: json['togetherGuestControl'] as bool? ?? true,
  eqDetailed: json['eqDetailed'] as bool? ?? false,
  discordPresence: json['discordPresence'] as bool? ?? false,
  discordClientId: json['discordClientId'] as String? ?? '',
  discordCovers: json['discordCovers'] as bool? ?? true,
);

Map<String, dynamic> _$AppSettingsToJson(_AppSettings instance) =>
    <String, dynamic>{
      'theme': instance.theme.toJson(),
      'autoCheckUpdates': instance.autoCheckUpdates,
      'localeCode': instance.localeCode,
      'reduceMotion': instance.reduceMotion,
      'crossfadeSeconds': instance.crossfadeSeconds,
      'closeToTray': instance.closeToTray,
      'highPriority': instance.highPriority,
      'normalization': _$NormalizationModeEnumMap[instance.normalization]!,
      'autoAnalyzeLoudness': instance.autoAnalyzeLoudness,
      'onlineLyrics': instance.onlineLyrics,
      'autoFindInfo': instance.autoFindInfo,
      'visualizerStyle': instance.visualizerStyle,
      'visualizerSensitivity': instance.visualizerSensitivity,
      'visualizerLowPower': instance.visualizerLowPower,
      'visualizerLive': instance.visualizerLive,
      'seekBarStyle': instance.seekBarStyle,
      'liveSeekBar': instance.liveSeekBar,
      'seekBarColor': instance.seekBarColor,
      'seekBarSize': instance.seekBarSize,
      'seekBarDensity': instance.seekBarDensity,
      'seekBarThickness': instance.seekBarThickness,
      'seekBarDim': instance.seekBarDim,
      'seekBarReact': instance.seekBarReact,
      'seekBarHead': instance.seekBarHead,
      'seekBarTimes': instance.seekBarTimes,
      'background': instance.background.toJson(),
      'relayUrl': instance.relayUrl,
      'togetherInternet': instance.togetherInternet,
      'togetherName': instance.togetherName,
      'togetherGuestControl': instance.togetherGuestControl,
      'eqDetailed': instance.eqDetailed,
      'discordPresence': instance.discordPresence,
      'discordClientId': instance.discordClientId,
      'discordCovers': instance.discordCovers,
    };

const _$NormalizationModeEnumMap = {
  NormalizationMode.off: 'off',
  NormalizationMode.track: 'track',
  NormalizationMode.album: 'album',
};

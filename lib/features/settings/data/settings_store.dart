import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/theme_config.dart';
import '../domain/app_settings.dart';

/// Loads/saves [AppSettings] in shared preferences.
class SettingsStore {
  SettingsStore(this._prefs);

  static const _key = 'settings.v1';

  /// Set once the "Prism colors are the default now" move was done.
  static const _prismDefaultKey = 'settings.prismColorsDefault';
  final SharedPreferencesAsync _prefs;

  Future<AppSettings> load() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) {
      // Fresh install: starts with the default (Prism colors) already.
      await _prefs.setBool(_prismDefaultKey, true);
      return const AppSettings();
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['theme'] case final Map<String, dynamic> theme) json['theme'] = upgradeTheme(theme);
      var s = AppSettings.fromJson(json);
      s = s.copyWith(theme: s.theme.sanitized());
      if (await _prefs.getBool(_prismDefaultKey) != true) {
        await _prefs.setBool(_prismDefaultKey, true);
        final moved = toPrismColors(s.theme);
        if (moved != s.theme) {
          s = s.copyWith(theme: moved);
          await save(s);
        }
      }
      return s;
    } on Object {
      // Corrupt settings should never brick the app.
      return const AppSettings();
    }
  }

  /// Settings from before black & white existed: anyone still on a built-in
  /// color preset moves to the new default (their font is kept); a theme
  /// they made themselves stays as it was.
  static Map<String, dynamic> upgradeTheme(Map<String, dynamic> theme) {
    if (theme.containsKey('monochrome')) return theme;
    if (!ThemeConfig.legacyPresetNames.contains(theme['name'])) return ThemeConfig.upgradeJson(theme);
    return defaultTheme.copyWith(fontFamily: theme['fontFamily'] as String?).toJson();
  }

  /// Prism's colors became the default (they were black & white before).
  /// Someone still on the untouched old default moves along, once; their font
  /// and background stay. Anything they picked or changed stays as it is.
  static ThemeConfig toPrismColors(ThemeConfig t) {
    final untouched = t.copyWith(fontFamily: null, background: null) == const ThemeConfig();
    return untouched ? defaultTheme.copyWith(fontFamily: t.fontFamily, background: t.background) : t;
  }

  Future<void> save(AppSettings settings) => _prefs.setString(_key, jsonEncode(settings.toJson()));
}

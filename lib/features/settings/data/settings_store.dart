import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/theme_config.dart';
import '../domain/app_settings.dart';

/// Loads/saves [AppSettings] in shared preferences.
class SettingsStore {
  SettingsStore(this._prefs);

  static const _key = 'settings.v1';
  final SharedPreferencesAsync _prefs;

  Future<AppSettings> load() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) return const AppSettings();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['theme'] case final Map<String, dynamic> theme) json['theme'] = upgradeTheme(theme);
      final s = AppSettings.fromJson(json);
      return s.copyWith(theme: s.theme.sanitized());
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
    return const ThemeConfig().copyWith(fontFamily: theme['fontFamily'] as String?).toJson();
  }

  Future<void> save(AppSettings settings) => _prefs.setString(_key, jsonEncode(settings.toJson()));
}

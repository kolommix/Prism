import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import '../../l10n/l10n.dart';
part 'theme_config.freezed.dart';
part 'theme_config.g.dart';

/// Base brightness of the UI.
enum ThemeBrightnessMode {
  system,
  light,
  dark,

  /// Pure black surfaces – saves battery on OLED screens.
  amoled,
}

/// Everything a user can customise about the look of Prism.
///
/// This object is the *only* input of `buildPrismTheme`, and it is exactly what
/// gets exported/imported as a `.prism-theme.json` file, so friends can share
/// themes. Colors are stored as ARGB ints (`0xFFRRGGBB`).
@freezed
abstract class ThemeConfig with _$ThemeConfig {
  const ThemeConfig._();

  const factory ThemeConfig({
    @Default('Mono') String name,
    @Default(0xFF7C4DFF) int primaryColor,
    @Default(0xFF00E5FF) int accentColor,
    @Default(ThemeBrightnessMode.amoled) ThemeBrightnessMode brightness,

    /// Base corner radius in logical pixels (cards, sheets, buttons).
    @Default(16.0) double cornerRadius,

    /// Font family name. `null` = platform default. Bundled Google Fonts
    /// names (see `availableFonts`) are fetched and cached on first use.
    String? fontFamily,

    /// 0 = no blur (flat), 1 = strong frosted glass.
    @Default(0.5) double glassIntensity,

    /// Multiplier for every animation duration (0.5 = twice as fast).
    @Default(1.0) double animationSpeed,

    /// Derive colors from the current album art instead of [primaryColor].
    @Default(true) bool dynamicColor,

    /// Black & white UI: greys only, covers stay in color. Overrides the
    /// colors above (they come back when this is turned off).
    @Default(true) bool monochrome,

    /// The background saved with this theme, in `BackgroundFiles.toThemeJson`
    /// form (kept as JSON: the theme layer doesn't know about backgrounds).
    Map<String, dynamic>? background,
  }) = _ThemeConfig;

  factory ThemeConfig.fromJson(Map<String, dynamic> json) => _$ThemeConfigFromJson(json);

  /// Format marker + version written into exported files.
  static const fileFormat = 'prism-theme';
  static const fileVersion = 1;

  /// Names of the built-in color presets from before black & white existed.
  static const legacyPresetNames = {'Prism', 'Sunset', 'Mint', 'Midnight'};

  /// Themes saved before `monochrome` existed were colored: a missing key
  /// means "off", not the new default.
  static Map<String, dynamic> upgradeJson(Map<String, dynamic> json) =>
      json.containsKey('monochrome') ? json : {...json, 'monochrome': false};

  /// Pretty JSON used for export, wrapped with format/version info.
  String toShareableJson() => const JsonEncoder.withIndent('  ').convert({
        'format': fileFormat,
        'version': fileVersion,
        'theme': toJson(),
      });

  /// Parses an exported theme. Accepts both the wrapped format and a bare
  /// theme object. Values are clamped so a hand-edited file can't break the UI.
  /// Throws [FormatException] for anything that isn't a theme.
  static ThemeConfig fromShareableJson(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw FormatException(l10n.notAValidJsonFile);
    }
    if (decoded is! Map<String, dynamic>) {
      throw FormatException(l10n.themeFileMustContainAJson);
    }
    final Map<String, dynamic> body;
    if (decoded.containsKey('format')) {
      if (decoded['format'] != fileFormat) {
        throw FormatException(l10n.unknownFileFormat(decoded['format']));
      }
      final v = decoded['version'];
      if (v is int && v > fileVersion) {
        throw FormatException(l10n.themeWasMadeWithANewer(v));
      }
      final t = decoded['theme'];
      if (t is! Map<String, dynamic>) throw FormatException(l10n.missingThemeObject);
      body = t;
    } else {
      body = decoded;
    }
    try {
      return ThemeConfig.fromJson(upgradeJson(body)).sanitized();
    } catch (e) {
      throw FormatException(l10n.invalidThemeValues(e));
    }
  }

  /// Returns a copy with every numeric value inside its allowed range.
  ThemeConfig sanitized() => copyWith(
        cornerRadius: cornerRadius.clamp(0.0, 40.0),
        glassIntensity: glassIntensity.clamp(0.0, 1.0),
        animationSpeed: animationSpeed.clamp(0.25, 3.0),
        primaryColor: primaryColor | 0xFF000000,
        accentColor: accentColor | 0xFF000000,
      );
}

/// A few built-in themes shown in the theme editor.
const builtInThemes = <ThemeConfig>[
  ThemeConfig(),
  ThemeConfig(name: 'Paper', brightness: ThemeBrightnessMode.light, cornerRadius: 14, glassIntensity: 0.3),
  ThemeConfig(name: 'Prism', monochrome: false, brightness: ThemeBrightnessMode.dark, cornerRadius: 18, glassIntensity: 0.6),
  ThemeConfig(
    name: 'Sunset',
    monochrome: false,
    primaryColor: 0xFFFF6E40,
    accentColor: 0xFFFFD740,
    brightness: ThemeBrightnessMode.dark,
    cornerRadius: 24,
    glassIntensity: 0.6,
  ),
  ThemeConfig(
    name: 'Mint',
    monochrome: false,
    primaryColor: 0xFF00BFA5,
    accentColor: 0xFF69F0AE,
    brightness: ThemeBrightnessMode.light,
    cornerRadius: 14,
    glassIntensity: 0.3,
  ),
  ThemeConfig(
    name: 'Midnight',
    monochrome: false,
    primaryColor: 0xFF448AFF,
    accentColor: 0xFFE040FB,
    brightness: ThemeBrightnessMode.amoled,
    cornerRadius: 10,
    glassIntensity: 0.8,
  ),
];

/// Fonts offered in the editor (`null` = system font).
const availableFonts = <String?>[null, 'Inter', 'Poppins', 'Manrope', 'Nunito', 'Space Grotesk', 'JetBrains Mono'];

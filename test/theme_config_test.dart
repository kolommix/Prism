import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/theme/theme_config.dart';
import 'package:flutter/material.dart';
import 'package:prism/core/theme/prism_theme_extensions.dart';
import 'package:prism/core/theme/theme_builder.dart';
import 'package:prism/features/settings/data/settings_store.dart';
import 'package:prism/features/settings/domain/app_settings.dart';

void main() {
  test('export → import round trip keeps every value', () {
    const theme = ThemeConfig(
      name: 'Friends',
      primaryColor: 0xFF123456,
      accentColor: 0xFFABCDEF,
      brightness: ThemeBrightnessMode.amoled,
      cornerRadius: 7,
      fontFamily: 'Inter',
      glassIntensity: 0.25,
      animationSpeed: 1.5,
      dynamicColor: false,
    );
    expect(ThemeConfig.fromShareableJson(theme.toShareableJson()), theme);
  });

  test('accepts a bare theme object and fills defaults', () {
    final t = ThemeConfig.fromShareableJson('{"name": "Bare", "cornerRadius": 4}');
    expect(t.name, 'Bare');
    expect(t.cornerRadius, 4);
    expect(t.brightness, const ThemeConfig().brightness);
  });

  test('clamps out-of-range values from hand-edited files', () {
    final t = ThemeConfig.fromShareableJson(jsonEncode({
      'format': 'prism-theme',
      'version': 1,
      'theme': {'cornerRadius': 500, 'glassIntensity': -3, 'animationSpeed': 99, 'primaryColor': 0x00112233},
    }));
    expect(t.cornerRadius, 40);
    expect(t.glassIntensity, 0);
    expect(t.animationSpeed, 3);
    expect(t.primaryColor, 0xFF112233, reason: 'alpha forced to opaque');
  });

  test('rejects garbage with a FormatException', () {
    expect(() => ThemeConfig.fromShareableJson('not json'), throwsFormatException);
    expect(() => ThemeConfig.fromShareableJson('[1,2]'), throwsFormatException);
    expect(() => ThemeConfig.fromShareableJson('{"format":"other"}'), throwsFormatException);
    expect(() => ThemeConfig.fromShareableJson('{"format":"prism-theme","version":99,"theme":{}}'), throwsFormatException);
    expect(() => ThemeConfig.fromShareableJson('{"brightness":"neon"}'), throwsFormatException);
  });

  test('settings with nested theme serialise to plain JSON', () {
    const s = AppSettings(theme: ThemeConfig(name: 'X'), crossfadeSeconds: 4, reduceMotion: true);
    final decoded = AppSettings.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
    expect(decoded, s);
    expect(decoded.crossfade, const Duration(seconds: 4));
  });

  group('black & white', () {
    test('is the default theme', () {
      const t = ThemeConfig();
      expect(t.monochrome, isTrue);
      expect(t.brightness, ThemeBrightnessMode.amoled);
      expect(builtInThemes.first, t);
    });

    test('old theme files without the key stay colored', () {
      final t = ThemeConfig.fromShareableJson('{"name": "Old", "primaryColor": 4282682111}');
      expect(t.monochrome, isFalse);
      expect(ThemeConfig.fromShareableJson(const ThemeConfig().toShareableJson()).monochrome, isTrue);
    });

    test('settings upgrade: built-in color preset → new default, own theme kept', () {
      final preset = SettingsStore.upgradeTheme({'name': 'Midnight', 'fontFamily': 'JetBrains Mono', 'cornerRadius': 10.0});
      final upgraded = ThemeConfig.fromJson(preset);
      expect(upgraded.monochrome, isTrue);
      expect(upgraded.name, 'Mono');
      expect(upgraded.fontFamily, 'JetBrains Mono', reason: 'the font choice survives');

      final own = ThemeConfig.fromJson(SettingsStore.upgradeTheme({'name': 'Mine', 'primaryColor': 0xFF112233}));
      expect(own.monochrome, isFalse);
      expect(own.primaryColor, 0xFF112233);

      final current = {'name': 'Mint', 'monochrome': false};
      expect(SettingsStore.upgradeTheme(current), same(current), reason: 'already upgraded');
    });

    test('scheme is grey only: white on black, black on white', () {
      final dark = buildPrismTheme(const ThemeConfig(), platformBrightness: Brightness.dark, reduceMotion: false);
      expect(dark.colorScheme.primary, const Color(0xFFFFFFFF));
      expect(dark.colorScheme.surface, const Color(0xFF000000));
      expect(dark.extension<PrismLook>()!.monochrome, isTrue);
      final light = buildPrismTheme(
        const ThemeConfig(brightness: ThemeBrightnessMode.light),
        platformBrightness: Brightness.dark,
        reduceMotion: false,
      );
      expect(light.colorScheme.primary, const Color(0xFF000000));
      for (final c in [dark.colorScheme.primary, dark.colorScheme.secondary, dark.colorScheme.tertiary,
        dark.colorScheme.surfaceContainerHigh, light.colorScheme.secondaryContainer]) {
        expect(c.r, closeTo(c.g, 0.001));
        expect(c.g, closeTo(c.b, 0.001));
      }
      // The album color is ignored in black & white.
      final seeded = buildPrismTheme(const ThemeConfig(),
          platformBrightness: Brightness.dark, reduceMotion: false, dynamicSeed: const Color(0xFFFF0000));
      expect(seeded.colorScheme.primary, dark.colorScheme.primary);
    });
  });
}

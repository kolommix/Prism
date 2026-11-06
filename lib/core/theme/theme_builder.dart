import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../motion/page_transitions.dart';
import 'prism_theme_extensions.dart';
import 'theme_config.dart';

/// Builds the complete [ThemeData] from a [ThemeConfig].
///
/// [dynamicSeed] is the color extracted from the current album art; it
/// replaces the user's primary color when `config.dynamicColor` is on
/// (ignored in black & white mode).
ThemeData buildPrismTheme(
  ThemeConfig config, {
  required Brightness platformBrightness,
  required bool reduceMotion,
  Color? dynamicSeed,
  double? panelOpacity,
  bool frostedPanels = false,
}) {
  final mode = config.brightness;
  final brightness = switch (mode) {
    ThemeBrightnessMode.system => platformBrightness,
    ThemeBrightnessMode.light => Brightness.light,
    ThemeBrightnessMode.dark || ThemeBrightnessMode.amoled => Brightness.dark,
  };
  final amoled = mode == ThemeBrightnessMode.amoled;
  final mono = config.monochrome;

  ColorScheme scheme;
  if (mono) {
    scheme = monochromeScheme(brightness, amoled: amoled);
  } else {
    final seed = (config.dynamicColor && dynamicSeed != null) ? dynamicSeed : Color(config.primaryColor);
    scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );
    // The accent color drives the tertiary role (highlights, active waveform).
    scheme = scheme.copyWith(
      tertiary: Color(config.accentColor),
      onTertiary: ThemeData.estimateBrightnessForColor(Color(config.accentColor)) == Brightness.dark
          ? Colors.white
          : Colors.black,
    );
    if (amoled) {
      scheme = scheme.copyWith(
        surface: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: const Color(0xFF050505),
        surfaceContainer: const Color(0xFF0B0B0B),
        surfaceContainerHigh: const Color(0xFF121212),
        surfaceContainerHighest: const Color(0xFF1A1A1A),
      );
    }
  }

  final radius = config.cornerRadius;
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
  final speed = config.animationSpeed;
  // Selected states are one surface step up, not a filled color: the chrome
  // stays quiet and the amber LED dot marks what is on.
  final selectedBg = scheme.surfaceContainerHighest;
  final selectedFg = scheme.onSurface;
  final led = mono
      ? (brightness == Brightness.dark ? PrismLook.ledAmber : PrismLook.ledAmberOnLight)
      : scheme.primary;

  var base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: scheme.surface,
    visualDensity: VisualDensity.standard,
    // Plain ripple (sparkle runs a noise shader per tap and reads as decoration).
    splashFactory: InkRipple.splashFactory,
    pageTransitionsTheme: PrismPageTransitions.theme(speed: speed, reduceMotion: reduceMotion),
    cardTheme: CardThemeData(shape: shape, clipBehavior: Clip.antiAlias, elevation: 0),
    dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius * 1.3))),
    bottomSheetTheme: BottomSheetThemeData(
      showDragHandle: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(radius * 1.5))),
    ),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: shape)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: shape)),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: shape)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: mono ? scheme.surfaceContainerHigh : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide.none),
      focusedBorder: mono
          ? OutlineInputBorder(
              borderRadius: BorderRadius.circular(radius),
              borderSide: BorderSide(color: scheme.onSurface.withValues(alpha: 0.6)),
            )
          : null,
    ),
    listTileTheme: ListTileThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius * 0.6))),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius * 0.8)),
    ),
    navigationBarTheme: mono
        ? NavigationBarThemeData(
            indicatorColor: selectedBg,
            iconTheme: WidgetStateProperty.resolveWith(
              (s) => IconThemeData(color: s.contains(WidgetState.selected) ? selectedFg : scheme.onSurfaceVariant),
            ),
          )
        : null,
    segmentedButtonTheme: mono
        ? SegmentedButtonThemeData(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? selectedBg : null),
              foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? selectedFg : null),
              side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
            ),
          )
        : null,
    chipTheme: mono
        ? ChipThemeData(
            selectedColor: selectedBg,
            checkmarkColor: selectedFg,
            secondaryLabelStyle: TextStyle(color: selectedFg),
            side: BorderSide(color: scheme.outlineVariant),
          )
        : null,
    tabBarTheme: mono
        ? TabBarThemeData(
            indicatorColor: scheme.onSurface,
            labelColor: scheme.onSurface,
            unselectedLabelColor: scheme.onSurfaceVariant,
            dividerColor: Colors.transparent,
          )
        : null,
    extensions: [
      PrismMotion(speed: speed, reduceMotion: reduceMotion),
      PrismGlass(intensity: config.glassIntensity, tint: scheme.surface, panelOverride: panelOpacity, frosted: frostedPanels),
      PrismShape(radius: radius),
      PrismLook(monochrome: mono, led: led),
    ],
  );

  final font = config.fontFamily;
  if (font != null) {
    try {
      base = base.copyWith(textTheme: GoogleFonts.getTextTheme(font, base.textTheme));
    } on ArgumentError {
      // Unknown font name in an imported theme: keep the default.
    }
  }
  // Hierarchy from size and color, not weight: headings 600 at most, only
  // the large ones slightly tightened.
  final t = base.textTheme;
  TextStyle? head(TextStyle? s, double spacing) => s?.copyWith(fontWeight: FontWeight.w600, letterSpacing: spacing);
  return base.copyWith(
    textTheme: t.copyWith(
      displaySmall: head(t.displaySmall, -0.8),
      headlineLarge: head(t.headlineLarge, -0.6),
      headlineMedium: head(t.headlineMedium, -0.5),
      headlineSmall: head(t.headlineSmall, -0.3),
      titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      labelSmall: t.labelSmall?.copyWith(letterSpacing: 0.1),
    ),
  );
}

/// Greys only. Dark: white accents on black; light: black on white.
ColorScheme monochromeScheme(Brightness brightness, {bool amoled = false}) {
  if (brightness == Brightness.light) {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF000000),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFF1A1A1A),
      onPrimaryContainer: Color(0xFFFFFFFF),
      secondary: Color(0xFF3A3A3A),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFE2E2E2),
      onSecondaryContainer: Color(0xFF000000),
      tertiary: Color(0xFF000000),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFD4D4D4),
      onTertiaryContainer: Color(0xFF000000),
      error: Color(0xFFC62828),
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: Color(0xFFFAFAFA),
      onSurface: Color(0xFF171717),
      onSurfaceVariant: Color(0xFF525252),
      surfaceDim: Color(0xFFE6E6E6),
      surfaceBright: Color(0xFFFFFFFF),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF4F4F4),
      surfaceContainer: Color(0xFFEEEEEE),
      surfaceContainerHigh: Color(0xFFE8E8E8),
      surfaceContainerHighest: Color(0xFFE0E0E0),
      outline: Color(0xFF8A8A8A),
      outlineVariant: Color(0xFFD2D2D2),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF141414),
      onInverseSurface: Color(0xFFF2F2F2),
      inversePrimary: Color(0xFFFFFFFF),
      surfaceTint: Colors.transparent,
    );
  }
  return ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFFFFFFFF),
    onPrimary: const Color(0xFF000000),
    primaryContainer: const Color(0xFFEDEDED),
    onPrimaryContainer: const Color(0xFF000000),
    secondary: const Color(0xFFD0D0D0),
    onSecondary: const Color(0xFF000000),
    secondaryContainer: const Color(0xFF2A2A2A),
    onSecondaryContainer: const Color(0xFFFFFFFF),
    tertiary: const Color(0xFFFFFFFF),
    onTertiary: const Color(0xFF000000),
    tertiaryContainer: const Color(0xFF3A3A3A),
    onTertiaryContainer: const Color(0xFFFFFFFF),
    error: const Color(0xFFFF6B6B),
    onError: const Color(0xFF000000),
    errorContainer: const Color(0xFF3B1A1A),
    onErrorContainer: const Color(0xFFFFB4AB),
    surface: amoled ? const Color(0xFF000000) : const Color(0xFF0E0E0E),
    onSurface: const Color(0xFFEDEDED),
    onSurfaceVariant: const Color(0xFFA1A1A6),
    surfaceDim: amoled ? const Color(0xFF000000) : const Color(0xFF0E0E0E),
    surfaceBright: const Color(0xFF2C2C2C),
    surfaceContainerLowest: amoled ? const Color(0xFF000000) : const Color(0xFF090909),
    surfaceContainerLow: amoled ? const Color(0xFF0A0A0A) : const Color(0xFF131313),
    surfaceContainer: amoled ? const Color(0xFF111111) : const Color(0xFF181818),
    surfaceContainerHigh: amoled ? const Color(0xFF191919) : const Color(0xFF202020),
    surfaceContainerHighest: amoled ? const Color(0xFF222222) : const Color(0xFF292929),
    outline: const Color(0xFF6B6B6B),
    outlineVariant: const Color(0xFF26262A),
    shadow: const Color(0xFF000000),
    scrim: const Color(0xFF000000),
    inverseSurface: const Color(0xFFF5F5F5),
    onInverseSurface: const Color(0xFF111111),
    inversePrimary: const Color(0xFF000000),
    surfaceTint: Colors.transparent,
  );
}

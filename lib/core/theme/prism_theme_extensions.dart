import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Animation settings available to every widget via `context.motion`.
///
/// Widgets should never hard-code durations; they call [d] so the user's
/// animation-speed slider and "reduce motion" switch apply everywhere.
@immutable
class PrismMotion extends ThemeExtension<PrismMotion> {
  const PrismMotion({required this.speed, required this.reduceMotion});

  /// Duration multiplier (0.5 = twice as fast).
  final double speed;

  /// When true, [d] returns [Duration.zero] and decorative loops stop.
  final bool reduceMotion;

  // Standard durations used across the app.
  static const short = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 300);
  static const long = Duration(milliseconds: 500);
  static const page = Duration(milliseconds: 380);

  /// The one easing curve: fast start, long soft landing, no overshoot.
  static const curve = Cubic(0.22, 1, 0.36, 1);

  /// Scales [base] by the user's speed, or zero when motion is reduced.
  Duration d(Duration base) =>
      reduceMotion ? Duration.zero : Duration(microseconds: (base.inMicroseconds * speed).round());

  /// Whether purely decorative, continuous animations should run.
  bool get decorative => !reduceMotion;

  @override
  PrismMotion copyWith({double? speed, bool? reduceMotion}) =>
      PrismMotion(speed: speed ?? this.speed, reduceMotion: reduceMotion ?? this.reduceMotion);

  @override
  PrismMotion lerp(PrismMotion? other, double t) => other == null
      ? this
      : PrismMotion(speed: lerpDouble(speed, other.speed, t)!, reduceMotion: t < 0.5 ? reduceMotion : other.reduceMotion);
}

/// Frosted-glass look for panels, the mini-player and the nav bar.
@immutable
class PrismGlass extends ThemeExtension<PrismGlass> {
  const PrismGlass({required this.intensity, required this.tint, this.panelOverride, this.frosted = false});

  /// 0..1 from the theme config.
  final double intensity;

  /// Base color the glass is tinted with (surface color).
  final Color tint;

  /// Panel opacity while an animated background runs, so it shows through.
  final double? panelOverride;

  /// An animated background runs: panels blur it, so it reads as behind glass.
  final bool frosted;

  double get blurSigma => 30 * intensity;

  /// Glass is more opaque when blur is low so text stays readable.
  double get opacity => 0.92 - 0.45 * intensity;

  bool get enabled => intensity > 0.02;

  @override
  PrismGlass copyWith({double? intensity, Color? tint}) =>
      PrismGlass(intensity: intensity ?? this.intensity, tint: tint ?? this.tint, panelOverride: panelOverride, frosted: frosted);

  @override
  PrismGlass lerp(PrismGlass? other, double t) => other == null
      ? this
      : PrismGlass(
          intensity: lerpDouble(intensity, other.intensity, t)!,
          tint: Color.lerp(tint, other.tint, t)!,
          panelOverride: t < 0.5 ? panelOverride : other.panelOverride,
          frosted: t < 0.5 ? frosted : other.frosted,
        );
}

/// Corner radius scale derived from one user value.
@immutable
class PrismShape extends ThemeExtension<PrismShape> {
  const PrismShape({required this.radius});

  final double radius;

  BorderRadius get small => BorderRadius.circular(radius * 0.5);
  BorderRadius get medium => BorderRadius.circular(radius);
  BorderRadius get large => BorderRadius.circular(radius * 1.5);

  @override
  PrismShape copyWith({double? radius}) => PrismShape(radius: radius ?? this.radius);

  @override
  PrismShape lerp(PrismShape? other, double t) =>
      other == null ? this : PrismShape(radius: lerpDouble(radius, other.radius, t)!);
}

/// Short accessors: `context.motion.d(PrismMotion.medium)`.
extension PrismThemeContext on BuildContext {
  PrismMotion get motion =>
      Theme.of(this).extension<PrismMotion>() ?? const PrismMotion(speed: 1, reduceMotion: false);
  PrismGlass get glass =>
      Theme.of(this).extension<PrismGlass>() ?? PrismGlass(intensity: 0.5, tint: Theme.of(this).colorScheme.surface);
  PrismShape get shape => Theme.of(this).extension<PrismShape>() ?? const PrismShape(radius: 16);
}

/// Overall style switches that widgets adapt to.
@immutable
class PrismLook extends ThemeExtension<PrismLook> {
  const PrismLook({required this.monochrome, this.led = ledAmber});

  /// The signature "power LED" color: the one accent, used only for small
  /// dots and marks on things that are live (playing, selected, switched on).
  final Color led;

  static const ledAmber = Color(0xFFF2A43A);
  static const ledAmberOnLight = Color(0xFFB56A00);

  /// Black & white UI: backgrounds use the (grey) cover instead of color
  /// gradients, accents are white on black (or black on white).
  final bool monochrome;

  @override
  PrismLook copyWith({bool? monochrome, Color? led}) =>
      PrismLook(monochrome: monochrome ?? this.monochrome, led: led ?? this.led);

  @override
  PrismLook lerp(PrismLook? other, double t) => other == null
      ? this
      : PrismLook(monochrome: t < 0.5 ? monochrome : other.monochrome, led: Color.lerp(led, other.led, t)!);
}

extension PrismLookContext on BuildContext {
  PrismLook get look => Theme.of(this).extension<PrismLook>() ?? const PrismLook(monochrome: false);
}

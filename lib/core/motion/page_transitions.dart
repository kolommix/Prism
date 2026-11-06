import 'package:flutter/material.dart';

import '../theme/prism_theme_extensions.dart';

/// Page transitions used by every route (and go_router pages).
///
/// A subtle "fade through + rise": the new page fades in while sliding up a
/// few pixels and scaling from 98 %, the old page fades out. With reduce
/// motion on, pages simply cross-fade instantly.
class PrismPageTransitions extends PageTransitionsBuilder {
  const PrismPageTransitions({required this.speed, required this.reduceMotion});

  final double speed;
  final bool reduceMotion;

  static PageTransitionsTheme theme({required double speed, required bool reduceMotion}) {
    final b = PrismPageTransitions(speed: speed, reduceMotion: reduceMotion);
    return PageTransitionsTheme(builders: {for (final p in TargetPlatform.values) p: b});
  }

  @override
  Duration get transitionDuration => reduceMotion
      ? Duration.zero
      : Duration(microseconds: (PrismMotion.page.inMicroseconds * speed).round());

  @override
  Duration get reverseTransitionDuration => transitionDuration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) =>
      buildFadeRise(animation, secondaryAnimation, child);

  /// Shared by go_router `CustomTransitionPage`s.
  static Widget buildFadeRise(Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final inCurve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final outCurve = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInOut);
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: outCurve, curve: const Interval(0, 0.6))),
      child: FadeTransition(
        opacity: inCurve,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(inCurve),
          child: ScaleTransition(scale: Tween(begin: 0.98, end: 1.0).animate(inCurve), child: child),
        ),
      ),
    );
  }

  /// Slide-up used for the full-screen player.
  static Widget buildSheetUp(Animation<double> animation, Widget child) {
    final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutQuart, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: const Interval(0, 0.5)),
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.12), end: Offset.zero).animate(curve),
        child: child,
      ),
    );
  }
}

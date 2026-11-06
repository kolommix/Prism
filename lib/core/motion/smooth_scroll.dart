import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/prism_theme_extensions.dart';

/// Scroll controller whose **mouse-wheel** scrolling glides instead of
/// jumping. Flutter applies each wheel notch instantly, which feels steppy on
/// Windows; here every notch moves a target the list glides after, like
/// browsers and native Windows lists.
///
/// Touch, touchpad and scrollbar dragging are untouched.
class SmoothScrollController extends ScrollController {
  SmoothScrollController({this.smooth = true});

  /// False (reduce motion) = classic instant wheel steps.
  bool smooth;

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition? oldPosition) =>
      _SmoothWheelPosition(
        physics: physics,
        context: context,
        oldPosition: oldPosition,
        initialPixels: initialScrollOffset,
        keepScrollOffset: keepScrollOffset,
        debugLabel: debugLabel,
        controller: this,
      );
}

class _SmoothWheelPosition extends ScrollPositionWithSingleContext {
  _SmoothWheelPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    super.initialPixels,
    super.keepScrollOffset,
    super.debugLabel,
    required this.controller,
  });

  final SmoothScrollController controller;

  @override
  void pointerScroll(double delta) {
    if (!controller.smooth || delta == 0) return super.pointerScroll(delta);
    final current = activity;
    if (current is _WheelGlide) {
      // Quick notches add up without restarting anything: the speed carries on.
      current.target = (current.target + delta).clamp(minScrollExtent, maxScrollExtent);
      return;
    }
    final target = (pixels + delta).clamp(minScrollExtent, maxScrollExtent);
    if (target == pixels) return;
    beginActivity(_WheelGlide(this, context.vsync, target));
  }
}

/// Follows the wheel's target like a damped spring, frame by frame. Restarting
/// a timed animation per notch made the list stop and go while spinning the
/// wheel; this keeps one continuous movement at any frame rate.
class _WheelGlide extends ScrollActivity {
  _WheelGlide(_SmoothWheelPosition super.delegate, TickerProvider vsync, this.target) {
    _ticker = vsync.createTicker(_tick)..start();
  }

  double target;
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _velocity = 0;

  /// How fast the gap closes, per second: about 250 ms to settle.
  static const _rate = 16.0;

  _SmoothWheelPosition get _position => delegate as _SmoothWheelPosition;

  void _tick(Duration now) {
    final dt = math.min(0.05, (now - _last).inMicroseconds / 1e6);
    _last = now;
    final p = _position;
    final goal = target.clamp(p.minScrollExtent, p.maxScrollExtent);
    final before = p.pixels;
    final next = before + (goal - before) * (1 - math.exp(-_rate * dt));
    if ((goal - next).abs() < 0.4) {
      p.setPixels(goal);
      p.goIdle();
      return;
    }
    if (p.setPixels(next) != 0) {
      p.goIdle(); // hit the end of the list
      return;
    }
    if (dt > 0) _velocity = (next - before) / dt;
  }

  @override
  bool get isScrolling => true;

  @override
  bool get shouldIgnorePointer => false;

  @override
  double get velocity => _velocity;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}

/// Builds a scroll view with a [SmoothScrollController] it owns.
///
/// ```dart
/// SmoothScroll(builder: (c) => ListView(controller: c, children: ...))
/// ```
class SmoothScroll extends StatefulWidget {
  const SmoothScroll({super.key, required this.builder});

  final Widget Function(ScrollController controller) builder;

  @override
  State<SmoothScroll> createState() => _SmoothScrollState();
}

class _SmoothScrollState extends State<SmoothScroll> {
  final _controller = SmoothScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.smooth = context.motion.decorative;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}

/// `CustomScrollView` with smooth mouse-wheel scrolling.
class SmoothCustomScrollView extends StatelessWidget {
  const SmoothCustomScrollView({super.key, required this.slivers});

  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) =>
      SmoothScroll(builder: (c) => CustomScrollView(controller: c, slivers: slivers));
}

/// `ListView` with smooth mouse-wheel scrolling.
class SmoothListView extends StatelessWidget {
  const SmoothListView({super.key, this.padding, required this.children});

  final EdgeInsetsGeometry? padding;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      SmoothScroll(builder: (c) => ListView(controller: c, padding: padding, children: children));
}

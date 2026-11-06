import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../theme/prism_theme_extensions.dart';

/// Wraps any child with a springy "squish" on press.
///
/// Pressing compresses the child to [pressedScale]; releasing lets a
/// critically damped spring settle it back (no overshoot, no wobble: it feels
/// like a physical key, not a toy). Disabled automatically with reduce motion.
class SpringButton extends StatefulWidget {
  const SpringButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.tooltip,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final String? tooltip;

  @override
  State<SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<SpringButton> with SingleTickerProviderStateMixin {
  // Unbounded so the spring may overshoot past 1.0.
  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: 1);

  // damping = 2 * sqrt(stiffness * mass): critically damped.
  static const _spring = SpringDescription(mass: 1, stiffness: 520, damping: 46);

  void _down() {
    if (!context.motion.decorative) return;
    _c.animateTo(widget.pressedScale, duration: const Duration(milliseconds: 90), curve: Curves.easeOut);
  }

  void _up() {
    if (!context.motion.decorative) {
      _c.value = 1;
      return;
    }
    _c.animateWith(SpringSimulation(_spring, _c.value, 1, _c.velocity));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final handlesTap = widget.onTap != null || widget.onLongPress != null;
    Widget result = AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.scale(scale: _c.value, child: child),
      child: widget.child,
    );
    if (handlesTap) {
      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: result,
      );
    }
    // A Listener sees raw pointer events without joining the gesture arena,
    // so the squish also works around children that handle taps themselves
    // (e.g. wrapping a FilledButton with no onTap here).
    result = Listener(
      onPointerDown: (_) => _down(),
      onPointerUp: (_) => _up(),
      onPointerCancel: (_) => _up(),
      child: result,
    );
    if (widget.tooltip != null) result = Tooltip(message: widget.tooltip, child: result);
    return MouseRegion(cursor: handlesTap ? SystemMouseCursors.click : MouseCursor.defer, child: result);
  }
}

/// Round icon button with spring feedback, used for transport controls.
class SpringIconButton extends StatelessWidget {
  const SpringIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 24,
    this.filled = false,
    this.color,
    this.tooltip,
    this.padding = 10,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final double size;
  final bool filled;
  final Color? color;
  final String? tooltip;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? (filled ? scheme.onPrimary : scheme.onSurface);
    return SpringButton(
      onTap: onPressed,
      tooltip: tooltip,
      child: AnimatedContainer(
        duration: context.motion.d(PrismMotion.medium),
        curve: PrismMotion.curve,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(shape: BoxShape.circle, color: filled ? scheme.primary : Colors.transparent),
        child: IconTheme(
          data: IconThemeData(size: size, color: onPressed == null ? fg.withValues(alpha: 0.38) : fg),
          child: icon,
        ),
      ),
    );
  }
}

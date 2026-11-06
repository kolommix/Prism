import 'package:flutter/material.dart';

import '../theme/prism_theme_extensions.dart';

/// Prism's signature: a small indicator light, like the power LED on a hi-fi
/// amplifier. It marks what is live – the selected page, a tool that is
/// switched on – and is the only place the accent color appears in the
/// chrome. Turning on/off fades and scales, nothing pulses.
class LedDot extends StatelessWidget {
  const LedDot({super.key, this.on = true, this.size = 6});

  final bool on;
  final double size;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    return AnimatedOpacity(
      opacity: on ? 1 : 0,
      duration: motion.d(PrismMotion.short),
      child: AnimatedScale(
        scale: on ? 1 : 0.4,
        duration: motion.d(PrismMotion.medium),
        curve: PrismMotion.curve,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: context.look.led, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

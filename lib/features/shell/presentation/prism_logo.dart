import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/prism_theme_extensions.dart';
import '../../background/application/background_input.dart';
import '../../background/domain/background_config.dart';
import '../../settings/application/settings_controller.dart';
import '../../../l10n/l10n.dart';

/// The Prism logo: the dotted mark in the theme's two colors.
///
/// It reacts: the mark tilts towards the mouse and the color follows it, a
/// click spins it and sends rings out (and a shockwave through an animated
/// background), right-click switches to the next background.
class PrismLogo extends ConsumerStatefulWidget {
  const PrismLogo({super.key, this.size = 34, this.showName = true, this.nameStyle});

  final double size;
  final bool showName;
  final TextStyle? nameStyle;

  @override
  ConsumerState<PrismLogo> createState() => _PrismLogoState();
}

class _PrismLogoState extends ConsumerState<PrismLogo> with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this);
  late final AnimationController _hover = AnimationController(vsync: this);
  final _markKey = GlobalKey();

  /// Mouse relative to the mark's centre, -1..1 on both axes.
  Offset _aim = Offset.zero;

  void _onHover(Offset global) {
    final box = _markKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final local = box.globalToLocal(global) - box.size.center(Offset.zero);
    final next = Offset(
      (local.dx / (box.size.width)).clamp(-1.0, 1.0),
      (local.dy / (box.size.height)).clamp(-1.0, 1.0),
    );
    if (next != _aim) setState(() => _aim = next);
  }

  void _click() {
    _spin.duration = context.motion.d(const Duration(milliseconds: 1100));
    unawaited(_spin.forward(from: 0));
    final box = _markKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      ref.read(backgroundInputProvider).burst(box.localToGlobal(box.size.center(Offset.zero)), strength: 1.8);
    }
  }

  void _nextBackground() {
    ref.read(settingsProvider.notifier).update((s) {
      // Your own picture or video only once there is one.
      final all = [
        for (final b in BackgroundStyle.values)
          if ((b != BackgroundStyle.image || s.background.imagePath.isNotEmpty) && (b != BackgroundStyle.video || s.background.videoDir.isNotEmpty)) b,
      ];
      final next = all[(all.indexOf(s.background.current) + 1) % all.length];
      return s.copyWith(background: s.background.copyWith(style: next.name));
    });
    _click();
  }

  @override
  void dispose() {
    _spin.dispose();
    _hover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final motion = context.motion;
    final mark = AnimatedBuilder(
      animation: Listenable.merge([_spin, _hover]),
      builder: (context, _) {
        final spin = PrismMotion.curve.transform(_spin.value);
        final h = Curves.easeOutCubic.transform(_hover.value);
        final pop = math.sin(_spin.value * math.pi);
        // The gradient turns towards the mouse and sweeps round on a click.
        final angle = math.atan2(_aim.dy, _aim.dx) * h + spin * math.pi * 2;
        final begin = Alignment(math.cos(angle + math.pi), math.sin(angle + math.pi));
        final end = Alignment(math.cos(angle), math.sin(angle));
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (_spin.value > 0 && _spin.value < 1)
              IgnorePointer(
                child: CustomPaint(
                  size: Size.square(widget.size),
                  painter: _RingsPainter(t: _spin.value, color: scheme.primary, accent: scheme.tertiary),
                ),
              ),
            Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.004)
                ..rotateX(-_aim.dy * 0.7 * h)
                ..rotateY(_aim.dx * 0.7 * h)
                ..rotateZ(spin * math.pi * 2)
                ..scaleByDouble(1 + 0.12 * h + 0.22 * pop, 1 + 0.12 * h + 0.22 * pop, 1, 1),
              child: ShaderMask(
                shaderCallback: (r) => LinearGradient(
                  begin: begin,
                  end: end,
                  colors: [scheme.primary, scheme.tertiary],
                ).createShader(r),
                child: Icon(Icons.blur_on_rounded, key: _markKey, size: widget.size, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        _hover.duration = motion.d(PrismMotion.short);
        unawaited(_hover.forward());
      },
      onHover: (e) => _onHover(e.position),
      onExit: (_) {
        _hover.duration = motion.d(PrismMotion.long);
        unawaited(_hover.reverse());
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _click,
        onSecondaryTap: _nextBackground,
        onLongPress: _nextBackground,
        child: Tooltip(
          message: l10n.rightClickNextBackground,
          waitDuration: const Duration(seconds: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(dimension: widget.size, child: mark),
              if (widget.showName) ...[
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Prism',
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: widget.nameStyle ??
                        Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Two rings that open up and fade after a click.
class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.t, required this.color, required this.accent});

  final double t;
  final Color color, accent;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    void ring(double start, Color col) {
      final f = ((t - start) / (1 - start)).clamp(0.0, 1.0);
      if (f <= 0 || f >= 1) return;
      canvas.drawCircle(
        c,
        size.width * (0.5 + 1.1 * Curves.easeOutCubic.transform(f)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 * (1 - f)
          ..color = col.withValues(alpha: 0.8 * (1 - f)),
      );
    }

    ring(0, color);
    ring(0.2, accent);
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.t != t || old.color != color || old.accent != accent;
}

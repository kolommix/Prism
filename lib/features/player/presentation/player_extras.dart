import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/spring_button.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../library/application/library_providers.dart';
import '../application/player_providers.dart';
import 'sleep_timer_sheet.dart';
import '../../../l10n/l10n.dart';

/// Heart that pops when toggled.
class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    final fav = ref.watch(favoriteIdsProvider.select((s) => track != null && (s.value?.contains(track.id) ?? false)));
    final scheme = Theme.of(context).colorScheme;
    return SpringIconButton(
      tooltip: fav ? l10n.removeFromFavorites : l10n.addToFavorites,
      size: size,
      color: fav ? scheme.tertiary : scheme.onSurfaceVariant,
      onPressed: track == null ? null : () => ref.read(libraryRepositoryProvider).toggleFavorite(track.id),
      icon: AnimatedSwitcher(
        duration: context.motion.d(PrismMotion.medium),
        transitionBuilder: (child, a) => ScaleTransition(
          scale: CurvedAnimation(parent: a, curve: PrismMotion.curve, reverseCurve: Curves.easeIn),
          child: child,
        ),
        child: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, key: ValueKey(fav)),
      ),
    );
  }
}

/// Moon icon; highlighted while a sleep timer runs.
class SleepTimerButton extends ConsumerWidget {
  const SleepTimerButton({super.key, this.size = 24});

  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(sleepTimerStateProvider.select((s) => s.value?.isActive ?? false));
    final scheme = Theme.of(context).colorScheme;
    return SpringIconButton(
      tooltip: l10n.sleepTimer,
      size: size,
      color: active ? scheme.primary : scheme.onSurfaceVariant,
      onPressed: () => showSleepTimerSheet(context),
      icon: Icon(active ? Icons.bedtime_rounded : Icons.bedtime_outlined),
    );
  }
}

/// Player volume 0..1 for the UI. Kept here (not in a widget) so the slider
/// shows the real value after the player bar is rebuilt or re-created.
class PlayerVolume extends Notifier<double> {
  double _beforeMute = 1;

  @override
  double build() => ref.read(playerControllerProvider).volume;

  void set(double v) {
    state = v.clamp(0.0, 1.0);
    ref.read(playerControllerProvider).setVolume(state);
  }

  void toggleMute() {
    if (state == 0) {
      set(_beforeMute == 0 ? 1 : _beforeMute);
    } else {
      _beforeMute = state;
      set(0);
    }
  }
}

final playerVolumeProvider = NotifierProvider<PlayerVolume, double>(PlayerVolume.new);

/// Volume: the speaker button (mute / unmute) and a staircase of thin bars
/// that light up to the level, the last one partly. Click or drag to set,
/// mouse wheel and arrow keys nudge it. On hover it grows a little and shows
/// the percent. Mute slides the bars down instead of jumping.
class VolumeSlider extends ConsumerStatefulWidget {
  const VolumeSlider({super.key, this.showSlider = true});

  final bool showSlider;

  @override
  ConsumerState<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends ConsumerState<VolumeSlider> {
  bool _hover = false;
  bool _dragging = false;
  final _focus = FocusNode(debugLabel: 'volume');

  static const _width = 104.0;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _setFrom(Offset local) => ref.read(playerVolumeProvider.notifier).set(local.dx / _width);

  @override
  Widget build(BuildContext context) {
    final volume = ref.watch(playerVolumeProvider);
    final ctrl = ref.read(playerVolumeProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final motion = context.motion;
    final active = _hover || _dragging || _focus.hasFocus;
    final icon = volume == 0
        ? Icons.volume_off_rounded
        : (volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded);
    return Listener(
      onPointerSignal: (e) {
        if (e is PointerScrollEvent) ctrl.set(volume - e.scrollDelta.dy / 1500);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpringIconButton(
              tooltip: volume == 0 ? l10n.unmute : l10n.mute((volume * 100).round()),
              size: 22,
              color: active ? scheme.onSurface : scheme.onSurfaceVariant,
              icon: Icon(icon),
              onPressed: ctrl.toggleMute,
            ),
            if (widget.showSlider) ...[
              const SizedBox(width: 4),
              Semantics(
                slider: true,
                value: '${(volume * 100).round()}%',
                child: Focus(
                  focusNode: _focus,
                  onFocusChange: (_) => setState(() {}),
                  onKeyEvent: (_, e) {
                    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
                    final step = switch (e.logicalKey) {
                      LogicalKeyboardKey.arrowRight || LogicalKeyboardKey.arrowUp => 0.05,
                      LogicalKeyboardKey.arrowLeft || LogicalKeyboardKey.arrowDown => -0.05,
                      _ => 0.0,
                    };
                    if (step == 0) return KeyEventResult.ignored;
                    ctrl.set(volume + step);
                    return KeyEventResult.handled;
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) {
                      _focus.requestFocus();
                      _setFrom(d.localPosition);
                    },
                    onHorizontalDragStart: (d) {
                      setState(() => _dragging = true);
                      _setFrom(d.localPosition);
                    },
                    onHorizontalDragUpdate: (d) => _setFrom(d.localPosition),
                    onHorizontalDragEnd: (_) => setState(() => _dragging = false),
                    onHorizontalDragCancel: () => setState(() => _dragging = false),
                    child: SizedBox(
                      width: _width,
                      height: 32,
                      child: TweenAnimationBuilder<double>(
                        // Dragging follows the pointer exactly; everything else glides.
                        tween: Tween(end: volume),
                        duration: _dragging ? Duration.zero : motion.d(PrismMotion.medium),
                        curve: PrismMotion.curve,
                        builder: (context, v, _) => TweenAnimationBuilder<double>(
                          tween: Tween(end: active ? 1 : 0),
                          duration: motion.d(PrismMotion.short),
                          curve: PrismMotion.curve,
                          builder: (context, grow, _) => CustomPaint(
                            painter: VolumeBarsPainter(
                              value: v,
                              grow: grow,
                              on: scheme.onSurface,
                              off: scheme.onSurface.withValues(alpha: 0.16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedSize(
                duration: motion.d(PrismMotion.short),
                curve: PrismMotion.curve,
                child: active
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: SizedBox(
                          width: 32,
                          child: Text(
                            fmtNum((volume * 100).round()),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: scheme.onSurface,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Thin rounded bars, short to tall, lit up to [value] (the edge bar partly).
class VolumeBarsPainter extends CustomPainter {
  VolumeBarsPainter({required this.value, required this.grow, required this.on, required this.off});

  final double value;

  /// 0..1: hover / drag makes the bars a little taller.
  final double grow;
  final Color on;
  final Color off;

  static const bars = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final slot = size.width / bars;
    final w = math.max(2.0, slot * 0.5);
    final maxH = size.height * (0.62 + 0.24 * grow);
    final minH = size.height * 0.16;
    final bottom = size.height / 2 + maxH / 2;
    final lit = Paint()..color = on;
    final dim = Paint()..color = off;
    final r = Radius.circular(w / 2);
    for (var i = 0; i < bars; i++) {
      final t = (i + 1) / bars;
      final h = minH + (maxH - minH) * math.pow(t, 1.15);
      final x = i * slot + (slot - w) / 2;
      final bar = RRect.fromRectAndRadius(Rect.fromLTWH(x, bottom - h, w, h), r);
      // How much of this bar is below the level: 0, 1, or a part of the edge bar.
      final fill = ((value * bars) - i).clamp(0.0, 1.0);
      if (fill >= 1) {
        canvas.drawRRect(bar, lit);
        continue;
      }
      canvas.drawRRect(bar, dim);
      if (fill > 0) {
        canvas
          ..save()
          ..clipRect(Rect.fromLTWH(x, bottom - h * fill, w, h * fill))
          ..drawRRect(bar, lit)
          ..restore();
      }
    }
  }

  @override
  bool shouldRepaint(VolumeBarsPainter old) =>
      old.value != value || old.grow != grow || old.on != on || old.off != off;
}

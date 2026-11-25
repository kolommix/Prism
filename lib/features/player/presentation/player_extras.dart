import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/motion/spring_button.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/track.dart';
import '../../settings/application/settings_controller.dart';
import '../application/player_providers.dart';
import '../application/song_volumes.dart';
import '../domain/volume_style.dart';
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

  /// The user sets the volume (slider, wheel, keys, hotkeys). With "remember
  /// the volume of each song" on, the song that plays keeps it.
  void set(double v) {
    apply(v);
    final track = ref.read(currentTrackProvider);
    if (track != null && ref.read(settingsProvider).volumePerSong) {
      ref.read(songVolumesProvider).remember(track.id, state);
    }
  }

  /// Changes the volume without remembering it for the song (a song's own
  /// saved volume coming back).
  void apply(double v) {
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

/// Each song's own volume (only read when the setting is on).
final songVolumesProvider = Provider<SongVolumes>((ref) {
  final v = SongVolumes(prefs: SharedPreferencesAsync());
  ref.onDispose(v.dispose);
  return v;
});

/// With "remember the volume of each song" on: when a song with a saved
/// volume starts, the volume goes to it; other songs keep the volume as it
/// is. Kept alive by the app.
final songVolumeFollowerProvider = Provider<void>((ref) {
  var alive = true;
  ref.onDispose(() => alive = false);
  Future<void> follow(Track? t) async {
    if (t == null || !ref.read(settingsProvider).volumePerSong) return;
    final memory = ref.read(songVolumesProvider);
    await memory.load();
    if (!alive || ref.read(currentTrackProvider)?.id != t.id) return;
    final v = memory.of(t.id);
    if (v != null && v != ref.read(playerVolumeProvider)) ref.read(playerVolumeProvider.notifier).apply(v);
  }

  ref.listen<Track?>(currentTrackProvider, (prev, next) {
    if (prev?.id != next?.id) unawaited(follow(next));
  }, fireImmediately: true);
});

/// Volume: the speaker button (mute / unmute) and a level control in one of
/// three looks ([VolumeStyle]: a line with a knob, a thick pill, a staircase
/// of bars). Click or drag anywhere on it to set, the mouse wheel moves 5 %
/// a notch (with Shift 1 %), arrow keys 5 %. While hovered or dragged it grows
/// a little and shows the percent (in room kept for it, so nothing moves).
/// Right-click picks the look.
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

  static const _width = 120.0;

  /// Room at both ends so the knob can reach 0 and 100 inside the box.
  static double inset(VolumeStyle style) => style == VolumeStyle.bars ? 0 : 8;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _setFrom(Offset local, VolumeStyle style) {
    final pad = inset(style);
    ref.read(playerVolumeProvider.notifier).set((local.dx - pad) / (_width - pad * 2));
  }

  Future<void> _pickStyle(Offset global, VolumeStyle current) async {
    final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
    final picked = await showMenu<VolumeStyle>(
      context: context,
      position: RelativeRect.fromRect(global & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        for (final s in VolumeStyle.values)
          CheckedPopupMenuItem(value: s, checked: s == current, child: Text(s.label)),
      ],
    );
    if (picked != null) ref.read(settingsProvider.notifier).update((x) => x.copyWith(volumeStyle: picked.name));
  }

  @override
  Widget build(BuildContext context) {
    final volume = ref.watch(playerVolumeProvider);
    final ctrl = ref.read(playerVolumeProvider.notifier);
    final style = VolumeStyle.parse(ref.watch(settingsProvider.select((s) => s.volumeStyle)));
    final scheme = Theme.of(context).colorScheme;
    final motion = context.motion;
    final active = _hover || _dragging || _focus.hasFocus;
    final icon = volume == 0
        ? Icons.volume_off_rounded
        : (volume < 0.5 ? Icons.volume_down_rounded : Icons.volume_up_rounded);
    return Listener(
      onPointerSignal: (e) {
        if (e is! PointerScrollEvent) return;
        final notch = e.scrollDelta.dy != 0 ? e.scrollDelta.dy : e.scrollDelta.dx;
        if (notch == 0) return;
        final step = HardwareKeyboard.instance.isShiftPressed ? 0.01 : 0.05;
        final volume = ref.read(playerVolumeProvider); // fresh: several notches can come in one frame
        // One step a notch, rounded to the step: 37 % + a notch = 40 %.
        final next = notch < 0 ? ((volume + 1e-6) / step).floor() * step + step : ((volume - 1e-6) / step).ceil() * step - step;
        ctrl.set(next);
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
              const SizedBox(width: 2),
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
                    ctrl.set(ref.read(playerVolumeProvider) + step);
                    return KeyEventResult.handled;
                  },
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) {
                      _focus.requestFocus();
                      _setFrom(d.localPosition, style);
                    },
                    onSecondaryTapUp: (d) => _pickStyle(d.globalPosition, style),
                    onHorizontalDragStart: (d) {
                      setState(() => _dragging = true);
                      _setFrom(d.localPosition, style);
                    },
                    onHorizontalDragUpdate: (d) => _setFrom(d.localPosition, style),
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
                            painter: switch (style) {
                              VolumeStyle.bars => VolumeBarsPainter(
                                  value: v,
                                  grow: grow,
                                  on: scheme.onSurface,
                                  off: scheme.onSurface.withValues(alpha: 0.16),
                                ),
                              _ => VolumeLinePainter(
                                  value: v,
                                  grow: grow,
                                  pill: style == VolumeStyle.pill,
                                  inset: inset(style),
                                  on: scheme.onSurface,
                                  off: scheme.onSurface.withValues(alpha: 0.16),
                                  knob: scheme.onSurface,
                                ),
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // The percent fades in a spot that is always kept: the bar
              // never moves under the pointer (it used to slide aside).
              AnimatedOpacity(
                opacity: active ? 1 : 0,
                duration: motion.d(PrismMotion.short),
                child: Padding(
                  padding: const EdgeInsets.only(left: 6),
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
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A rounded track filled to [value]: a thin line with a round knob, or
/// ([pill]) a thick bar with no knob. [inset] keeps the ends inside the box.
class VolumeLinePainter extends CustomPainter {
  VolumeLinePainter({
    required this.value,
    required this.grow,
    required this.pill,
    required this.inset,
    required this.on,
    required this.off,
    required this.knob,
  });

  final double value;

  /// 0..1: hover / drag makes it a little thicker and the knob bigger.
  final double grow;
  final bool pill;
  final double inset;
  final Color on;
  final Color off;
  final Color knob;

  @override
  void paint(Canvas canvas, Size size) {
    final thick = pill ? 8 + 4 * grow : 3 + 1.5 * grow;
    final left = inset, right = size.width - inset;
    final y = size.height / 2;
    final track = RRect.fromLTRBR(left, y - thick / 2, right, y + thick / 2, Radius.circular(thick / 2));
    canvas.drawRRect(track, Paint()..color = off);
    final x = left + (right - left) * value.clamp(0.0, 1.0);
    if (value > 0) {
      canvas
        ..save()
        ..clipRRect(track)
        ..drawRect(Rect.fromLTRB(left, y - thick / 2, x, y + thick / 2), Paint()..color = on)
        ..restore();
    }
    if (!pill) {
      final r = 5 + 2 * grow;
      // A soft shadow under the knob so it reads on light themes too.
      canvas.drawCircle(Offset(x, y + 1), r, Paint()..color = Colors.black.withValues(alpha: 0.25));
      canvas.drawCircle(Offset(x, y), r, Paint()..color = knob);
    }
  }

  @override
  bool shouldRepaint(VolumeLinePainter old) =>
      old.value != value ||
      old.grow != grow ||
      old.pill != pill ||
      old.inset != inset ||
      old.on != on ||
      old.off != off ||
      old.knob != knob;
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

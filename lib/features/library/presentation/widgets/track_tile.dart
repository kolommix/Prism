import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/prism_theme_extensions.dart';
import '../../../../core/widgets/artwork.dart';
import '../../../player/application/player_providers.dart';
import '../../../player/presentation/widgets/waveform_seek_bar.dart';
import '../../domain/track.dart';
import 'track_actions.dart';
import '../../../../l10n/l10n.dart';

/// One song row used by every list (songs, album, playlist, search, queue).
class TrackTile extends ConsumerWidget {
  const TrackTile({
    super.key,
    required this.track,
    this.onTap,
    this.showArtwork = true,
    this.leadingNumber,
    this.trailing,
    this.playlistId,
    this.playlistEntryId,
    this.leading,
    this.longPressActions = true,
  });

  final Track track;
  final VoidCallback? onTap;
  final bool showArtwork;

  /// Show a track number instead of artwork (album pages).
  final int? leadingNumber;

  /// Replaces the default "more" menu (e.g. a drag handle in the queue).
  final Widget? trailing;

  /// When shown inside a playlist, enables "Remove from playlist".
  final int? playlistId;
  final int? playlistEntryId;

  /// Replaces the artwork (a checkbox while selecting).
  final Widget? leading;

  /// False where press-and-hold means something else (drag on a phone).
  final bool longPressActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = ref.watch(currentTrackProvider.select((t) => t?.id == track.id));
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final titleColor = scheme.onSurface;

    Widget leading;
    if (leadingNumber != null && !isCurrent) {
      leading = SizedBox(
        width: 32,
        child: Text('$leadingNumber', textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
      );
    } else if (showArtwork) {
      leading = Stack(
        alignment: Alignment.center,
        children: [
          Artwork(path: track.artworkPath, size: 46, seed: track.album),
          if (isCurrent)
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: context.shape.small),
              child: Center(child: NowPlayingBars(color: context.look.led)),
            ),
        ],
      );
    } else {
      leading = SizedBox(width: 32, child: Center(child: NowPlayingBars(color: context.look.led)));
    }

    return ListTile(
      onTap: onTap,
      onLongPress: longPressActions ? () => showTrackActions(context, ref, track, playlistId: playlistId, playlistEntryId: playlistEntryId) : null,
      leading: this.leading ?? leading,
      title: AnimatedDefaultTextStyle(
        duration: context.motion.d(PrismMotion.medium),
        style: (text.bodyLarge ?? const TextStyle()).copyWith(
          color: titleColor,
          fontWeight: FontWeight.w500,
        ),
        child: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      subtitle: Text(
        // Streamed songs: say where they come from instead of "Unknown album".
        track.sourceId != 'local' && track.album.isEmpty
            ? '${track.displayArtist} · ${_sourceLabel(track.sourceId)}'
            : '${track.displayArtist} · ${track.displayAlbum}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (track.durationMs > 0)
                Text(formatDuration(track.duration), style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              IconButton(
                tooltip: l10n.more,
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () =>
                    showTrackActions(context, ref, track, playlistId: playlistId, playlistEntryId: playlistEntryId),
              ),
            ],
          ),
    );
  }
}

String _sourceLabel(String sourceId) => switch (sourceId) {
      'youtube' => l10n.youtube,
      'soundcloud' => 'SoundCloud',
      _ => sourceId,
    };

/// Three little bouncing bars – the universal "this is playing" sign.
/// Freezes when paused or when motion is reduced.
class NowPlayingBars extends ConsumerStatefulWidget {
  const NowPlayingBars({super.key, required this.color, this.size = 18});

  final Color color;
  final double size;

  @override
  ConsumerState<NowPlayingBars> createState() => _NowPlayingBarsState();
}

class _NowPlayingBarsState extends ConsumerState<NowPlayingBars> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  void _sync(bool playing) {
    final run = playing && context.motion.decorative;
    if (run && !_c.isAnimating) {
      unawaited(_c.repeat());
    } else if (!run && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync(ref.read(isPlayingProvider)); // reduce motion may have changed
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(isPlayingProvider, (_, playing) => _sync(playing));
    // The painter repaints from the controller: no widget rebuild per frame.
    return SizedBox.square(
      dimension: widget.size,
      child: CustomPaint(painter: _BarsPainter(_c, widget.color)),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.t, this.color) : super(repaint: t);
  final Animation<double> t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width / 5;
    for (var i = 0; i < 3; i++) {
      final phase = t.value * 2 * math.pi + i * 1.9;
      final h = size.height * (0.35 + 0.65 * (0.5 + 0.5 * math.sin(phase)));
      final x = w * (i * 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h, w, h), Radius.circular(w / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.t != t || old.color != color;
}

/// Fades + slides list items in, staggered by [index] (first ~12 only, so
/// long lists don't wait). Skipped entirely with reduce motion.
class StaggeredAppear extends StatelessWidget {
  const StaggeredAppear({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    if (!motion.decorative || index > 12) return child;
    // Lists re-create items that scroll back into view: those must not play
    // the intro again (that looked like the list "blinking"). Same widget
    // shape either way, so an item never loses its state when this flips.
    final position = Scrollable.maybeOf(context)?.position;
    final revealedByScroll = position != null &&
        (position.isScrollingNotifier.value || (position.hasPixels && position.pixels > 0));
    final total = motion.d(Duration(milliseconds: 260 + index * 35));
    final start = (index * 35) / (260 + index * 35);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: revealedByScroll ? 1 : 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, (1 - v) * 14), child: child),
      ),
      child: child,
    );
  }
}

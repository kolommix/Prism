import 'package:flutter/material.dart';

import '../../../../core/theme/prism_theme_extensions.dart';
import '../../../library/domain/track.dart';

/// Title + artist that slide/fade when the song changes.
class TrackText extends StatelessWidget {
  const TrackText({super.key, required this.track, this.dense = false, this.center = false});

  final Track track;
  final bool dense;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = (dense ? text.titleSmall : text.headlineSmall)?.copyWith(fontWeight: FontWeight.w600);
    final subStyle = (dense ? text.bodySmall : text.titleMedium)?.copyWith(color: scheme.onSurfaceVariant);
    return AnimatedSwitcher(
      duration: context.motion.d(PrismMotion.long),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (current, previous) => Stack(
        alignment: center ? Alignment.center : Alignment.centerLeft,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(a),
          child: child,
        ),
      ),
      child: Column(
        key: ValueKey(track.id),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: titleStyle),
          SizedBox(height: dense ? 0 : 4),
          Text(track.displayArtist, maxLines: 1, overflow: TextOverflow.ellipsis, style: subStyle),
        ],
      ),
    );
  }
}

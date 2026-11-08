import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/prism_theme_extensions.dart';
import '../../../library/domain/artist_names.dart';
import '../../../library/domain/track.dart';

/// Title + artist that slide/fade when the song changes.
///
/// With [linkArtists] each artist name is a link to the page with all of
/// their songs in the library ("Rat Boy, IBDY" is two links). Only for songs
/// from the library: a streamed song's artist has no page.
class TrackText extends StatelessWidget {
  const TrackText({super.key, required this.track, this.dense = false, this.center = false, this.linkArtists = true});

  final Track track;
  final bool dense;
  final bool center;
  final bool linkArtists;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final titleStyle = (dense ? text.titleSmall : text.headlineSmall)?.copyWith(fontWeight: FontWeight.w600);
    final subStyle = (dense ? text.bodySmall : text.titleMedium)?.copyWith(color: scheme.onSurfaceVariant);
    final links = linkArtists && track.sourceId == 'local' && track.artist.trim().isNotEmpty;
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
          if (links)
            ArtistLinks(artist: track.artist, style: subStyle, center: center)
          else
            Text(track.displayArtist, maxLines: 1, overflow: TextOverflow.ellipsis, style: subStyle),
        ],
      ),
    );
  }
}

/// "Rat Boy, IBDY" as two links, the separators as they were written. A name
/// lights up and gets underlined under the mouse; a tap opens its page.
class ArtistLinks extends StatefulWidget {
  const ArtistLinks({super.key, required this.artist, this.style, this.center = false});

  final String artist;
  final TextStyle? style;
  final bool center;

  @override
  State<ArtistLinks> createState() => _ArtistLinksState();
}

class _ArtistLinksState extends State<ArtistLinks> {
  int? _hover;
  final _taps = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final t in _taps) {
      t.dispose();
    }
    super.dispose();
  }

  /// The tag cut into names and the text between them, in order.
  List<(String text, String? name)> _parts() {
    final out = <(String, String?)>[];
    var at = 0;
    final raw = widget.artist;
    for (final m in artistSeparators.allMatches(raw)) {
      if (m.start > at) out.add((raw.substring(at, m.start), raw.substring(at, m.start).trim()));
      out.add((m[0]!, null));
      at = m.end;
    }
    if (at < raw.length) out.add((raw.substring(at), raw.substring(at).trim()));
    return [for (final p in out) if (p.$1.isNotEmpty) p];
  }

  @override
  Widget build(BuildContext context) {
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
    final on = Theme.of(context).colorScheme.onSurface;
    final spans = <InlineSpan>[];
    var i = 0;
    for (final (text, name) in _parts()) {
      if (name == null || name.isEmpty) {
        spans.add(TextSpan(text: text));
        continue;
      }
      final index = i++;
      final tap = TapGestureRecognizer()..onTap = () => context.go(Routes.artist(name));
      _taps.add(tap);
      final hovered = _hover == index;
      spans.add(TextSpan(
        text: text,
        recognizer: tap,
        mouseCursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = index),
        onExit: (_) => setState(() => _hover = null),
        style: hovered ? TextStyle(color: on, decoration: TextDecoration.underline, decorationColor: on) : null,
      ));
    }
    return Text.rich(
      TextSpan(style: widget.style, children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: widget.center ? TextAlign.center : TextAlign.start,
    );
  }
}

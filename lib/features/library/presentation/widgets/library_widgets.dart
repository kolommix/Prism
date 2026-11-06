import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/motion/spring_button.dart';
import '../../../../core/theme/prism_theme_extensions.dart';
import '../../../../core/widgets/artwork.dart';
import '../../../player/application/player_providers.dart';
import '../../application/library_providers.dart';
import '../../domain/library_models.dart';
import '../../domain/track.dart';
import '../add_folder.dart';
import 'track_tile.dart';
import '../../../../l10n/l10n.dart';

/// Bottom padding so content can scroll above the mini-player/nav bar.
double bottomInset(BuildContext context) => MediaQuery.paddingOf(context).bottom + 24;

/// A sliver list of tracks; tapping one plays the whole list from there.
class TrackSliverList extends ConsumerWidget {
  const TrackSliverList({super.key, required this.tracks, this.numbered = false, this.playlistId, this.entryIds});

  final List<Track> tracks;
  final bool numbered;
  final int? playlistId;
  final List<int>? entryIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverList.builder(
      itemCount: tracks.length,
      itemBuilder: (context, i) => StaggeredAppear(
        index: i,
        child: TrackTile(
          track: tracks[i],
          leadingNumber: numbered ? (tracks[i].trackNumber ?? i + 1) : null,
          playlistId: playlistId,
          playlistEntryId: entryIds?[i],
          onTap: () => ref.read(playerControllerProvider).playTracks(tracks, startIndex: i),
        ),
      ),
    );
  }
}

/// "Play" + "Shuffle" pill buttons used on collection pages.
class PlayShuffleButtons extends ConsumerWidget {
  const PlayShuffleButtons({super.key, required this.tracks});

  final List<Track> tracks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.read(playerControllerProvider);
    return Row(
      children: [
        SpringButton(
          child: FilledButton.icon(
            onPressed: tracks.isEmpty ? null : () => player.playTracks(tracks, shuffle: false),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(l10n.play),
          ),
        ),
        const SizedBox(width: 10),
        SpringButton(
          child: FilledButton.tonalIcon(
            onPressed: tracks.isEmpty ? null : () => player.playTracks(tracks, shuffle: true),
            icon: const Icon(Icons.shuffle_rounded),
            label: Text(l10n.shuffle),
          ),
        ),
      ],
    );
  }
}

/// Header with big cover + title used by album/artist/playlist/folder pages.
class CollectionHeader extends StatelessWidget {
  const CollectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.tracks,
    this.artworkPath,
    this.icon = Icons.album_rounded,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final List<Track> tracks;
  final String? artworkPath;
  final IconData icon;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final narrow = MediaQuery.sizeOf(context).width < 560;
    final cover = Artwork(path: artworkPath, size: narrow ? 160 : 190, borderRadius: context.shape.large, seed: title, icon: icon);
    final info = Column(
      crossAxisAlignment: narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title,
            style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: narrow ? TextAlign.center : TextAlign.start,
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 6),
        Text(subtitle, style: text.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [PlayShuffleButtons(tracks: tracks), ...actions],
        ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: narrow
          ? Column(children: [cover, const SizedBox(height: 16), info])
          : Row(children: [cover, const SizedBox(width: 24), Expanded(child: info)]),
    );
  }
}

/// Grid card for albums/artists with a springy press. On desktop, hovering
/// lifts the cover a little and shows a round play button ([onPlay]).
class CoverCard extends StatefulWidget {
  const CoverCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onPlay,
    this.artworkPath,
    this.circle = false,
  });

  final String title;
  final String subtitle;
  final String? artworkPath;
  final VoidCallback onTap;
  final VoidCallback? onPlay;
  final bool circle;

  @override
  State<CoverCard> createState() => _CoverCardState();
}

class _CoverCardState extends State<CoverCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;
    final motion = context.motion;
    final radius = widget.circle ? BorderRadius.circular(999) : context.shape.medium;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: SpringButton(
        onTap: widget.onTap,
        pressedScale: 0.97,
        child: Column(
          crossAxisAlignment: widget.circle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedContainer(
                    duration: motion.d(PrismMotion.medium),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: _hover ? 0.45 : 0.0),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Artwork(
                      path: widget.artworkPath,
                      borderRadius: radius,
                      seed: widget.title,
                      icon: widget.circle ? Icons.person_rounded : Icons.album_rounded,
                    ),
                  ),
                  if (widget.onPlay != null)
                    Positioned(
                      right: widget.circle ? 0 : 10,
                      bottom: 10,
                      left: widget.circle ? 0 : null,
                      child: Align(
                        alignment: widget.circle ? Alignment.center : Alignment.centerRight,
                        child: IgnorePointer(
                          ignoring: !_hover,
                          child: AnimatedOpacity(
                            opacity: _hover ? 1 : 0,
                            duration: motion.d(PrismMotion.short),
                            child: AnimatedSlide(
                              offset: Offset(0, _hover ? 0 : 0.35),
                              duration: motion.d(PrismMotion.medium),
                              curve: Curves.easeOutCubic,
                              child: SpringIconButton(
                                icon: const Icon(Icons.play_arrow_rounded),
                                filled: true,
                                size: 26,
                                padding: 10,
                                tooltip: l10n.play,
                                onPressed: widget.onPlay,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall),
            Text(
              widget.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when the library is empty – one tap to add the default folder.
class EmptyLibrary extends ConsumerWidget {
  const EmptyLibrary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final def = defaultMusicFolder();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.library_music_rounded, size: 72, color: scheme.primary),
            const SizedBox(height: 16),
            Text(l10n.yourLibraryIsEmpty, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.addAFolderWithMusicMp3, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (def != null)
              FilledButton.icon(
                onPressed: () => addLibraryFolder(context, ref, path: def),
                icon: const Icon(Icons.bolt_rounded),
                label: Text(l10n.add(def)),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => addLibraryFolder(context, ref),
              icon: const Icon(Icons.create_new_folder_rounded),
              label: Text(l10n.chooseFolder),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin animated progress line + text while a scan runs.
class ScanBanner extends ConsumerWidget {
  const ScanBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(scanControllerProvider);
    final (label, value) = switch (progress) {
      ScanDiscovering(:final found) => (l10n.lookingForMusicFiles(found), null),
      ScanReading(:final done, :final total) => (l10n.readingTags(done, total), total == 0 ? null : done / total),
      _ => (null, null),
    };
    return AnimatedSize(
      duration: context.motion.d(PrismMotion.medium),
      child: label == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 6),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: value ?? 0),
                    duration: context.motion.d(PrismMotion.medium),
                    builder: (context, v, _) => LinearProgressIndicator(value: value == null ? null : v),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Loading/error wrapper for AsyncValue lists.
Widget asyncSliver<T>(AsyncValue<T> value, Widget Function(T data) builder) => value.when(
      data: builder,
      loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
      error: (e, _) => SliverFillRemaining(child: Center(child: Text(l10n.error(e)))),
    );

/// Convenience for albums grid.
String albumSubtitle(AlbumSummary a) =>
    [if (a.artist.isNotEmpty) a.artist, if (a.year != null) '${a.year}'].join(' · ');

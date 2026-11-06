import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../background/presentation/prism_background.dart';
import '../application/library_providers.dart';
import 'library_page.dart';
import 'widgets/library_widgets.dart';
import '../../../l10n/l10n.dart';

import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
class AlbumPage extends ConsumerWidget {
  const AlbumPage({super.key, required this.album, required this.artist});

  final String album;
  final String artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(albumTracksProvider((album: album, artist: artist)));
    final art = tracks.value?.where((t) => t.artworkPath != null).firstOrNull?.artworkPath;
    return PrismBackground(
      artworkPath: art,
      intensity: 0.6,
      nested: true,
      child: CollectionPage(
        tracks: tracks,
        numbered: true,
        header: (list) {
          final minutes = list.fold<int>(0, (s, t) => s + t.durationMs) ~/ 60000;
          final year = list.map((t) => t.year).whereType<int>().firstOrNull;
          return CollectionHeader(
            title: album.isEmpty ? l10n.unknownAlbum : album,
            subtitle: [
              if (artist.isNotEmpty) artist,
              if (year != null) '$year',
              '${l10n.nSongs(list.length)} · ${l10n.minutesValue(minutes)}',
            ].join(' · '),
            artworkPath: art,
            tracks: list,
            actions: [
              IconButton(
                tooltip: l10n.metaFixAlbum,
                icon: const Icon(Icons.manage_search_rounded),
                onPressed: () => context.push(Routes.metadata(list.map((t) => t.id))),
              ),
            ],
          );
        },
      ),
    );
  }
}

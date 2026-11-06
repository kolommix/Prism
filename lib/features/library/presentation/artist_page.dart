import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/library_providers.dart';
import 'library_page.dart';
import 'widgets/library_widgets.dart';
import '../../../l10n/l10n.dart';

class ArtistPage extends ConsumerWidget {
  const ArtistPage({super.key, required this.artist});

  final String artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(artistTracksProvider(artist));
    return CollectionPage(
      tracks: tracks,
      header: (list) => CollectionHeader(
        title: artist.isEmpty ? l10n.unknownArtist : artist,
        subtitle: '${l10n.nAlbums(list.map((t) => t.album).toSet().length)} · ${l10n.nSongs(list.length)}',
        artworkPath: list.where((t) => t.artworkPath != null).firstOrNull?.artworkPath,
        icon: Icons.person_rounded,
        tracks: list,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/application/library_providers.dart';
import '../../library/presentation/library_page.dart';
import '../../library/presentation/widgets/library_widgets.dart';
import '../../../l10n/l10n.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CollectionPage(
      tracks: ref.watch(favoriteTracksProvider),
      header: (list) => CollectionHeader(
        title: l10n.favorites,
        subtitle: l10n.nSongs(list.length),
        artworkPath: list.where((t) => t.artworkPath != null).firstOrNull?.artworkPath,
        icon: Icons.favorite_rounded,
        tracks: list,
      ),
    );
  }
}

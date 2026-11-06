import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../application/library_providers.dart';
import 'library_page.dart';
import 'widgets/library_widgets.dart';
import '../../../l10n/l10n.dart';

import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
class FolderPage extends ConsumerWidget {
  const FolderPage({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(folderTracksProvider(path));
    return CollectionPage(
      tracks: tracks,
      header: (list) => CollectionHeader(
        title: p.basename(path),
        subtitle: '$path · ${l10n.nSongs(list.length)}',
        icon: Icons.folder_rounded,
        tracks: list,
        actions: [
          IconButton(
            tooltip: l10n.metaFixAlbum,
            icon: const Icon(Icons.manage_search_rounded),
            onPressed: () => context.push(Routes.metadata(list.map((t) => t.id))),
          ),
        ],
      ),
    );
  }
}

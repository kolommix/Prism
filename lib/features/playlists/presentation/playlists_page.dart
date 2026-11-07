import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/smooth_scroll.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/artwork.dart';
import '../../library/application/library_providers.dart';
import '../../library/presentation/widgets/library_widgets.dart';
import '../../library/presentation/widgets/track_tile.dart';
import '../../stats/application/stats_providers.dart';
import '../../stats/presentation/smart_playlist_page.dart';
import '../application/playlist_providers.dart';
import 'playlist_dialogs.dart';
import '../../../l10n/l10n.dart';

class PlaylistsPage extends ConsumerWidget {
  const PlaylistsPage({super.key});

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final name = await showPlaylistNameDialog(context);
    if (name == null) return;
    final id = await ref.read(playlistRepositoryProvider).create(name);
    if (context.mounted) context.go(Routes.playlist(id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider);
    final favCount = ref.watch(favoriteIdsProvider.select((s) => s.value?.length ?? 0));
    final repo = ref.read(playlistRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.playlists2, style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(tooltip: l10n.newPlaylist, icon: const Icon(Icons.add_rounded), onPressed: () => _create(context, ref)),
        ],
      ),
      body: SmoothCustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: ListTile(
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                ),
                child: Icon(Icons.favorite_rounded, color: Theme.of(context).colorScheme.onSurface),
              ),
              title: Text(l10n.favorites),
              subtitle: Text(favCount == 1 ? l10n.nSongs(1) : l10n.nSongs(favCount)),
              onTap: () => context.go(Routes.favorites),
            ),
          ),
          SliverToBoxAdapter(
            child: ListTile(
              leading: const SizedBox(width: 52, child: Icon(Icons.insights_rounded)),
              title: Text(l10n.yourListeningStats),
              subtitle: Text(l10n.topSongsArtistsAndStreaks),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go(Routes.stats),
            ),
          ),
          SliverToBoxAdapter(
            child: ListTile(
              leading: const SizedBox(width: 52, child: Icon(Icons.playlist_add_rounded)),
              title: Text(l10n.importPlaylists),
              subtitle: Text(l10n.fromSpotifyYoutubeSoundcloudDeezerApple),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.go(Routes.importPlaylists),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
              child: Row(children: [
                Text(l10n.smartPlaylists, style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => showSmartPlaylistEditor(context, ref),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.xNew),
                ),
              ]),
            ),
          ),
          SliverList.list(children: [
            for (final sp in ref.watch(smartPlaylistsProvider).value ?? const [])
              SmartPlaylistTile(playlist: sp, onTap: () => context.go(Routes.smartPlaylist(sp.id))),
          ]),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(l10n.playlists2, style: Theme.of(context).textTheme.titleSmall),
            ),
          ),
          asyncSliver(
            playlists,
            (list) => SliverList.builder(
              itemCount: list.length,
              itemBuilder: (context, i) {
                final p = list[i];
                return StaggeredAppear(
                  index: i,
                  child: ListTile(
                    leading: Artwork(path: p.artworkPath, size: 52, seed: p.name, icon: Icons.queue_music_rounded),
                    title: Text(p.name),
                    subtitle: Text(p.trackCount == 1 ? l10n.nSongs(1) : l10n.nSongs(p.trackCount)),
                    onTap: () => context.go(Routes.playlist(p.id)),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'rename') {
                          final name = await showPlaylistNameDialog(context, initial: p.name, title: l10n.renamePlaylist);
                          if (name != null) await repo.rename(p.id, name);
                        } else if (v == 'delete' && await confirmDelete(context, '"${p.name}"')) {
                          await repo.delete(p.id);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
                        PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SliverPadding(padding: EdgeInsets.only(bottom: bottomInset(context))),
        ],
      ),
    );
  }
}

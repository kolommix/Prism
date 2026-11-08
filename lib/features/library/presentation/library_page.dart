import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

import '../../../core/motion/smooth_scroll.dart';
import '../../../core/router/app_router.dart';
import '../../player/application/player_providers.dart';
import '../../tools/application/tools_providers.dart';
import '../application/library_providers.dart';
import '../data/library_repository.dart';
import '../domain/track.dart';
import 'widgets/library_widgets.dart';
import 'widgets/track_tile.dart';
import '../../../l10n/l10n.dart';

/// Library home: Songs / Albums / Artists / Folders tabs.
class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(tracksProvider.select((v) => v.value?.length));
    if (count == 0 && ref.watch(scanControllerProvider) == null) {
      return const Scaffold(backgroundColor: Colors.transparent, body: SafeArea(child: EmptyLibrary()));
    }
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(l10n.xLibrary, style: TextStyle(fontWeight: FontWeight.w600)),
          actions: [
            PopupMenuButton<TrackSort>(
              tooltip: l10n.sortSongs,
              icon: const Icon(Icons.sort_rounded),
              onSelected: ref.read(trackSortProvider.notifier).set,
              itemBuilder: (_) => [
                for (final s in TrackSort.values)
                  CheckedPopupMenuItem(
                    value: s,
                    checked: ref.read(trackSortProvider) == s,
                    child: Text(switch (s) {
                      TrackSort.title => l10n.title,
                      TrackSort.artist => l10n.artist,
                      TrackSort.album => l10n.album,
                      TrackSort.recentlyAdded => l10n.recentlyAdded,
                      TrackSort.duration => l10n.longestFirst,
                    }),
                  ),
              ],
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [Tab(text: l10n.songs), Tab(text: l10n.albums), Tab(text: l10n.artists), Tab(text: l10n.folders)],
          ),
        ),
        body: const Column(
          children: [
            ScanBanner(),
            Expanded(child: TabBarView(children: [_SongsTab(), _AlbumsTab(), _ArtistsTab(), _FoldersTab()])),
          ],
        ),
      ),
    );
  }
}

class _SongsTab extends ConsumerWidget {
  const _SongsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracks = ref.watch(tracksProvider);
    return SmoothCustomScrollView(
      slivers: [
        asyncSliver(tracks, (list) => SliverMainAxisGroup(slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Text(l10n.nSongs(list.length), style: Theme.of(context).textTheme.labelLarge),
                      const _DuplicatesHint(),
                      const Spacer(),
                      PlayShuffleButtons(tracks: list),
                    ],
                  ),
                ),
              ),
              TrackSliverList(tracks: list),
            ])),
        SliverPadding(padding: EdgeInsets.only(bottom: bottomInset(context))),
      ],
    );
  }
}

/// "3 duplicates" next to the song count, only when there are some: one tap
/// to the cleanup.
class _DuplicatesHint extends ConsumerWidget {
  const _DuplicatesHint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(duplicatesProvider).value ?? const [];
    final extras = groups.fold<int>(0, (n, g) => n + g.length - 1);
    if (extras == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: TextButton.icon(
        onPressed: () => context.go(Routes.duplicates),
        icon: const Icon(Icons.layers_outlined, size: 16),
        label: Text(l10n.dupInLibrary(extras)),
      ),
    );
  }
}

/// Quick play from a grid card (first snapshot of the collection).
Future<void> _play(WidgetRef ref, Stream<List<Track>> tracks) async {
  final list = await tracks.first;
  if (list.isNotEmpty) await ref.read(playerControllerProvider).playTracks(list);
}

SliverGridDelegate _gridDelegate() => const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 190,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.78,
    );

class _AlbumsTab extends ConsumerWidget {
  const _AlbumsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(albumsProvider);
    return SmoothCustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset(context)),
          sliver: asyncSliver(
            albums,
            (list) => SliverGrid.builder(
              gridDelegate: _gridDelegate(),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final a = list[i];
                return StaggeredAppear(
                  index: i,
                  child: CoverCard(
                    title: a.name.isEmpty ? l10n.unknownAlbum : a.name,
                    subtitle: albumSubtitle(a),
                    artworkPath: a.artworkPath,
                    onTap: () => context.go(Routes.album(a.name, a.artist)),
                    onPlay: () => _play(ref, ref.read(libraryRepositoryProvider).watchAlbumTracks(a.name, a.artist)),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ArtistsTab extends ConsumerWidget {
  const _ArtistsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artists = ref.watch(artistsProvider);
    return SmoothCustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset(context)),
          sliver: asyncSliver(
            artists,
            (list) => SliverGrid.builder(
              gridDelegate: _gridDelegate(),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final a = list[i];
                return StaggeredAppear(
                  index: i,
                  child: CoverCard(
                    circle: true,
                    title: a.name.isEmpty ? l10n.unknownArtist : a.name,
                    subtitle: '${l10n.nAlbums(a.albumCount)} · ${l10n.nSongs(a.trackCount)}',
                    artworkPath: a.artworkPath,
                    onTap: () => context.go(Routes.artist(a.name)),
                    onPlay: () => _play(ref, ref.read(libraryRepositoryProvider).watchArtistTracks(a.name)),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FoldersTab extends ConsumerWidget {
  const _FoldersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(folderSummariesProvider);
    return SmoothCustomScrollView(
      slivers: [
        asyncSliver(
          folders,
          (list) => SliverList.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final f = list[i];
              return StaggeredAppear(
                index: i,
                child: ListTile(
                  leading: const Icon(Icons.folder_rounded),
                  title: Text(p.basename(f.path)),
                  subtitle: Text(f.path, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text('${f.trackCount}'),
                  onTap: () => context.go(Routes.folder(f.path)),
                ),
              );
            },
          ),
        ),
        SliverPadding(padding: EdgeInsets.only(bottom: bottomInset(context))),
      ],
    );
  }
}

/// Shared scaffold for album/artist/folder detail pages.
class CollectionPage extends StatelessWidget {
  const CollectionPage({super.key, required this.header, required this.tracks, this.numbered = false});

  final Widget Function(List<Track> tracks) header;
  final AsyncValue<List<Track>> tracks;
  final bool numbered;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SmoothCustomScrollView(
        slivers: [
          asyncSliver(tracks, (list) => SliverToBoxAdapter(child: header(list))),
          asyncSliver(tracks, (list) => TrackSliverList(tracks: list, numbered: numbered)),
          SliverPadding(padding: EdgeInsets.only(bottom: bottomInset(context))),
        ],
      ),
    );
  }
}

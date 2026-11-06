import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/smooth_scroll.dart';
import '../../../l10n/l10n.dart';
import '../../library/domain/track.dart';
import '../../library/presentation/widgets/library_widgets.dart';
import '../../library/presentation/widgets/track_actions.dart';
import '../../library/presentation/widgets/track_tile.dart';
import '../../player/application/player_providers.dart';
import '../../player/domain/reorder.dart';
import '../application/playlist_providers.dart';
import '../data/playlist_repository.dart';
import 'playlist_dialogs.dart';
import 'reorder_widgets.dart';
import 'share_dialog.dart';

String playlistSortLabel(PlaylistSort s) => switch (s) {
      PlaylistSort.custom => l10n.orderCustom,
      PlaylistSort.title => l10n.title,
      PlaylistSort.artist => l10n.artist,
      PlaylistSort.album => l10n.album,
      PlaylistSort.recent => l10n.recentlyAdded,
      PlaylistSort.longest => l10n.longestFirst,
    };

/// One playlist: drag to reorder (handle on Windows, hold on a phone), select
/// several and drag or move them together, swipe to remove, rename/delete/share
/// in the bar. The custom order stays saved under whatever sort is on.
class PlaylistPage extends ConsumerStatefulWidget {
  const PlaylistPage({super.key, required this.playlistId});

  final int playlistId;

  @override
  ConsumerState<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends ConsumerState<PlaylistPage> {
  /// Local copy so a drag shows its result instantly, before the DB write
  /// round-trips back through the stream.
  List<PlaylistItem>? _optimistic;

  /// Entry ids, so a selection survives the list moving under it.
  final _selected = <int>{};
  bool _selecting = false;

  PlaylistRepository get _repo => ref.read(playlistRepositoryProvider);

  Future<void> _moveGroup(List<PlaylistItem> items, Set<int> indices, int start) async {
    final moves = groupMoves(items.length, indices, start);
    if (moves.isEmpty) return;
    setState(() => _optimistic = applyMoves(items, moves));
    await _repo.moveMany(widget.playlistId, indices, start);
  }

  /// [to] is the final index (onReorderItem already adjusts for the removal).
  Future<void> _onDrop(List<PlaylistItem> items, int from, int to) async {
    final selected = {
      for (var i = 0; i < items.length; i++)
        if (_selected.contains(items[i].entryId)) i,
    };
    if (selected.length > 1 && selected.contains(from)) {
      await _moveGroup(items, selected, groupDropStart(selected, from, to));
    } else {
      await _moveGroup(items, {from}, to);
    }
  }

  void _toggle(int entryId) => setState(() {
        if (!_selected.remove(entryId)) _selected.add(entryId);
        if (_selected.isEmpty) _selecting = false;
      });

  void _clearSelection() => setState(() {
        _selected.clear();
        _selecting = false;
      });

  Future<void> _removeSelected(List<PlaylistItem> items) async {
    final ids = {..._selected};
    setState(() {
      _optimistic = [for (final i in items) if (!ids.contains(i.entryId)) i];
      _selected.clear();
      _selecting = false;
    });
    await _repo.removeEntries(widget.playlistId, ids);
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.playlistId;
    final name = ref.watch(playlistNameProvider(id)).value ?? '';
    final itemsAsync = ref.watch(playlistItemsProvider(id));
    final sort = ref.watch(playlistSortProvider(id)).value ?? PlaylistSort.custom;
    ref.listen(playlistItemsProvider(id), (_, _) => setState(() => _optimistic = null));
    final repo = _repo;
    final custom = _optimistic ?? itemsAsync.value ?? const <PlaylistItem>[];
    final isCustom = sort == PlaylistSort.custom;
    final items = isCustom ? custom : sortPlaylistItems(custom, sort);
    final tracks = <Track>[for (final i in items) i.track];
    final scheme = Theme.of(context).colorScheme;
    final selectedIndices = {
      for (var i = 0; i < items.length; i++)
        if (_selected.contains(items[i].entryId)) i,
    };

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          PopupMenuButton<PlaylistSort>(
            tooltip: l10n.orderSort,
            icon: const Icon(Icons.sort_rounded),
            initialValue: sort,
            onSelected: (s) => repo.setSort(id, s),
            itemBuilder: (_) => [
              for (final s in PlaylistSort.values) PopupMenuItem(value: s, child: Text(playlistSortLabel(s))),
            ],
          ),
          IconButton(
            tooltip: l10n.orderSelect,
            icon: Icon(_selecting ? Icons.checklist_rtl_rounded : Icons.checklist_rounded),
            onPressed: items.isEmpty ? null : () => _selecting ? _clearSelection() : setState(() => _selecting = true),
          ),
          IconButton(
            tooltip: l10n.shareButton,
            icon: const Icon(Icons.ios_share_rounded),
            onPressed: tracks.isEmpty ? null : () => showShareDialog(context, name, tracks),
          ),
          IconButton(
            tooltip: l10n.rename,
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              final n = await showPlaylistNameDialog(context, initial: name, title: l10n.renamePlaylist);
              if (n != null) await repo.rename(id, n);
            },
          ),
          IconButton(
            tooltip: l10n.deletePlaylist,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () async {
              if (await confirmDelete(context, '"$name"')) {
                await repo.delete(id);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: Column(children: [
        if (_selecting && selectedIndices.isNotEmpty)
          SelectionBar(
            count: selectedIndices.length,
            onTop: () => _moveGroup(custom, _customIndices(custom), 0),
            onBottom: () => _moveGroup(custom, _customIndices(custom), custom.length),
            onRemove: () => _removeSelected(custom),
            onClear: _clearSelection,
          ),
        Expanded(
          child: SmoothCustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: CollectionHeader(
                  title: name,
                  subtitle: l10n.nSongs(tracks.length),
                  artworkPath: tracks.where((t) => t.artworkPath != null).firstOrNull?.artworkPath,
                  icon: Icons.queue_music_rounded,
                  tracks: tracks,
                ),
              ),
              if (!isCustom)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      Text(l10n.orderSortedHint(playlistSortLabel(sort)), style: Theme.of(context).textTheme.bodySmall),
                      TextButton(onPressed: () => repo.setSort(id, PlaylistSort.custom), child: Text(l10n.orderBackToCustom)),
                      TextButton(
                        onPressed: () async {
                          await repo.setOrder(id, [for (final i in items) i.entryId]);
                          await repo.setSort(id, PlaylistSort.custom);
                        },
                        child: Text(l10n.orderKeepThis),
                      ),
                    ]),
                  ),
                ),
              if (items.isEmpty && !itemsAsync.isLoading)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(l10n.emptyPlaylistLongPressASong, textAlign: TextAlign.center)),
                ),
              SliverReorderableList(
                itemCount: items.length,
                onReorderItem: (from, to) => _onDrop(items, from, to),
                proxyDecorator: (child, index, animation) => reorderProxy(
                  context,
                  child,
                  animation,
                  group: selectedIndices.contains(index) ? selectedIndices.length : 1,
                ),
                itemBuilder: (context, i) {
                  final item = items[i];
                  final picked = _selected.contains(item.entryId);
                  final row = reorderRow(
                    index: i,
                    enabled: isCustom,
                    child: TrackTile(
                      track: item.track,
                      playlistId: id,
                      playlistEntryId: item.entryId,
                      longPressActions: !(reorderByLongPress && isCustom),
                      leading: _selecting
                          ? Checkbox(value: picked, onChanged: (_) => _toggle(item.entryId))
                          : null,
                      onTap: _selecting
                          ? () => _toggle(item.entryId)
                          : () => ref.read(playerControllerProvider).playTracks(tracks, startIndex: i),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          tooltip: l10n.more,
                          icon: const Icon(Icons.more_vert_rounded, size: 20),
                          onPressed: () => showTrackActions(context, ref, item.track, playlistId: id, playlistEntryId: item.entryId),
                        ),
                        if (isCustom) ReorderHandle(index: i),
                      ]),
                    ),
                  );
                  return Dismissible(
                    key: ValueKey('e${item.entryId}'),
                    direction: _selecting ? DismissDirection.none : DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      color: scheme.errorContainer,
                      child: Icon(Icons.playlist_remove_rounded, color: scheme.onErrorContainer),
                    ),
                    onDismissed: (_) {
                      setState(() => _optimistic = [for (final x in custom) if (x.entryId != item.entryId) x]);
                      repo.removeEntry(id, item.entryId);
                    },
                    child: row,
                  );
                },
              ),
              SliverPadding(padding: EdgeInsets.only(bottom: bottomInset(context))),
            ],
          ),
        ),
      ]),
    );
  }

  /// The selection as positions in the custom order.
  Set<int> _customIndices(List<PlaylistItem> custom) => {
        for (var i = 0; i < custom.length; i++)
          if (_selected.contains(custom[i].entryId)) i,
      };
}

/// [items] as the sort shows them; the same song twice stays twice.
List<PlaylistItem> sortPlaylistItems(List<PlaylistItem> items, PlaylistSort sort) {
  int text(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
  final out = [...items];
  switch (sort) {
    case PlaylistSort.custom:
      break;
    case PlaylistSort.title:
      out.sort((a, b) => text(a.track.title, b.track.title));
    case PlaylistSort.artist:
      out.sort((a, b) {
        final c = text(a.track.displayArtist, b.track.displayArtist);
        return c != 0 ? c : text(a.track.title, b.track.title);
      });
    case PlaylistSort.album:
      out.sort((a, b) {
        final c = text(a.track.album, b.track.album);
        return c != 0 ? c : (a.track.trackNumber ?? 0).compareTo(b.track.trackNumber ?? 0);
      });
    case PlaylistSort.recent:
      out.sort((a, b) => b.entryId.compareTo(a.entryId));
    case PlaylistSort.longest:
      out.sort((a, b) => b.track.durationMs.compareTo(a.track.durationMs));
  }
  return out;
}

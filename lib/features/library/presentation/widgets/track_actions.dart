import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/artwork.dart';
import '../../../player/application/player_providers.dart';
import '../../../playlists/application/playlist_providers.dart';
import '../../../playlists/presentation/playlist_dialogs.dart';
import '../../application/library_providers.dart';
import '../../../tools/presentation/tag_editor_dialog.dart';
import '../../domain/track.dart';
import '../../../online/application/online_providers.dart';
import '../../../online/services/music_service_module.dart';
import '../../../online/services/youtube/youtube_module.dart';

import 'package:url_launcher/url_launcher.dart';
import '../../../../l10n/l10n.dart';

void _toast(BuildContext context, String msg) =>
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));

/// Asks, removes the song from Prism (never the file), offers undo.
Future<void> removeTrackFromPrism(BuildContext context, WidgetRef ref, Track track) async {
  final repo = ref.read(libraryRepositoryProvider);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (context) => AlertDialog(
      title: Text(l10n.removeFromPrismAsk(track.title)),
      content: Text(l10n.removeFromPrismText),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.removeFromPrism)),
      ],
    ),
  );
  if (ok != true) return;
  final undo = await repo.removeFromLibrary([track]);
  messenger?.showSnackBar(
    SnackBar(
      content: Text(l10n.removeFromPrismDone),
      duration: const Duration(seconds: 8),
      action: SnackBarAction(label: l10n.undoAction, onPressed: undo),
    ),
  );
}

/// Bottom sheet with everything you can do with a song.
///
/// Streamed songs (YouTube, SoundCloud search results) are saved first so
/// favorites/playlists get a real id; file-only actions (editor, tags, album
/// and artist pages of the local library) are hidden for them.
Future<void> showTrackActions(
  BuildContext context,
  WidgetRef ref,
  Track track, {
  int? playlistId,
  int? playlistEntryId,
}) async {
  if (track.id <= 0) {
    track = await ref.read(remoteTrackStoreProvider).ensure(track);
    if (!context.mounted) return;
  }
  final player = ref.read(playerControllerProvider);
  final repo = ref.read(libraryRepositoryProvider);
  final isLocal = track.sourceId == 'local';
  final module = isLocal
      ? null
      : ref.read(onlineHubProvider).modules.where((m) => m.playableSourceId == track.sourceId).firstOrNull;
  final canCache =
      module != null && module.features.contains(ModuleFeature.stream) && track.sourceId == youtubeSourceId;
  final cache = ref.read(streamCacheProvider);
  final cached = isLocal ? null : await cache.fileFor(track);
  if (!context.mounted) return;
  final t = track;
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final isFav = ref.watch(favoriteIdsProvider.select((s) => s.value?.contains(t.id) ?? false));
        void close() => Navigator.of(sheetContext).pop();
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Artwork(path: track.artworkPath, size: 52, seed: track.album),
                title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '${track.displayArtist} · ${track.displayAlbum}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.playlist_play_rounded),
                title: Text(l10n.playNext),
                onTap: () {
                  close();
                  player.playNext([t]);
                  _toast(context, l10n.playingNext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.queue_music_rounded),
                title: Text(l10n.addToQueue),
                onTap: () {
                  close();
                  player.addToQueue([t]);
                  _toast(context, l10n.addedToQueue);
                },
              ),
              ListTile(
                leading: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                title: Text(isFav ? l10n.removeFromFavorites : l10n.addToFavorites),
                onTap: () => repo.toggleFavorite(t.id),
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: Text(l10n.addToPlaylist),
                onTap: () async {
                  close();
                  await showAddToPlaylistDialog(context, ref, [t.id]);
                },
              ),
              if (!isLocal) ...[
                if (canCache)
                  ListTile(
                    leading: Icon(cached != null ? Icons.download_done_rounded : Icons.download_for_offline_rounded),
                    title: Text(cached != null ? l10n.removeOfflineCopy : l10n.saveForOffline),
                    subtitle: Text(l10n.personalUseOnlySeeSettingsOnline),
                    onTap: () {
                      close();
                      if (cached != null) {
                        cache.remove(t);
                        _toast(context, l10n.offlineCopyRemoved);
                      } else {
                        cache.download(t, module);
                        _toast(context, l10n.savingForOffline);
                      }
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.open_in_new_rounded),
                  title: Text(l10n.openOn(module?.service.label ?? l10n.theWeb)),
                  onTap: () {
                    close();
                    launchUrl(Uri.parse(t.uri.split('#').first), mode: LaunchMode.externalApplication);
                  },
                ),
              ],
              if (isLocal)
                ListTile(
                  leading: const Icon(Icons.content_cut_rounded),
                  title: Text(l10n.xEdit2),
                  subtitle: Text(l10n.trimCutSpeedPitchFadesOriginal),
                  onTap: () {
                    close();
                    context.go(Routes.editor(track.id));
                  },
                ),
              if (isLocal)
                ListTile(
                  leading: const Icon(Icons.edit_note_rounded),
                  title: Text(l10n.editTags),
                  onTap: () {
                    close();
                    showTagEditor(context, track);
                  },
                ),
              if (isLocal)
                ListTile(
                  leading: const Icon(Icons.manage_search_rounded),
                  title: Text(l10n.metaFix),
                  onTap: () {
                    close();
                    context.push(Routes.metadata([track.id]));
                  },
                ),
              if (playlistId != null && playlistEntryId != null) ...[
                ListTile(
                  leading: const Icon(Icons.vertical_align_top_rounded),
                  title: Text(l10n.orderMoveTop),
                  onTap: () {
                    close();
                    ref.read(playlistRepositoryProvider).moveEntryToEdge(playlistId, playlistEntryId, top: true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.vertical_align_bottom_rounded),
                  title: Text(l10n.orderMoveBottom),
                  onTap: () {
                    close();
                    ref.read(playlistRepositoryProvider).moveEntryToEdge(playlistId, playlistEntryId, top: false);
                  },
                ),
              ],
              if (playlistId != null && playlistEntryId != null)
                ListTile(
                  leading: const Icon(Icons.playlist_remove_rounded),
                  title: Text(l10n.removeFromThisPlaylist),
                  onTap: () {
                    close();
                    ref.read(playlistRepositoryProvider).removeEntry(playlistId, playlistEntryId);
                  },
                ),
              if (isLocal)
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline_rounded),
                  title: Text(l10n.removeFromPrism),
                  subtitle: Text(l10n.removeFromPrismHint),
                  onTap: () {
                    close();
                    unawaited(removeTrackFromPrism(context, ref, t));
                  },
                ),
              if (isLocal && track.album.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.album_rounded),
                  title: Text(l10n.goToAlbum),
                  onTap: () {
                    close();
                    context.go(
                      Routes.album(track.album, track.albumArtist.isNotEmpty ? track.albumArtist : track.artist),
                    );
                  },
                ),
              if (isLocal && track.artist.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.person_rounded),
                  title: Text(l10n.goToArtist),
                  onTap: () {
                    close();
                    context.go(Routes.artist(track.artist));
                  },
                ),
            ],
          ),
        );
      },
    ),
  );
}

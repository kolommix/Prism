import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/playlist_providers.dart';
import '../../../l10n/l10n.dart';

/// Asks for a playlist name. Returns null when cancelled.
Future<String?> showPlaylistNameDialog(BuildContext context, {String initial = '', String? title}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    useRootNavigator: true,
    builder: (context) => AlertDialog(
      title: Text(title ?? l10n.newPlaylist),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l10n.playlistName),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l10n.save)),
      ],
    ),
  ).whenComplete(controller.dispose);
}

Future<bool> confirmDelete(BuildContext context, String what) async =>
    await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (context) => AlertDialog(
        title: Text(l10n.delete2(what)),
        content: Text(l10n.thisCannotBeUndone),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    ) ??
    false;

/// Picks (or creates) a playlist and appends [trackIds] to it.
Future<void> showAddToPlaylistDialog(BuildContext context, WidgetRef ref, List<int> trackIds) async {
  final repo = ref.read(playlistRepositoryProvider);
  final chosen = await showDialog<int>(
    context: context,
    useRootNavigator: true,
    builder: (context) => Consumer(
      builder: (context, ref, _) {
        final playlists = ref.watch(playlistsProvider).value ?? const [];
        return SimpleDialog(
          title: Text(l10n.addToPlaylist2),
          children: [
            SimpleDialogOption(
              onPressed: () async {
                final name = await showPlaylistNameDialog(context);
                if (name == null) return;
                final id = await repo.create(name);
                if (context.mounted) Navigator.pop(context, id);
              },
              child: ListTile(leading: Icon(Icons.add_rounded), title: Text(l10n.newPlaylist2)),
            ),
            for (final p in playlists)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, p.id),
                child: ListTile(
                  leading: const Icon(Icons.queue_music_rounded),
                  title: Text(p.name),
                  subtitle: Text(p.trackCount == 1 ? l10n.nSongs(1) : l10n.nSongs(p.trackCount)),
                ),
              ),
          ],
        );
      },
    ),
  );
  if (chosen == null) return;
  await repo.addTracks(chosen, trackIds);
  if (context.mounted) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(l10n.addedToPlaylist)));
  }
}

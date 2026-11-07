import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/motion/smooth_scroll.dart';
import '../../library/presentation/widgets/library_widgets.dart';
import '../../player/application/player_providers.dart';
import '../../player/presentation/widgets/waveform_seek_bar.dart';
import '../../playlists/presentation/playlist_dialogs.dart';
import '../application/tools_providers.dart';
import '../../../l10n/l10n.dart';

/// Songs that look like the same recording (title + artist, length ±2 s).
class DuplicatesPage extends ConsumerWidget {
  const DuplicatesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(duplicatesProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(l10n.duplicateFinder)),
      body: groups.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? Center(child: Text(l10n.noDuplicatesFound))
            : SmoothListView(
                padding: EdgeInsets.only(bottom: bottomInset(context)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.nGroupsHint(list.length),
                        style: text.bodyMedium),
                  ),
                  for (final g in list)
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        ListTile(
                          title: Text(g.first.title, style: text.titleMedium),
                          subtitle: Text('${g.first.displayArtist} · ${l10n.nCopies(g.length)}'),
                        ),
                        for (final t in g)
                          ListTile(
                            dense: true,
                            leading: Text(p.extension(t.uri).replaceFirst('.', '').toUpperCase(),
                                style: text.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                            title: Text(t.uri, maxLines: 2, overflow: TextOverflow.ellipsis),
                            subtitle: Text('${formatDuration(t.duration)} · ${_size(t.uri)}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) async {
                                switch (v) {
                                  case 'play':
                                    await ref.read(playerControllerProvider).playTracks([t]);
                                  case 'remove':
                                    await ref.read(backupServiceProvider).library.removeFromLibrary([t]);
                                  case 'delete':
                                    if (await confirmDelete(context, l10n.theFile(t.uri))) await deleteTrackFile(ref, t);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(value: 'play', child: Text(l10n.play)),
                                PopupMenuItem(value: 'remove', child: Text(l10n.removeFromLibrary)),
                                PopupMenuItem(value: 'delete', child: Text(l10n.deleteFile)),
                              ],
                            ),
                          ),
                      ]),
                    ),
                ],
              ),
      ),
    );
  }

  static String _size(String path) {
    try {
      final bytes = File(path).lengthSync();
      return l10n.mb(fmtNum((bytes / (1024 * 1024)), 1));
    } on FileSystemException {
      return 'missing';
    }
  }
}

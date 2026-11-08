import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/motion/smooth_scroll.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/led_dot.dart';
import '../../library/domain/track.dart';
import '../../library/presentation/widgets/library_widgets.dart';
import '../../player/application/player_providers.dart';
import '../../player/presentation/widgets/waveform_seek_bar.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/tools_providers.dart';
import '../domain/track_matching.dart';
import '../../../l10n/l10n.dart';

/// Songs that are in the library more than once. Prism marks the best copy of
/// each (lossless, then bitrate, then cover and tags); a tap keeps another one.
/// One button cleans everything up: playlists, likes and listens move to the
/// kept copy, the extras leave Prism, and their files can go too.
class DuplicatesPage extends ConsumerStatefulWidget {
  const DuplicatesPage({super.key});

  @override
  ConsumerState<DuplicatesPage> createState() => _DuplicatesPageState();
}

class _DuplicatesPageState extends ConsumerState<DuplicatesPage> {
  /// The user's own picks, by group (its ids joined).
  final _picked = <String, int>{};
  final _sizes = <String, int>{};
  bool _busy = false;

  static String _key(List<Track> g) => (g.map((t) => t.id).toList()..sort()).join(',');

  int _size(Track t) => _sizes.putIfAbsent(t.uri, () {
        try {
          return File(t.uri).lengthSync();
        } on FileSystemException {
          return 0;
        }
      });

  Track _keep(List<Track> g) {
    final id = _picked[_key(g)];
    return g.where((t) => t.id == id).firstOrNull ?? bestCopy(g, _size);
  }

  Future<void> _cleanUp(List<List<Track>> groups) async {
    final extras = groups.fold<int>(0, (n, g) => n + g.length - 1);
    final deleteFiles = await showDialog<bool>(
      context: context,
      builder: (_) => _CleanUpDialog(extras: extras),
    );
    if (deleteFiles == null || !mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final result = await ref.read(duplicateCleanerProvider).run(
        [for (final g in groups) (_keep(g), g)],
        deleteFiles: deleteFiles,
      );
      messenger?.showSnackBar(SnackBar(
        content: Text([
          l10n.dupCleanedUp(result.removed),
          if (result.filesKept > 0) l10n.dupFilesKept(result.filesKept),
        ].join('. ')),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(duplicatesProvider);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(l10n.duplicateFinder)),
      body: groups.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) return Center(child: Text(l10n.noDuplicatesFound, style: text.bodyLarge));
          final extras = list.fold<int>(0, (n, g) => n + g.length - 1);
          return SmoothListView(
            padding: EdgeInsets.fromLTRB(16, 4, 16, bottomInset(context)),
            children: [
              Text(l10n.dupSummary(list.length), style: text.bodyMedium),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.icon(
                  onPressed: _busy ? null : () => _cleanUp(list),
                  icon: _busy
                      ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.cleaning_services_outlined, size: 18),
                  label: Text(l10n.dupCleanUp(extras)),
                ),
              ),
              const SizedBox(height: 16),
              for (final g in list) ...[
                _Group(
                  group: g,
                  keep: _keep(g),
                  sizeOf: _size,
                  onKeep: (t) => setState(() => _picked[_key(g)] = t.id),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Group extends ConsumerWidget {
  const _Group({required this.group, required this.keep, required this.sizeOf, required this.onKeep});

  final List<Track> group;
  final Track keep;
  final int Function(Track) sizeOf;
  final ValueChanged<Track> onKeep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final head = keep;
    return SettingsGroup(
      children: [
        ListTile(
          leading: Artwork(path: head.artworkPath, size: 44, seed: head.album),
          title: Text(head.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.titleSmall),
          subtitle: Text(head.displayArtist, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        for (final t in group)
          ListTile(
            onTap: () => onKeep(t),
            leading: SizedBox(
              width: 44,
              child: Center(
                child: t.id == keep.id
                    ? Tooltip(message: l10n.dupKept, child: const LedDot(on: true))
                    : Tooltip(
                        message: l10n.dupKeepThis,
                        child: Icon(Icons.radio_button_unchecked_rounded, size: 18, color: scheme.onSurfaceVariant),
                      ),
              ),
            ),
            title: Text(
              p.basename(t.uri),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: t.id == keep.id ? text.bodyMedium?.copyWith(fontWeight: FontWeight.w600) : text.bodyMedium,
            ),
            subtitle: Text(
              _details(t, sizeOf(t)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            trailing: IconButton(
              tooltip: l10n.play,
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: () => ref.read(playerControllerProvider).playTracks([t]),
            ),
          ),
      ],
    );
  }

  /// "FLAC · 912 kbps · 24.1 MB · 3:12 · Music/Album"
  static String _details(Track t, int bytes) {
    final format = p.extension(t.uri).replaceFirst('.', '').toUpperCase();
    final kbps = t.durationMs > 0 && bytes > 0 ? (bytes * 8 / t.durationMs).round() : null;
    final folder = p.split(p.dirname(t.uri));
    final where = folder.length >= 2 ? p.joinAll(folder.sublist(folder.length - 2)) : p.dirname(t.uri);
    return [
      format,
      if (kbps != null) l10n.edBitrate(fmtNum(kbps)),
      if (bytes > 0) l10n.mb(fmtNum(bytes / (1024 * 1024), 1)),
      formatDuration(t.duration),
      where,
    ].join(' · ');
  }
}

/// Asks once, and whether the files go too. Null = cancelled.
class _CleanUpDialog extends StatefulWidget {
  const _CleanUpDialog({required this.extras});
  final int extras;

  @override
  State<_CleanUpDialog> createState() => _CleanUpDialogState();
}

class _CleanUpDialogState extends State<_CleanUpDialog> {
  bool _files = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(l10n.dupCleanUpAsk(widget.extras)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dupMoveNote),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _files,
            onChanged: (v) => setState(() => _files = v ?? false),
            title: Text(l10n.dupDeleteFiles),
            subtitle: Text(Platform.isAndroid ? l10n.dupDeleteFilesAndroid : l10n.dupDeleteFilesWindows),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, _files), child: Text(l10n.dupCleanUp(widget.extras))),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/artwork.dart';
import '../../library/presentation/widgets/library_widgets.dart';
import '../application/online_providers.dart';
import '../data/import_repository.dart';
import '../../../l10n/l10n.dart';
import 'import_job_page.dart';
import 'import_page.dart';

/// All uncertain matches of all imports in one list: one tap to accept, one to
/// fix, one to say "none of these". Instead of asking about every song.
class ImportReviewPage extends ConsumerWidget {
  const ImportReviewPage({super.key});

  Future<void> _acceptAll(WidgetRef ref, List<ImportItem> items) async {
    final repo = ref.read(importRepositoryProvider);
    final jobs = <int>{};
    for (final i in items) {
      if (i.status != ImportItemStatus.matched) continue;
      await repo.acceptMatch(i.id);
      jobs.add(i.jobId);
    }
    for (final j in jobs) {
      await repo.writePlaylist(j, finish: false);
    }
  }

  Future<void> _skipNotFound(WidgetRef ref, List<ImportItem> items) async {
    final repo = ref.read(importRepositoryProvider);
    for (final i in items) {
      await repo.rejectMatch(i.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(importReviewProvider).value ?? const <ImportItem>[];
    final canAccept = items.where((i) => i.status == ImportItemStatus.matched).length;
    final notFound = items.where((i) => i.status == ImportItemStatus.unmatched).toList();
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(l10n.importReview),
        actions: [
          if (canAccept > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: Text(l10n.importAcceptAll(canAccept)),
              onPressed: () => _acceptAll(ref, items),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(l10n.importReviewEmpty, textAlign: TextAlign.center, style: text.bodyLarge),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.only(bottom: bottomInset(context)),
              itemCount: items.length + 1,
              itemBuilder: (_, i) {
                if (i > 0) return _ReviewRow(item: items[i - 1]);
                if (notFound.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      FindTheRest(jobIds: {for (final n in notFound) n.jobId}.toList()),
                      OutlinedButton(
                        onPressed: () => _skipNotFound(ref, notFound),
                        child: Text(l10n.importSkipNotFound(notFound.length)),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _ReviewRow extends ConsumerWidget {
  const _ReviewRow({required this.item});
  final ImportItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = item.wanted;
    final t = item.track;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final repo = ref.read(importRepositoryProvider);
    Future<void> decide(Future<void> Function() change) async {
      await change();
      await repo.refreshPlaylistOfItem(item.id);
    }

    return ListTile(
      leading: Artwork(path: t?.artworkPath ?? w.artworkUrl, size: 44, seed: w.album),
      title: Text(
        '${w.title} – ${w.artist.isEmpty ? l10n.unknownArtist : w.artist}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.jobName != null)
            Text(item.jobName!, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
          if (t != null)
            Row(
              children: [
                Icon(sourceIcon(item.matchSource), size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${t.displayArtist} – ${t.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                ),
              ],
            )
          else
            Text(item.note ?? l10n.noGoodMatchFound, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodySmall),
          const SizedBox(height: 3),
          ConfidenceChip(level: item.level, value: item.confidence),
        ],
      ),
      isThreeLine: true,
      onTap: t == null ? null : () => playTracksAnywhere(ref, [t]),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (t != null)
            IconButton(
              tooltip: l10n.importAccept,
              icon: const Icon(Icons.check_rounded),
              onPressed: () => decide(() => repo.acceptMatch(item.id)),
            ),
          TextButton(onPressed: () => showFixMatchSheet(context, ref, item), child: Text(l10n.fix)),
          IconButton(
            tooltip: l10n.noMatch,
            icon: const Icon(Icons.close_rounded),
            onPressed: () => decide(() => repo.rejectMatch(item.id)),
          ),
        ],
      ),
    );
  }
}

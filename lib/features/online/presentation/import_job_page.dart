import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/widgets/artwork.dart';
import '../../library/domain/track.dart';
import '../../library/presentation/widgets/library_widgets.dart';
import '../../player/presentation/widgets/waveform_seek_bar.dart';
import '../application/import_downloader.dart';
import '../application/import_flow.dart';
import '../application/match_service.dart';
import '../application/online_providers.dart';
import '../data/import_repository.dart';
import '../domain/import_intake.dart';
import '../domain/matching.dart';
import '../domain/online_error.dart';
import 'import_page.dart';
import '../../../l10n/l10n.dart';

enum _Filter { all, unmatched, matched, duplicates }

IconData sourceIcon(String? source) => switch (source) {
  'local' => Icons.folder_rounded,
  'youtube' || 'direct' => Icons.smart_display_rounded,
  'soundcloud' => Icons.cloud_rounded,
  'manual' => Icons.touch_app_rounded,
  _ => Icons.help_outline_rounded,
};

String sourceLabel(Track t) => switch (t.sourceId) {
  'local' => l10n.yourLibrary,
  'youtube' => l10n.youtube,
  'soundcloud' => 'SoundCloud',
  _ => t.sourceId,
};

/// One import: matching progress, pause/resume, review with confidence,
/// "fix match", and saving as a Prism playlist.
class ImportJobPage extends ConsumerStatefulWidget {
  const ImportJobPage({super.key, required this.jobId});
  final int jobId;

  @override
  ConsumerState<ImportJobPage> createState() => _ImportJobPageState();
}

class _ImportJobPageState extends ConsumerState<ImportJobPage> {
  _Filter _filter = _Filter.all;
  bool _syncing = false;

  Future<void> _resync(ImportJob job) async {
    setState(() => _syncing = true);
    try {
      await ref.read(importFlowProvider).resync(job);
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(importProblemFor(e).message)));
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(importJobProvider(widget.jobId)).value;
    final items = ref.watch(importItemsProvider(widget.jobId)).value ?? const <ImportItem>[];
    final run = ref.watch(importRunnerProvider);
    final runner = ref.read(importRunnerProvider.notifier);
    final running = run != null && run.jobId == widget.jobId && run.running;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (job == null) {
      return Scaffold(body: Center(child: Text(l10n.thisImportWasDeleted)));
    }
    final unmatched = items.where((i) => i.status == ImportItemStatus.unmatched).length;
    final dupes = items.where((i) => i.status == ImportItemStatus.duplicate).length;
    final shown = items
        .where(
          (i) => switch (_filter) {
            _Filter.all => true,
            _Filter.unmatched => i.status == ImportItemStatus.unmatched,
            _Filter.matched => i.status == ImportItemStatus.matched,
            _Filter.duplicates => i.status == ImportItemStatus.duplicate,
          },
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(job.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (ImportFlow.canResync(job))
            IconButton(
              tooltip: l10n.importResync,
              icon: const Icon(Icons.sync_rounded),
              onPressed: _syncing || running ? null : () => _resync(job),
            ),
          if (job.playlistId != null)
            IconButton(
              tooltip: l10n.openPlaylist,
              icon: const Icon(Icons.queue_music_rounded),
              onPressed: () => context.go(Routes.playlist(job.playlistId!)),
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${job.origin.label} · ${l10n.matchedOf(job.matched, job.total)}${unmatched > 0 ? ' · ${l10n.nNotFound(unmatched)}' : ''}${dupes > 0 ? ' · ${l10n.nDuplicates(dupes)}' : ''}',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  if (running) ...[
                    LinearProgressIndicator(value: run.total == 0 ? null : run.done / run.total),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.matchingLocalFilesFirstThenOnline(run.done, run.total),
                            style: text.bodySmall,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: runner.pause,
                          icon: const Icon(Icons.pause_rounded),
                          label: Text(l10n.pause),
                        ),
                      ],
                    ),
                  ] else if (job.pending > 0) ...[
                    if (job.message != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(job.message!, style: text.bodySmall?.copyWith(color: scheme.tertiary)),
                      ),
                    FilledButton.tonalIcon(
                      onPressed: () => unawaited(runner.run(job.id)),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(l10n.resumeMatchingLeft(job.pending)),
                    ),
                  ] else ...[
                    // Imports from before songs went in by themselves.
                    if (job.playlistId == null && job.matched > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FilledButton.icon(
                          onPressed: () => ref.read(importRepositoryProvider).writePlaylist(job.id),
                          icon: const Icon(Icons.playlist_add_rounded),
                          label: Text(l10n.createPlaylistN(job.matched)),
                        ),
                      ),
                    FindTheRest(
                      jobIds: [job.id],
                      notFound: unmatched,
                      toDownload: items.where((i) => i.status == ImportItemStatus.matched && i.track?.sourceId == 'youtube').length,
                    ),
                  ],
                  if (ref.watch(importDownloaderProvider) case final d? when d.jobId == job.id) ...[
                    const SizedBox(height: 8),
                    if (d.running) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 6),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            d.running ? l10n.importDownloading(d.done, d.current ?? '') : l10n.importDownloaded(d.done),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodySmall,
                          ),
                        ),
                        if (d.running)
                          TextButton(
                            onPressed: ref.read(importDownloaderProvider.notifier).stop,
                            child: Text(l10n.pause),
                          ),
                      ],
                    ),
                    if (!d.running && d.failed > 0)
                      Text(
                        '${l10n.importDownloadFailed(d.failed)}${d.message == null ? '' : ' ${d.message}'}',
                        style: text.bodySmall?.copyWith(color: scheme.tertiary),
                      ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final (f, label) in [
                        (_Filter.all, l10n.xAll(items.length)),
                        (_Filter.unmatched, l10n.notFound(unmatched)),
                        (_Filter.matched, l10n.matched(job.matched)),
                        if (dupes > 0) (_Filter.duplicates, l10n.duplicates(dupes)),
                      ])
                        ChoiceChip(
                          label: Text(label),
                          selected: _filter == f,
                          onSelected: (_) => setState(() => _filter = f),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverList.builder(
            itemCount: shown.length,
            itemBuilder: (_, i) => _ItemTile(item: shown[i]),
          ),
          SliverPadding(padding: EdgeInsets.only(bottom: bottomInset(context))),
        ],
      ),
    );
  }
}

class _ItemTile extends ConsumerWidget {
  const _ItemTile({required this.item});
  final ImportItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final w = item.wanted;
    final t = item.track;
    final Widget status = switch (item.status) {
      ImportItemStatus.pending => Text(l10n.waiting, style: text.bodySmall),
      ImportItemStatus.duplicate => Text(
        l10n.duplicateOfSkipped((item.duplicateOf ?? 0) + 1),
        style: text.bodySmall,
      ),
      ImportItemStatus.skipped => Text(l10n.skipped, style: text.bodySmall),
      ImportItemStatus.unmatched => Text(
        item.note ?? l10n.noGoodMatchFound,
        style: text.bodySmall?.copyWith(color: scheme.error),
      ),
      ImportItemStatus.matched => Row(
        children: [
          Icon(sourceIcon(item.matchSource), size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${t?.title ?? '?'} · ${t == null ? '' : sourceLabel(t)}${item.note == null ? '' : ' · ${item.note}'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall,
            ),
          ),
        ],
      ),
    };
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
          status,
        ],
      ),
      onTap: t == null ? null : () => playTracksAnywhere(ref, [t]),
      trailing: item.status == ImportItemStatus.pending
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(onPressed: () => showFixMatchSheet(context, ref, item), child: Text(l10n.fix)),
              ],
            ),
    );
  }
}

/// Nothing was found for some songs: search again, or first turn on a place to
/// find them. YouTube stays off until someone says yes to its terms.
/// Asks once, with the terms, before songs are saved from YouTube. True = yes.
Future<bool> askToDownload(BuildContext context, WidgetRef ref) async {
  final hub = ref.read(onlineHubProvider);
  final ok = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (c) => AlertDialog(
      title: Text(l10n.importDownloadAsk),
      content: Text(l10n.importDownloadTerms),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.importOnlyLibrary)),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l10n.iUnderstandTurnOn)),
      ],
    ),
  );
  if (ok != true) return false;
  await hub.setFlags(hub.flags.copyWith(youtubeExtractor: true, importDownload: true));
  return true;
}

class FindTheRest extends ConsumerWidget {
  const FindTheRest({super.key, required this.jobIds, this.notFound = 1, this.toDownload = 0});
  final List<int> jobIds;
  final int notFound;
  final int toDownload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(onlineRevisionProvider);
    final hub = ref.watch(onlineHubProvider);
    final text = Theme.of(context).textTheme;
    final noneOnline = hub.playable.isEmpty;
    final downloads = hub.flags.importDownload && !noneOnline;
    final busy = ref.watch(importDownloaderProvider)?.running ?? false;
    if (busy || (notFound == 0 && toDownload == 0)) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (noneOnline)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(l10n.importOnlyLibrarySearched, style: text.bodySmall),
          ),
        FilledButton.tonalIcon(
          icon: Icon(downloads ? Icons.refresh_rounded : Icons.download_rounded),
          label: Text(downloads ? l10n.importTryAgainSongs : l10n.importDownloadSongs),
          onPressed: () async {
            if (!downloads && !await askToDownload(context, ref)) return;
            final flow = ref.read(importFlowProvider);
            final downloader = ref.read(importDownloaderProvider.notifier);
            for (final id in jobIds) {
              if (notFound > 0) await flow.retryUnmatched(id);
              downloader.retry(id);
            }
          },
        ),
      ],
    );
  }
}

/// Pick the right song by hand: search local + online, each result with its
/// confidence; or mark "no match".
Future<void> showFixMatchSheet(BuildContext context, WidgetRef ref, ImportItem item) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  builder: (_) => _FixMatchSheet(item: item),
);

class _FixMatchSheet extends ConsumerStatefulWidget {
  const _FixMatchSheet({required this.item});
  final ImportItem item;

  @override
  ConsumerState<_FixMatchSheet> createState() => _FixMatchSheetState();
}

class _FixMatchSheetState extends ConsumerState<_FixMatchSheet> {
  late final _query = TextEditingController(text: MatchScorer.queryFor(widget.item.wanted));
  Future<(List<ScoredCandidate>, Map<String, String>)>? _results;

  @override
  void initState() {
    super.initState();
    _results = _find();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<(List<ScoredCandidate>, Map<String, String>)> _find() =>
      ref.read(matchServiceProvider).candidates(widget.item.wanted, _query.text);

  void _search() {
    final next = _find();
    setState(() => _results = next);
  }

  Future<void> _choose(ScoredCandidate c) async {
    final t = await ref.read(remoteTrackStoreProvider).ensure(c.track);
    final repo = ref.read(importRepositoryProvider);
    await repo.saveMatch(widget.item.id, trackId: t.id, confidence: c.score.value, source: manualSource);
    await repo.refreshPlaylistOfItem(widget.item.id);
    if (ref.read(onlineHubProvider).flags.importDownload) {
      ref.read(importDownloaderProvider.notifier).poke(widget.item.jobId);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.item.wanted;
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: Column(
            children: [
              ListTile(
                title: Text(l10n.fixMatch, style: text.titleLarge),
                subtitle: Text(
                  '${w.title} – ${w.artist}${w.durationMs > 0 ? ' · ${formatDuration(Duration(milliseconds: w.durationMs))}' : ''}',
                ),
                trailing: TextButton(
                  onPressed: () async {
                    final repo = ref.read(importRepositoryProvider);
                    await repo.rejectMatch(widget.item.id);
                    await repo.refreshPlaylistOfItem(widget.item.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Text(l10n.noMatch),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _query,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward_rounded), onPressed: _search),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder(
                  future: _results,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) return Center(child: Text(describeOnlineError(snap.error!)));
                    final (list, errors) = snap.data!;
                    return ListView(
                      children: [
                        for (final e in errors.entries)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.cloud_off_rounded),
                            title: Text('${e.key}: ${e.value}'),
                          ),
                        if (list.isEmpty) ListTile(title: Text(l10n.nothingFoundTryOtherWords)),
                        for (final c in list)
                          ListTile(
                            leading: Artwork(path: c.track.artworkPath, size: 44, seed: c.track.album),
                            title: Text(c.track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${c.track.displayArtist} · ${sourceLabel(c.track)}'
                                  '${c.track.durationMs > 0 ? ' · ${formatDuration(c.track.duration)}' : ''}'
                                  '${c.score.note == null ? '' : ' · ${c.score.note}'}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                ConfidenceChip(level: c.score.confidence, value: c.score.value),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () => _choose(c),
                            trailing: IconButton(
                              tooltip: l10n.listen,
                              icon: const Icon(Icons.play_circle_outline_rounded),
                              onPressed: () => playTracksAnywhere(ref, [c.track]),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

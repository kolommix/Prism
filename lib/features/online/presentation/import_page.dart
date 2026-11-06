import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/smooth_scroll.dart';
import '../../../core/router/app_router.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/led_dot.dart';
import '../../library/presentation/widgets/library_widgets.dart';
import '../../playlists/presentation/playlist_dialogs.dart';
import '../../player/presentation/widgets/waveform_seek_bar.dart';
import '../application/online_hub.dart';
import '../application/online_providers.dart';
import '../data/import_repository.dart';
import '../domain/external_track.dart';
import '../domain/import_parsers.dart';
import '../domain/link_parser.dart';
import '../domain/matching.dart';
import '../domain/online_error.dart';
import '../services/music_service_module.dart';
import 'terms_notes.dart';
import '../../../l10n/l10n.dart';

import '../../playlists/application/share_inbox.dart';
import '../../playlists/domain/playlist_share.dart';
void _toast(BuildContext context, String msg) =>
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 4)));

/// Runs [load] with a small blocking progress dialog; shows errors as a toast.
Future<T?> _withProgress<T>(BuildContext context, String label, Future<T> Function() load) async {
  final nav = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          const SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 3)),
          const SizedBox(width: 20),
          Expanded(child: Text(label)),
        ],
      ),
    ),
  );
  try {
    return await load();
  } on Object catch (e) {
    if (context.mounted) _toast(context, e is ImportFormatException ? e.message : describeOnlineError(e));
    return null;
  } finally {
    nav.pop();
  }
}

/// Playlists → Import: paste a link, pick a file, or browse connected
/// accounts. Everything goes through the preview before anything is saved.
class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  final _link = TextEditingController();

  /// What the box currently holds, understood (null = not a supported link).
  ParsedLink? _parsed;

  /// The link came from the clipboard (said under the box).
  bool _fromClipboard = false;

  @override
  void initState() {
    super.initState();
    _link.addListener(_onText);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkClipboard();
      _openInbox();
    });
    ref.listenManual(shareInboxProvider, (_, next) {
      if (next != null) _openInbox();
    });
  }

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  void _onText() {
    // Rebuild on every change: the hint and the clear button follow the text.
    setState(() => _parsed = _link.text.trim().isEmpty ? null : parseMusicLink(_link.text));
  }

  /// A copied playlist link is offered right away: one click to import.
  Future<void> _checkClipboard() async {
    try {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clip?.text?.trim() ?? '';
      final known = isSharedPlaylistText(text) || (text.length <= 500 && parseMusicLink(text) != null);
      if (!mounted || _link.text.isNotEmpty || !known) return;
      _link.text = text;
      setState(() => _fromClipboard = true);
    } on Object {
      // No clipboard access: the box simply stays empty.
    }
  }

  /// A shared playlist that came in from outside the app.
  void _openInbox() {
    final list = ref.read(shareInboxProvider.notifier).take();
    if (list != null) _preview([list]);
  }

  void _preview(List<ImportedList> lists) {
    if (lists.isEmpty || !mounted) return;
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ImportPreviewPage(lists: lists)));
  }

  Future<void> _openLink() async {
    if (isSharedPlaylistText(_link.text)) {
      try {
        _preview([decodeSharedPlaylist(_link.text)]);
      } on ShareFormatException catch (e) {
        _toast(context, e.message);
      }
      return;
    }
    final link = _parsed ?? parseMusicLink(_link.text);
    if (link == null) {
      _toast(context, l10n.pasteAPlaylistAlbumOrLikes);
      return;
    }
    final hub = ref.read(onlineHubProvider);
    final m = hub.module(link.service);
    if (m == null) {
      final st = hub.status(link.service);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(switch (st.state) {
          ModuleState.off => l10n.isTurnedOff(link.service.label),
          _ => '${link.service.label}: ${st.message ?? l10n.notAvailable}',
        }),
        action: SnackBarAction(label: l10n.setUp, onPressed: () => context.go(Routes.onlineServices)),
      ));
      return;
    }
    final list = await _withProgress(context, l10n.reading(link.service.label), () => m.openLink(link));
    if (list != null) _preview([list]);
  }

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(
      dialogTitle: l10n.importAPlaylistFile,
      type: FileType.custom,
      allowedExtensions: const ['csv', 'tsv', 'txt', 'json', 'm3u', 'm3u8', shareExtension],
    );
    if (file == null || !mounted) return;
    final lists = await _withProgress(context, l10n.reading(file.name), () async {
      final bytes = await file.readAsBytes();
      // Most exports are UTF-8; old M3U files are often Windows-1252.
      String text;
      try {
        text = utf8.decode(bytes);
      } on FormatException {
        text = latin1.decode(bytes);
      }
      return parseImportFile(file.path ?? file.name, text);
    });
    if (lists != null) _preview(lists);
  }

  /// "Spotify playlist", "YouTube likes"…
  static String _describe(ParsedLink l) => '${l.service.label} ${switch (l.kind) {
        LinkKind.playlist => l10n.playlist,
        LinkKind.album => l10n.album2,
        LinkKind.track => l10n.song,
        LinkKind.likes => l10n.likes,
        LinkKind.shortLink => l10n.link,
      }}';

  @override
  Widget build(BuildContext context) {
    ref.watch(onlineRevisionProvider);
    final hub = ref.watch(onlineHubProvider);
    final jobs = ref.watch(importJobsProvider).value ?? const [];
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final parsed = _parsed;
    final ready = parsed != null && hub.module(parsed.service) != null;
    final accounts = [
      for (final m in hub.modules)
        if (m.features.contains(ModuleFeature.login) &&
            (m.features.contains(ModuleFeature.myPlaylists) || m.features.contains(ModuleFeature.likes)))
          m,
    ];
    const linkServices = [
      OnlineService.spotify,
      OnlineService.youtube,
      OnlineService.soundcloud,
      OnlineService.deezer,
      OnlineService.appleMusic,
      OnlineService.yandex,
    ];

    final String hint;
    if (parsed == null) {
      hint = _link.text.trim().isEmpty
          ? l10n.playlistAlbumAndLikesLinksWork
          : (isSharedPlaylistText(_link.text) ? l10n.shareRecognized : l10n.notALinkPrismCanRead);
    } else if (!ready) {
      hint = l10n.needsToBeSetUpFirst(_describe(parsed), parsed.service.label);
    } else {
      hint = '${_describe(parsed)}${_fromClipboard ? l10n.fromYourClipboard : ''}';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(l10n.importPlaylists)),
      body: SmoothListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset(context)),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.bringYourPlaylistsFromSpotifyYoutube,
                  style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                // The one place to start: paste a link (or it is already
                // there from the clipboard), or pick an export file.
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _link,
                                onSubmitted: (_) => _openLink(),
                                onChanged: (_) => _fromClipboard = false,
                                decoration: InputDecoration(
                                  hintText: l10n.pasteALink,
                                  prefixIcon: const Icon(Icons.link_rounded, size: 20),
                                  suffixIcon: _link.text.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: l10n.clear,
                                          icon: const Icon(Icons.close_rounded, size: 18),
                                          onPressed: () {
                                            _link.clear();
                                            _fromClipboard = false;
                                          },
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              // Also for a service that is off: the snackbar offers set-up.
                              onPressed: parsed != null ? _openLink : null,
                              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                              child: Text(l10n.xImport),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: LedDot(on: ready),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                hint,
                                style: text.bodySmall?.copyWith(
                                  color: ready ? scheme.onSurface : scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(height: 1, color: scheme.onSurface.withValues(alpha: 0.08)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.orAFileCsvFromExportify,
                                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _pickFile,
                              icon: const Icon(Icons.upload_file_rounded, size: 18),
                              label: Text(l10n.chooseFile),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Which link sources work right now.
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    for (final s in linkServices)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LedDot(on: hub.module(s) != null, size: 5),
                          const SizedBox(width: 6),
                          Text(
                            s.label,
                            style: text.bodySmall?.copyWith(
                              color: hub.module(s) != null ? scheme.onSurface : scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    InkWell(
                      onTap: () => context.go(Routes.onlineServices),
                      child: Text(
                        l10n.setUpServices,
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                if (accounts.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(l10n.fromYourAccounts, style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  for (final m in accounts) _AccountImports(module: m, onPicked: _preview),
                ],
                if (jobs.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(l10n.yourImports, style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  for (final j in jobs) ImportJobTile(job: j),
                ],
                const SizedBox(height: 24),
                const TermsNotesTile(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Liked songs", "Saved albums" and "Playlists" of one connected account.
class _AccountImports extends ConsumerWidget {
  const _AccountImports({required this.module, required this.onPicked});
  final MusicServiceModule module;
  final void Function(List<ImportedList>) onPicked;

  Future<void> _pickFrom(
    BuildContext context,
    String title,
    Future<List<RemotePlaylistInfo>> Function() list, {
    bool album = false,
  }) async {
    final items = await _withProgress(context, l10n.loading(module.service.label), list);
    if (items == null || !context.mounted) return;
    final picked = await showModalBottomSheet<List<RemotePlaylistInfo>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => _PickListsSheet(title: title, items: items),
    );
    if (picked == null || picked.isEmpty || !context.mounted) return;
    final lists = await _withProgress(context, album ? l10n.readingNAlbums(picked.length) : l10n.readingNPlaylists(picked.length), () async {
      return [for (final p in picked) await module.fetchList(p, album: album)];
    });
    if (lists != null) onPicked(lists);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProvider(module.service));
    final f = module.features;
    final connected = account.value != null;
    return ExpansionTile(
      leading: const Icon(Icons.account_circle_rounded),
      title: Text(module.service.label),
      subtitle: Text(switch (account) {
        AsyncValue(:final value?) => value.name,
        AsyncValue(:final error?) => describeOnlineError(error),
        _ => l10n.notConnectedSettingsOnlineServices,
      }),
      children: !connected
          ? const []
          : [
              if (f.contains(ModuleFeature.likes))
                ListTile(
                  leading: const Icon(Icons.favorite_rounded),
                  title: Text(module.service == OnlineService.youtube ? l10n.likedVideos : l10n.likedSongs),
                  onTap: () async {
                    final l = await _withProgress(context, l10n.readingLikes, module.likedSongs);
                    if (l != null) onPicked([l]);
                  },
                ),
              if (f.contains(ModuleFeature.savedAlbums))
                ListTile(
                  leading: const Icon(Icons.album_rounded),
                  title: Text(l10n.savedAlbums),
                  onTap: () => _pickFrom(context, l10n.savedAlbums2, module.savedAlbums, album: true),
                ),
              if (f.contains(ModuleFeature.myPlaylists))
                ListTile(
                  leading: const Icon(Icons.queue_music_rounded),
                  title: Text(l10n.playlists),
                  onTap: () => _pickFrom(context, l10n.playlists2, module.myPlaylists),
                ),
            ],
    );
  }
}

class _PickListsSheet extends StatefulWidget {
  const _PickListsSheet({required this.title, required this.items});
  final String title;
  final List<RemotePlaylistInfo> items;

  @override
  State<_PickListsSheet> createState() => _PickListsSheetState();
}

class _PickListsSheetState extends State<_PickListsSheet> {
  final _picked = <String>{};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          children: [
            ListTile(
              title: Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
              trailing: FilledButton(
                onPressed: _picked.isEmpty
                    ? null
                    : () => Navigator.pop(context, widget.items.where((i) => _picked.contains(i.id)).toList()),
                child: Text(l10n.xImport2(_picked.length)),
              ),
            ),
            Expanded(
              child: widget.items.isEmpty
                  ? Center(child: Text(l10n.nothingHere))
                  : ListView.builder(
                      itemCount: widget.items.length,
                      itemBuilder: (_, i) {
                        final p = widget.items[i];
                        return CheckboxListTile(
                          value: _picked.contains(p.id),
                          onChanged: (v) => setState(() => v == true ? _picked.add(p.id) : _picked.remove(p.id)),
                          secondary: Artwork(
                            path: p.artworkUrl,
                            size: 44,
                            seed: p.name,
                            icon: Icons.queue_music_rounded,
                          ),
                          title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text([if (p.trackCount != null) l10n.nSongs(p.trackCount!), ?p.owner].join(' · ')),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row for one import job (on the import page).
class ImportJobTile extends ConsumerWidget {
  const ImportJobTile({super.key, required this.job});
  final ImportJob job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref.watch(importRunnerProvider);
    final running = run != null && run.jobId == job.id && run.running;
    final status = switch (job.state) {
      _ when running => l10n.matching(job.total - job.pending, job.total),
      ImportJobState.paused => '${l10n.pausedLeft(job.pending)}${job.message == null ? '' : ' · ${job.message}'}',
      ImportJobState.matching => l10n.stoppedLeftTapToResume(job.pending),
      ImportJobState.review => l10n.ofMatchedReadyToSave(job.matched, job.total),
      ImportJobState.done => l10n.ofMatchedSaved(job.matched, job.total),
    };
    return ListTile(
      leading: SizedBox(width: 40, child: Icon(running ? Icons.sync_rounded : Icons.playlist_add_check_rounded)),
      title: Text(job.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${job.origin.label} · $status', maxLines: 2, overflow: TextOverflow.ellipsis),
      onTap: () => context.go(Routes.importJob(job.id)),
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'delete' && await confirmDelete(context, l10n.thisImportThePlaylistStays)) {
            if (running) ref.read(importRunnerProvider.notifier).pause();
            await ref.read(importRepositoryProvider).deleteJob(job.id);
          }
        },
        itemBuilder: (_) => [PopupMenuItem(value: 'delete', child: Text(l10n.deleteImport))],
      ),
    );
  }
}

/// Preview before anything is saved: names, song lists, duplicates, and a
/// warning when the same link/file was imported before.
class ImportPreviewPage extends ConsumerStatefulWidget {
  const ImportPreviewPage({super.key, required this.lists});
  final List<ImportedList> lists;

  @override
  ConsumerState<ImportPreviewPage> createState() => _ImportPreviewPageState();
}

class _ImportPreviewPageState extends ConsumerState<ImportPreviewPage> {
  late final List<bool> _selected = List.filled(widget.lists.length, true);
  late final List<TextEditingController> _names = [for (final l in widget.lists) TextEditingController(text: l.name)];
  late final List<Map<int, int>> _dupes = [for (final l in widget.lists) findImportDuplicates(l.tracks)];
  final _earlier = <int, ImportJob>{};
  bool _skipDuplicates = true;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    final repo = ref.read(importRepositoryProvider);
    for (var i = 0; i < widget.lists.length; i++) {
      repo.jobForSource(widget.lists[i].sourceUrl).then((j) {
        if (j != null && mounted) setState(() => _earlier[i] = j);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    final repo = ref.read(importRepositoryProvider);
    final ids = <int>[];
    for (var i = 0; i < widget.lists.length; i++) {
      if (!_selected[i]) continue;
      final l = widget.lists[i];
      ids.add(
        await repo.createJob(
          ImportedList(
            name: _names[i].text.trim().isEmpty ? l.name : _names[i].text.trim(),
            origin: l.origin,
            tracks: l.tracks,
            sourceUrl: l.sourceUrl,
          ),
          skipDuplicates: _skipDuplicates,
        ),
      );
    }
    if (!mounted || ids.isEmpty) return;
    final runner = ref.read(importRunnerProvider.notifier);
    // One job at a time, in the background; the job page shows progress.
    () async {
      for (final id in ids) {
        await runner.run(id);
      }
    }();
    Navigator.of(context).pop();
    context.go(ids.length == 1 ? Routes.importJob(ids.single) : Routes.importPlaylists);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final hub = ref.watch(onlineHubProvider);
    final total = [
      for (var i = 0; i < widget.lists.length; i++)
        if (_selected[i]) widget.lists[i].tracks.length,
    ].fold(0, (a, b) => a + b);
    final dupeCount = [
      for (var i = 0; i < widget.lists.length; i++)
        if (_selected[i]) _dupes[i].length,
    ].fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(title: Text(widget.lists.length == 1 ? l10n.preview : l10n.previewNPlaylists(widget.lists.length))),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hub.playable.isEmpty)
                  ListTile(
                    leading: Icon(Icons.info_outline_rounded, color: scheme.tertiary),
                    title: Text(l10n.onlyYourLibraryWillBeSearched),
                    subtitle: Text(
                      l10n.turnOnYoutubePlaybackOrSoundcloud,
                    ),
                  ),
                if (dupeCount > 0)
                  SwitchListTile(
                    title: Text(l10n.skipDuplicates(dupeCount)),
                    subtitle: Text(l10n.sameSongTwiceInOneList),
                    value: _skipDuplicates,
                    onChanged: (v) => setState(() => _skipDuplicates = v),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < widget.lists.length; i++) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
                child: Row(
                  children: [
                    if (widget.lists.length > 1)
                      Checkbox(value: _selected[i], onChanged: (v) => setState(() => _selected[i] = v ?? false)),
                    Expanded(
                      child: TextField(
                        controller: _names[i],
                        style: text.titleMedium,
                        decoration: InputDecoration(
                          labelText: l10n.playlistName,
                          helperText:
                              '${l10n.songsFromOrigin(widget.lists[i].tracks.length, widget.lists[i].origin.label)}${_dupes[i].isEmpty ? '' : ' · ${l10n.nDuplicates(_dupes[i].length)}'}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_earlier[i] case final j?)
              SliverToBoxAdapter(
                child: ListTile(
                  leading: Icon(Icons.history_rounded, color: scheme.tertiary),
                  title: Text(l10n.importedBefore),
                  subtitle: Text(
                    l10n.ofMatchedImportingAgainMakesA(j.name, j.matched, j.total),
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go(Routes.importJob(j.id));
                    },
                    child: Text(l10n.open),
                  ),
                ),
              ),
            if (_selected[i])
              SliverList.builder(
                itemCount: widget.lists[i].tracks.length,
                itemBuilder: (_, k) {
                  final t = widget.lists[i].tracks[k];
                  final dup = _dupes[i][k];
                  return ListTile(
                    dense: true,
                    leading: SizedBox(
                      width: 32,
                      child: Text('${k + 1}', textAlign: TextAlign.center, style: text.bodySmall),
                    ),
                    title: Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: dup != null && _skipDuplicates
                          ? TextStyle(color: scheme.onSurfaceVariant, decoration: TextDecoration.lineThrough)
                          : null,
                    ),
                    subtitle: Text(
                      [
                        t.artist.isEmpty ? l10n.unknownArtist : t.artist,
                        if (t.album.isNotEmpty) t.album,
                        if (dup != null) l10n.duplicateOf(dup + 1),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: t.durationMs > 0
                        ? Text(formatDuration(Duration(milliseconds: t.durationMs)), style: text.labelSmall)
                        : null,
                  );
                },
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _starting || total == 0 ? null : _start,
        icon: const Icon(Icons.auto_fix_high_rounded),
        label: Text(l10n.matchNSongs(total)),
      ),
    );
  }
}

/// "High" / "Medium" / "Low – check it" badge.
class ConfidenceChip extends StatelessWidget {
  const ConfidenceChip({super.key, required this.level, this.value});
  final MatchConfidence level;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (level) {
      MatchConfidence.high => (scheme.primaryContainer, scheme.onPrimaryContainer),
      MatchConfidence.medium => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      MatchConfidence.low => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      MatchConfidence.none => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        value == null || level == MatchConfidence.none ? level.label : '${level.label} ${(value! * 100).round()}%',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

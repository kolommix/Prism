import 'dart:async';
import 'dart:io';

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
import '../application/import_flow.dart';
import '../application/online_providers.dart';
import '../data/import_repository.dart';
import 'import_job_page.dart';
import '../domain/external_track.dart';
import '../domain/import_intake.dart';
import '../domain/link_parser.dart';
import '../domain/matching.dart';
import '../domain/online_error.dart';
import '../services/music_service_module.dart';
import 'terms_notes.dart';
import '../../../l10n/l10n.dart';

import '../../playlists/application/share_inbox.dart';
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
    if (context.mounted) _toast(context, importProblemFor(e).message);
    return null;
  } finally {
    nav.pop();
  }
}

/// The one Import screen: paste a link, or drop or pick a file. The service is
/// worked out from what you give it. No preview step: the songs start arriving
/// in a playlist right away and the uncertain ones wait in Review.
class ImportPage extends ConsumerStatefulWidget {
  const ImportPage({super.key});

  @override
  ConsumerState<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends ConsumerState<ImportPage> {
  final _link = TextEditingController();
  late final AppLifecycleListener _lifecycle;

  /// Copied links already answered this session, so they aren't offered again.
  static final _handledClips = <String>{};

  /// What the box holds, understood.
  ImportInput _input = const UnknownInput();

  /// A playlist link found in the clipboard, offered with one tap.
  String? _clip;

  /// What is being read right now.
  String? _busy;

  /// What went wrong, and how to try the same thing again.
  ImportProblem? _problem;
  VoidCallback? _retry;

  bool _advancedOpen = false;

  /// Said "only my library" this session: not asked at every import.
  static bool _saidNoToDownloads = false;

  @override
  void initState() {
    super.initState();
    _link.addListener(_onText);
    _lifecycle = AppLifecycleListener(onResume: _checkClipboard);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkClipboard();
      _openInbox();
    });
    ref.listenManual(importInboxProvider, (_, next) {
      if (next.isNotEmpty) _openInbox();
    });
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _link.dispose();
    super.dispose();
  }

  void _onText() {
    // Rebuild on every change: the hint and the clear button follow the text.
    setState(() {
      _input = classifyImportText(_link.text);
      _problem = null;
    });
  }

  /// A copied playlist link is offered, never imported by itself.
  Future<void> _checkClipboard() async {
    try {
      final clip = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clip?.text?.trim() ?? '';
      if (!mounted || text.isEmpty || text.length > 16000 || _handledClips.contains(text)) return;
      final isList = switch (classifyImportText(text)) {
        SharedPlaylistInput() => true,
        ServiceLinkInput(:final link) => link.isList,
        _ => false,
      };
      if (!isList) {
        if (_clip != null) setState(() => _clip = null);
        return;
      }
      if (classifyImportText(text) case ServiceLinkInput(:final link)) {
        final earlier = await ref.read(importRepositoryProvider).jobForSource(link.canonicalUrl);
        if (earlier != null) return;
      }
      if (mounted) setState(() => _clip = text);
    } on Object {
      // No clipboard access: nothing to offer.
    }
  }

  void _dismissClip() {
    final c = _clip;
    if (c != null) _handledClips.add(c);
    setState(() => _clip = null);
  }

  /// Things that came from outside: share sheet, drag and drop, liner:// links.
  Future<void> _openInbox() async {
    for (final r in ref.read(importInboxProvider.notifier).takeAll()) {
      if (!mounted) return;
      if (r.fileName != null) {
        await _importFile(r.fileName!, r.fileText ?? '');
      } else {
        await _importText(r.text ?? '');
      }
    }
  }

  /// Reads, starts, and shows the result. Errors stay on this screen with a next step.
  Future<void> _run(String label, Future<List<ImportedList>> Function() read, {ParsedLink? link, VoidCallback? retry}) async {
    setState(() {
      _busy = label;
      _problem = null;
      _retry = retry;
    });
    try {
      final flow = ref.read(importFlowProvider);
      final lists = await read();
      if (!mounted) return;
      // Only asked once there is really something to import.
      if (!ref.read(onlineHubProvider).flags.importDownload && !_saidNoToDownloads) {
        if (!await askToDownload(context, ref)) _saidNoToDownloads = true;
        if (!mounted) return;
      }
      final ids = await flow.start(lists);
      if (!mounted) return;
      _link.clear();
      setState(() => _busy = null);
      if (ids.length == 1) context.go(Routes.importJob(ids.single));
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = null;
        _problem = importProblemFor(e, link: link);
        if (_problem!.step == ImportNextStep.advanced) _advancedOpen = true;
      });
    }
  }

  Future<void> _importText(String text) async {
    final flow = ref.read(importFlowProvider);
    final input = classifyImportText(text);
    final link = input is ServiceLinkInput ? input.link : null;
    await _run(
      l10n.reading(link?.service.label ?? l10n.link),
      () => flow.readText(text),
      link: link,
      retry: () => _importText(text),
    );
  }

  Future<void> _importFile(String name, String text) {
    final flow = ref.read(importFlowProvider);
    return _run(l10n.reading(name), () async => flow.readFile(name, text));
  }

  Future<void> _submit() async {
    if (_input is UnknownInput) return;
    await _importText(_link.text);
  }

  Future<void> _acceptClip() async {
    final c = _clip;
    if (c == null) return;
    _handledClips.add(c);
    setState(() => _clip = null);
    await _importText(c);
  }

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(
      dialogTitle: l10n.importAPlaylistFile,
      type: FileType.custom,
      allowedExtensions: importFileExtensions,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    await _importFile(file.path ?? file.name, decodeImportBytes(bytes));
  }

  void _startLists(List<ImportedList> lists) {
    if (lists.isNotEmpty) unawaited(_run(l10n.xImport, () async => lists));
  }

  Widget _box(BuildContext context, {required Widget child}) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(onlineRevisionProvider);
    final hub = ref.watch(onlineHubProvider);
    final jobs = ref.watch(importJobsProvider).value ?? const [];
    final review = ref.watch(importReviewProvider).value?.length ?? 0;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final input = _input;
    final empty = _link.text.trim().isEmpty;
    final known = input is! UnknownInput;
    final parsed = input is ServiceLinkInput ? input.link : null;
    final needsSetUp = parsed?.service == OnlineService.soundcloud && hub.module(OnlineService.soundcloud) == null;

    final String hint;
    if (empty) {
      hint = l10n.importSupported;
    } else if (input is SharedPlaylistInput) {
      hint = l10n.shareRecognized;
    } else if (input is FileInput) {
      hint = input.path;
    } else if (parsed == null) {
      hint = l10n.notALinkPrismCanRead;
    } else if (needsSetUp) {
      hint = l10n.importErrorNeedsKey(parsed.service.label);
    } else {
      hint = describeLink(parsed);
    }

    final clip = _clip;
    final clipLink = clip == null ? null : classifyImportText(clip);
    final busy = _busy;
    final problem = _problem;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(l10n.xImport)),
      body: SmoothListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset(context)),
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (clip != null) ...[
                  _box(
                    context,
                    child: Row(
                      children: [
                        Icon(Icons.content_paste_rounded, size: 20, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.importClipboardAsk, style: text.titleSmall),
                              const SizedBox(height: 2),
                              Text(
                                clipLink is ServiceLinkInput ? describeLink(clipLink.link) : l10n.shareRecognized,
                                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(onPressed: busy == null ? _acceptClip : null, child: Text(l10n.xImport)),
                        IconButton(
                          tooltip: l10n.close,
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: _dismissClip,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _box(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _link,
                              onSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                hintText: l10n.pasteALink,
                                prefixIcon: const Icon(Icons.link_rounded, size: 20),
                                suffixIcon: _link.text.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: l10n.clear,
                                        icon: const Icon(Icons.close_rounded, size: 18),
                                        onPressed: _link.clear,
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: known && busy == null ? _submit : null,
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
                            child: LedDot(on: known && !needsSetUp),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              hint,
                              style: text.bodySmall?.copyWith(
                                color: known && !needsSetUp ? scheme.onSurface : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.importDownloadSwitch, style: text.bodyMedium),
                                Text(
                                  l10n.importDownloadSwitchHint,
                                  style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Switch(
                            value: hub.flags.importDownload,
                            onChanged: (on) async {
                              if (on) {
                                _saidNoToDownloads = !await askToDownload(context, ref);
                                if (!_saidNoToDownloads) await ref.read(importFlowProvider).resumeAll();
                              } else {
                                await hub.setFlags(hub.flags.copyWith(importDownload: false));
                              }
                            },
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
                              Platform.isWindows ? l10n.importFileOrDrop : l10n.importFileHint,
                              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: busy == null ? _pickFile : null,
                            icon: const Icon(Icons.upload_file_rounded, size: 18),
                            label: Text(l10n.chooseFile),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (busy != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(busy, style: text.bodyMedium)),
                    ],
                  ),
                ],
                if (problem != null) ...[
                  const SizedBox(height: 12),
                  _box(
                    context,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(problem.message, style: text.bodyMedium),
                        if (problem.step != ImportNextStep.none) ...[
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: switch (problem.step) {
                              ImportNextStep.tryAgain => _retry,
                              ImportNextStep.chooseFile => _pickFile,
                              ImportNextStep.advanced => () => context.go(Routes.onlineServices),
                              ImportNextStep.none => null,
                            },
                            child: Text(switch (problem.step) {
                              ImportNextStep.tryAgain => l10n.tryAgain,
                              ImportNextStep.chooseFile => l10n.chooseFile,
                              _ => l10n.setUp,
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (review > 0) ...[
                  const SizedBox(height: 16),
                  Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: const SizedBox(width: 40, child: Icon(Icons.rule_rounded)),
                      title: Text(l10n.importReviewCount(review)),
                      subtitle: Text(l10n.importReviewHint),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.go(Routes.importReview),
                    ),
                  ),
                ],
                if (jobs.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(l10n.importRecent, style: text.titleSmall?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  for (final j in jobs) ImportJobTile(job: j),
                ],
                const SizedBox(height: 24),
                _AdvancedImport(
                  key: ValueKey(_advancedOpen),
                  open: _advancedOpen,
                  onPicked: _startLists,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Optional: accounts and keys, with the steps written out. Public links and
/// files never need anything here.
class _AdvancedImport extends ConsumerWidget {
  const _AdvancedImport({super.key, required this.open, required this.onPicked});
  final bool open;
  final void Function(List<ImportedList>) onPicked;

  static String _steps(OnlineService s) => switch (s) {
        OnlineService.spotify => l10n.importStepsSpotify,
        OnlineService.youtube => l10n.importStepsYoutube,
        OnlineService.soundcloud => l10n.importStepsSoundcloud,
        OnlineService.yandex => l10n.importStepsYandex,
        _ => '',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(onlineHubProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: ExpansionTile(
        initiallyExpanded: open,
        tilePadding: const EdgeInsets.symmetric(horizontal: 4),
        title: Text(l10n.importAdvanced, style: text.titleSmall),
        subtitle: Text(l10n.importAdvancedHint, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
        children: [
          for (final s in const [OnlineService.spotify, OnlineService.youtube, OnlineService.soundcloud, OnlineService.yandex])
            _AdvancedService(service: s, module: hub.module(s), steps: _steps(s), onPicked: onPicked),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.cloud_outlined, size: 18),
              label: Text(l10n.onlineServices),
              onPressed: () => context.go(Routes.onlineServices),
            ),
          ),
          const SizedBox(height: 8),
          const TermsNotesTile(),
        ],
      ),
    );
  }
}

class _AdvancedService extends ConsumerWidget {
  const _AdvancedService({required this.service, required this.module, required this.steps, required this.onPicked});
  final OnlineService service;
  final MusicServiceModule? module;
  final String steps;
  final void Function(List<ImportedList>) onPicked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = module;
    final canLogIn = m != null && m.features.contains(ModuleFeature.login);
    final connected = canLogIn && ref.watch(accountProvider(service)).value != null;
    if (connected) return _AccountImports(module: m, onPicked: onPicked);
    final text = Theme.of(context).textTheme;
    return ExpansionTile(
      leading: const Icon(Icons.account_circle_outlined),
      title: Text(service.label),
      subtitle: Text(l10n.importNotConnected),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      expandedAlignment: Alignment.centerLeft,
      children: [Text(steps, style: text.bodySmall)],
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

/// Row for one import: what happened, one tap to sync it with its source.
class ImportJobTile extends ConsumerStatefulWidget {
  const ImportJobTile({super.key, required this.job});
  final ImportJob job;

  @override
  ConsumerState<ImportJobTile> createState() => _ImportJobTileState();
}

class _ImportJobTileState extends ConsumerState<ImportJobTile> {
  bool _syncing = false;

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      await ref.read(importFlowProvider).resync(widget.job);
    } on Object catch (e) {
      if (mounted) _toast(context, importProblemFor(e).message);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final run = ref.watch(importRunnerProvider);
    final running = run != null && run.jobId == job.id && run.running;
    final status = switch (job.state) {
      _ when running => l10n.matching(job.total - job.pending, job.total),
      ImportJobState.paused => '${l10n.pausedLeft(job.pending)}${job.message == null ? '' : ' · ${job.message}'}',
      ImportJobState.matching => l10n.stoppedLeftTapToResume(job.pending),
      ImportJobState.review => l10n.ofMatchedReadyToSave(job.matched, job.total),
      ImportJobState.done => l10n.ofMatchedSaved(job.matched, job.total),
    };
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: SizedBox(width: 40, child: Icon(running ? Icons.sync_rounded : Icons.playlist_add_check_rounded)),
        title: Text(job.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${job.origin.label} · ${dateShort(job.updatedAt)} · $status',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () => context.go(Routes.importJob(job.id)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ImportFlow.canResync(job))
              IconButton(
                tooltip: l10n.importResync,
                icon: const Icon(Icons.sync_rounded),
                onPressed: _syncing || running ? null : _sync,
              ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'delete' && await confirmDelete(context, l10n.thisImportThePlaylistStays)) {
                  if (running) ref.read(importRunnerProvider.notifier).pause();
                  await ref.read(importRepositoryProvider).deleteJob(job.id);
                }
              },
              itemBuilder: (_) => [PopupMenuItem(value: 'delete', child: Text(l10n.deleteImport))],
            ),
          ],
        ),
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

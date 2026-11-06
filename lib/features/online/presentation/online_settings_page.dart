import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/motion/smooth_scroll.dart';
import '../../library/presentation/widgets/library_widgets.dart';
import '../application/online_hub.dart';
import '../application/online_providers.dart';
import '../domain/external_track.dart';
import '../domain/online_error.dart';
import '../services/music_service_module.dart';
import '../services/soundcloud/soundcloud_module.dart';
import '../services/spotify/spotify_module.dart';
import 'terms_notes.dart';
import '../../../l10n/l10n.dart';

import '../services/yandex/yandex_module.dart';
import 'yandex_token_dialog.dart';
void _toast(BuildContext context, String msg) =>
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 4)));

/// Settings → Online services: config file, one card per service (flag,
/// status, account), offline cache and the terms notes.
class OnlineSettingsPage extends ConsumerWidget {
  const OnlineSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(onlineRevisionProvider);
    final hub = ref.watch(onlineHubProvider);
    final text = Theme.of(context).textTheme;
    final config = hub.config;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(title, style: text.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(l10n.onlineServices)),
      body: SmoothListView(
        padding: EdgeInsets.only(bottom: bottomInset(context)),
        children: [
          ListTile(
            leading: const Icon(Icons.key_rounded),
            title: Text(l10n.apiKeysFile),
            subtitle: SelectableText(
              '${config.path ?? '-'}\n${l10n.keysLocalOnly}',
            ),
            isThreeLine: true,
          ),
          if (config.error != null)
            ListTile(
              leading: Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error),
              title: Text(config.error!),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.note_add_rounded),
                  label: Text(l10n.createFile),
                  onPressed: () async {
                    final path = await hub.configLoader.createTemplate();
                    await hub.reloadConfig();
                    if (context.mounted) _toast(context, l10n.templateAtFillInYourKeys(path));
                  },
                ),
                if (Platform.isWindows)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.folder_open_rounded),
                    label: Text(l10n.openFolder),
                    onPressed: () =>
                        launchUrl(Uri.file(File(config.path ?? hub.configLoader.defaultFile.path).parent.path)),
                  ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.reload),
                  onPressed: () async {
                    await hub.reloadConfig();
                    if (context.mounted) _toast(context, l10n.configReloaded);
                  },
                ),
              ],
            ),
          ),
          section(l10n.services),
          for (final s in const [
            OnlineService.spotify,
            OnlineService.youtube,
            OnlineService.soundcloud,
            OnlineService.deezer,
            OnlineService.appleMusic,
            OnlineService.yandex,
          ])
            _ServiceCard(service: s),
          section(l10n.offline),
          const _CacheSection(),
          section(l10n.terms),
          const TermsNotesTile(),
        ],
      ),
    );
  }
}

String _describe(OnlineService s) => switch (s) {
  OnlineService.spotify => l10n.importPlaylistsLikedSongsAndSaved,
  OnlineService.youtube => l10n.searchPlaylistsPlaybackYoutubeYoutubeMusic,
  OnlineService.soundcloud => l10n.searchLikesAndPlaylistsPlaybackWhere,
  OnlineService.deezer => l10n.importPublicPlaylistAlbumLinksNo,
  OnlineService.appleMusic => l10n.importPublicPlaylistAlbumLinksReads,
  OnlineService.yandex => l10n.yandexDescribe,
  OnlineService.file => '',
};

class _ServiceCard extends ConsumerStatefulWidget {
  const _ServiceCard({required this.service});
  final OnlineService service;

  @override
  ConsumerState<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends ConsumerState<_ServiceCard> {
  bool _busy = false;

  Future<void> _connect(MusicServiceModule m) async {
    if (m is YandexModule) {
      if (await showYandexTokenDialog(context, m)) ref.read(onlineHubProvider).notify();
      return;
    }
    setState(() => _busy = true);
    _toast(context, l10n.finishTheLoginInYourBrowser(widget.service.label));
    try {
      final a = await m.connect();
      if (mounted) _toast(context, l10n.connectedAs(a.name));
    } on Object catch (e) {
      if (mounted) _toast(context, describeOnlineError(e));
    } finally {
      ref.read(onlineHubProvider).notify();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setExtractor(OnlineHub hub, bool on) async {
    if (on) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(l10n.turnOnTheYoutubeExtractor),
          content: Text(
            l10n.thisPlaysYoutubeAudioInsidePrism,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l10n.iUnderstandTurnOn)),
          ],
        ),
      );
      if (ok != true) return;
    }
    await hub.setFlags(hub.flags.copyWith(youtubeExtractor: on));
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(onlineRevisionProvider);
    final hub = ref.watch(onlineHubProvider);
    final s = widget.service;
    final status = hub.status(s);
    final m = hub.module(s);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final account = m != null && m.features.contains(ModuleFeature.login) ? ref.watch(accountProvider(s)) : null;
    final personal = termsNotes.any((n) => n.service == s && n.personalUseOnly) && s != OnlineService.youtube;

    final (statusText, statusColor) = switch (status.state) {
      ModuleState.off => (l10n.xOff, scheme.onSurfaceVariant),
      ModuleState.notConfigured => (l10n.needsSetup(status.message ?? ''), scheme.tertiary),
      ModuleState.failed => (l10n.notWorking(status.message ?? ''), scheme.error),
      ModuleState.ready => (status.message ?? l10n.ready, scheme.primary),
    };

    String? redirect;
    if (m is SpotifyModule) redirect = m.redirectUri;
    if (m is SoundcloudModule) redirect = m.redirectUri;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(s.label, style: text.titleMedium),
                  if (personal) const PersonalUseChip(),
                ],
              ),
              subtitle: Text(_describe(s)),
              value: hub.flags.enabled(s),
              onChanged: (v) => hub.setFlags(hub.flags.withService(s, v)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(statusText, style: text.bodySmall?.copyWith(color: statusColor)),
            ),
            if (redirect != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.redirectUriToRegister(redirect), style: text.bodySmall)),
                    IconButton(
                      tooltip: l10n.copy,
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      onPressed: () => Clipboard.setData(ClipboardData(text: redirect!)),
                    ),
                  ],
                ),
              ),
            if (s == OnlineService.youtube && hub.flags.youtube)
              SwitchListTile(
                title: Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [Text(l10n.youtubeExtractor), PersonalUseChip()],
                ),
                subtitle: Text(l10n.playbackOfflineCopiesSearchWithoutAn),
                value: hub.flags.youtubeExtractor,
                onChanged: (v) => _setExtractor(hub, v),
              ),
            if (account != null)
              ListTile(
                leading: const Icon(Icons.account_circle_rounded),
                title: switch (account) {
                  AsyncValue(:final value?) => Text(
                    value.detail == null ? l10n.connectedAs(value.name) : l10n.connectedAsWithDetail(value.name, value.detail!),
                  ),
                  AsyncValue(:final error?) => Text(describeOnlineError(error), style: TextStyle(color: scheme.error)),
                  AsyncValue(isLoading: true) => Text(l10n.checking),
                  _ => Text(l10n.notConnected),
                },
                trailing: _busy
                    ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : (account.value != null
                          ? TextButton(
                              onPressed: () async {
                                await m!.disconnect();
                                hub.notify();
                              },
                              child: Text(l10n.disconnect),
                            )
                          : FilledButton(onPressed: () => _connect(m!), child: Text(l10n.connect))),
              ),
          ],
        ),
      ),
    );
  }
}

class _CacheSection extends ConsumerStatefulWidget {
  const _CacheSection();

  @override
  ConsumerState<_CacheSection> createState() => _CacheSectionState();
}

class _CacheSectionState extends ConsumerState<_CacheSection> {
  int? _size;
  int? _limit;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final s = await ref.read(streamCacheProvider).sizeBytes();
    if (mounted) setState(() => _size = s);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(onlineRevisionProvider);
    final hub = ref.watch(onlineHubProvider);
    final f = hub.flags;
    final mb = _size == null ? '…' : fmtNum((_size! / 1024 / 1024), 0);
    final limit = _limit ?? f.cacheLimitMb;
    return Column(
      children: [
        SwitchListTile(
          secondary: const Icon(Icons.download_for_offline_rounded),
          title: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [Text(l10n.keepPlayedSongsOffline), PersonalUseChip()],
          ),
          subtitle: Text(
            f.youtubeExtractor
                ? l10n.savesACopyOfYoutubeSongs
                : l10n.needsTheYoutubeExtractor,
          ),
          value: f.offlineCache,
          onChanged: f.youtubeExtractor ? (v) => hub.setFlags(f.copyWith(offlineCache: v)) : null,
        ),
        ListTile(
          leading: const Icon(Icons.storage_rounded),
          title: Text(l10n.offlineCopiesMbOfGb(mb, fmtNum((limit / 1024), 1))),
          subtitle: Slider(
            value: limit.toDouble().clamp(256, 20480),
            min: 256,
            max: 20480,
            divisions: 79,
            label: l10n.gb(fmtNum((limit / 1024), 1)),
            // Saved on release: changing flags rebuilds the modules.
            onChanged: (v) => setState(() => _limit = v.round()),
            onChangeEnd: (v) => hub.setFlags(f.copyWith(cacheLimitMb: v.round())),
          ),
          trailing: TextButton(
            onPressed: () async {
              await ref.read(streamCacheProvider).clear();
              await _refresh();
            },
            child: Text(l10n.clear),
          ),
        ),
      ],
    );
  }
}

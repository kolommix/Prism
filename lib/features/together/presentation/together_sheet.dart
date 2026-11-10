import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/spring_button.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/widgets/led_dot.dart';
import '../../settings/application/settings_controller.dart';
import '../application/together_controller.dart';
import '../data/nearby.dart';
import '../domain/together_protocol.dart';
import '../../../core/widgets/artwork.dart';
import '../../online/application/online_providers.dart';
import '../../player/application/player_providers.dart';
import '../../../l10n/l10n.dart';

/// Player-bar button; lit while a session is active.
class TogetherButton extends ConsumerWidget {
  const TogetherButton({super.key, this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(togetherProvider);
    final scheme = Theme.of(context).colorScheme;
    return SpringIconButton(
      tooltip: l10n.listenTogether,
      size: size,
      color: s.connected ? scheme.primary : scheme.onSurfaceVariant,
      onPressed: () => showTogetherSheet(context),
      icon: Icon(s.connected ? Icons.groups_rounded : Icons.group_add_outlined),
    );
  }
}

Future<void> showTogetherSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => const TogetherSheet(),
    );

/// Listen together in one sheet: start or join (a code, a pasted invite or a
/// session on this Wi-Fi), then who is here and how it goes for each.
class TogetherSheet extends ConsumerStatefulWidget {
  const TogetherSheet({super.key});

  @override
  ConsumerState<TogetherSheet> createState() => _TogetherSheetState();
}

class _TogetherSheetState extends ConsumerState<TogetherSheet> {
  final _code = TextEditingController();
  bool _copied = false;
  Timer? _copiedTimer;

  @override
  void initState() {
    super.initState();
    unawaited(_codeFromClipboard());
  }

  /// A friend just sent you the code? It's already filled in.
  Future<void> _codeFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final found = findJoinCode(data?.text);
      if (found != null && mounted && _code.text.isEmpty) setState(() => _code.text = found);
    } on Object {
      // No clipboard (tests, or it's busy).
    }
  }

  void _copy(String text) {
    unawaited(Clipboard.setData(ClipboardData(text: text)));
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _copiedTimer?.cancel();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(togetherProvider);
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: AnimatedSize(
          duration: context.motion.d(PrismMotion.medium),
          curve: PrismMotion.curve,
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.role == TogetherRole.guest && (s.hostName ?? '').isNotEmpty ? l10n.xWith(s.hostName!) : l10n.listenTogether,
                    style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.everyonePlaysTheSameSongAt, style: muted),
                  const SizedBox(height: 20),
                  ...switch (s.role) {
                    TogetherRole.host => _host(s),
                    TogetherRole.guest => _guest(s),
                    TogetherRole.none => _start(s),
                  },
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------ not in one

  List<Widget> _start(TogetherState s) {
    final ctrl = ref.read(togetherProvider.notifier);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return [
      const _NameField(),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: SpringButton(
          child: FilledButton.icon(
            onPressed: s.busy ? null : ctrl.host,
            icon: const Icon(Icons.podcasts_rounded),
            label: Text(l10n.startASession),
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text(l10n.togetherJoinTitle, style: text.labelLarge),
      const SizedBox(height: 8),
      const _NearbyList(),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              enabled: !s.busy,
              decoration: InputDecoration(hintText: l10n.friendSCode),
              onSubmitted: ctrl.join,
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: s.busy ? null : () => ctrl.join(_code.text),
            child: Text(l10n.join),
          ),
        ],
      ),
      if (s.status != null) ...[
        const SizedBox(height: 12),
        Row(
          children: [
            if (s.busy) ...[
              const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(s.status!, style: TextStyle(color: s.error ? scheme.error : scheme.onSurfaceVariant)),
            ),
          ],
        ),
      ],
      const SizedBox(height: 16),
      Text(l10n.eachPersonPlaysTheSongFrom, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
    ];
  }

  // ------------------------------------------------------------------ host

  List<Widget> _host(TogetherState s) {
    final ctrl = ref.read(togetherProvider.notifier);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final muted = text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    return [
      const _NowPlaying(),
      Text(l10n.sendThisCodeToYourFriends, style: text.labelLarge),
      const SizedBox(height: 6),
      Row(
        children: [
          Flexible(
            child: SelectableText(
              s.code ?? '',
              style: text.displaySmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: l10n.copy,
            icon: const Icon(Icons.copy_rounded),
            onPressed: () => _copy(s.code ?? ''),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          FilledButton.tonalIcon(
            onPressed: () => _copy(ctrl.inviteText()),
            icon: Icon(_copied ? Icons.check_rounded : Icons.ios_share_rounded),
            label: Text(_copied ? l10n.togetherInviteCopied : l10n.togetherCopyInvite),
          ),
          Text(s.overInternet ? l10n.worksFromAnywhere : l10n.worksOnThisWiFiOnly, style: muted),
        ],
      ),
      const SizedBox(height: 20),
      _People(people: s.who, empty: l10n.waitingForFriends),
      const SizedBox(height: 12),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.togetherFriendsControl),
        subtitle: Text(l10n.togetherFriendsControlHint),
        value: s.control,
        onChanged: ctrl.setGuestControl,
      ),
      const SizedBox(height: 12),
      FilledButton.tonalIcon(
        onPressed: ctrl.leave,
        icon: const Icon(Icons.stop_rounded),
        label: Text(l10n.endSession),
      ),
    ];
  }

  // ----------------------------------------------------------------- guest

  List<Widget> _guest(TogetherState s) {
    final ctrl = ref.read(togetherProvider.notifier);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final muted = text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final host = s.hostName ?? '';
    return [
      const _NowPlaying(),
      Text(s.status ?? '', style: muted),
      if (s.missingSong != null) ...[
        const SizedBox(height: 8),
        Text(l10n.missing(s.missingSong!), style: TextStyle(color: scheme.error)),
        const SizedBox(height: 2),
        if (ref.watch(onlineHubProvider).playable.isEmpty) ...[
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.travel_explore_rounded),
            label: Text(l10n.togetherFindOnYoutube),
            onPressed: () async {
              final hub = ref.read(onlineHubProvider);
              final ok = await showDialog<bool>(
                context: context,
                useRootNavigator: true,
                builder: (c) => AlertDialog(
                  title: Text(l10n.turnOnTheYoutubeExtractor),
                  content: Text(l10n.thisPlaysYoutubeAudioInsidePrism),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.cancel)),
                    FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l10n.iUnderstandTurnOn)),
                  ],
                ),
              );
              if (ok != true) return;
              await hub.setFlags(hub.flags.copyWith(youtubeExtractor: true));
              ctrl.findMissingOnline();
            },
          ),
        ] else
          Text(l10n.addTheSongToYourLibrary, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      ],
      const SizedBox(height: 16),
      _People(
        people: [
          if (host.isNotEmpty) SessionPerson('$host · ${l10n.togetherHostLabel}', PersonStatus.listening),
          ...s.who,
        ],
        empty: l10n.justYouAndTheHost,
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Icon(s.control ? Icons.touch_app_rounded : Icons.lock_outline_rounded, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              s.control ? l10n.togetherYouCanControl : l10n.togetherOnlyHostControls(host.isEmpty ? l10n.friend : host),
              style: muted,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      FilledButton.tonalIcon(
        onPressed: ctrl.leave,
        icon: const Icon(Icons.logout_rounded),
        label: Text(l10n.leave),
      ),
    ];
  }
}

class _NowPlaying extends ConsumerWidget {
  const _NowPlaying();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentTrackProvider);
    if (current == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Artwork(path: current.artworkPath, size: 44, seed: current.album),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(current.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyLarge),
                Text(current.displayArtist, maxLines: 1, overflow: TextOverflow.ellipsis, style: muted),
              ],
            ),
          ),
          if (ref.watch(isPlayingProvider)) const LedDot(on: true),
        ],
      ),
    );
  }
}

/// "Your name" right where it matters: friends see it in their list.
class _NameField extends ConsumerWidget {
  const _NameField();

  @override
  Widget build(BuildContext context, WidgetRef ref) => TextFormField(
        initialValue: ref.read(settingsProvider).togetherName,
        maxLength: 32,
        decoration: InputDecoration(
          labelText: l10n.yourNameInASession,
          hintText: l10n.theNameOfThisDevice,
          isDense: true,
          counterText: '',
          prefixIcon: const Icon(Icons.badge_outlined, size: 20),
        ),
        onChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(togetherName: v.trim())),
      );
}

class _People extends StatelessWidget {
  const _People({required this.people, required this.empty});

  final List<SessionPerson> people;
  final String empty;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    if (people.isEmpty) return Text(empty, style: muted);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final p in people)
          Chip(
            visualDensity: VisualDensity.compact,
            avatar: switch (p.status) {
              PersonStatus.listening => const LedDot(on: true),
              PersonStatus.finding => const SizedBox.square(dimension: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
              PersonStatus.missing => Icon(Icons.music_off_rounded, size: 16, color: scheme.error),
            },
            label: Text(switch (p.status) {
              PersonStatus.listening => p.name,
              PersonStatus.finding => '${p.name} · ${l10n.togetherStatusFinding}',
              PersonStatus.missing => '${p.name} · ${l10n.togetherStatusMissing}',
            }),
          ),
      ],
    );
  }
}

/// Sessions on this network: one click, no code.
class _NearbyList extends ConsumerWidget {
  const _NearbyList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(nearbySessionsProvider).value ?? const <NearbySession>[];
    if (list.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onThisNetwork, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          for (final n in list)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.podcasts_rounded),
              title: Text(n.name),
              subtitle: n.song.isEmpty
                  ? null
                  : Text(n.song, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurfaceVariant)),
              trailing: FilledButton.tonal(
                onPressed: () => ref.read(togetherProvider.notifier).join(n.room, direct: n.address),
                child: Text(l10n.join),
              ),
            ),
        ],
      ),
    );
  }
}

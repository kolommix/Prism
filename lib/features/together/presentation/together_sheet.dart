import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/spring_button.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/widgets/led_dot.dart';
import '../application/together_controller.dart';
import '../data/nearby.dart';
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
      builder: (_) => const _TogetherSheet(),
    );

class _TogetherSheet extends ConsumerStatefulWidget {
  const _TogetherSheet();

  @override
  ConsumerState<_TogetherSheet> createState() => _TogetherSheetState();
}

class _TogetherSheetState extends ConsumerState<_TogetherSheet> {
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

  void _copy(String code) {
    unawaited(Clipboard.setData(ClipboardData(text: code)));
    setState(() => _copied = true);
    _copiedTimer?.cancel();
    _copiedTimer = Timer(const Duration(seconds: 2), () {
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
    final ctrl = ref.read(togetherProvider.notifier);
    final current = ref.watch(currentTrackProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final muted = text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: AnimatedSize(
          duration: context.motion.d(PrismMotion.medium),
          curve: PrismMotion.curve,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.listenTogether, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(l10n.everyonePlaysTheSameSongAt, style: muted),
                const SizedBox(height: 20),
                if (s.role != TogetherRole.none && current != null) ...[
                  Row(
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
                      if (ref.watch(isPlayingProvider)) LedDot(on: true),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (s.role == TogetherRole.host) ...[
                  Text(l10n.sendThisCodeToYourFriends, style: text.labelLarge),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SelectableText(
                        s.code ?? '',
                        style: text.displaySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: _copied ? l10n.copied : l10n.copy,
                        icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded),
                        onPressed: () => _copy(s.code ?? ''),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.overInternet ? l10n.worksFromAnywhere : l10n.worksOnThisWiFiOnly,
                    style: muted,
                  ),
                  const SizedBox(height: 16),
                  _People(names: s.people, empty: l10n.waitingForFriends),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: ctrl.leave,
                    icon: const Icon(Icons.stop_rounded),
                    label: Text(l10n.endSession),
                  ),
                ] else if (s.role == TogetherRole.guest) ...[
                  Text(
                    s.hostName == null || s.hostName!.isEmpty ? l10n.session(s.code ?? '') : l10n.xWith(s.hostName!),
                    style: text.titleLarge,
                  ),
                  const SizedBox(height: 2),
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
                      Text(
                        l10n.addTheSongToYourLibrary,
                        style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                  ],
                  const SizedBox(height: 16),
                  _People(names: s.people, empty: l10n.justYouAndTheHost),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: ctrl.leave,
                    icon: const Icon(Icons.logout_rounded),
                    label: Text(l10n.leave),
                  ),
                ] else ...[
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(l10n.togetherOr, style: muted)),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SpringButton(
                    child: FilledButton.icon(
                      onPressed: s.busy ? null : ctrl.host,
                      icon: const Icon(Icons.podcasts_rounded),
                      label: Text(l10n.startASession),
                    ),
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
                  const SizedBox(height: 12),
                  Text(
                    l10n.eachPersonPlaysTheSongFrom,
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _People extends StatelessWidget {
  const _People({required this.names, required this.empty});

  final List<String> names;
  final String empty;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    if (names.isEmpty) return Text(empty, style: muted);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final n in names)
          Chip(
            visualDensity: VisualDensity.compact,
            avatar: const LedDot(on: true),
            label: Text(n),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.onThisNetwork, style: text.labelLarge),
          const SizedBox(height: 6),
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

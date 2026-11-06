import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/led_dot.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/presentation/settings_widgets.dart';
import '../application/desktop_extras.dart';
import '../data/discord_ipc.dart';
import '../../../l10n/l10n.dart';

/// Rows of the Discord status in Settings → Windows.
class DiscordSettings extends ConsumerStatefulWidget {
  const DiscordSettings({super.key});

  @override
  ConsumerState<DiscordSettings> createState() => _DiscordSettingsState();
}

class _DiscordSettingsState extends ConsumerState<DiscordSettings> {
  late final TextEditingController _id;
  Timer? _clipboardWatch;
  bool _ownId = false;

  @override
  void initState() {
    super.initState();
    _id = TextEditingController(text: ref.read(settingsProvider).discordClientId);
  }

  void _save(String v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(discordClientId: v.trim()));

  /// Opens the Discord page and picks the id up from the clipboard by itself
  /// as soon as it is copied there.
  Future<void> _setUp() async {
    await launchUrl(Uri.parse('https://discord.com/developers/applications'));
    _clipboardWatch?.cancel();
    var left = 300;
    _clipboardWatch = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (--left <= 0 || !mounted) {
        t.cancel();
        return;
      }
      final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim() ?? '';
      if (RegExp(r'^\d{17,20}$').hasMatch(text) && mounted) {
        t.cancel();
        _id.text = text;
        _save(text);
      }
    });
  }

  @override
  void dispose() {
    _clipboardWatch?.cancel();
    _id.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final status = ref.watch(discordStatusProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    const builtIn = prismDiscordClientId != '';
    final needsSetup = !builtIn && settings.discordClientId.trim().isEmpty;

    final (statusText, on) = switch (status.link) {
      DiscordLink.connected => (status.user == null ? l10n.connectedToDiscord : l10n.connectedAs(status.user ?? ''), true),
      DiscordLink.notRunning => (l10n.discordIsnTRunningItConnects, false),
      DiscordLink.badId => (l10n.discordDidnTAcceptThisApplication, false),
      DiscordLink.needsId => (l10n.oneSetupStepLeft, false),
      DiscordLink.off => (l10n.connecting, false),
    };

    return Column(
      children: [
        SettingsSwitch(
          icon: Icons.discord_outlined,
          title: l10n.discordStatus,
          subtitle: l10n.songAlbumArtProgressLinksAnd,
          value: settings.discordPresence,
          onChanged: (v) => ctrl.update((s) => s.copyWith(discordPresence: v)),
        ),
        if (settings.discordPresence) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(52, 0, 16, 16),
            child: Row(
              children: [
                LedDot(on: on),
                if (on) const SizedBox(width: 8),
                Expanded(child: Text(statusText, style: muted)),
              ],
            ),
          ),
          SettingsSwitch(
            icon: Icons.image_search_rounded,
            title: l10n.findAlbumArt,
            subtitle: l10n.sendsTitleAndArtistToApple,
            value: settings.discordCovers,
            onChanged: (v) => ctrl.update((s) => s.copyWith(discordCovers: v)),
          ),
          if (needsSetup)
            Padding(
              padding: const EdgeInsets.fromLTRB(52, 4, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.discordNeedsAnApplicationToShow,
                    style: muted,
                  ),
                  const SizedBox(height: 10),
                  FilledButton.tonalIcon(
                    onPressed: _setUp,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: Text(l10n.openTheDiscordPage),
                  ),
                ],
              ),
            ),
          if (needsSetup || _ownId || settings.discordClientId.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(52, 0, 16, 16),
              child: TextField(
                controller: _id,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: l10n.applicationId, isDense: true),
                onChanged: _save,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(44, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _ownId = true),
                  child: Text(l10n.useMyOwnApplication),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

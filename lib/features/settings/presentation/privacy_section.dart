import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/l10n.dart';
import 'settings_widgets.dart';

/// Settings → Privacy: the same list as docs/PRIVACY.md. A new permission goes
/// here and there first, or `tool/privacy_check.dart` fails the build.
class PrivacySection extends StatelessWidget {
  const PrivacySection({super.key});

  static final _full = Uri.parse('https://github.com/kolommix/Prism/blob/main/docs/PRIVACY.md');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroup(
          children: [
            SettingsTile(
              icon: Icons.location_off_outlined,
              title: l10n.privacyNoLocationTitle,
              subtitle: l10n.privacyNoLocationText,
            ),
            SettingsTile(
              icon: Icons.desktop_windows_outlined,
              title: l10n.privacyWindowsTitle,
              subtitle: l10n.privacyWindowsText,
            ),
          ],
        ),
        SettingsGroup(
          title: l10n.privacyPermsTitle,
          footer: l10n.privacyPermsFooter,
          children: [
            SettingsTile(icon: Icons.library_music_outlined, title: l10n.privacyPermMusic, subtitle: l10n.privacyPermMusicWhy),
            SettingsTile(icon: Icons.play_circle_outline_rounded, title: l10n.privacyPermPlayback, subtitle: l10n.privacyPermPlaybackWhy),
            SettingsTile(icon: Icons.notifications_none_rounded, title: l10n.privacyPermNotify, subtitle: l10n.privacyPermNotifyWhy),
            SettingsTile(icon: Icons.language_rounded, title: l10n.privacyPermInternet, subtitle: l10n.privacyPermInternetWhy),
            SettingsTile(icon: Icons.mic_none_rounded, title: l10n.privacyPermMic, subtitle: l10n.privacyPermMicWhy),
            SettingsTile(icon: Icons.music_note_outlined, title: l10n.privacyPermRingtone, subtitle: l10n.privacyPermRingtoneWhy),
          ],
        ),
        SettingsGroup(
          title: l10n.privacySentTitle,
          footer: l10n.privacySentFooter,
          children: [
            SettingsTile(icon: Icons.update_rounded, title: l10n.privacySentUpdates, subtitle: l10n.privacySentUpdatesWhat),
            SettingsTile(icon: Icons.image_search_rounded, title: l10n.privacySentInfo, subtitle: l10n.privacySentInfoWhat),
            SettingsTile(icon: Icons.lyrics_outlined, title: l10n.privacySentLyrics, subtitle: l10n.privacySentLyricsWhat),
            SettingsTile(icon: Icons.font_download_outlined, title: l10n.privacySentFonts, subtitle: l10n.privacySentFontsWhat),
            SettingsTile(icon: Icons.playlist_add_rounded, title: l10n.privacySentImport, subtitle: l10n.privacySentImportWhat),
            SettingsTile(icon: Icons.cloud_outlined, title: l10n.privacySentOnline, subtitle: l10n.privacySentOnlineWhat),
            SettingsTile(icon: Icons.manage_search_rounded, title: l10n.privacySentFixer, subtitle: l10n.privacySentFixerWhat),
            SettingsTile(icon: Icons.groups_outlined, title: l10n.privacySentTogether, subtitle: l10n.privacySentTogetherWhat),
            SettingsTile(icon: Icons.chat_bubble_outline_rounded, title: l10n.privacySentDiscord, subtitle: l10n.privacySentDiscordWhat),
          ],
        ),
        SettingsGroup(
          children: [
            SettingsTile(
              icon: Icons.open_in_new_rounded,
              title: l10n.privacyFullText,
              onTap: () => launchUrl(_full, mode: LaunchMode.externalApplication),
            ),
          ],
        ),
      ],
    );
  }
}

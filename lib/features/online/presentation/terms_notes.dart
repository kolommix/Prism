import 'package:flutter/material.dart';

import '../domain/external_track.dart';
import '../../../l10n/l10n.dart';

/// What each service allows, in plain words. Same text as README → Online
/// services. "Personal use only" marks features that go beyond what the
/// service officially offers.
class TermsNote {
  const TermsNote(this.service, this.title, this.text, {this.personalUseOnly = false});
  final OnlineService service;
  final String title;
  final String text;
  final bool personalUseOnly;
}

List<TermsNote> get termsNotes => [
  TermsNote(OnlineService.yandex, l10n.yandexTermsTitle, l10n.yandexTermsText, personalUseOnly: true),
  TermsNote(
    OnlineService.spotify,
    l10n.spotifyImportOnlyNeverAudio,
    l10n.usesTheOfficialWebApiTo,
    personalUseOnly: true,
  ),
  TermsNote(
    OnlineService.youtube,
    l10n.youtubeDataApiOfficial,
    l10n.searchPlaylistsAndWithGoogleLogin,
  ),
  TermsNote(
    OnlineService.youtube,
    l10n.youtubeExtractorPlaybackAndOfflineCopies,
    l10n.playsYoutubeAudioInsidePrismSearches,
    personalUseOnly: true,
  ),
  TermsNote(
    OnlineService.soundcloud,
    l10n.soundcloudOfficialApi,
    l10n.searchYourLikesAndPlaylistsThrough,
  ),
  TermsNote(
    OnlineService.deezer,
    l10n.deezerPublicPlaylistLinks,
    l10n.readsPublicPlaylistsAlbumsAndSongs,
  ),
  TermsNote(
    OnlineService.appleMusic,
    l10n.appleMusicPublicPageReading,
    l10n.appleHasNoFreeApiSo,
    personalUseOnly: true,
  ),
];

class PersonalUseChip extends StatelessWidget {
  const PersonalUseChip({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(8)),
      child: Text(
        l10n.personalUseOnly,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onTertiaryContainer),
      ),
    );
  }
}

/// Expandable list of all notes.
class TermsNotesTile extends StatelessWidget {
  const TermsNotesTile({super.key, this.initiallyExpanded = false});
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ExpansionTile(
      leading: const Icon(Icons.gavel_rounded),
      title: Text(l10n.whatEachServiceAllows),
      subtitle: Text(l10n.termsOfServiceLimitsInPlain),
      initiallyExpanded: initiallyExpanded,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        for (final n in termsNotes)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(n.title, style: text.titleSmall),
                    if (n.personalUseOnly) const PersonalUseChip(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(n.text, style: text.bodySmall),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Text(
          l10n.prismIsAPersonalPlayerFor,
          style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

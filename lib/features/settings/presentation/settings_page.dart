import '../../../core/app_version.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/motion/smooth_scroll.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/widgets/led_dot.dart';
import '../../audio_fx/application/eq_controller.dart';
import '../../audio_fx/application/loudness_controller.dart';
import '../../audio_fx/domain/loudness.dart';
import '../../desktop/presentation/discord_settings.dart';
import '../../library/application/auto_tagger.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/library_models.dart';
import '../../library/presentation/add_folder.dart';
import '../../library/presentation/widgets/library_widgets.dart';
import '../../player/domain/seek_bar_style.dart';
import '../../player/presentation/widgets/waveform_seek_bar.dart';
import '../../onboarding/presentation/welcome_tour.dart';
import '../../shell/presentation/prism_logo.dart';
import '../../tools/presentation/tools_section.dart';
import '../../visualizer/presentation/visualizer.dart';
import '../application/settings_controller.dart';
import 'settings_widgets.dart';
import '../../../l10n/l10n.dart';

import '../../visualizer/data/live_fft.dart';
import '../domain/app_settings.dart';
import 'color_picker.dart';
import '../../library/presentation/removed_songs.dart';
import 'privacy_section.dart';
import '../../update/update_check.dart';
/// The settings categories, in the order they are listed.
enum SettingsSection {
  library(Icons.library_music_outlined),
  playback(Icons.graphic_eq_rounded),
  appearance(Icons.contrast_rounded),
  online(Icons.cloud_outlined),
  together(Icons.groups_outlined),
  windows(Icons.desktop_windows_outlined),
  backup(Icons.save_alt_rounded),
  privacy(Icons.shield_outlined),
  about(Icons.info_outline_rounded);

  const SettingsSection(this.icon);
  final IconData icon;

  String get label => switch (this) {
        SettingsSection.library => l10n.xLibrary,
        SettingsSection.playback => l10n.playback,
        SettingsSection.appearance => l10n.appearance,
        SettingsSection.online => l10n.onlineImport,
        SettingsSection.together => l10n.listenTogether,
        SettingsSection.windows => l10n.windows,
        SettingsSection.backup => l10n.backup,
        SettingsSection.privacy => l10n.privacy,
        SettingsSection.about => l10n.about,
      };

  static List<SettingsSection> get visible => [
        for (final s in values)
          if (s != windows || Platform.isWindows) s,
      ];
}

class _SelectedSection extends Notifier<SettingsSection> {
  @override
  SettingsSection build() => SettingsSection.library;
  void select(SettingsSection s) => state = s;
}

/// Which category the wide two-pane settings shows (kept while switching tabs).
final selectedSettingsSectionProvider =
    NotifierProvider<_SelectedSection, SettingsSection>(_SelectedSection.new);

/// Settings home.
///
/// * Wide: categories on the left, the chosen one on the right.
/// * Narrow (phone): the list of categories; each opens its own page.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, title: Text(l10n.settings)),
      body: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth < 720) {
            return SmoothListView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset(context)),
              children: [
                SettingsGroup(
                  children: [
                    for (final s in SettingsSection.visible)
                      SettingsTile(
                        icon: s.icon,
                        title: s.label,
                        subtitle: _summary(ref, s),
                        chevron: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(builder: (_) => _SectionPage(section: s)),
                        ),
                      ),
                  ],
                ),
              ],
            );
          }
          final selected = ref.watch(selectedSettingsSectionProvider);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 232,
                child: SmoothListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 24),
                  children: [
                    for (final s in SettingsSection.visible)
                      _CategoryRow(
                        section: s,
                        selected: s == selected,
                        onTap: () => ref.read(selectedSettingsSectionProvider.notifier).select(s),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: context.motion.d(PrismMotion.medium),
                  switchInCurve: PrismMotion.curve,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.015), end: Offset.zero).animate(a),
                      child: child,
                    ),
                  ),
                  child: Align(
                    key: ValueKey(selected),
                    alignment: Alignment.topLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: _SectionBody(section: selected, padding: EdgeInsets.fromLTRB(16, 8, 24, bottomInset(context))),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One-line state of a category, shown under its name on phones.
String? _summary(WidgetRef ref, SettingsSection s) {
  final settings = ref.watch(settingsProvider);
  return switch (s) {
    SettingsSection.library => () {
        final folders = ref.watch(libraryFoldersProvider).value?.length ?? 0;
        final songs = ref.watch(tracksProvider.select((v) => v.value?.length)) ?? 0;
        return '${l10n.nFolders(folders)} · ${l10n.nSongs(songs)}';
      }(),
    SettingsSection.playback =>
      '${settings.crossfadeSeconds == 0 ? l10n.gapless : l10n.crossfadeN(settings.crossfadeSeconds)} · ${ref.watch(eqControllerProvider.select((e) => e.settings.enabled)) ? l10n.eqOn : l10n.eqOff}',
    SettingsSection.appearance => settings.theme.name,
    SettingsSection.online => l10n.importPlaylistsAccountsOfflineCopies,
    SettingsSection.together => settings.togetherInternet || settings.relayUrl.isNotEmpty ? l10n.anywhere : l10n.sameWiFiOnly,
    SettingsSection.windows => settings.closeToTray ? l10n.closesToTheTray : null,
    SettingsSection.backup => l10n.saveOrRestoreEverythingInOne,
    SettingsSection.privacy => l10n.privacyNoLocationTitle,
    SettingsSection.about => null,
  };
}

class _CategoryRow extends StatefulWidget {
  const _CategoryRow({required this.section, required this.selected, required this.onTap});

  final SettingsSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = widget.selected || _hover;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: context.motion.d(PrismMotion.short),
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: widget.selected ? 0.08 : (_hover ? 0.04 : 0)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(widget.section.icon, size: 20, color: on ? scheme.onSurface : scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.section.label,
                    style: TextStyle(fontSize: 14, color: on ? scheme.onSurface : scheme.onSurfaceVariant),
                  ),
                ),
                LedDot(on: widget.selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Phone: one category on its own page.
class _SectionPage extends StatelessWidget {
  const _SectionPage({required this.section});

  final SettingsSection section;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(section.label)),
        body: _SectionBody(section: section, padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset(context))),
      );
}

class _SectionBody extends ConsumerWidget {
  const _SectionBody({required this.section, required this.padding});

  final SettingsSection section;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = switch (section) {
      SettingsSection.library => _library(context, ref),
      SettingsSection.playback => _playback(context, ref),
      SettingsSection.appearance => _appearance(context, ref),
      SettingsSection.online => _online(context),
      SettingsSection.together => _together(ref),
      SettingsSection.windows => _windows(ref),
      SettingsSection.backup => _backup(context, ref),
      SettingsSection.privacy => const [PrivacySection()],
      SettingsSection.about => _about(context, ref),
    };
    return SmoothListView(padding: padding, children: children);
  }

  List<Widget> _library(BuildContext context, WidgetRef ref) {
    final folders = ref.watch(libraryFoldersProvider).value ?? const [];
    final scan = ref.watch(scanControllerProvider);
    final scanning = scan != null && scan is! ScanFinished;
    final songs = ref.watch(tracksProvider.select((v) => v.value?.length)) ?? 0;
    return [
      SettingsGroup(
        title: l10n.musicFolders,
        footer: l10n.musicFoldersIntro(songs),
        children: [
          for (final f in folders)
            SettingsTile(
              icon: Icons.folder_outlined,
              title: f,
              trailing: IconButton(
                tooltip: l10n.removeFolder,
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () => ref.read(scanControllerProvider.notifier).removeFolder(f),
              ),
            ),
          SettingsTile(
            icon: Icons.add_rounded,
            title: l10n.addFolder,
            enabled: !scanning,
            onTap: () => addLibraryFolder(context, ref),
          ),
          if ((ref.watch(removedTracksProvider).value ?? const []).isNotEmpty)
            SettingsTile(
              icon: Icons.remove_circle_outline_rounded,
              title: l10n.removedSongs,
              subtitle: l10n.removedSongsCount(ref.watch(removedTracksProvider).value!.length),
              chevron: true,
              onTap: () => showRemovedSongs(context),
            ),
        ],
      ),
      const _AutoFindGroup(),
      SettingsGroup(
        children: [
          SettingsTile(
            icon: Icons.refresh_rounded,
            title: l10n.rescanLibrary,
            subtitle: switch (scan) {
              ScanFinished(:final added, :final updated, :final removed, :final took) =>
                l10n.lastScanNewChangedRemovedIn(added, updated, removed, fmtNum((took.inMilliseconds / 1000), 1)),
              _ => l10n.onlyNewOrChangedFilesAre,
            },
            enabled: !scanning,
            onTap: () => ref.read(scanControllerProvider.notifier).rescanAll(),
          ),
          if (scanning) const ScanBanner(),
          SettingsTile(
            icon: Icons.content_copy_outlined,
            title: l10n.findDuplicates,
            subtitle: l10n.theSameSongInSeveralFiles,
            chevron: true,
            onTap: () => context.go(Routes.duplicates),
          ),
        ],
      ),
    ];
  }

  List<Widget> _playback(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final eq = ref.watch(eqControllerProvider.select((e) => e.settings));
    final fade = settings.crossfadeSeconds;
    return [
      SettingsGroup(
        title: l10n.sound,
        children: [
          SettingsTile(
            icon: Icons.equalizer_rounded,
            title: l10n.equalizer,
            trailing: SettingsValue(eq.enabled ? eq.presetName : l10n.xOff),
            chevron: true,
            onTap: () => context.go(Routes.equalizer),
          ),
          SettingsTile(
            icon: Icons.compare_arrows_rounded,
            title: l10n.crossfade,
            subtitle: l10n.blendTheEndOfASong,
            trailing: SettingsValue(fade == 0 ? l10n.offGapless : l10n.secondsValue(fade)),
          ),
          SettingsControl(
            child: Slider(
              value: fade.toDouble(),
              max: 12,
              divisions: 12,
              onChanged: (v) => ctrl.update((s) => s.copyWith(crossfadeSeconds: v.round())),
            ),
          ),
        ],
      ),
      const _LoudnessGroup(),
      SettingsGroup(
        title: l10n.lyrics,
        footer: l10n.sendsOnlyTitleArtistAlbumAnd,
        children: [
          SettingsSwitch(
            icon: Icons.lyrics_outlined,
            title: l10n.findLyricsOnline,
            value: settings.onlineLyrics,
            onChanged: (v) => ctrl.update((s) => s.copyWith(onlineLyrics: v)),
          ),
        ],
      ),
    ];
  }

  List<Widget> _appearance(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final style = VisualizerStyle.parse(settings.visualizerStyle);
    return [
      SettingsGroup(
        children: [
          SettingsTile(
            icon: Icons.translate_rounded,
            title: l10n.langTitle,
            trailing: DropdownButton<String>(
              value: settings.localeCode,
              underline: const SizedBox.shrink(),
              items: [
                DropdownMenuItem(value: '', child: Text(l10n.langSystem)),
                DropdownMenuItem(value: 'en', child: Text(l10n.langEnglish)),
                DropdownMenuItem(value: 'ru', child: Text(l10n.langRussian)),
              ],
              onChanged: (v) => ctrl.update((s) => s.copyWith(localeCode: v ?? '')),
            ),
          ),
          SettingsTile(
            icon: Icons.palette_outlined,
            title: l10n.theme,
            trailing: SettingsValue(settings.theme.name),
            chevron: true,
            onTap: () => context.go(Routes.themeEditor),
          ),
          SettingsTile(
            icon: Icons.blur_on_rounded,
            title: l10n.background,
            subtitle: l10n.bgStylesSubtitle,
            trailing: SettingsValue(settings.background.current.label),
            chevron: true,
            onTap: () => context.go(Routes.background),
          ),
          SettingsTile(
            icon: Icons.graphic_eq_rounded,
            title: l10n.visualizer,
            subtitle: l10n.shownInTheFullPlayer,
            trailing: DropdownButton<VisualizerStyle>(
              value: style,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(10),
              items: [for (final s in VisualizerStyle.values) DropdownMenuItem(value: s, child: Text(s.label))],
              onChanged: (s) {
                if (s != null) ctrl.update((x) => x.copyWith(visualizerStyle: s.name));
              },
            ),
          ),
          SettingsTile(
            icon: Icons.tune_rounded,
            title: l10n.vizSensitivity,
            trailing: SizedBox(
              width: 180,
              child: Slider(
                value: settings.visualizerSensitivity.clamp(0.5, 2.0),
                min: 0.5,
                max: 2,
                onChanged: (v) => ctrl.update((s) => s.copyWith(visualizerSensitivity: v)),
              ),
            ),
          ),
          SettingsSwitch(
            icon: Icons.battery_saver_outlined,
            title: l10n.vizLowPower,
            subtitle: l10n.vizLowPowerHint,
            value: settings.visualizerLowPower,
            onChanged: (v) => ctrl.update((s) => s.copyWith(visualizerLowPower: v)),
          ),
          if (LiveFft.supported)
            SettingsSwitch(
              icon: Icons.mic_none_rounded,
              title: l10n.vizLive,
              subtitle: l10n.vizLiveHint,
              value: settings.visualizerLive,
              onChanged: (v) async {
                if (v && !await LiveFft.hasPermission() && context.mounted) {
                  // Say why before Android's own question about the microphone.
                  final go = await showDialog<bool>(
                    context: context,
                    useRootNavigator: true,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.vizLiveAskTitle),
                      content: Text(l10n.vizLiveAskText),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.privacyContinue)),
                      ],
                    ),
                  );
                  if (go != true) return;
                }
                if (v && !await LiveFft.requestPermission()) {
                  if (context.mounted) {
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(l10n.vizLiveRefused)));
                  }
                  return;
                }
                ctrl.update((s) => s.copyWith(visualizerLive: v));
              },
            ),
          SettingsSwitch(
            icon: Icons.motion_photos_off_outlined,
            title: l10n.reduceMotion,
            subtitle: l10n.turnsOffDecorativeAnimations,
            value: settings.reduceMotion,
            onChanged: (v) => ctrl.update((s) => s.copyWith(reduceMotion: v)),
          ),
        ],
      ),
      SettingsGroup(
        title: l10n.seekBar,
        footer: l10n.rightClickTheSeekBarTo,
        children: [
          SettingsSwitch(
            icon: Icons.graphic_eq_rounded,
            title: l10n.movesWithTheMusic,
            subtitle: l10n.everyStyleReactsToTheSong,
            value: settings.liveSeekBar,
            onChanged: (v) => ctrl.update((x) => x.copyWith(liveSeekBar: v)),
          ),
          for (final s in SeekBarStyle.values)
            _SeekStyleRow(
              style: s,
              selected: s == SeekBarStyle.parse(settings.seekBarStyle),
              live: settings.liveSeekBar,
              onTap: () => ctrl.update((x) => x.copyWith(seekBarStyle: s.name)),
              look: settings.seekBarLook,
            ),
        ],
      ),
      const _SeekBarCustomGroup(),
    ];
  }

  List<Widget> _online(BuildContext context) => [
        SettingsGroup(
          children: [
            SettingsTile(
              icon: Icons.playlist_add_rounded,
              title: l10n.importPlaylists,
              subtitle: l10n.importOneScreenHint,
              chevron: true,
              onTap: () => context.go(Routes.importPlaylists),
            ),
            SettingsTile(
              icon: Icons.cloud_outlined,
              title: l10n.onlineServices,
              subtitle: l10n.spotifyYoutubeSoundcloudDeezerAppleMusic,
              chevron: true,
              onTap: () => context.go(Routes.onlineServices),
            ),
          ],
        ),
      ];

  List<Widget> _together(WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    return [
      SettingsGroup(
        footer: l10n.sessionsOnTheSameWiFi,
        children: [
          SettingsSwitch(
            icon: Icons.public_rounded,
            title: l10n.sessionsOverTheInternet,
            subtitle: l10n.offSameWiFiOnlyNothing,
            value: settings.togetherInternet,
            onChanged: (v) => ctrl.update((s) => s.copyWith(togetherInternet: v)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(52, 4, 16, 14),
            child: TextFormField(
              initialValue: settings.togetherName,
              maxLength: 32,
              decoration: InputDecoration(
                labelText: l10n.yourNameInASession,
                hintText: l10n.theNameOfThisDevice,
                isDense: true,
                counterText: '',
              ),
              onChanged: (v) => ctrl.update((s) => s.copyWith(togetherName: v.trim())),
            ),
          ),
        ],
      ),
      SettingsGroup(
        title: l10n.ownServerOptional,
        footer: l10n.ifYouWouldRatherNotUse,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextFormField(
              initialValue: settings.relayUrl,
              decoration: const InputDecoration(hintText: 'ws://your-server:47800/', isDense: true),
              onChanged: (v) => ctrl.update((s) => s.copyWith(relayUrl: v.trim())),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _windows(WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    return [
      SettingsGroup(
        children: [
          SettingsSwitch(
            icon: Icons.minimize_rounded,
            title: l10n.closeToTray,
            subtitle: l10n.keepPlayingInTheTrayWhen,
            value: settings.closeToTray,
            onChanged: (v) => ctrl.update((s) => s.copyWith(closeToTray: v)),
          ),
          SettingsSwitch(
            icon: Icons.speed_rounded,
            title: l10n.highPriorityTitle,
            subtitle: l10n.highPrioritySubtitle,
            value: settings.highPriority,
            onChanged: (v) => ctrl.update((s) => s.copyWith(highPriority: v)),
          ),
          const DiscordSettings(),
        ],
      ),
    ];
  }

  List<Widget> _backup(BuildContext context, WidgetRef ref) => [
        SettingsGroup(
          footer: l10n.settingsEqThemesPlaylistsFavoritesSmart,
          children: [
            SettingsTile(
              icon: Icons.save_alt_rounded,
              title: l10n.backUpToAFile,
              onTap: () => BackupActions.backup(context, ref),
            ),
            SettingsTile(
              icon: Icons.settings_backup_restore_rounded,
              title: l10n.restoreFromAFile,
              onTap: () => BackupActions.restore(context, ref),
            ),
          ],
        ),
      ];

  List<Widget> _about(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final songs = ref.watch(tracksProvider.select((v) => v.value?.length)) ?? 0;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
        child: Row(
          children: [
            const PrismLogo(size: 44, showName: false),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Prism', style: text.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    l10n.versionAndSongs(songs, appVersion),
                    style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      SettingsGroup(
        children: [
          SettingsTile(
            icon: Icons.waving_hand_outlined,
            title: l10n.tourShowAgain,
            subtitle: l10n.tourShowAgainHint,
            chevron: true,
            onTap: () => WelcomeTour.show(ref.context),
          ),
          SettingsTile(
            icon: Icons.system_update_alt_rounded,
            title: l10n.updateCheck,
            chevron: true,
            onTap: () => checkForUpdatesInteractive(ref.context),
          ),
          SettingsSwitch(
            icon: Icons.update_rounded,
            title: l10n.updateAuto,
            subtitle: l10n.updateAutoHint,
            value: ref.watch(settingsProvider.select((s) => s.autoCheckUpdates)),
            onChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(autoCheckUpdates: v)),
          ),
        ],
      ),
      Text(
        l10n.aMusicPlayerForYourOwn,
        style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
    ];
  }
}

/// Finding missing covers and artists online.
class _AutoFindGroup extends ConsumerWidget {
  const _AutoFindGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(settingsProvider.select((s) => s.autoFindInfo));
    final tagger = ref.watch(autoTaggerProvider);
    final count = ref.watch(_autoTaggedCountProvider).value ?? 0;
    final ctrl = ref.read(autoTaggerProvider.notifier);
    final String status;
    if (tagger.running) {
      status = l10n.lookingOfSongsFound(tagger.done, tagger.total, tagger.found);
    } else if (tagger.note != null) {
      status = tagger.note!;
    } else {
      status = count == 0 ? l10n.nothingFoundYet : l10n.foundInfoFor(count);
    }
    return SettingsGroup(
      title: l10n.missingInfo,
      footer: l10n.sendsOnlyTitleAndArtistTo,
      children: [
        SettingsSwitch(
          icon: Icons.auto_fix_high_rounded,
          title: l10n.findCoversAndArtistsOnline,
          subtitle: status,
          value: on,
          onChanged: (v) => ref.read(settingsProvider.notifier).update((s) => s.copyWith(autoFindInfo: v)),
        ),
        if (tagger.running && tagger.total > 0)
          SettingsControl(child: LinearProgressIndicator(value: tagger.done / tagger.total)),
        if (on)
          SettingsTile(
            icon: Icons.manage_search_rounded,
            title: l10n.lookAgain,
            subtitle: l10n.forSongsThatGotNothingSo,
            enabled: !tagger.running,
            onTap: ctrl.lookAgain,
          ),
        if (count > 0)
          SettingsTile(
            icon: Icons.undo_rounded,
            title: l10n.undoEverythingFound,
            subtitle: l10n.backToWhatYourFilesSay,
            onTap: () async {
              await ctrl.undoAll();
            },
          ),
      ],
    );
  }
}

final _autoTaggedCountProvider = StreamProvider<int>((ref) => ref.watch(libraryRepositoryProvider).watchAutoTaggedCount());

/// A seek bar style with a working sample of it.
/// Color, size and the rest of the seek bar, shown on the chosen style while
/// you change them.
class _SeekBarCustomGroup extends ConsumerWidget {
  const _SeekBarCustomGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final look = s.seekBarLook;
    final scheme = Theme.of(context).colorScheme;

    List<Widget> slider(
      IconData icon,
      String title,
      double value,
      double min,
      double max,
      AppSettings Function(AppSettings, double) set, {
      double shownOver = 1,
    }) => [
          SettingsTile(
            icon: icon,
            title: title,
            trailing: SettingsValue('${fmtNum(value / shownOver * 100, 0)} %'),
          ),
          SettingsControl(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: (v) => ctrl.update((x) => set(x, v)),
            ),
          ),
        ];

    return SettingsGroup(
      title: l10n.seekBarCustomize,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: SeekBarStylePreview(
            style: SeekBarStyle.parse(s.seekBarStyle),
            live: s.liveSeekBar,
            look: look,
            height: 44,
          ),
        ),
        SettingsSwitch(
          icon: Icons.palette_outlined,
          title: l10n.seekBarOwnColor,
          subtitle: l10n.seekBarOwnColorHint,
          value: s.seekBarColor != null,
          onChanged: (v) => ctrl.update((x) => x.copyWith(seekBarColor: v ? scheme.primary.toARGB32() : null)),
        ),
        if (s.seekBarColor != null)
          ColorPickerTile(
            title: l10n.seekBarColor,
            color: Color(s.seekBarColor!),
            onChanged: (c) => ctrl.update((x) => x.copyWith(seekBarColor: c.toARGB32())),
          ),
        ...slider(Icons.height_rounded, l10n.seekBarSize, s.seekBarSize, 0.6, 1.6, (x, v) => x.copyWith(seekBarSize: v)),
        ...slider(Icons.bar_chart_rounded, l10n.seekBarDensity, s.seekBarDensity, 0.5, 2, (x, v) => x.copyWith(seekBarDensity: v)),
        ...slider(Icons.line_weight_rounded, l10n.seekBarThickness, s.seekBarThickness, 0.5, 2, (x, v) => x.copyWith(seekBarThickness: v)),
        ...slider(Icons.brightness_low_rounded, l10n.seekBarDim, s.seekBarDim, 0.05, 0.6, (x, v) => x.copyWith(seekBarDim: v), shownOver: 0.18),
        if (s.liveSeekBar)
          ...slider(Icons.graphic_eq_rounded, l10n.seekBarReact, s.seekBarReact, 0, 2, (x, v) => x.copyWith(seekBarReact: v)),
        SettingsSwitch(
          icon: Icons.vertical_align_center_rounded,
          title: l10n.seekBarHead,
          value: s.seekBarHead,
          onChanged: (v) => ctrl.update((x) => x.copyWith(seekBarHead: v)),
        ),
        SettingsSwitch(
          icon: Icons.schedule_rounded,
          title: l10n.seekBarTimes,
          value: s.seekBarTimes,
          onChanged: (v) => ctrl.update((x) => x.copyWith(seekBarTimes: v)),
        ),
        SettingsTile(
          icon: Icons.restart_alt_rounded,
          title: l10n.seekBarReset,
          enabled: !look.isDefault,
          onTap: () => ctrl.update(
            (x) => x.copyWith(
              seekBarColor: null,
              seekBarSize: 1,
              seekBarDensity: 1,
              seekBarThickness: 1,
              seekBarDim: 0.18,
              seekBarReact: 1,
              seekBarHead: true,
              seekBarTimes: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _SeekStyleRow extends StatelessWidget {
  const _SeekStyleRow({required this.style, required this.selected, required this.live, required this.onTap, required this.look});

  final SeekBarLook look;

  final SeekBarStyle style;
  final bool selected;
  final bool live;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(style.label, style: text.bodyLarge?.copyWith(fontSize: 15))),
                LedDot(on: selected),
              ],
            ),
            const SizedBox(height: 2),
            Text(style.description, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 12),
            SeekBarStylePreview(style: style, live: live, look: look),
          ],
        ),
      ),
    );
  }
}

/// Loudness normalization: mode, automatic measuring and library analysis.
class _LoudnessGroup extends ConsumerWidget {
  const _LoudnessGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final ctrl = ref.read(settingsProvider.notifier);
    final progress = ref.watch(loudnessControllerProvider);
    final missing = ref.watch(tracksWithoutLoudnessProvider).value ?? 0;
    final available = ref.watch(loudnessAnalyzerProvider).available;
    return SettingsGroup(
      title: l10n.loudness,
      footer: l10n.usesReplaygainTagsOrMeasuresSongs,
      children: [
        SettingsTile(
          icon: Icons.volume_up_outlined,
          title: l10n.evenOutLoudness,
          trailing: SegmentedButton<NormalizationMode>(
            segments: [
              ButtonSegment(value: NormalizationMode.off, label: Text(l10n.xOff)),
              ButtonSegment(value: NormalizationMode.track, label: Text(l10n.song2)),
              ButtonSegment(value: NormalizationMode.album, label: Text(l10n.album)),
            ],
            selected: {settings.normalization},
            showSelectedIcon: false,
            style: const ButtonStyle(visualDensity: VisualDensity.compact),
            onSelectionChanged: (s) => ctrl.update((x) => x.copyWith(normalization: s.first)),
          ),
        ),
        SettingsSwitch(
          icon: Icons.auto_mode_rounded,
          title: l10n.measureSongsAutomatically,
          subtitle: l10n.whenASongWithoutReplaygainTags,
          value: settings.autoAnalyzeLoudness,
          onChanged: available ? (v) => ctrl.update((x) => x.copyWith(autoAnalyzeLoudness: v)) : null,
        ),
        SettingsTile(
          icon: Icons.analytics_outlined,
          title: progress == null ? l10n.measureTheWholeLibrary : l10n.measuringOf(progress.done + 1, progress.total),
          subtitle: progress != null
              ? null
              : (available ? l10n.notMeasuredYet(missing) : l10n.ffmpegIsMissingOnThisDevice),
          enabled: progress != null || (available && missing > 0),
          onTap: progress == null ? ref.read(loudnessControllerProvider.notifier).analyzeLibrary : null,
          trailing: progress == null
              ? null
              : IconButton(
                  tooltip: l10n.stop,
                  icon: const Icon(Icons.stop_rounded),
                  onPressed: ref.read(loudnessControllerProvider.notifier).cancel,
                ),
        ),
        if (progress != null)
          SettingsControl(
            child: LinearProgressIndicator(value: progress.total == 0 ? null : progress.done / progress.total),
          ),
      ],
    );
  }
}

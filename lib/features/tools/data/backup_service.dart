import 'dart:convert';

import '../../audio_fx/application/eq_controller.dart';
import '../../audio_fx/domain/eq_settings.dart';
import '../../editor/data/edit_repository.dart';
import '../../editor/domain/edit_decision_list.dart';
import '../../library/data/library_repository.dart';
import '../../playlists/data/playlist_repository.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/domain/app_settings.dart';
import '../../stats/data/stats_repository.dart';
import '../../stats/domain/smart_playlist.dart';
import '../../../core/theme/theme_config.dart';
import '../domain/track_matching.dart';
import '../../../l10n/l10n.dart';

/// What a restore changed.
class RestoreReport {
  RestoreReport({this.settings, this.eq});
  final AppSettings? settings;
  final EqState? eq;
  int playlists = 0, playlistSongs = 0, missingSongs = 0, favorites = 0, themes = 0, smart = 0, edits = 0;

  @override
  String toString() => '${l10n.backupSummary(playlists, playlistSongs, favorites, themes, smart, edits)}${missingSongs > 0 ? ' · ${l10n.songsNotInLibrary(missingSongs)}' : ''}';
}

/// One-file backup (`.prism-backup.json`) of everything the user made:
/// settings, EQ + presets, themes, playlists, favorites, smart playlists and
/// editor edits. Songs are referenced portably ([TrackRef]) so a backup can be
/// restored on another device where paths differ.
class BackupService {
  BackupService({
    required this.library,
    required this.playlists,
    required this.themes,
    required this.stats,
    required this.edits,
  });

  final LibraryRepository library;
  final PlaylistRepository playlists;
  final SavedThemesRepository themes;
  final StatsRepository stats;
  final EditRepository edits;

  static const format = 'prism-backup';
  static const version = 1;

  Future<String> export({required AppSettings settings, required EqState eq}) async {
    final tracks = {for (final t in await library.watchTracks().first) t.id: t};
    final lists = <Map<String, Object>>[];
    for (final p in await playlists.watchPlaylists().first) {
      final items = await playlists.watchItems(p.id).first;
      lists.add({'name': p.name, 'tracks': [for (final i in items) TrackRef.of(i.track).toJson()]});
    }
    final storedEdits = <Map<String, Object>>[];
    for (final (id, e) in await edits.all()) {
      final t = tracks[id];
      if (t != null) storedEdits.add({'track': TrackRef.of(t).toJson(), 'live': e.livePreset, 'edl': e.edl.toJson()});
    }
    return const JsonEncoder.withIndent(' ').convert({
      'format': format,
      'version': version,
      'createdAt': DateTime.now().toIso8601String(),
      'settings': settings.toJson(),
      'eq': {'settings': eq.settings.toJson(), 'presets': [for (final p in eq.customPresets) p.toJson()]},
      'themes': [for (final (_, t) in await themes.watchAll().first) t.toJson()],
      'playlists': lists,
      'favorites': [for (final t in await library.watchFavoriteTracks().first) TrackRef.of(t).toJson()],
      'smartPlaylists': [
        for (final s in await stats.watchSmartPlaylists().first)
          if (s.id > 0) s.copyWith(id: 0).toJson(),
      ],
      'edits': storedEdits,
    });
  }

  /// Restores a backup. Settings/EQ are returned for the caller to apply to
  /// the live controllers; everything else is written here.
  Future<RestoreReport> restore(String json) async {
    final Map<String, dynamic> m;
    try {
      m = jsonDecode(json) as Map<String, dynamic>;
    } on FormatException {
      throw FormatException(l10n.notAPrismBackupInvalidJson);
    }
    if (m['format'] != format) throw FormatException(l10n.notAPrismBackup);
    if ((m['version'] as int? ?? 0) > version) throw FormatException(l10n.backupIsFromANewerPrism);

    final eqJson = m['eq'] as Map<String, dynamic>?;
    final report = RestoreReport(
      settings: m['settings'] == null ? null : AppSettings.fromJson(m['settings'] as Map<String, dynamic>),
      eq: eqJson == null
          ? null
          : EqState(
              settings: EqSettings.fromJson(eqJson['settings'] as Map<String, dynamic>).sanitized(),
              customPresets: [
                for (final p in (eqJson['presets'] as List? ?? const [])) EqPreset.fromJson(p as Map<String, dynamic>),
              ],
            ),
    );
    final matcher = TrackMatcher(await library.watchTracks().first);

    final existingThemes = {for (final (_, t) in await themes.watchAll().first) t.name};
    for (final t in (m['themes'] as List? ?? const [])) {
      final theme = ThemeConfig.fromJson(t as Map<String, dynamic>).sanitized();
      if (existingThemes.add(theme.name)) {
        await themes.save(theme);
        report.themes++;
      }
    }

    final existingLists = {for (final p in await playlists.watchPlaylists().first) p.name};
    for (final pl in (m['playlists'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      var name = pl['name'] as String? ?? l10n.playlist2;
      if (existingLists.contains(name)) name = l10n.restored(name);
      final ids = <int>[];
      for (final r in (pl['tracks'] as List? ?? const [])) {
        final t = matcher.match(TrackRef.fromJson(r as Map<String, dynamic>));
        t == null ? report.missingSongs++ : ids.add(t.id);
      }
      final id = await playlists.create(name);
      await playlists.addTracks(id, ids);
      existingLists.add(name);
      report.playlists++;
      report.playlistSongs += ids.length;
    }

    for (final r in (m['favorites'] as List? ?? const [])) {
      final t = matcher.match(TrackRef.fromJson(r as Map<String, dynamic>));
      if (t == null) {
        report.missingSongs++;
      } else if (!await library.isFavorite(t.id)) {
        await library.toggleFavorite(t.id);
        report.favorites++;
      }
    }

    for (final s in (m['smartPlaylists'] as List? ?? const [])) {
      await stats.saveSmartPlaylist(SmartPlaylist.fromJson(s as Map<String, dynamic>).copyWith(id: 0));
      report.smart++;
    }

    for (final e in (m['edits'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final t = matcher.match(TrackRef.fromJson(e['track'] as Map<String, dynamic>));
      if (t == null) {
        report.missingSongs++;
        continue;
      }
      final edl = EditDecisionList.fromJson(e['edl'] as Map<String, dynamic>).copyWith(sourceUri: t.uri);
      await edits.save(t.id, edl, livePreset: e['live'] as bool? ?? false);
      report.edits++;
    }
    return report;
  }
}

import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../player/application/player_providers.dart';
import '../../editor/data/edit_repository.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/track.dart';
import '../../playlists/application/playlist_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../../stats/application/stats_providers.dart';
import '../data/backup_service.dart';
import '../data/tag_writer.dart';
import '../domain/track_matching.dart';
import 'duplicate_cleaner.dart';
import 'song_info_saver.dart';

final tagWriterProvider = FutureProvider<TagWriter>((ref) async {
  final support = await getApplicationSupportDirectory();
  return TagWriter(Directory(p.join(support.path, 'tag-backups')));
});

final backupServiceProvider = Provider<BackupService>((ref) => BackupService(
      library: ref.watch(libraryRepositoryProvider),
      playlists: ref.watch(playlistRepositoryProvider),
      themes: ref.watch(savedThemesRepositoryProvider),
      stats: ref.watch(statsRepositoryProvider),
      edits: ref.watch(editRepositoryProvider),
    ));

/// Duplicate groups of the whole library (recomputed when tracks change).
final duplicatesProvider = Provider<AsyncValue<List<List<Track>>>>(
  (ref) => ref.watch(tracksProvider).whenData(findDuplicates),
);

/// Saves the song's info (all of it, see [SongInfoSaver]), refreshes the
/// library entry and cover caches. Returns true when the file was written
/// (false: kept in Prism's library, the format can't hold tags).
Future<bool> saveTags(WidgetRef ref, Track track, TagEdit edit) async {
  final wrote = await ref.read(songInfoSaverProvider).save(track, edit);
  PaintingBinding.instance.imageCache.clear();
  // The queue (player, Discord, tray, media overlay) shows the new info now.
  final fresh = await ref.read(libraryRepositoryProvider).tracksByIds([track.id]);
  if (fresh.isNotEmpty) ref.read(playerControllerProvider).refreshTrackInfo(fresh.first);
  return wrote;
}

final duplicateCleanerProvider = Provider<DuplicateCleaner>((ref) => DuplicateCleaner(ref.watch(libraryRepositoryProvider)));

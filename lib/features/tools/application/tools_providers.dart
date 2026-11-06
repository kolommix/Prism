import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../editor/data/edit_repository.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/track.dart';
import '../../playlists/application/playlist_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../../stats/application/stats_providers.dart';
import '../data/backup_service.dart';
import '../data/tag_writer.dart';
import '../domain/track_matching.dart';

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

/// Writes tags, refreshes the library entry and cover caches.
Future<void> saveTags(WidgetRef ref, Track track, TagEdit edit) async {
  final writer = await ref.read(tagWriterProvider.future);
  await writer.write(track.uri, edit);
  // A changed cover must be re-extracted: drop the cached file first.
  if ((edit.cover != null || edit.removeCover) && track.artworkPath != null) {
    final f = File(track.artworkPath!);
    if (await f.exists()) await f.delete();
  }
  await ref.read(libraryScannerProvider).scanFolders([p.dirname(track.uri)]).drain<void>();
  PaintingBinding.instance.imageCache.clear();
}

/// Deletes a duplicate file from disk and the library.
Future<void> deleteTrackFile(WidgetRef ref, Track t) async {
  final f = File(t.uri);
  if (await f.exists()) await f.delete();
  await ref.read(libraryRepositoryProvider).deleteByUris([t.uri]);
}

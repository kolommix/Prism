import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/audio_metadata_tag_reader.dart';
import '../data/library_repository.dart';
import '../data/library_scanner.dart';
import '../domain/library_models.dart';
import '../domain/tag_reader.dart';
import '../domain/track.dart';

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) => LibraryRepository(ref.watch(appDatabaseProvider)));

final tagReaderProvider = Provider<TagReader>((ref) => AudioMetadataTagReader());

final libraryScannerProvider = Provider<LibraryScanner>(
  (ref) => LibraryScanner(
    repository: ref.watch(libraryRepositoryProvider),
    tagReader: ref.watch(tagReaderProvider),
    artworkDir: ref.watch(artworkDirProvider),
  ),
);

// ------------------------------------------------------------------ lists

class TrackSortNotifier extends Notifier<TrackSort> {
  @override
  TrackSort build() => TrackSort.title;
  void set(TrackSort sort) => state = sort;
}

final trackSortProvider = NotifierProvider<TrackSortNotifier, TrackSort>(TrackSortNotifier.new);

final tracksProvider = StreamProvider<List<Track>>(
  (ref) => ref.watch(libraryRepositoryProvider).watchTracks(sort: ref.watch(trackSortProvider)),
);

final albumsProvider = StreamProvider<List<AlbumSummary>>((ref) => ref.watch(libraryRepositoryProvider).watchAlbums());

final artistsProvider = StreamProvider<List<ArtistSummary>>((ref) => ref.watch(libraryRepositoryProvider).watchArtists());

final folderSummariesProvider =
    StreamProvider<List<FolderSummary>>((ref) => ref.watch(libraryRepositoryProvider).watchFolderSummaries());

final libraryFoldersProvider = StreamProvider<List<String>>((ref) => ref.watch(libraryRepositoryProvider).watchFolders());

final albumTracksProvider = StreamProvider.family<List<Track>, ({String album, String artist})>(
  (ref, key) => ref.watch(libraryRepositoryProvider).watchAlbumTracks(key.album, key.artist),
);

final artistTracksProvider = StreamProvider.family<List<Track>, String>(
  (ref, artist) => ref.watch(libraryRepositoryProvider).watchArtistTracks(artist),
);

final folderTracksProvider = StreamProvider.family<List<Track>, String>(
  (ref, folder) => ref.watch(libraryRepositoryProvider).watchFolderTracks(folder),
);

final favoriteIdsProvider = StreamProvider<Set<int>>((ref) => ref.watch(libraryRepositoryProvider).watchFavoriteIds());

final favoriteTracksProvider =
    StreamProvider<List<Track>>((ref) => ref.watch(libraryRepositoryProvider).watchFavoriteTracks());

// ----------------------------------------------------------------- search

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String q) => state = q;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

final searchResultsProvider = FutureProvider<List<Track>>((ref) async {
  final q = ref.watch(searchQueryProvider);
  if (q.trim().isEmpty) return const [];
  // Re-run when the library changes (e.g. during a scan).
  ref.watch(tracksProvider);
  return ref.watch(libraryRepositoryProvider).search(q);
});

// ------------------------------------------------------------------- scan

/// Drives folder scans and exposes the latest progress (null = idle).
class ScanController extends Notifier<ScanProgress?> {
  StreamSubscription<ScanProgress>? _sub;

  @override
  ScanProgress? build() {
    ref.onDispose(() => _sub?.cancel());
    return null;
  }

  bool get isScanning => state != null && state is! ScanFinished;

  Future<void> addFolder(String path) async {
    await ref.read(libraryRepositoryProvider).addFolder(path);
    await _run(ref.read(libraryScannerProvider).scanFolders([path]));
  }

  Future<void> removeFolder(String path) => ref.read(libraryRepositoryProvider).removeFolder(path);

  Future<void> rescanAll() => _run(ref.read(libraryScannerProvider).scanAll());

  Future<void> _run(Stream<ScanProgress> stream) async {
    if (isScanning) return;
    final done = Completer<void>();
    await _sub?.cancel();
    _sub = stream.listen(
      (p) => state = p,
      onError: (Object e, StackTrace st) {
        state = null;
        if (!done.isCompleted) done.completeError(e, st);
      },
      onDone: () {
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future;
  }
}

/// Songs the user took out of Prism (their files stay).
final removedTracksProvider = StreamProvider((ref) => ref.watch(libraryRepositoryProvider).watchRemoved());

final scanControllerProvider = NotifierProvider<ScanController, ScanProgress?>(ScanController.new);

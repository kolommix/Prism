import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../library/domain/library_models.dart';
import '../data/playlist_repository.dart';

import '../../player/domain/reorder.dart';
final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) => PlaylistRepository(ref.watch(appDatabaseProvider)));

final playlistsProvider =
    StreamProvider<List<PlaylistSummary>>((ref) => ref.watch(playlistRepositoryProvider).watchPlaylists());

final playlistItemsProvider = StreamProvider.family<List<PlaylistItem>, int>(
  (ref, id) => ref.watch(playlistRepositoryProvider).watchItems(id),
);

final playlistSortProvider = StreamProvider.family<PlaylistSort, int>(
  (ref, id) => ref.watch(playlistRepositoryProvider).watchSort(id),
);

final playlistNameProvider = StreamProvider.family<String?, int>(
  (ref, id) => ref.watch(playlistRepositoryProvider).watchName(id),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../player/application/player_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../data/lyrics_repository.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/track.dart';
import '../../online/application/online_providers.dart';
import '../../online/domain/external_track.dart';
import '../domain/lrc.dart';
import '../domain/lyrics_search.dart';

final lyricsRepositoryProvider = Provider<LyricsRepository>((ref) => LyricsRepository(ref.watch(appDatabaseProvider)));

/// Lyrics of the current track (null = none found).
final currentLyricsProvider = FutureProvider<Lyrics?>((ref) async {
  final track = ref.watch(currentTrackProvider);
  if (track == null) return null;
  final online = ref.watch(settingsProvider.select((s) => s.onlineLyrics));
  return ref.watch(lyricsRepositoryProvider).lyricsFor(track, online: online);
});

/// The offset slider while it is being dragged, before it is saved.
class LyricsOffsetLive extends Notifier<Duration?> {
  @override
  Duration? build() {
    // A new song drops the preview.
    ref.watch(currentTrackProvider);
    return null;
  }

  void preview(Duration d) => state = d;
}

final lyricsOffsetLiveProvider = NotifierProvider<LyricsOffsetLive, Duration?>(LyricsOffsetLive.new);

/// Per-song timing fix of the current song's lyrics.
final currentLyricsOffsetProvider = FutureProvider<Duration>((ref) async {
  final live = ref.watch(lyricsOffsetLiveProvider);
  if (live != null) return live;
  final track = ref.watch(currentTrackProvider);
  if (track == null) return Duration.zero;
  return Duration(milliseconds: await ref.watch(lyricsRepositoryProvider).offsetMs(track.id));
});

/// Saved lyrics of the library, searchable.
final lyricsIndexProvider = StreamProvider<List<LyricsIndexEntry>>(
  (ref) => ref.watch(lyricsRepositoryProvider).watchIndex(),
);

/// Library songs whose saved words have the search line, with that line.
final lyricsMatchesProvider = FutureProvider<List<(Track, String)>>((ref) async {
  final q = ref.watch(searchQueryProvider);
  if (!looksLikeLine(q)) return const [];
  final index = await ref.watch(lyricsIndexProvider.future);
  final hits = searchLyrics(index, q);
  if (hits.isEmpty) return const [];
  final tracks = await ref.read(libraryRepositoryProvider).tracksByIds([for (final h in hits) h.$1]);
  final byId = {for (final t in tracks) t.id: t};
  return [
    for (final (id, line) in hits)
      if (byId[id] case final t?) (t, line),
  ];
});

/// Songs that have the search line, found online (YouTube Music's song search
/// knows lyrics). Only with YouTube switched on; empty otherwise.
final onlineLyricsMatchesProvider = FutureProvider.autoDispose.family<List<Track>, String>((ref, query) async {
  if (!looksLikeLine(query) || loosen(query).split(' ').length < 3) return const [];
  ref.watch(onlineRevisionProvider);
  var cancelled = false;
  ref.onDispose(() => cancelled = true);
  await Future<void>.delayed(const Duration(milliseconds: 600));
  if (cancelled) return const [];
  final m = ref.read(onlineHubProvider).module(OnlineService.youtube);
  if (m == null) return const [];
  return m.searchSongs(query, limit: 5);
});

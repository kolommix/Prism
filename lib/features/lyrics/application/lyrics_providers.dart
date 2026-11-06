import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../player/application/player_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../data/lyrics_repository.dart';
import '../domain/lrc.dart';

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

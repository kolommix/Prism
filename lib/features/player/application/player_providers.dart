import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/theme/album_palette.dart';
import '../../library/domain/track.dart';
import '../domain/playback_queue.dart';
import '../engine/playback_engine.dart';
import 'player_controller.dart';
import 'sleep_timer.dart';
import '../../settings/application/settings_controller.dart';

/// The single [PlayerController], created in bootstrap (it must exist before
/// audio_service starts) and injected with `overrideWithValue`.
final playerControllerProvider =
    Provider<PlayerController>((ref) => throw UnimplementedError('override in bootstrap'));

/// Emits the current value first, then every change.
Stream<T> _seeded<T>(T current, Stream<T> changes) async* {
  yield current;
  yield* changes;
}

final queueProvider = StreamProvider<PlaybackQueue>((ref) {
  final p = ref.watch(playerControllerProvider);
  return _seeded(p.queue, p.queueStream);
});

/// Position/playing/duration – updates ~4x per second while playing. Widgets
/// that only need `playing` should `select` it to avoid rebuilding.
final engineStateProvider = StreamProvider<EngineState>((ref) {
  final p = ref.watch(playerControllerProvider);
  return _seeded(p.state, p.stateStream);
});

/// Speed, pitch and A-B loop points.
final tuningProvider = StreamProvider<PlaybackTuning>((ref) {
  final p = ref.watch(playerControllerProvider);
  return _seeded(p.tuning, p.tuningStream);
});

final currentTrackProvider = Provider<Track?>(
  (ref) => ref.watch(queueProvider.select((q) => q.value?.current)),
);

final isPlayingProvider = Provider<bool>(
  (ref) => ref.watch(engineStateProvider.select((s) => s.value?.playing ?? false)),
);

/// Palette of the current cover, used for dynamic theme + backgrounds.
/// Not computed in black & white mode (nothing uses it there, and the
/// extraction runs on the UI thread on every track change).
final currentPaletteProvider = FutureProvider<AlbumPalette?>((ref) {
  final theme = ref.watch(settingsProvider.select((s) => (s.theme.monochrome, s.theme.dynamicColor)));
  if (theme.$1 || !theme.$2) return null; // only needed as the dynamic theme seed
  final art = ref.watch(currentTrackProvider.select((t) => t?.artworkPath));
  return ref.watch(albumPaletteExtractorProvider).fromFile(art);
});

final sleepTimerProvider = Provider<SleepTimer>((ref) {
  final player = ref.watch(playerControllerProvider);
  final timer = SleepTimer(onFire: player.pause, setVolume: player.setVolume);
  final sub = player.events.listen((e) {
    if (e == EngineEvent.advancedToNext || e == EngineEvent.ended) timer.trackEnded();
  });
  ref.onDispose(() {
    sub.cancel();
    timer.dispose();
  });
  return timer;
});

final sleepTimerStateProvider = StreamProvider<SleepTimerState>((ref) {
  final t = ref.watch(sleepTimerProvider);
  return _seeded(t.state, t.stream);
});

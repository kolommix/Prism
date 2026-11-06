import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';

import '../../library/domain/track.dart';
import '../application/player_controller.dart';
import '../domain/playback_queue.dart';
import '../engine/playback_engine.dart';
import '../../../l10n/l10n.dart';

/// Bridges [PlayerController] to `audio_service`.
///
/// On Android this gives us the foreground service (background playback),
/// the media notification, lock-screen controls, Bluetooth/headset buttons
/// and Android Auto-style media sessions – all driven by the same controller
/// the UI uses.
class PrismAudioHandler extends BaseAudioHandler with SeekHandler {
  PrismAudioHandler(this._player) {
    _subs
      ..add(_player.queueStream.listen(_onQueue))
      ..add(_player.stateStream.listen(_onState));
    _onQueue(_player.queue);
  }

  final PlayerController _player;
  final _subs = <StreamSubscription<Object?>>[];

  /// Starts the Android media service. Call once at startup (Android only).
  static Future<PrismAudioHandler> init(PlayerController player) => AudioService.init(
        builder: () => PrismAudioHandler(player),
        config: AudioServiceConfig(
          androidNotificationChannelId: 'com.kolommix.prism.playback',
          androidNotificationChannelName: l10n.playback,
          androidNotificationIcon: 'drawable/ic_stat_prism',
          androidNotificationOngoing: true,
          androidStopForegroundOnPause: true,
        ),
      );

  // --------------------------------------------------- commands from system

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> skipToNext() => _player.skipNext();
  @override
  Future<void> skipToPrevious() => _player.skipPrevious();
  @override
  Future<void> skipToQueueItem(int index) => _player.jumpTo(index);

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) => _player.setRepeat(switch (repeatMode) {
        AudioServiceRepeatMode.none => QueueRepeatMode.off,
        AudioServiceRepeatMode.one => QueueRepeatMode.one,
        AudioServiceRepeatMode.all || AudioServiceRepeatMode.group => QueueRepeatMode.all,
      });

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) =>
      _player.setShuffle(shuffleMode != AudioServiceShuffleMode.none);

  @override
  Future<void> onTaskRemoved() async {
    // Swiping the app away while paused should not leave a zombie service.
    if (!_player.state.playing) await stop();
  }

  // -------------------------------------------------------- state to system

  void _onQueue(PlaybackQueue q) {
    queue.add([for (final t in q.tracks) _mediaItem(t)]);
    final cur = q.current;
    mediaItem.add(cur == null ? null : _mediaItem(cur));
    _onState(_player.state);
  }

  void _onState(EngineState s) {
    final q = _player.queue;
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        s.playing ? MediaControl.pause : MediaControl.play,
        MediaControl.skipToNext,
      ],
      systemActions: const {MediaAction.seek, MediaAction.seekForward, MediaAction.seekBackward},
      androidCompactActionIndices: const [0, 1, 2],
      processingState: switch (s.status) {
        EngineStatus.idle => AudioProcessingState.idle,
        EngineStatus.loading => AudioProcessingState.loading,
        EngineStatus.buffering => AudioProcessingState.buffering,
        EngineStatus.ready => AudioProcessingState.ready,
        EngineStatus.completed => AudioProcessingState.completed,
      },
      playing: s.playing,
      updatePosition: s.position,
      bufferedPosition: s.bufferedPosition,
      queueIndex: q.index < 0 ? null : q.index,
      repeatMode: switch (q.repeatMode) {
        QueueRepeatMode.off => AudioServiceRepeatMode.none,
        QueueRepeatMode.all => AudioServiceRepeatMode.all,
        QueueRepeatMode.one => AudioServiceRepeatMode.one,
      },
      shuffleMode: q.shuffled ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    ));
  }

  static MediaItem _mediaItem(Track t) => MediaItem(
        id: '${t.sourceId}:${t.id}',
        title: t.title,
        artist: t.displayArtist,
        album: t.displayAlbum,
        duration: t.durationMs > 0 ? t.duration : null,
        artUri: t.artworkPath == null
            ? null
            : (t.artworkPath!.startsWith('http') ? Uri.parse(t.artworkPath!) : File(t.artworkPath!).uri),
      );

  Future<void> dispose() async {
    for (final s in _subs) {
      await s.cancel();
    }
  }
}

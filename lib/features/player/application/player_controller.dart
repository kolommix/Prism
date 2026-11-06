import 'dart:async';
import 'dart:math';

import '../../library/domain/track.dart';
import '../domain/playback_queue.dart';
import '../engine/playback_engine.dart';
import 'playback_state_store.dart';

/// Live playback adjustments (not part of the queue).
class PlaybackTuning {
  const PlaybackTuning({this.speed = 1.0, this.pitchSemitones = 0.0, this.loopA, this.loopB});

  final double speed;
  final double pitchSemitones;

  /// A-B loop points (output time of the current track). A set without B
  /// means "A marked, waiting for B".
  final Duration? loopA;
  final Duration? loopB;

  bool get looping => loopA != null && loopB != null;

  PlaybackTuning copyWith({double? speed, double? pitchSemitones, Duration? loopA, Duration? loopB}) =>
      PlaybackTuning(
        speed: speed ?? this.speed,
        pitchSemitones: pitchSemitones ?? this.pitchSemitones,
        loopA: loopA ?? this.loopA,
        loopB: loopB ?? this.loopB,
      );
}

/// The brain of playback: owns the [PlaybackQueue] and keeps the
/// [PlaybackEngine] fed with "current + next".
///
/// Platform integrations (Android notification via audio_service, Windows
/// media keys / tray) and the UI all talk to this one object, so behaviour is
/// identical everywhere.
class PlayerController {
  PlayerController({
    required this._engine,
    this._store,
    Random? random,
  }) : _random = random ?? Random() {
    _eventSub = _engine.events.listen(_onEngineEvent);
    _stateSub = _engine.stateStream.listen(_onEngineState);
  }

  final PlaybackEngine _engine;
  final PlaybackStateStore? _store;
  final Random _random;
  late final StreamSubscription<EngineEvent> _eventSub;
  late final StreamSubscription<EngineState> _stateSub;

  final _queueCtrl = StreamController<PlaybackQueue>.broadcast();
  PlaybackQueue _queue = PlaybackQueue.empty;

  /// Index of the track we told the engine is "next" (see [_syncNext]).
  int? _engineNextIndex;
  DateTime _lastSave = DateTime.fromMillisecondsSinceEpoch(0);
  int _consecutiveFailures = 0;

  final _tuningCtrl = StreamController<PlaybackTuning>.broadcast();
  PlaybackTuning _tuning = const PlaybackTuning();

  PlaybackQueue get queue => _queue;
  Stream<PlaybackQueue> get queueStream => _queueCtrl.stream;
  EngineState get state => _engine.state;
  Stream<EngineState> get stateStream => _engine.stateStream;
  Stream<EngineEvent> get events => _engine.events;

  /// Why the last track failed to open (for a short message in the UI).
  Object? get lastError => _engine.lastError;
  Track? get current => _queue.current;
  PlaybackTuning get tuning => _tuning;
  Stream<PlaybackTuning> get tuningStream => _tuningCtrl.stream;

  // ---------------------------------------------------- speed / pitch / A-B

  Future<void> setSpeed(double speed) async {
    _setTuning(_tuning.copyWith(speed: speed.clamp(0.25, 4.0)));
    await _engine.setSpeed(_tuning.speed);
  }

  Future<void> setPitchSemitones(double semitones) async {
    _setTuning(_tuning.copyWith(pitchSemitones: semitones.clamp(-12.0, 12.0)));
    await _engine.setPitchSemitones(_tuning.pitchSemitones);
  }

  /// Sets loop point A (first tap), then B (second tap), then clears.
  Future<void> cycleAbLoop() async {
    final pos = _engine.state.position;
    if (_tuning.loopA == null) {
      _setTuning(PlaybackTuning(speed: _tuning.speed, pitchSemitones: _tuning.pitchSemitones, loopA: pos));
    } else if (_tuning.loopB == null && pos > _tuning.loopA! + const Duration(milliseconds: 200)) {
      _setTuning(_tuning.copyWith(loopB: pos));
      await _engine.setAbLoop(_tuning.loopA, pos);
    } else {
      await clearAbLoop();
    }
  }

  Future<void> setAbLoop(Duration a, Duration b) async {
    _setTuning(_tuning.copyWith(loopA: a, loopB: b));
    await _engine.setAbLoop(a, b);
  }

  Future<void> clearAbLoop() async {
    _setTuning(PlaybackTuning(speed: _tuning.speed, pitchSemitones: _tuning.pitchSemitones));
    await _engine.setAbLoop(null, null);
  }

  /// EQ preamp (applied through the engine's gain path on every platform).
  Future<void> setPreampDb(double db) => _engine.setPreampDb(db);

  /// The current track's plan changed (live edit preset applied/removed or
  /// loudness analysed): reload it at the same position.
  Future<void> reloadCurrent() => _engine.reloadCurrent();

  /// Restores this player's pitch/gain on the shared effects backend.
  Future<void> reapplyEffects() => _engine.reapplyEffects();

  void _setTuning(PlaybackTuning t) {
    _tuning = t;
    if (!_tuningCtrl.isClosed) _tuningCtrl.add(t);
  }

  // ------------------------------------------------------------- queue ops

  /// Replaces the queue and starts playing [tracks] from [startIndex].
  Future<void> playTracks(List<Track> tracks, {int startIndex = 0, bool? shuffle}) async {
    var q = _queue;
    if (shuffle != null) q = q.copyWith(shuffled: shuffle);
    _setQueue(q.load(tracks, startIndex: startIndex, random: _random));
    await _loadCurrent(play: true);
  }

  Future<void> playNext(List<Track> tracks) async {
    final wasEmpty = _queue.isEmpty;
    _setQueue(_queue.addAllNext(tracks));
    wasEmpty ? await _loadCurrent(play: true) : await _syncNext();
  }

  Future<void> addToQueue(List<Track> tracks) async {
    final wasEmpty = _queue.isEmpty;
    _setQueue(_queue.addToEnd(tracks));
    wasEmpty ? await _loadCurrent(play: true) : await _syncNext();
  }

  Future<void> removeAt(int index) async {
    final removingCurrent = index == _queue.index;
    _setQueue(_queue.removeAt(index));
    if (_queue.isEmpty) {
      await _engine.stop();
    } else if (removingCurrent) {
      await _loadCurrent(play: _engine.state.playing);
    } else {
      await _syncNext();
    }
  }

  /// [from]/[to] are final indices (see [PlaybackQueue.reorderableToTarget]).
  Future<void> move(int from, int to) async {
    _setQueue(_queue.move(from, to));
    await _syncNext();
  }

  /// Moves several items together (multi-select drag, move to top/bottom).
  Future<void> moveMany(Iterable<int> indices, int start) async {
    _setQueue(_queue.moveMany(indices, start));
    await _syncNext();
  }

  /// Removes several items, highest first so the others keep their index.
  Future<void> removeMany(Iterable<int> indices) async {
    for (final i in indices.toSet().toList()..sort((a, b) => b - a)) {
      await removeAt(i);
    }
  }

  Future<void> jumpTo(int index) async {
    if (index == _queue.index) return seek(Duration.zero);
    _setQueue(_queue.jumpTo(index));
    await _loadCurrent(play: true);
  }

  Future<void> skipNext() async {
    final before = _queue.index;
    _setQueue(_queue.skipNext());
    if (_queue.index != before) await _loadCurrent(play: true);
  }

  /// Restarts the track if more than 3 s played, otherwise goes back.
  Future<void> skipPrevious() async {
    if (_engine.state.position > const Duration(seconds: 3) || _queue.previousIndex == null) {
      return seek(Duration.zero);
    }
    _setQueue(_queue.skipPrevious());
    await _loadCurrent(play: true);
  }

  Future<void> setShuffle(bool enabled) async {
    _setQueue(_queue.setShuffle(enabled, random: _random));
    await _syncNext();
  }

  Future<void> toggleShuffle() => setShuffle(!_queue.shuffled);

  Future<void> setRepeat(QueueRepeatMode mode) async {
    _setQueue(_queue.setRepeat(mode));
    await _engine.setRepeatOne(mode == QueueRepeatMode.one);
    await _syncNext();
  }

  Future<void> cycleRepeat() => setRepeat(_queue.cycleRepeat().repeatMode);

  // ------------------------------------------------------------ transport

  Future<void> play() async {
    if (_queue.isEmpty) return;
    if (_engine.state.status == EngineStatus.idle) {
      await _loadCurrent(play: true, position: _engine.state.position);
      return;
    }
    if (_engine.state.status == EngineStatus.completed) await _engine.seek(Duration.zero);
    await _engine.play();
  }

  Future<void> pause() async {
    await _engine.pause();
    await _save(force: true);
  }

  Future<void> togglePlay() => _engine.state.playing ? pause() : play();

  Future<void> seek(Duration position) => _engine.seek(position);

  Future<void> stop() async {
    await _save(force: true);
    await _engine.stop();
  }

  Future<void> setCrossfade(Duration d) => _engine.setCrossfade(d);
  Future<void> setVolume(double v) => _engine.setVolume(v);

  // ---------------------------------------------------------- persistence

  /// Restores the last session (queue + position) without auto-playing.
  Future<void> restore(Future<List<Track>> Function(List<int> ids) loadTracks) async {
    final saved = await _store?.load();
    if (saved == null || saved.trackIds.isEmpty) return;
    final tracks = await loadTracks(saved.trackIds);
    if (tracks.isEmpty) return;
    final byId = {for (final t in tracks) t.id: t};
    final original = [for (final id in saved.originalIds) if (byId[id] != null) byId[id]!];
    final index = saved.index.clamp(0, tracks.length - 1);
    _setQueue(PlaybackQueue(
      tracks: List.unmodifiable(tracks),
      originalOrder: List.unmodifiable(original.isEmpty ? tracks : original),
      index: index,
      repeatMode: saved.repeatMode,
      shuffled: saved.shuffled,
    ));
    await _engine.setRepeatOne(saved.repeatMode == QueueRepeatMode.one);
    await _loadCurrent(play: false, position: saved.position);
  }

  Future<void> _save({bool force = false}) async {
    final store = _store;
    if (store == null) return;
    final now = DateTime.now();
    if (!force && now.difference(_lastSave) < const Duration(seconds: 5)) return;
    _lastSave = now;
    await store.save(SavedPlayback(
      trackIds: [for (final t in _queue.tracks) t.id],
      originalIds: [for (final t in _queue.originalOrder) t.id],
      index: _queue.index,
      position: _engine.state.position,
      repeatMode: _queue.repeatMode,
      shuffled: _queue.shuffled,
    ));
  }

  // -------------------------------------------------------------- internals

  void _setQueue(PlaybackQueue q) {
    _queue = q;
    if (!_queueCtrl.isClosed) _queueCtrl.add(q);
    unawaited(_save(force: true));
  }

  /// "Next" for the engine. With repeat-one the engine loops by itself, so we
  /// pre-buffer the track a manual "next" would go to.
  int? _computeEngineNext() =>
      _queue.repeatMode == QueueRepeatMode.one ? _queue.setRepeat(QueueRepeatMode.all).nextIndex : _queue.nextIndex;

  Future<void> _loadCurrent({required bool play, Duration position = Duration.zero}) async {
    final cur = _queue.current;
    if (cur == null) return;
    _dropLoopPoints();
    _engineNextIndex = _computeEngineNext();
    await _engine.load(
      cur,
      next: _engineNextIndex == null ? null : _queue.tracks[_engineNextIndex!],
      position: position,
      play: play,
    );
  }

  /// Always re-sends next: even if the index is unchanged, the track at that
  /// index may differ after a reorder or "play next".
  Future<void> _syncNext() async {
    final n = _computeEngineNext();
    _engineNextIndex = n;
    await _engine.setNext(n == null ? null : _queue.tracks[n]);
  }

  Future<void> _onEngineEvent(EngineEvent e) async {
    switch (e) {
      case EngineEvent.advancedToNext:
        _consecutiveFailures = 0;
        _dropLoopPoints();
        final n = _engineNextIndex;
        if (n != null) _setQueue(_queue.jumpTo(n));
        await _syncNext();
      case EngineEvent.ended:
        await _save(force: true);
      case EngineEvent.failed:
        // Skip broken files, but don't loop forever over a fully broken queue.
        _consecutiveFailures++;
        if (_consecutiveFailures < _queue.length && _queue.skipNext().index != _queue.index) {
          await skipNext();
        }
    }
  }

  void _onEngineState(EngineState s) {
    if (s.playing) unawaited(_save());
  }

  /// A-B points belong to one track; the engine clears its own on load.
  void _dropLoopPoints() {
    if (_tuning.loopA == null) return;
    _setTuning(PlaybackTuning(speed: _tuning.speed, pitchSemitones: _tuning.pitchSemitones));
  }

  /// A song got new info (cover, artist): everything showing it updates, the
  /// sound doesn't notice.
  void refreshTrackInfo(Track fresh) {
    List<Track> swap(List<Track> list) => [for (final t in list) t.id == fresh.id ? fresh : t];
    _setQueue(_queue.copyWith(tracks: swap(_queue.tracks), originalOrder: swap(_queue.originalOrder)));
  }

  Future<void> dispose() async {
    await _save(force: true);
    await _eventSub.cancel();
    await _stateSub.cancel();
    await _queueCtrl.close();
    await _tuningCtrl.close();
    await _engine.dispose();
  }
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/player/application/playback_state_store.dart';
import 'package:prism/features/player/application/player_controller.dart';
import 'package:prism/features/player/domain/playback_queue.dart';
import 'package:prism/features/player/engine/playback_engine.dart';

import 'helpers.dart';

/// Records what the controller asks the engine to do.
class FakeEngine implements PlaybackEngine {
  final _events = StreamController<EngineEvent>.broadcast(sync: true);
  final _states = StreamController<EngineState>.broadcast(sync: true);
  EngineState _state = const EngineState();

  Track? loaded;
  Track? next;
  bool repeatOne = false;
  Duration? loadedAt;

  void emit(EngineEvent e) => _events.add(e);
  void setPosition(Duration d) => _state = _state.copyWith(position: d, status: EngineStatus.ready);

  @override
  Stream<EngineEvent> get events => _events.stream;
  @override
  Object? lastError;
  @override
  Stream<EngineState> get stateStream => _states.stream;
  @override
  EngineState get state => _state;

  @override
  Future<void> load(Track current, {Track? next, Duration position = Duration.zero, bool play = true}) async {
    loaded = current;
    this.next = next;
    loadedAt = position;
    _state = EngineState(playing: play, status: EngineStatus.ready, position: position);
  }

  @override
  Future<void> setNext(Track? next) async => this.next = next;
  @override
  Future<void> play() async => _state = _state.copyWith(playing: true);
  @override
  Future<void> pause() async => _state = _state.copyWith(playing: false);
  @override
  Future<void> seek(Duration position) async => _state = _state.copyWith(position: position);
  @override
  Future<void> stop() async => _state = const EngineState();
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> setCrossfade(Duration duration) async {}
  @override
  Future<void> setRepeatOne(bool enabled) async => repeatOne = enabled;
  @override
  Future<void> reloadCurrent() async {}
  @override
  Future<void> reapplyEffects() async {}
  @override
  Future<void> setSpeed(double speed) async => this.speed = speed;
  @override
  Future<void> setPitchSemitones(double semitones) async => pitch = semitones;
  @override
  Future<void> setPreampDb(double db) async {}
  @override
  Future<void> setAbLoop(Duration? a, Duration? b) async => loop = (a, b);
  @override
  Future<void> dispose() async {}

  double speed = 1;
  double pitch = 0;
  (Duration?, Duration?) loop = (null, null);
}

class MemoryStore implements PlaybackStateStore {
  SavedPlayback? saved;
  @override
  Future<SavedPlayback?> load() async => saved;
  @override
  Future<void> save(SavedPlayback state) async => saved = state;
}

void main() {
  late FakeEngine engine;
  late MemoryStore store;
  late PlayerController player;
  final songs = [for (var i = 1; i <= 4; i++) t(i)];

  setUp(() {
    engine = FakeEngine();
    store = MemoryStore();
    player = PlayerController(engine: engine, store: store);
  });

  test('playTracks loads current and pre-buffers next', () async {
    await player.playTracks(songs, startIndex: 1);
    expect(engine.loaded!.id, 2);
    expect(engine.next!.id, 3);
  });

  test('gapless advance from the engine moves the queue and feeds a new next', () async {
    await player.playTracks(songs);
    engine.emit(EngineEvent.advancedToNext);
    await pumpEventQueue();
    expect(player.current!.id, 2);
    expect(engine.next!.id, 3);
  });

  test('"play next" and reorder update the engine next without reloading', () async {
    await player.playTracks(songs);
    final loadedBefore = engine.loaded;
    await player.playNext([t(9)]);
    expect(engine.next!.id, 9);
    await player.move(1, 3); // move 9 to the end
    expect(engine.next!.id, 2);
    expect(identical(engine.loaded, loadedBefore), isTrue);
  });

  test('repeat one tells the engine to loop and still pre-buffers the next song', () async {
    await player.playTracks(songs, startIndex: 3);
    await player.setRepeat(QueueRepeatMode.one);
    expect(engine.repeatOne, isTrue);
    expect(engine.next!.id, 1, reason: 'manual "next" wraps to the start');
  });

  test('previous restarts the song after 3 seconds', () async {
    await player.playTracks(songs, startIndex: 2);
    engine.setPosition(const Duration(seconds: 10));
    await player.skipPrevious();
    expect(player.current!.id, 3);
    expect(engine.state.position, Duration.zero);
    await player.skipPrevious();
    expect(player.current!.id, 2);
  });

  test('a broken file is skipped', () async {
    await player.playTracks(songs);
    engine.emit(EngineEvent.failed);
    await pumpEventQueue();
    expect(player.current!.id, 2);
  });

  test('session is saved and restored at the same position', () async {
    await player.playTracks(songs, startIndex: 2);
    engine.setPosition(const Duration(seconds: 42));
    await player.pause();

    final engine2 = FakeEngine();
    final restored = PlayerController(engine: engine2, store: store);
    await restored.restore((ids) async => [for (final id in ids) songs.firstWhere((s) => s.id == id)]);
    expect(restored.current!.id, 3);
    expect(engine2.loadedAt, const Duration(seconds: 42));
    expect(engine2.state.playing, isFalse, reason: 'restore must not auto-play');
  });
}

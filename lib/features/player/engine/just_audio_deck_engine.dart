import 'dart:async';
import 'dart:math' as math;

import 'package:just_audio/just_audio.dart';

import '../../../core/sources/track_source.dart';
import '../../audio_fx/domain/eq_math.dart';
import '../../audio_fx/platform/audio_effects_backend.dart';
import '../../library/domain/track.dart';
import '../domain/playback_plan.dart';
import 'playback_engine.dart';

/// Resolves how a track should be played (live edit preset, track gain).
typedef PlanResolver = Future<PlaybackPlan> Function(Track track);

/// A track inside a deck's playlist window, expanded into its clips.
class _Entry {
  _Entry(this.track, this.plan);
  final Track track;
  final PlaybackPlan plan;
  int get clipCount => plan.clips.length;
}

/// One `just_audio` player plus bookkeeping.
class _Deck {
  _Deck(this.name) : player = AudioPlayer();

  final String name;
  final AudioPlayer player;

  /// Tracks currently in this player's playlist (current [+ next]).
  final window = <_Entry>[];

  /// Crossfade multiplier applied on top of the master volume.
  double fade = 1.0;

  int get flatLength => window.fold(0, (n, e) => n + e.clipCount);

  /// Maps a playlist index to (entry, clip).
  (int, int) locate(int flatIndex) {
    var i = flatIndex;
    for (var e = 0; e < window.length; e++) {
      if (i < window[e].clipCount) return (e, i);
      i -= window[e].clipCount;
    }
    return (window.isEmpty ? 0 : window.length - 1, 0);
  }

  _Entry? get current => window.isEmpty ? null : window.first;

  /// Clip index of the current entry that is playing now.
  int get clipIndex {
    final (e, c) = locate(player.currentIndex ?? 0);
    return e == 0 ? c : 0;
  }
}

/// [PlaybackEngine] built on two `just_audio` players ("decks").
///
/// **Gapless mode** (crossfade = 0): only the active deck is used. Its
/// playlist is a sliding window `[current clips…, next clips…]`; the backend
/// (ExoPlayer on Android, libmpv via media_kit on Windows) pre-buffers what
/// comes next and switches without a gap. When playback enters the next
/// track we drop the old track's clips and the controller appends a new next.
///
/// **Crossfade mode**: the active deck holds only the current track. Shortly
/// before its end the idle deck starts the next track at volume 0, volumes are
/// ramped in opposite directions, then the decks swap roles.
///
/// **Plans**: a track is played according to its [PlaybackPlan] – a plain
/// track is one source; a track with a live edit preset is a run of clipped
/// sources. On every clip change the engine applies that clip's speed,
/// pitch and gain; fades and the A-B loop are driven by a 50 ms ticker.
///
/// All playlist mutations run through [_serial] so they never interleave.
class JustAudioDeckEngine implements PlaybackEngine {
  JustAudioDeckEngine({
    required this._sources,
    AudioEffectsBackend? effects,
    PlanResolver? planFor,
    this._ownsEffects = true,
  })  : _effects = effects ?? NoAudioEffects(),
        _planFor = planFor ?? ((_) async => PlaybackPlan.plain) {
    for (final deck in _decks) {
      _subs.add(deck.player.playerStateStream.listen((s) => _onPlayerState(deck, s)));
      _subs.add(deck.player.currentIndexStream.listen((i) => _onIndex(deck, i)));
      _subs.add(deck.player.durationStream.listen((_) => _emit()));
    }
    unawaited(_effects.attach([for (final d in _decks) d.player]));
  }

  final TrackSourceRegistry _sources;
  final AudioEffectsBackend _effects;
  final PlanResolver _planFor;

  /// False when the effects backend is shared with another engine.
  final bool _ownsEffects;
  final _decks = [_Deck('A'), _Deck('B')];
  final _subs = <StreamSubscription<Object?>>[];
  final _stateCtrl = StreamController<EngineState>.broadcast();
  final _eventCtrl = StreamController<EngineEvent>.broadcast();

  int _activeIdx = 0;
  _Deck get _active => _decks[_activeIdx];
  _Deck get _idle => _decks[1 - _activeIdx];

  Track? _next;
  Duration _crossfade = Duration.zero;
  bool _repeatOne = false;
  double _volume = 1.0;
  double _speed = 1.0;
  double _pitch = 0.0;
  double _preampDb = 0.0;
  double? _appliedPitch;
  double _appliedExtraDb = 0;
  Duration? _loopA, _loopB;
  bool _fading = false;
  bool _endedSent = false;

  /// The next track couldn't be resolved (e.g. a stream link failed): when the
  /// current one ends we report [EngineEvent.failed] so the controller loads
  /// it again (and skips it if it still fails) instead of stopping.
  bool _nextUnresolved = false;
  int _tickCount = 0;
  Timer? _ticker;
  Timer? _fadeTimer;
  EngineState _state = const EngineState();

  /// Why the last load failed, so the UI can say it (e.g. "you're offline").
  Object? _lastError;
  @override
  Object? get lastError => _lastError;
  Future<void> _serial = Future.value();

  bool get _gapless => _crossfade == Duration.zero;

  @override
  Stream<EngineState> get stateStream => _stateCtrl.stream;
  @override
  EngineState get state => _state;
  @override
  Stream<EngineEvent> get events => _eventCtrl.stream;

  /// Runs [op] after every previously queued operation finished.
  Future<void> _run(Future<void> Function() op) {
    final result = _serial.then((_) => op());
    // Keep the chain alive even if one op fails.
    _serial = result.catchError((Object _) {});
    return result;
  }

  Future<_Entry> _entryFor(Track track) async => _Entry(track, await _planFor(track));

  /// One just_audio source per clip (a plain track is one plain source).
  Future<List<AudioSource>> _sourcesFor(_Entry entry) async {
    final rendered = entry.plan.renderedFile;
    if (rendered != null) return [AudioSource.uri(Uri.file(rendered), tag: entry.track)];
    final source = _sources.sourceFor(entry.track);
    final uri = await source.resolvePlaybackUri(entry.track);
    final headers = await source.playbackHeaders(entry.track);
    AudioSource child() => AudioSource.uri(uri, headers: headers.isEmpty ? null : headers, tag: entry.track);
    if (!entry.plan.isEdited) return [child()];
    return [
      for (final c in entry.plan.clips)
        ClippingAudioSource(child: child() as UriAudioSource, start: c.sourceStart, end: c.sourceEnd, tag: entry.track),
    ];
  }

  /// Multi-clip tracks can't use LoopMode.one (that loops one clip), so
  /// repeat-one plays them alone with LoopMode.all.
  bool _isolate(_Entry e) => _repeatOne && e.clipCount > 1;

  LoopMode _loopModeFor(_Entry e) => !_repeatOne ? LoopMode.off : (e.clipCount > 1 ? LoopMode.all : LoopMode.one);

  // ------------------------------------------------------------- commands

  @override
  Future<void> load(Track current, {Track? next, Duration position = Duration.zero, bool play = true}) =>
      _run(() async {
        _cancelFade();
        await _idle.player.stop();
        _idle.window.clear();
        _next = next;
        _endedSent = false;
        _nextUnresolved = false;
        final entry = await _entryFor(current);
        final List<AudioSource> sources;
        try {
          sources = await _sourcesFor(entry);
        } on Object catch (e) {
          // Remote track that can't be resolved (offline, removed video…).
          _lastError = e;
          _active.window.clear();
          _eventCtrl.add(EngineEvent.failed);
          return;
        }
        _Entry? nextEntry;
        if (_gapless && next != null && !_isolate(entry)) {
          try {
            nextEntry = await _entryFor(next);
            sources.addAll(await _sourcesFor(nextEntry));
          } on Object {
            nextEntry = null;
            _nextUnresolved = true;
          }
        }
        final (clip, inClip) = entry.plan.locate(position);
        _active.fade = 1;
        _active.window
          ..clear()
          ..add(entry);
        await _applyClipParams();
        try {
          await _active.player.setAudioSources(sources, initialIndex: clip, initialPosition: inClip);
          if (nextEntry != null) _active.window.add(nextEntry);
        } on Object catch (e) {
          _lastError = e;
          _active.window.clear();
          _eventCtrl.add(EngineEvent.failed);
          return;
        }
        await _active.player.setLoopMode(_loopModeFor(entry));
        _loopA = _loopB = null;
        await _applyClipParams();
        // Note: just_audio's play() future completes only when playback stops,
        // so it is intentionally not awaited.
        if (play) unawaited(_active.player.play());
        _startTicker();
        _emit();
      });

  @override
  Future<void> reloadCurrent() async {
    final cur = _active.current;
    if (cur == null) return;
    final plan = await _planFor(cur.track);
    // Only the gain changed (e.g. loudness was just measured): swap the plan
    // in place – no reload, no hiccup.
    if (_sameStructure(cur.plan, plan)) {
      _active.window[0] = _Entry(cur.track, plan);
      await _applyVolumes();
      return;
    }
    final pos = _state.position;
    final playing = _active.player.playing;
    await load(cur.track, next: _next, position: pos, play: playing);
  }

  static bool _sameStructure(PlaybackPlan a, PlaybackPlan b) {
    if (a.clips.length != b.clips.length || a.fadeIn != b.fadeIn || a.fadeOut != b.fadeOut) return false;
    if (a.renderedFile != b.renderedFile) return false;
    for (var i = 0; i < a.clips.length; i++) {
      if (a.clips[i] != b.clips[i]) return false;
    }
    return true;
  }

  @override
  Future<void> setNext(Track? next) => _run(() async {
        _next = next;
        _nextUnresolved = false;
        if (!_gapless) return; // crossfade mode reads _next when it fades
        final deck = _active;
        final cur = deck.current;
        if (cur == null) return;
        // A gapless switch into the next track is pending; _onIndex will fix
        // the window and the controller will send a fresh next.
        final (entry, _) = deck.locate(deck.player.currentIndex ?? 0);
        if (entry != 0) return;
        if (deck.window.length > 1) {
          await deck.player.removeAudioSourceRange(cur.clipCount, deck.flatLength);
          deck.window.removeRange(1, deck.window.length);
        }
        if (next != null && !_isolate(cur)) {
          try {
            final e = await _entryFor(next);
            await deck.player.addAudioSources(await _sourcesFor(e));
            deck.window.add(e);
          } on Object {
            _nextUnresolved = true;
          }
        }
      });

  @override
  Future<void> play() async {
    _endedSent = false;
    unawaited(_active.player.play());
    if (_fading) unawaited(_idle.player.play());
    _startTicker();
  }

  @override
  Future<void> pause() async {
    // Pausing during a crossfade finishes it immediately (simplest UX).
    if (_fading) await _finishFade();
    await _active.player.pause();
    _emit();
  }

  @override
  Future<void> seek(Duration position) => _run(() => _seekOutput(position));

  Future<void> _seekOutput(Duration position) async {
    if (_fading) await _finishFade();
    _endedSent = false;
    final entry = _active.current;
    if (entry == null) return;
    final (clip, inClip) = entry.plan.locate(position < Duration.zero ? Duration.zero : position);
    await _active.player.seek(inClip, index: clip);
    _emit();
  }

  @override
  Future<void> stop() => _run(() async {
        _cancelFade();
        for (final d in _decks) {
          await d.player.stop();
        }
        _ticker?.cancel();
        _ticker = null;
        _emit();
      });

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _applyVolumes();
  }

  @override
  Future<void> setCrossfade(Duration duration) => _run(() async {
        final wasGapless = _gapless;
        _crossfade = duration < Duration.zero ? Duration.zero : duration;
        final deck = _active;
        final cur = deck.current;
        if (cur == null) return;
        final (entry, _) = deck.locate(deck.player.currentIndex ?? 0);
        if (entry != 0) return;
        if (wasGapless && !_gapless && deck.window.length > 1) {
          // Leaving gapless: the active deck must not auto-advance any more.
          await deck.player.removeAudioSourceRange(cur.clipCount, deck.flatLength);
          deck.window.removeRange(1, deck.window.length);
        } else if (!wasGapless && _gapless && _next != null && deck.window.length == 1 && !_isolate(cur)) {
          try {
            final e = await _entryFor(_next!);
            await deck.player.addAudioSources(await _sourcesFor(e));
            deck.window.add(e);
          } on Object {
            _nextUnresolved = true;
          }
        }
      });

  @override
  Future<void> setRepeatOne(bool enabled) async {
    _repeatOne = enabled;
    final cur = _active.current;
    if (cur == null) return;
    await _active.player.setLoopMode(_loopModeFor(cur));
    // Multi-clip tracks need the next track out of the window while looping.
    if (cur.clipCount > 1) await setNext(_next);
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.25, 4.0);
    await _applyClipParams();
  }

  @override
  Future<void> setPitchSemitones(double semitones) async {
    _pitch = semitones.clamp(-12.0, 12.0);
    await _applyClipParams();
  }

  @override
  Future<void> reapplyEffects() async {
    // Forget what we think is applied so everything is pushed again.
    _appliedPitch = null;
    _appliedExtraDb = -999;
    await _applyClipParams();
  }

  @override
  Future<void> setPreampDb(double db) async {
    _preampDb = db;
    await _applyVolumes();
  }

  @override
  Future<void> setAbLoop(Duration? a, Duration? b) async {
    if (a != null && b != null && b > a + const Duration(milliseconds: 200)) {
      _loopA = a;
      _loopB = b;
      // Jump in right away if we are already past B.
      if (_state.position >= b || _state.position < a) await seek(a);
    } else {
      _loopA = _loopB = null;
    }
  }

  @override
  Future<void> dispose() async {
    _ticker?.cancel();
    _fadeTimer?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    // A shared backend (editor preview) must outlive this engine.
    _ownsEffects ? await _effects.dispose() : await _effects.detach([for (final d in _decks) d.player]);
    for (final d in _decks) {
      await d.player.dispose();
    }
    await _stateCtrl.close();
    await _eventCtrl.close();
  }

  // -------------------------------------------------------------- internals

  void _onIndex(_Deck deck, int? index) {
    if (index == null) return;
    if (!identical(deck, _active)) {
      // Clip change on the incoming crossfade deck.
      unawaited(_applyClipParams());
      return;
    }
    final (entry, _) = deck.locate(index);
    if (entry == 0 || !_gapless) {
      unawaited(_applyClipParams());
      return;
    }
    _run(() async {
      // Re-check: things may have changed while queued.
      final (e, _) = deck.locate(deck.player.currentIndex ?? 0);
      if (!identical(deck, _active) || e == 0) return;
      final old = deck.window.first;
      await deck.player.removeAudioSourceRange(0, old.clipCount);
      deck.window.removeAt(0);
      await deck.player.setLoopMode(_loopModeFor(deck.window.first));
      _eventCtrl.add(EngineEvent.advancedToNext);
      await _applyClipParams();
      _emit();
    });
  }

  void _onPlayerState(_Deck deck, PlayerState s) {
    if (!identical(deck, _active)) return;
    if (s.processingState == ProcessingState.completed && !_endedSent && !_fading) {
      _endedSent = true;
      if (_nextUnresolved && _next != null) {
        _nextUnresolved = false;
        _eventCtrl.add(EngineEvent.failed);
      } else {
        _eventCtrl.add(EngineEvent.ended);
      }
    }
    // Playback may be started from outside (notification, media keys).
    if (s.playing) _startTicker();
    _emit();
  }

  /// Applies speed, pitch and gain of the clip each deck is playing now.
  Future<void> _applyClipParams() async {
    for (final d in _decks) {
      final e = d.current;
      if (e == null) continue;
      final clip = e.plan.clips[d.clipIndex.clamp(0, e.clipCount - 1)];
      final speed = (_speed * clip.speed).clamp(0.25, 4.0);
      if ((d.player.speed - speed).abs() > 0.001) await d.player.setSpeed(speed);
    }
    final cur = _active.current;
    final clipPitch = cur == null ? 0.0 : cur.plan.clips[_active.clipIndex.clamp(0, cur.clipCount - 1)].pitchSemitones;
    final pitch = _pitch + clipPitch;
    if (_appliedPitch != pitch) {
      _appliedPitch = pitch;
      await _effects.setPitchRatio(semitonesToRatio(pitch));
    }
    await _applyVolumes();
  }

  /// Volume = master × crossfade × gains (preamp, track, clip) × edit fades.
  /// What the player volume can't do (positive gain on Android) goes to the
  /// effects backend.
  Future<void> _applyVolumes() async {
    var extraDb = 0.0;
    for (final d in _decks) {
      var gainDb = _preampDb;
      var planFade = 1.0;
      final e = d.current;
      if (e != null) {
        final idx = d.clipIndex.clamp(0, e.clipCount - 1);
        gainDb += e.plan.trackGainDb + e.plan.clips[idx].gainDb;
        if (e.plan.fadeIn > Duration.zero || e.plan.fadeOut > Duration.zero) {
          final out = e.plan.toOutput(idx, d.player.position);
          planFade = e.plan.fadeFactor(out, _totalOf(e, d));
        }
      }
      var linear = _volume * d.fade * planFade * dbToLinear(gainDb);
      final max = _effects.maxLinearVolume;
      if (linear > max) {
        if (identical(d, _active)) extraDb = 20 * math.log(linear / max) / math.ln10;
        linear = max;
      }
      if ((d.player.volume - linear).abs() > 0.0005) await d.player.setVolume(linear);
    }
    if ((extraDb - _appliedExtraDb).abs() > 0.05) {
      _appliedExtraDb = extraDb;
      await _effects.setExtraGainDb(extraDb);
    }
  }

  Duration? _totalOf(_Entry e, _Deck d) {
    if (!e.plan.isEdited) return d.player.duration ?? e.track.duration;
    return e.plan.outputDuration(sourceDuration: e.track.durationMs > 0 ? e.track.duration : null);
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
  }

  void _tick() {
    _tickCount++;
    final p = _active.player;
    final e = _active.current;
    // Nothing to drive while paused: stop the timer (restarted on play).
    if (!p.playing && !_fading) {
      _ticker?.cancel();
      _ticker = null;
      _emit();
      return;
    }
    // A-B loop (output time).
    if (_loopA != null && _loopB != null && p.playing && _state.position >= _loopB!) {
      unawaited(seek(_loopA!));
    }
    // Edit fades need smooth volume updates.
    if (e != null && p.playing && (e.plan.fadeIn > Duration.zero || e.plan.fadeOut > Duration.zero)) {
      unawaited(_applyVolumes());
    }
    // Position updates for the UI at ~4 Hz (the seek bar interpolates).
    if (_tickCount % 5 == 0 || (_loopA != null && p.playing)) _emit();
    if (_tickCount % 5 != 0) return;
    if (_gapless || _fading || _repeatOne || _next == null || e == null) return;
    final total = _totalOf(e, _active);
    if (!p.playing || total == null || total < _crossfade * 2) return;
    if (_state.position >= total - _crossfade) _startCrossfade();
  }

  void _startCrossfade() {
    final next = _next;
    if (next == null) return;
    _fading = true;
    _run(() async {
      final incoming = _idle;
      final outgoing = _active;
      try {
        final entry = await _entryFor(next);
        await incoming.player.setAudioSources(await _sourcesFor(entry));
        incoming.window
          ..clear()
          ..add(entry);
        await incoming.player.setLoopMode(_loopModeFor(entry));
      } on Object {
        _fading = false;
        _nextUnresolved = true;
        return; // let the current track end normally
      }
      incoming.fade = 0;
      await _applyClipParams();
      unawaited(incoming.player.play());

      // Swap roles now so position/UI follow the new track immediately.
      _activeIdx = 1 - _activeIdx;
      _next = null;
      _endedSent = false;
      _loopA = _loopB = null;
      _eventCtrl.add(EngineEvent.advancedToNext);

      final totalMs = _crossfade.inMilliseconds;
      final sw = Stopwatch()..start();
      _fadeTimer = Timer.periodic(const Duration(milliseconds: 40), (t) {
        final f = (sw.elapsedMilliseconds / totalMs).clamp(0.0, 1.0);
        incoming.fade = f;
        outgoing.fade = 1 - f;
        _applyVolumes();
        if (f >= 1) {
          t.cancel();
          _completeFade(outgoing);
        }
      });
    });
  }

  Future<void> _completeFade(_Deck outgoing) async {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    await outgoing.player.stop();
    outgoing.window.clear();
    outgoing.fade = 1;
    _active.fade = 1;
    _fading = false;
    await _applyVolumes();
  }

  Future<void> _finishFade() async {
    if (!_fading) return;
    await _completeFade(_idle);
  }

  void _cancelFade() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _fading = false;
    for (final d in _decks) {
      d.fade = 1;
    }
  }

  void _emit() {
    final d = _active;
    final p = d.player;
    final e = d.current;
    var position = p.position;
    var buffered = p.bufferedPosition;
    var duration = p.duration;
    if (e != null && e.plan.isEdited) {
      final idx = d.clipIndex.clamp(0, e.clipCount - 1);
      position = e.plan.toOutput(idx, position);
      buffered = e.plan.toOutput(idx, buffered);
      duration = _totalOf(e, d);
    }
    final next = EngineState(
      playing: p.playing,
      status: switch (p.processingState) {
        ProcessingState.idle => EngineStatus.idle,
        ProcessingState.loading => EngineStatus.loading,
        ProcessingState.buffering => EngineStatus.buffering,
        ProcessingState.ready => EngineStatus.ready,
        ProcessingState.completed => EngineStatus.completed,
      },
      position: position,
      bufferedPosition: buffered,
      duration: duration,
    );
    // Identical snapshots (e.g. while paused) would only cause rebuilds.
    if (_same(next, _state)) return;
    _state = next;
    if (!_stateCtrl.isClosed) _stateCtrl.add(_state);
  }

  static bool _same(EngineState a, EngineState b) =>
      a.playing == b.playing &&
      a.status == b.status &&
      a.duration == b.duration &&
      a.position == b.position &&
      (a.bufferedPosition - b.bufferedPosition).abs() < const Duration(milliseconds: 500);
}

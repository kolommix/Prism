import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/ffmpeg/ffmpeg_runner.dart';
import '../../../core/providers.dart';
import '../../../l10n/l10n.dart';
import '../../audio_fx/application/eq_controller.dart';
import '../../audio_fx/application/loudness_controller.dart';
import '../../audio_fx/domain/eq_math.dart';
import '../../audio_fx/domain/eq_settings.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/track.dart';
import '../../player/application/player_providers.dart';
import '../../player/domain/playback_plan.dart';
import '../../player/engine/just_audio_deck_engine.dart';
import '../../player/engine/playback_engine.dart';
import '../data/edit_repository.dart';
import '../data/peak_cache.dart';
import '../domain/audio_analysis.dart';
import '../domain/edit_decision_list.dart';
import '../domain/editor_tools.dart';
import '../domain/export_command.dart';
import '../domain/timeline.dart';
import 'edit_exporter.dart';

final editExporterProvider = Provider<EditExporter>((ref) => EditExporter(
      ffmpeg: ref.watch(ffmpegRunnerProvider),
      repo: ref.watch(libraryRepositoryProvider),
      scanner: ref.watch(libraryScannerProvider),
    ));

/// Android ringtone calls; everywhere else [supported] is false.
class RingtoneService {
  static const _channel = MethodChannel('prism/ringtone');
  static bool get supported => Platform.isAndroid;
  static Future<bool> needsPermission() async => await _channel.invokeMethod<bool>('needsPermission') ?? true;
  static Future<void> openPermission() => _channel.invokeMethod<void>('openPermission');
  static Future<void> set(String path, String title) => _channel.invokeMethod<void>('set', {'path': path, 'title': title});
}

/// Where the export goes.
enum ExportTarget { newTrack, file, overwrite }

/// Everything the editor screen shows.
class EditorState {
  const EditorState({
    this.track,
    this.sourceDuration = Duration.zero,
    this.history = const EditHistory(),
    this.timeline,
    this.livePreset = false,
    this.analysis,
    this.others = const {},
    this.error,
    this.selA,
    this.selB,
    this.cursor = Duration.zero,
    this.previewB = true,
    this.previewPlaying = false,
    this.previewPos = Duration.zero,
    this.previewAt,
    this.previewRendering = false,
    this.loopSelection = false,
    this.followPlayhead = true,
    this.snapBeats = false,
    this.snapSilence = false,
    this.snapZero = true,
    this.busy,
    this.progress,
    this.restoredViewStart = Duration.zero,
    this.restoredViewLength = Duration.zero,
  });

  final Track? track;
  final Duration sourceDuration;
  final EditHistory history;
  final Timeline? timeline;
  final bool livePreset;

  /// The track's waveform, beats and silences.
  final AudioAnalysis? analysis;

  /// Waveforms of merged songs, by path.
  final Map<String, PeakPyramid> others;
  final String? error;

  /// Selection and cursor in output (edited) time.
  final Duration? selA, selB;
  final Duration cursor;

  /// A/B preview: false = original file, true = edited version.
  final bool previewB;
  final bool previewPlaying;

  /// Playhead in output time (mapped when previewing the original), as of
  /// [previewAt]; the screen moves it on between updates.
  final Duration previewPos;
  final DateTime? previewAt;

  /// Rendering a preview of an edit the player can't do on the fly.
  final bool previewRendering;
  final bool loopSelection;
  final bool followPlayhead;
  final bool snapBeats, snapSilence, snapZero;

  /// Non-null while exporting/rendering ("Exporting…").
  final String? busy;
  final double? progress;
  final Duration restoredViewStart, restoredViewLength;

  bool get ready => track != null && timeline != null;
  bool get hasSelection => selA != null && selB != null && (selB! - selA!).abs() >= minSegment;
  Duration get selStart => selA! < selB! ? selA! : selB!;
  Duration get selEnd => selA! < selB! ? selB! : selA!;

  PeakPyramid get pyramid => analysis?.pyramid ?? PeakPyramid.empty;

  /// Range the tools act on: the selection, or the segment under the cursor.
  (Duration, Duration) get targetRange {
    if (hasSelection) return (selStart, selEnd);
    final t = timeline!;
    final (i, _) = t.locate(cursor);
    final start = t.segmentStarts[i];
    return (start, start + t.segments[i].outputLength);
  }

  /// Snap targets in output time, sorted (only the kinds that are on).
  List<Duration> snapPoints() {
    final t = timeline;
    final a = analysis;
    if (t == null) return const [];
    final out = <Duration>[...t.segmentStarts, t.duration];
    if (a != null && snapBeats) {
      for (final b in a.beats) {
        out.add(t.sourceToOutput(b));
      }
    }
    if (a != null && snapSilence) {
      for (final (from, to) in a.silences) {
        out
          ..add(t.sourceToOutput(from))
          ..add(t.sourceToOutput(to));
      }
    }
    return out..sort();
  }

  static const _keep = Object();

  EditorState copyWith({
    Track? track,
    Duration? sourceDuration,
    EditHistory? history,
    Timeline? timeline,
    bool? livePreset,
    AudioAnalysis? analysis,
    Map<String, PeakPyramid>? others,
    Object? error = _keep,
    Object? selA = _keep,
    Object? selB = _keep,
    Duration? cursor,
    bool? previewB,
    bool? previewPlaying,
    Duration? previewPos,
    DateTime? previewAt,
    bool? previewRendering,
    bool? loopSelection,
    bool? followPlayhead,
    bool? snapBeats,
    bool? snapSilence,
    bool? snapZero,
    Object? busy = _keep,
    Object? progress = _keep,
    Duration? restoredViewStart,
    Duration? restoredViewLength,
  }) =>
      EditorState(
        track: track ?? this.track,
        sourceDuration: sourceDuration ?? this.sourceDuration,
        history: history ?? this.history,
        timeline: timeline ?? this.timeline,
        livePreset: livePreset ?? this.livePreset,
        analysis: analysis ?? this.analysis,
        others: others ?? this.others,
        error: identical(error, _keep) ? this.error : error as String?,
        selA: identical(selA, _keep) ? this.selA : selA as Duration?,
        selB: identical(selB, _keep) ? this.selB : selB as Duration?,
        cursor: cursor ?? this.cursor,
        previewB: previewB ?? this.previewB,
        previewPlaying: previewPlaying ?? this.previewPlaying,
        previewPos: previewPos ?? this.previewPos,
        previewAt: previewAt ?? this.previewAt,
        previewRendering: previewRendering ?? this.previewRendering,
        loopSelection: loopSelection ?? this.loopSelection,
        followPlayhead: followPlayhead ?? this.followPlayhead,
        snapBeats: snapBeats ?? this.snapBeats,
        snapSilence: snapSilence ?? this.snapSilence,
        snapZero: snapZero ?? this.snapZero,
        busy: identical(busy, _keep) ? this.busy : busy as String?,
        progress: identical(progress, _keep) ? this.progress : progress as double?,
        restoredViewStart: restoredViewStart ?? this.restoredViewStart,
        restoredViewLength: restoredViewLength ?? this.restoredViewLength,
      );
}

/// Non-destructive editor for one track (keyed by track id).
///
/// * Every change pushes an [EditOp] into the [EditHistory] and the session is
///   saved right away (`track_edits`), redo steps and zoom included, so nothing
///   is lost; the audio file is only written by an explicit "overwrite".
/// * Preview runs its own [JustAudioDeckEngine]. "B" plays the edit through the
///   clip plan the main player uses for live presets, or a rendered WAV when
///   the edit has things clips can't do. "A" plays the original. Switching
///   keeps the musical position.
class EditorController extends Notifier<EditorState> {
  EditorController(this.trackId);

  final int trackId;
  JustAudioDeckEngine? _preview;
  StreamSubscription<EngineState>? _previewSub;
  Timer? _loopTimer;
  Timer? _liveRender;
  FfmpegCancel? _previewCancel;
  FfmpegCancel? _exportCancel;
  int _viewStartMs = 0, _viewLengthMs = 0;
  Timer? _viewSave;

  EditRepository get _edits => ref.read(editRepositoryProvider);
  EditExporter get _exporter => ref.read(editExporterProvider);

  @override
  EditorState build() {
    ref.onDispose(_onDispose);
    Future.microtask(_load);
    return const EditorState();
  }

  Future<void> _onDispose() async {
    _viewSave?.cancel();
    _liveRender?.cancel();
    _loopTimer?.cancel();
    _previewCancel?.cancel();
    await _disposePreview();
  }

  Future<PeakCache> _peakCache() async {
    final dir = await getApplicationSupportDirectory();
    return PeakCache(Directory(p.join(dir.path, 'peak_cache')), ref.read(ffmpegRunnerProvider));
  }

  Future<void> _load() async {
    final track = await ref.read(libraryRepositoryProvider).trackById(trackId);
    if (!ref.mounted) return;
    if (track == null) {
      state = state.copyWith(error: l10n.trackNotFound);
      return;
    }
    final stored = await _edits.load(trackId);
    if (!ref.mounted) return;
    final exporter = _exporter;
    AudioAnalysis? analysis;
    String? error;
    try {
      if (exporter.available) analysis = await (await _peakCache()).load(track.uri);
    } on Object catch (e) {
      error = '$e';
    }
    if (!ref.mounted) return;
    // Decoded length is the most reliable duration (tags can be wrong).
    final decoded = analysis?.pyramid.duration;
    final duration = decoded != null && decoded > Duration.zero ? decoded : track.duration;
    final same = stored != null && stored.edl.sourceUri == track.uri;
    final ops = same ? stored.edl.ops : const <EditOp>[];
    final redo = same ? stored.edl.redoOps : const <EditOp>[];
    final history = EditHistory(ops: List.unmodifiable([...ops, ...redo]), cursor: ops.length);
    final timeline = Timeline.fromOps(duration, history.applied);
    _viewStartMs = same ? stored.edl.viewStartMs : 0;
    _viewLengthMs = same ? stored.edl.viewLengthMs : 0;
    final cursorMs = same ? stored.edl.cursorMs : 0;
    state = EditorState(
      track: track,
      sourceDuration: duration,
      history: history,
      timeline: timeline,
      livePreset: stored?.livePreset ?? false,
      analysis: analysis,
      cursor: Duration(milliseconds: cursorMs) > timeline.duration ? Duration.zero : Duration(milliseconds: cursorMs),
      error: exporter.available ? error : l10n.ffmpegIsNotAvailableWaveformAnd,
      restoredViewStart: Duration(milliseconds: _viewStartMs),
      restoredViewLength: Duration(milliseconds: _viewLengthMs),
    );
    await _loadMerged(timeline);
  }

  /// Waveforms for songs merged in an earlier session.
  Future<void> _loadMerged(Timeline t) async {
    final cache = await _peakCache();
    for (final s in t.segments) {
      final uri = s.input;
      if (uri == null || state.others.containsKey(uri)) continue;
      try {
        final a = await cache.load(uri);
        if (!ref.mounted) return;
        if (a != null) state = state.copyWith(others: {...state.others, uri: a.pyramid});
      } on Object {
        // The waveform stays flat; the song still exports.
      }
    }
  }

  EditDecisionList _edl([EditHistory? h]) {
    final hist = h ?? state.history;
    return EditDecisionList(
      version: 2,
      sourceUri: state.track!.uri,
      sourceDurationMs: state.sourceDuration.inMilliseconds,
      ops: hist.applied,
      redoOps: hist.ops.sublist(hist.cursor),
      cursorMs: state.cursor.inMilliseconds,
      viewStartMs: _viewStartMs,
      viewLengthMs: _viewLengthMs,
    );
  }

  // ------------------------------------------------------------- editing

  void apply(EditOp op) => _setHistory(state.history.push(op), clearSelection: true);
  void undo() => _setHistory(state.history.undo());
  void redo() => _setHistory(state.history.redo());

  /// Back to the original; every op stays in history, so "redo" brings the
  /// edits back one by one.
  void resetAll() => _setHistory(EditHistory(ops: state.history.applied, cursor: 0));

  void _setHistory(EditHistory h, {bool clearSelection = false}) {
    if (!state.ready) return;
    final t = Timeline.fromOps(state.sourceDuration, h.applied);
    var s = state.copyWith(history: h, timeline: t);
    if (clearSelection) s = s.copyWith(selA: null, selB: null);
    state = s.copyWith(cursor: s.cursor > t.duration ? t.duration : s.cursor);
    unawaited(_persist());
    if (state.previewB) unawaited(_reloadPreview());
  }

  Future<void> _persist() async {
    await _edits.save(trackId, _edl(), livePreset: state.livePreset);
    if (state.livePreset) _scheduleLive();
  }

  void _refreshMainPlayer() {
    if (ref.read(currentTrackProvider)?.id == trackId) ref.read(playerControllerProvider).reloadCurrent();
  }

  /// Live preset with things the player can't do: render the file it will
  /// play, a moment after the last change.
  void _scheduleLive() {
    _liveRender?.cancel();
    _liveRender = Timer(const Duration(milliseconds: 800), () => unawaited(_renderLive()));
  }

  Future<void> _renderLive() async {
    if (!state.ready) return;
    final t = state.timeline!;
    if (!t.isLiveCompatible) {
      final path = EditRepository.renderPath(trackId, _edl());
      if (path == null) return;
      try {
        await _exporter.renderWav(_edl(), path);
        await _dropOldRenders(path);
      } on Object catch (e) {
        if (ref.mounted) state = state.copyWith(error: '$e');
        return;
      }
    }
    if (ref.mounted) _refreshMainPlayer();
  }

  Future<void> _dropOldRenders(String keep) async {
    final dir = Directory(p.dirname(keep));
    await for (final f in dir.list()) {
      if (f is File && p.basename(f.path).startsWith('$trackId-') && f.path != keep) await f.delete();
    }
  }

  /// "Apply edit as live preset": the main player plays the track edited.
  Future<void> setLivePreset(bool on) async {
    state = state.copyWith(livePreset: on);
    await _edits.save(trackId, _edl(), livePreset: on);
    if (on && !state.timeline!.isLiveCompatible) {
      await _busy(l10n.edRenderingPreset, (onProgress, cancel) async {
        final path = EditRepository.renderPath(trackId, _edl());
        if (path != null) await _exporter.renderWav(_edl(), path, onProgress: onProgress, cancel: cancel);
      });
    }
    _refreshMainPlayer();
  }

  void setSelection(Duration? a, Duration? b) => state = state.copyWith(selA: a, selB: b);
  void selectAll() => setSelection(Duration.zero, state.timeline?.duration);
  void setCursor(Duration t) {
    state = state.copyWith(cursor: t);
    _saveSessionSoon();
  }

  void setView(Duration start, Duration length) {
    _viewStartMs = start.inMilliseconds;
    _viewLengthMs = length.inMilliseconds;
    _saveSessionSoon();
  }

  void _saveSessionSoon() {
    if (!state.ready) return;
    _viewSave?.cancel();
    _viewSave = Timer(const Duration(seconds: 1), () => unawaited(_edits.save(trackId, _edl(), livePreset: state.livePreset)));
  }

  void toggleSnapBeats() => state = state.copyWith(snapBeats: !state.snapBeats);
  void toggleSnapSilence() => state = state.copyWith(snapSilence: !state.snapSilence);
  void toggleSnapZero() => state = state.copyWith(snapZero: !state.snapZero);
  void toggleFollow() => state = state.copyWith(followPlayhead: !state.followPlayhead);

  /// Moves the selection's edges onto the nearest zero crossings, so cuts don't
  /// click. Runs after a drag ends: it reads a few milliseconds of the file.
  Future<void> refineSelection() async {
    if (!state.snapZero || !state.hasSelection || !_exporter.available) return;
    final a = state.selA!, b = state.selB!;
    final na = await _zeroNear(a), nb = await _zeroNear(b);
    if (!ref.mounted) return;
    if (state.selA == a && state.selB == b) setSelection(na, nb);
  }

  Future<Duration> _zeroNear(Duration t) async {
    final tl = state.timeline!;
    final (i, src) = tl.locate(t);
    final s = tl.segments[i];
    if (s.silent) return t;
    final zero = await _exporter.nearestZero(s.input ?? state.track!.uri, src);
    final deltaUs = (zero - src).inMicroseconds * (s.reverse ? -1 : 1);
    return t + Duration(microseconds: (deltaUs / s.speed).round());
  }

  // --------------------------------------------------------- quick tools

  SegmentPeak get _peak => peakReader(state.pyramid, state.others);

  /// Returns false when there was nothing to do.
  bool autoTrim() {
    final op = autoTrimOp(state.timeline!, _peak);
    if (op == null) return false;
    apply(op);
    return true;
  }

  bool removeSilence() {
    final op = removeSilenceOp(state.timeline!, _peak);
    if (op == null) return false;
    apply(op);
    return true;
  }

  bool normalize() {
    final db = normalizeGainDb(state.timeline!, _peak);
    if (db == null) return false;
    apply(EditOp.masterGain(db: state.timeline!.masterGainDb + db));
    return true;
  }

  /// Adds songs at the end of the edit.
  Future<void> merge(List<Track> tracks) async {
    final cache = await _peakCache();
    for (final t in tracks) {
      AudioAnalysis? a;
      try {
        a = await cache.load(t.uri);
      } on Object {
        a = null;
      }
      final len = a?.pyramid.duration ?? t.duration;
      if (len <= Duration.zero) continue;
      if (a != null) state = state.copyWith(others: {...state.others, t.uri: a.pyramid});
      apply(EditOp.merge(uri: t.uri, durationMs: len.inMilliseconds));
    }
  }

  // ------------------------------------------------------------- preview

  bool get _needsRender => state.previewB && !state.timeline!.isLiveCompatible;

  Future<JustAudioDeckEngine> _engine() async {
    final existing = _preview;
    if (existing != null) return existing;
    final engine = JustAudioDeckEngine(
      sources: ref.read(trackSourcesProvider),
      effects: ref.read(audioEffectsProvider),
      ownsEffects: false,
      planFor: (_) async => state.previewB && !_needsRender ? state.timeline!.toPlan() : PlaybackPlan.plain,
    );
    final eq = ref.read(eqControllerProvider).settings;
    await engine.setPreampDb(eq.enabled ? eq.preampDb : 0);
    _previewSub = engine.stateStream.listen((s) {
      final t = state.timeline;
      if (t == null) return;
      final pos = state.previewB ? s.position : t.sourceToOutput(s.position);
      state = state.copyWith(previewPlaying: s.playing, previewPos: pos, previewAt: DateTime.now());
      _syncLoopTimer();
    });
    return _preview = engine;
  }

  /// Converts an output position to what the preview engine expects.
  Duration _toEngine(Duration out) => state.previewB ? out : state.timeline!.outputToSource(out);

  /// The track to load: itself, or the rendered file of the edit.
  Future<Track?> _previewTrack() async {
    final track = state.track!;
    if (!_needsRender) return track;
    final dir = await getTemporaryDirectory();
    final edl = _edl();
    final name = EditRepository.renderPath(trackId, edl);
    final path = p.join(dir.path, 'prism_preview', p.basename(name ?? '$trackId-preview.wav'));
    _previewCancel?.cancel();
    final cancel = FfmpegCancel();
    _previewCancel = cancel;
    state = state.copyWith(previewRendering: true);
    try {
      await _exporter.renderWav(edl, path, cancel: cancel);
      await _dropOldRenders(path);
      if (!ref.mounted) return null;
      return track.copyWith(uri: path);
    } on ExportCancelled {
      return null;
    } on Object catch (e) {
      if (ref.mounted) state = state.copyWith(error: '$e');
      return null;
    } finally {
      if (ref.mounted && identical(_previewCancel, cancel)) state = state.copyWith(previewRendering: false);
    }
  }

  Future<void> togglePreview() async {
    if (!state.ready) return;
    final engine = await _engine();
    if (state.previewPlaying) {
      await engine.pause();
      return;
    }
    // Only one thing plays at a time.
    await ref.read(playerControllerProvider).pause();
    if (engine.state.status == EngineStatus.idle || engine.state.status == EngineStatus.completed) {
      final track = await _previewTrack();
      if (track == null) return;
      final start = state.loopSelection && state.hasSelection ? state.selStart : state.cursor;
      await engine.load(track, position: _toEngine(start));
    } else {
      await engine.play();
    }
  }

  /// A/B switch at the same musical position.
  Future<void> setPreviewB(bool b) async {
    if (b == state.previewB || !state.ready) return;
    final pos = state.previewPlaying ? currentPosition() : state.cursor;
    state = state.copyWith(previewB: b, cursor: pos);
    await _reloadPreview();
  }

  Future<void> seekPreview(Duration out) async {
    state = state.copyWith(cursor: out, previewPos: out, previewAt: DateTime.now());
    _saveSessionSoon();
    final engine = _preview;
    if (engine != null && engine.state.status != EngineStatus.idle) await engine.seek(_toEngine(out));
  }

  Future<void> _reloadPreview() async {
    final engine = _preview;
    if (engine == null || engine.state.status == EngineStatus.idle) return;
    final playing = engine.state.playing;
    final pos = state.previewPlaying ? currentPosition() : state.cursor;
    if (playing) await engine.pause();
    final track = await _previewTrack();
    if (track == null) return;
    await engine.load(track, position: _toEngine(pos > state.timeline!.duration ? Duration.zero : pos), play: playing);
  }

  /// Playhead right now, between the engine's position updates.
  Duration currentPosition() {
    if (!state.previewPlaying || state.previewAt == null) return state.previewPos;
    final moved = DateTime.now().difference(state.previewAt!);
    final t = state.previewPos + moved;
    final total = state.timeline?.duration ?? t;
    return t > total ? total : t;
  }

  void toggleLoop() {
    state = state.copyWith(loopSelection: !state.loopSelection);
    _syncLoopTimer();
  }

  void _syncLoopTimer() {
    final want = state.loopSelection && state.previewPlaying;
    if (!want) {
      _loopTimer?.cancel();
      _loopTimer = null;
    } else {
      _loopTimer ??= Timer.periodic(const Duration(milliseconds: 15), (_) => _checkLoop());
    }
  }

  void _checkLoop() {
    if (!state.hasSelection || !state.previewPlaying) return;
    final pos = currentPosition();
    if (pos >= state.selEnd || pos < state.selStart - const Duration(milliseconds: 300)) {
      unawaited(seekPreview(state.selStart));
    }
  }

  Future<void> _disposePreview() async {
    await _previewSub?.cancel();
    final engine = _preview;
    _preview = null;
    if (engine != null) {
      await engine.dispose();
      // The preview used the shared effects backend; restore the player's.
      await ref.read(playerControllerProvider).reapplyEffects();
    }
  }

  // -------------------------------------------------------------- export

  List<String> _eqFilters(bool on) {
    if (!on) return const [];
    final EqSettings eq = ref.read(eqControllerProvider).settings;
    if (!eq.enabled) return const [];
    return eqExportFilters(
      frequencies: eqBandFrequencies,
      gainsDb: eq.gainsDb,
      q: eqBandQ,
      bassDb: eq.bassBoostDb,
      bassFrequency: bassBoostFrequency,
      bassQ: bassShelfQ,
      preampDb: eq.preampDb,
    );
  }

  void cancelExport() => _exportCancel?.cancel();

  Future<String?> saveAsNewTrack(ExportFormat format, ExportSettings settings) =>
      _busy(l10n.savingNewTrack, (onProgress, cancel) => _exporter.saveAsNewTrack(state.track!, _edl(), format,
          settings: settings, globalFilters: _eqFilters(settings.applyGlobalEq), onProgress: onProgress, cancel: cancel));

  Future<(String, List<int>)?> renderForFile(ExportFormat format, ExportSettings settings) => _busy(l10n.exporting, (onProgress, cancel) async {
        final (name, bytes) = await _exporter.renderToBytes(state.track!, _edl(), format,
            settings: settings, globalFilters: _eqFilters(settings.applyGlobalEq), onProgress: onProgress, cancel: cancel);
        return (name, bytes as List<int>);
      });

  /// Writes over the song's file (backup first) and clears the edit, which is
  /// now part of the file. Returns the backup's path.
  Future<String?> overwriteOriginal(ExportSettings settings) => _busy(l10n.exporting, (onProgress, cancel) async {
        // Windows won't replace a file that is open.
        final player = ref.read(playerControllerProvider);
        if (ref.read(currentTrackProvider)?.id == trackId) await player.pause();
        await _disposePreview();
        final dir = await getApplicationSupportDirectory();
        final backup = await _exporter.overwriteWithBackup(state.track!, _edl(), Directory(p.join(dir.path, 'tag-backups')),
            settings: settings, globalFilters: _eqFilters(settings.applyGlobalEq), onProgress: onProgress, cancel: cancel);
        await _edits.delete(trackId);
        final reloaded = EditHistory.of(const []);
        final fresh = await (await _peakCache()).load(state.track!.uri);
        final len = fresh?.pyramid.duration ?? state.timeline!.duration;
        state = state.copyWith(
          history: reloaded,
          timeline: Timeline.fromOps(len, const []),
          sourceDuration: len,
          analysis: fresh,
          livePreset: false,
          cursor: Duration.zero,
          selA: null,
          selB: null,
        );
        return backup;
      });

  /// The selection (or the whole edit) as a file for a ringtone: Android sets
  /// it right away if allowed; returns the rendered path. Null = no permission
  /// yet (the system screen was opened) or cancelled.
  Future<String?> makeRingtone() => _busy(l10n.edMakingRingtone, (onProgress, cancel) async {
        final s = state;
        final ops = s.hasSelection ? ringtoneOps(s.selStart, s.selEnd) : const <EditOp>[];
        final edl = EditDecisionList(
          sourceUri: s.track!.uri,
          sourceDurationMs: s.sourceDuration.inMilliseconds,
          ops: [...s.history.applied, ...ops],
        );
        final dir = await getTemporaryDirectory();
        final path = p.join(dir.path, 'prism_ringtone_$trackId.m4a');
        await _exporter.render(edl, path, ExportFormat.m4a,
            settings: const ExportSettings(keepMetadata: false, removeCover: true), onProgress: onProgress, cancel: cancel);
        return path;
      });

  Future<T?> _busy<T>(String label, Future<T> Function(void Function(double), FfmpegCancel) work) async {
    if (state.busy != null || !state.ready) return null;
    final cancel = FfmpegCancel();
    _exportCancel = cancel;
    state = state.copyWith(busy: label, progress: 0.0);
    try {
      return await work((p) {
        if (ref.mounted) state = state.copyWith(progress: p);
      }, cancel);
    } on ExportCancelled {
      return null;
    } finally {
      _exportCancel = null;
      if (ref.mounted) state = state.copyWith(busy: null, progress: null);
    }
  }
}

final editorControllerProvider =
    NotifierProvider.autoDispose.family<EditorController, EditorState, int>(EditorController.new);

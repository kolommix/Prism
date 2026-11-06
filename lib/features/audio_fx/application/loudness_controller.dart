import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ffmpeg/ffmpeg_runner.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/track.dart';
import '../../player/application/playback_plan_service.dart';
import '../../player/application/player_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/loudness.dart';
import 'loudness_analyzer.dart';

/// FFmpeg for this platform (null when unavailable). Overridden in bootstrap.
final ffmpegRunnerProvider = Provider<FfmpegRunner?>((ref) => null);

/// Plan service shared with the engine. Overridden in bootstrap.
final playbackPlanServiceProvider = Provider<PlaybackPlanService>(
  (ref) => PlaybackPlanService(freshTrack: ref.watch(libraryRepositoryProvider).trackById),
);

final loudnessAnalyzerProvider = Provider<LoudnessAnalyzer>(
  (ref) => LoudnessAnalyzer(ref.watch(ffmpegRunnerProvider), ref.watch(libraryRepositoryProvider)),
);

final tracksWithoutLoudnessProvider =
    StreamProvider<int>((ref) => ref.watch(libraryRepositoryProvider).watchTracksWithoutLoudnessCount());

/// Keeps normalisation in sync with settings and runs loudness analysis:
/// * on demand for the whole library ([analyzeLibrary], with progress),
/// * automatically for the track that starts playing when it has no data.
class LoudnessController extends Notifier<LoudnessProgress?> {
  StreamSubscription<LoudnessProgress>? _batch;
  final _autoDone = <int>{};

  @override
  LoudnessProgress? build() {
    ref.onDispose(() => _batch?.cancel());
    ref.listen(settingsProvider.select((s) => s.normalization), (_, mode) => _setMode(mode), fireImmediately: true);
    ref.listen(currentTrackProvider, (_, t) => _maybeAutoAnalyze(t));
    return null;
  }

  void _setMode(NormalizationMode mode) {
    final service = ref.read(playbackPlanServiceProvider);
    if (service.normalization == mode) return;
    service.normalization = mode;
    _reloadPlayer();
  }

  Future<void> _maybeAutoAnalyze(Track? t) async {
    final s = ref.read(settingsProvider);
    if (t == null || s.normalization == NormalizationMode.off || !s.autoAnalyzeLoudness) return;
    if (t.rgTrackGain != null || t.loudnessLufs != null || !_autoDone.add(t.id)) return;
    final analyzer = ref.read(loudnessAnalyzerProvider);
    if (!analyzer.available || analyzer.busy) return;
    if (await analyzer.analyze(t) && ref.read(currentTrackProvider)?.id == t.id) _reloadPlayer();
  }

  /// Measures every track without ReplayGain tags / measurement.
  void analyzeLibrary() {
    final analyzer = ref.read(loudnessAnalyzerProvider);
    if (!analyzer.available || analyzer.busy) return;
    _batch = analyzer.analyzeMissing().listen(
      (p) => state = p,
      onDone: () {
        state = null;
        _reloadPlayer();
      },
    );
  }

  void cancel() {
    ref.read(loudnessAnalyzerProvider).cancel();
  }

  void _reloadPlayer() {
    try {
      ref.read(playerControllerProvider).reloadCurrent();
    } on UnimplementedError {
      // No player in widget tests.
    }
  }
}

final loudnessControllerProvider = NotifierProvider<LoudnessController, LoudnessProgress?>(LoudnessController.new);

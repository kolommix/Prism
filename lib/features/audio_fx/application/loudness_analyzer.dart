import 'dart:async';

import '../../../core/ffmpeg/ffmpeg_runner.dart';
import '../../library/data/library_repository.dart';
import '../../library/domain/track.dart';
import '../domain/loudness.dart';

/// Progress of a batch analysis.
class LoudnessProgress {
  const LoudnessProgress(this.done, this.total, this.current);
  final int done;
  final int total;
  final String current;
  bool get finished => done >= total;
}

/// Measures EBU R128 integrated loudness + true peak with FFmpeg's `ebur128`
/// filter for tracks that have no ReplayGain tags, and stores the result.
///
/// Decoding a whole file takes ~0.5–2 s on a PC, a few seconds on a phone,
/// so it runs one file at a time in the background and can be cancelled.
class LoudnessAnalyzer {
  LoudnessAnalyzer(this._ffmpeg, this._repo);

  final FfmpegRunner? _ffmpeg;
  final LibraryRepository _repo;
  bool _cancel = false;
  bool _busy = false;

  bool get available => _ffmpeg != null;
  bool get busy => _busy;

  /// Measures one file; null when FFmpeg is missing or the file can't decode.
  Future<LoudnessMeasurement?> measure(String path) async {
    final ff = _ffmpeg;
    if (ff == null) return null;
    final res = await ff.run(['-nostats', '-i', path, '-vn', '-af', 'ebur128=peak=true', '-f', 'null', '-']);
    return res.ok ? parseEbur128Summary(res.log) : null;
  }

  /// Measures and saves [track]; returns true when stored.
  Future<bool> analyze(Track track) async {
    // Streams aren't measured (a full download per song); ReplayGain-less
    // online songs simply play at their own level.
    if (track.sourceId != 'local') return false;
    final m = await measure(track.uri);
    if (m == null) return false;
    await _repo.saveLoudness(track.id, lufs: m.integratedLufs, truePeakDb: m.truePeakDb);
    return true;
  }

  /// Analyses every track without loudness data, emitting progress.
  Stream<LoudnessProgress> analyzeMissing() async* {
    if (_busy || _ffmpeg == null) return;
    _busy = true;
    _cancel = false;
    try {
      final todo = await _repo.tracksWithoutLoudness();
      for (var i = 0; i < todo.length && !_cancel; i++) {
        yield LoudnessProgress(i, todo.length, todo[i].title);
        await analyze(todo[i]);
      }
      yield LoudnessProgress(todo.length, todo.length, '');
    } finally {
      _busy = false;
    }
  }

  void cancel() => _cancel = true;
}

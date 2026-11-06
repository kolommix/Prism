import '../../audio_fx/domain/loudness.dart';
import '../../library/domain/track.dart';
import '../domain/playback_plan.dart';

/// Decides how each track is played: its live edit preset (if any) plus the
/// loudness-normalisation gain. The engine calls [planFor] whenever it loads
/// a track, so changes take effect on the next load / `reloadCurrent()`.
class PlaybackPlanService {
  PlaybackPlanService({
    required this.freshTrack,
    this.normalization = NormalizationMode.off,
  });

  /// Latest DB copy of a track (queue entries are snapshots, but loudness may
  /// have been measured since).
  final Future<Track?> Function(int id) freshTrack;

  /// Returns the live edit preset's plan for a track, or null when the track
  /// plays unedited. Set by the editor feature at startup.
  Future<PlaybackPlan?> Function(Track track) liveEditPlan = _noEdits;

  /// Current normalisation mode (settings update it).
  NormalizationMode normalization;

  static Future<PlaybackPlan?> _noEdits(Track _) async => null;

  Future<PlaybackPlan> planFor(Track track) async {
    final t = (await freshTrack(track.id)) ?? track;
    final edited = await liveEditPlan(t);
    return (edited ?? PlaybackPlan.plain).withTrackGain(normalizationGainDb(t, normalization));
  }
}

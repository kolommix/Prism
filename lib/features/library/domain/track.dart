import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../l10n/l10n.dart';
part 'track.freezed.dart';
part 'track.g.dart';

/// A playable song, independent of where it comes from.
///
/// Local files, and later streaming services, all produce [Track]s. The
/// [sourceId] says which `TrackSource` owns the track and knows how to turn
/// [uri] into something the audio engine can play.
@freezed
abstract class Track with _$Track {
  const Track._();

  const factory Track({
    /// Database id (unique per library). Remote tracks may use negative ids.
    required int id,

    /// Id of the `TrackSource` that owns this track, e.g. `local`.
    @Default('local') String sourceId,

    /// Source-specific location. For local files: absolute file path.
    required String uri,
    required String title,
    @Default('') String artist,
    @Default('') String album,
    @Default('') String albumArtist,
    @Default('') String genre,
    int? year,
    int? trackNumber,
    int? discNumber,

    /// Length in milliseconds (0 when unknown).
    @Default(0) int durationMs,

    /// Path to a cached cover image on disk, if the file had one.
    String? artworkPath,

    /// ReplayGain from tags (gain in dB, peak linear) – see `loudness.dart`.
    double? rgTrackGain,
    double? rgTrackPeak,
    double? rgAlbumGain,
    double? rgAlbumPeak,

    /// Measured integrated loudness / true peak when tags are missing.
    double? loudnessLufs,
    double? truePeakDb,
  }) = _Track;

  factory Track.fromJson(Map<String, dynamic> json) => _$TrackFromJson(json);

  Duration get duration => Duration(milliseconds: durationMs);

  /// Artist shown in lists: album artist wins for compilations.
  String get displayArtist =>
      artist.isNotEmpty ? artist : (albumArtist.isNotEmpty ? albumArtist : l10n.unknownArtist);

  String get displayAlbum => album.isNotEmpty ? album : l10n.unknownAlbum;
}

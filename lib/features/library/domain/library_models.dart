import 'package:freezed_annotation/freezed_annotation.dart';

part 'library_models.freezed.dart';

/// Aggregated album row (computed from tracks, not stored separately).
@freezed
abstract class AlbumSummary with _$AlbumSummary {
  const factory AlbumSummary({
    required String name,
    required String artist,
    required int trackCount,
    int? year,
    String? artworkPath,
  }) = _AlbumSummary;
}

/// Aggregated artist row.
@freezed
abstract class ArtistSummary with _$ArtistSummary {
  const factory ArtistSummary({
    required String name,
    required int trackCount,
    required int albumCount,
    String? artworkPath,
  }) = _ArtistSummary;
}

/// A directory that directly contains at least one track.
@freezed
abstract class FolderSummary with _$FolderSummary {
  const factory FolderSummary({
    required String path,
    required int trackCount,
  }) = _FolderSummary;
}

/// User-made playlist header (entries are loaded separately).
@freezed
abstract class PlaylistSummary with _$PlaylistSummary {
  const factory PlaylistSummary({
    required int id,
    required String name,
    required int trackCount,
    required DateTime updatedAt,
    String? artworkPath,
  }) = _PlaylistSummary;
}

/// Progress events emitted while scanning folders.
@freezed
sealed class ScanProgress with _$ScanProgress {
  /// Walking directories, [found] audio files so far.
  const factory ScanProgress.discovering({required int found}) = ScanDiscovering;

  /// Reading tags: [done] of [total] files processed.
  const factory ScanProgress.reading({
    required int done,
    required int total,
    required String currentFile,
  }) = ScanReading;

  /// Finished. [added]/[updated]/[removed] are track counts.
  const factory ScanProgress.finished({
    required int added,
    required int updated,
    required int removed,
    required Duration took,
  }) = ScanFinished;
}

/// What was found online for a song; null = keep what is there.
class AutoTagChange {
  const AutoTagChange({this.title, this.artist, this.album, this.genre, this.year, this.artworkPath});

  final String? title, artist, album, genre, artworkPath;
  final int? year;

  bool get isEmpty =>
      title == null && artist == null && album == null && genre == null && year == null && artworkPath == null;
}

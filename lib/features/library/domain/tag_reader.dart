import 'dart:typed_data';

/// Raw tag data read from one audio file.
///
/// Every field is optional – files in the wild have broken or missing tags,
/// and the scanner fills gaps (e.g. title from file name).
class AudioTags {
  const AudioTags({
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.genre,
    this.year,
    this.trackNumber,
    this.discNumber,
    this.duration,
    this.coverBytes,
    this.rgTrackGain,
    this.rgTrackPeak,
    this.rgAlbumGain,
    this.rgAlbumPeak,
  });

  /// ReplayGain tags (gain in dB, linear peak), when present.
  final double? rgTrackGain;
  final double? rgTrackPeak;
  final double? rgAlbumGain;
  final double? rgAlbumPeak;

  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final int? discNumber;
  final Duration? duration;

  /// Embedded front cover (JPEG/PNG bytes), if any.
  final Uint8List? coverBytes;
}

/// Reads tags from a file. Implementations must never throw for a corrupt
/// file – return empty [AudioTags] instead so one bad file can't stop a scan.
///
/// Kept behind an interface so the tag library can be swapped (or faked in
/// tests) without touching the scanner.
abstract class TagReader {
  Future<AudioTags> read(String path, {bool withCover = true});

  /// Reads many files. The default reads one by one; real implementations
  /// override this to do the parsing off the UI isolate.
  Future<List<AudioTags>> readMany(List<String> paths, {bool withCover = true}) async => [
        for (final path in paths) await read(path, withCover: withCover),
      ];
}

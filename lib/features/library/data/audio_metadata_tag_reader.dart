import 'dart:io';
import 'dart:isolate';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

import '../../audio_fx/domain/loudness.dart';
import '../domain/tag_reader.dart';

/// [TagReader] backed by the pure-Dart `audio_metadata_reader` package
/// (MP3/ID3, FLAC, MP4/M4A, OGG/Vorbis, WAV/RIFF – no native code needed on
/// any platform).
///
/// [readMany] parses a whole batch inside a short-lived background isolate so
/// big scans never block the UI thread.
class AudioMetadataTagReader extends TagReader {
  @override
  Future<AudioTags> read(String path, {bool withCover = true}) async => _readSync(path, withCover);

  @override
  Future<List<AudioTags>> readMany(List<String> paths, {bool withCover = true}) =>
      Isolate.run(() => [for (final path in paths) _readSync(path, withCover)]);

  static AudioTags _readSync(String path, bool withCover) {
    try {
      final m = readMetadata(File(path), getImage: withCover);
      Picture? cover;
      if (withCover && m.pictures.isNotEmpty) {
        cover = m.pictures.firstWhere(
          (pic) => pic.pictureType == PictureType.coverFront,
          orElse: () => m.pictures.first,
        );
      }
      final rg = _replayGain(path);
      return AudioTags(
        title: m.title,
        artist: m.artist,
        album: m.album,
        albumArtist: m.albumArtist,
        genre: m.genres.isEmpty ? null : m.genres.first,
        year: m.year?.year,
        trackNumber: m.trackNumber,
        discNumber: m.discNumber,
        duration: m.duration,
        coverBytes: cover?.bytes,
        rgTrackGain: parseReplayGain(rg['REPLAYGAIN_TRACK_GAIN']),
        rgTrackPeak: parseReplayGain(rg['REPLAYGAIN_TRACK_PEAK']),
        rgAlbumGain: parseReplayGain(rg['REPLAYGAIN_ALBUM_GAIN']),
        rgAlbumPeak: parseReplayGain(rg['REPLAYGAIN_ALBUM_PEAK']),
      );
    } catch (_) {
      // Corrupt or unsupported tags: the scanner falls back to the file name.
      return const AudioTags();
    }
  }

  /// ReplayGain tags from the format-specific metadata: ID3 `TXXX` frames
  /// (MP3) and Vorbis comments (FLAC/OGG). MP4 freeform atoms are not exposed
  /// by the parser, so M4A relies on Prism's own loudness analysis.
  static Map<String, String> _replayGain(String path) {
    try {
      final all = readAllMetadata(File(path), getImage: false);
      return switch (all) {
        Mp3Metadata m => {for (final e in m.customMetadata.entries) e.key.toUpperCase(): e.value},
        VorbisMetadata v => {
            if (v.replayGainTrackGain.isNotEmpty) 'REPLAYGAIN_TRACK_GAIN': v.replayGainTrackGain.first,
            if (v.replayGainTrackPeak.isNotEmpty) 'REPLAYGAIN_TRACK_PEAK': v.replayGainTrackPeak.first,
            if (v.replayGainAlbumGain.isNotEmpty) 'REPLAYGAIN_ALBUM_GAIN': v.replayGainAlbumGain.first,
            if (v.replayGainAlbumPeak.isNotEmpty) 'REPLAYGAIN_ALBUM_PEAK': v.replayGainAlbumPeak.first,
          },
        _ => const {},
      };
    } catch (_) {
      return const {};
    }
  }
}

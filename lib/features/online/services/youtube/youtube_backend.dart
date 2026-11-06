import '../../../../l10n/l10n.dart';

/// One YouTube video as Prism needs it.
class YtVideo {
  const YtVideo({required this.id, required this.title, required this.channel, this.durationMs = 0, this.thumbnailUrl});

  final String id;
  final String title;
  final String channel;
  final int durationMs;
  final String? thumbnailUrl;

  String get url => 'https://www.youtube.com/watch?v=$id';
}

class YtPlaylist {
  const YtPlaylist({required this.id, required this.title, this.author, required this.videos});
  final String id;
  final String title;
  final String? author;
  final List<YtVideo> videos;
}

/// A resolved audio stream. URLs expire (usually after ~6 h).
class YtAudioStream {
  const YtAudioStream({
    required this.url,
    required this.container,
    required this.length,
    required this.mimeType,
    this.headers = const {},
    this.expiresAt,
  });
  final Uri url;

  /// `webm` / `mp4` – used as the cache file extension.
  final String container;

  /// Size in bytes (the stream proxy needs it to answer range requests).
  final int length;
  final String mimeType;
  final Map<String, String> headers;
  final DateTime? expiresAt;
}

/// The swappable part of the YouTube module ("extractor interface").
///
/// * `DataApiBackend` – official YouTube Data API v3 (API key): search,
///   playlists, video details. Can't stream audio (the API doesn't offer it).
/// * `ExplodeBackend` – youtube_explode_dart (unofficial, no key, personal
///   use only): search, playlists and audio streams.
///
/// Another extractor (e.g. a local yt-dlp or a Piped/Invidious instance) only
/// needs to implement this class and be picked in `YoutubeModule`.
abstract class YoutubeBackend {
  String get name;
  bool get canStream;

  Future<List<YtVideo>> search(String query, {int limit = 20});
  Future<YtPlaylist> playlist(String id, {int max = 5000});
  Future<YtVideo> video(String id);

  /// [refresh] skips any cached URL (the old one expired or was refused).
  Future<YtAudioStream> audioStream(String id, {bool refresh = false}) =>
      throw UnsupportedError(l10n.canNotStreamAudio(name));

  /// Saves the audio to `<pathWithoutExt>.<container>`; returns the extension.
  Future<String> download(String id, String pathWithoutExt) => throw UnsupportedError(l10n.canNotDownloadAudio(name));

  void close() {}
}

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yte;

import '../../domain/external_track.dart';
import '../../domain/online_error.dart';
import 'web_playlist_reader.dart';
import 'youtube_backend.dart';
import '../../../../l10n/l10n.dart';

/// Unofficial extractor (youtube_explode_dart). No API key and no quota, but
/// it reads YouTube's internal APIs, which YouTube's Terms don't allow and
/// which change often – so it's behind its own flag, marked personal use, and
/// every error becomes an [OnlineException] instead of crashing anything.
class ExplodeBackend extends YoutubeBackend {
  ExplodeBackend([yte.YoutubeExplode? yt]) : _yt = yt ?? yte.YoutubeExplode();

  final yte.YoutubeExplode _yt;

  /// Resolved stream URLs, reused until shortly before they expire.
  final _streams = <String, YtAudioStream>{};

  @override
  String get name => l10n.youtubeExplodeUnofficial;

  @override
  bool get canStream => true;

  Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op().timeout(const Duration(seconds: 30));
    } on OnlineException {
      rethrow;
    } on SocketException {
      throw OnlineException(OnlineErrorKind.offline, service: OnlineService.youtube);
    } on http.ClientException catch (e) {
      // Too many requests: YouTube redirects to its "unusual traffic" page.
      if (e.toString().contains('google_abuse') ||
          e.toString().contains('/sorry/') ||
          e.toString().contains('Redirect limit')) {
        throw OnlineException(
          OnlineErrorKind.rateLimited,
          service: OnlineService.youtube,
          message: l10n.youtubeAsksToSlowDownToo,
        );
      }
      throw OnlineException(OnlineErrorKind.offline, service: OnlineService.youtube);
    } on TimeoutException {
      throw OnlineException(
        OnlineErrorKind.offline,
        service: OnlineService.youtube,
        message: l10n.youtubeDidNotAnswerInTime,
      );
    } on yte.RequestLimitExceededException {
      throw OnlineException(OnlineErrorKind.rateLimited, service: OnlineService.youtube);
    } on yte.VideoUnavailableException catch (e) {
      throw OnlineException(
        OnlineErrorKind.notFound,
        service: OnlineService.youtube,
        message: l10n.thisYoutubeVideoIsUnavailableRemoved(_short(e)),
      );
    } on yte.YoutubeExplodeException catch (e) {
      throw OnlineException(
        OnlineErrorKind.badResponse,
        service: OnlineService.youtube,
        message: l10n.youtubeExtractorFailedYoutubeMayHave(_short(e)),
      );
    } on ArgumentError catch (e) {
      throw OnlineException(
        OnlineErrorKind.notFound,
        service: OnlineService.youtube,
        message: l10n.notAValidYoutubeId(e.message),
      );
    }
  }

  static String _short(Object e) {
    final s = '$e';
    return s.length > 160 ? '${s.substring(0, 160)}…' : s;
  }

  YtVideo _map(yte.Video v) => YtVideo(
    id: v.id.value,
    title: v.title,
    channel: v.author,
    durationMs: v.duration?.inMilliseconds ?? 0,
    thumbnailUrl: v.thumbnails.mediumResUrl,
  );

  @override
  Future<List<YtVideo>> search(String query, {int limit = 20}) => _guard(() async {
    await _paceSearch();
    final list = await _yt.search.search(query);
    return [for (final v in list.take(limit)) _map(v)];
  });

  /// Searches scrape the results page; more than ~1 per second from one
  /// connection quickly triggers YouTube's bot check, so they are queued.
  static const searchGap = Duration(milliseconds: 1500);
  Future<void> _searchSlot = Future.value();

  Future<void> _paceSearch() {
    final slot = _searchSlot.then((_) => Future<void>.delayed(searchGap));
    final mine = _searchSlot;
    _searchSlot = slot;
    return mine;
  }

  @override
  Future<YtPlaylist> playlist(String id, {int max = 5000}) => _guard(() async {
    final pl = await _yt.playlists.get(id);
    var videos = await _yt.playlists.getVideos(pl.id).take(max).map(_map).toList();
    if (videos.isEmpty && (pl.videoCount ?? 1) > 0) {
      // The library can't read the current page layout: own reader.
      final reader = WebPlaylistReader();
      try {
        videos = (await reader.read(pl.id.value, max: max)).videos;
      } finally {
        reader.close();
      }
    }
    return YtPlaylist(id: pl.id.value, title: pl.title, author: pl.author, videos: videos);
  });

  @override
  Future<YtVideo> video(String id) => _guard(() async => _map(await _yt.videos.get(id)));

  @override
  Future<YtAudioStream> audioStream(String id, {bool refresh = false}) async {
    final cached = refresh ? null : _streams[id];
    if (cached != null && (cached.expiresAt?.isAfter(DateTime.now().add(const Duration(minutes: 10))) ?? false)) {
      return cached;
    }
    return _guard(() async {
      final manifest = await _yt.videos.streamsClient.getManifest(id);
      final audio = manifest.audioOnly;
      if (audio.isEmpty) {
        throw OnlineException(
          OnlineErrorKind.notFound,
          service: OnlineService.youtube,
          message: l10n.noAudioStreamForThisVideo,
        );
      }
      final best = audio.withHighestBitrate();
      final expire = int.tryParse(best.url.queryParameters['expire'] ?? '');
      final s = YtAudioStream(
        url: best.url,
        container: best.container.name,
        length: best.size.totalBytes,
        mimeType: best.codec.mimeType,
        expiresAt: expire == null
            ? DateTime.now().add(const Duration(hours: 1))
            : DateTime.fromMillisecondsSinceEpoch(expire * 1000),
      );
      _streams[id] = s;
      return s;
    });
  }

  @override
  Future<String> download(String id, String pathWithoutExt) => _guard(() async {
    final manifest = await _yt.videos.streamsClient.getManifest(id);
    final best = manifest.audioOnly.withHighestBitrate();
    final ext = best.container.name;
    final part = File('$pathWithoutExt.$ext.part');
    await part.parent.create(recursive: true);
    final sink = part.openWrite();
    try {
      await sink.addStream(_yt.videos.streamsClient.get(best));
    } finally {
      await sink.close();
    }
    await part.rename('$pathWithoutExt.$ext');
    return ext;
  });

  @override
  void close() => _yt.close();
}

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yte;

import '../../domain/external_track.dart';
import '../../domain/online_error.dart';
import 'web_playlist_reader.dart';
import 'youtube_backend.dart';
import 'ytdlp.dart';
import '../../../../l10n/l10n.dart';

/// Unofficial extractor (youtube_explode_dart). No API key and no quota, but
/// it reads YouTube's internal APIs, which YouTube's Terms don't allow and
/// which change often – so it's behind its own flag, marked personal use, and
/// every error becomes an [OnlineException] instead of crashing anything.
class ExplodeBackend extends YoutubeBackend {
  ExplodeBackend({yte.YoutubeExplode? yt, this.saver}) : _yt = yt ?? yte.YoutubeExplode();

  final yte.YoutubeExplode _yt;

  /// Saves songs where this reader is refused (Windows); null elsewhere.
  final YtDlp? saver;

  /// Resolved stream URLs, reused until shortly before they expire.
  final _streams = <String, YtAudioStream>{};

  @override
  String get name => l10n.youtubeExplodeUnofficial;

  @override
  bool get canStream => true;

  Future<T> _guard<T>(Future<T> Function() op, {Duration limit = const Duration(seconds: 30)}) async {
    try {
      return await op().timeout(limit);
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

  /// Clients that skip the watch page (the page YouTube rate limits soonest).
  static final _clients = [
    yte.YoutubeApiClient.androidVr,
    yte.YoutubeApiClient.android,
    yte.YoutubeApiClient.androidSdkless,
  ];

  final http.Client _http = http.Client();

  /// The best audio-only stream whose URL really serves the whole file. AAC
  /// (m4a) is preferred: Prism can write tags into it and every player reads it.
  Future<yte.AudioOnlyStreamInfo> _resolve(String id) async {
    Object? last;
    var blocked = false;
    for (final client in _clients) {
      try {
        final m = await _yt.videos.streamsClient
            .getManifest(id, requireWatchPage: false, ytClients: [client])
            .timeout(const Duration(seconds: 20));
        final audio = m.audioOnly.toList();
        if (audio.isEmpty) continue;
        final mp4 = audio.where((a) => a.container == yte.StreamContainer.mp4).toList();
        final best = (mp4.isNotEmpty ? mp4 : audio)..sort((a, b) => b.bitrate.compareTo(a.bitrate));
        if (await _servesWhole(best.first.url, best.first.size.totalBytes)) return best.first;
        blocked = true;
      } on Object catch (e) {
        last = e;
      }
    }
    if (blocked || last == null || last is yte.VideoUnplayableException) {
      throw OnlineException(
        OnlineErrorKind.notFound,
        service: OnlineService.youtube,
        message: l10n.youtubeBlocksThisSong,
      );
    }
    throw last;
  }

  /// Asks for the last bytes: without YouTube's proof token many URLs give
  /// the first megabyte or so and then answer 403.
  Future<bool> _servesWhole(Uri url, int total) async {
    try {
      final from = total > 16 ? total - 16 : 0;
      final r = await _http
          .get(url, headers: {HttpHeaders.rangeHeader: 'bytes=$from-${total - 1}'})
          .timeout(const Duration(seconds: 10));
      return r.statusCode == 206 || r.statusCode == 200;
    } on Object {
      return false;
    }
  }

  @override
  Future<YtAudioStream> audioStream(String id, {bool refresh = false}) async {
    final cached = refresh ? null : _streams[id];
    if (cached != null && (cached.expiresAt?.isAfter(DateTime.now().add(const Duration(minutes: 10))) ?? false)) {
      return cached;
    }
    return _guard(() async {
      final best = await _resolve(id);
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
    }, limit: const Duration(seconds: 90));
  }

  /// Pieces fetched at the same time. YouTube serves small ranges at full
  /// speed and slows down one long request, so this is much faster than one stream.
  static const downloadParallel = 4;
  static const downloadChunk = 512 * 1024;

  /// yt-dlp first where there is one: YouTube now refuses this reader the
  /// whole file of most music uploads. If yt-dlp can't, this reader tries; if
  /// both fail, yt-dlp's reason is the one shown.
  @override
  Future<String> download(String id, String pathWithoutExt) async {
    final saver = this.saver;
    if (saver == null) return _downloadOwn(id, pathWithoutExt);
    try {
      return await saver.download(id, pathWithoutExt);
    } on OnlineException catch (e) {
      if (e.kind == OnlineErrorKind.offline || e.kind == OnlineErrorKind.rateLimited) rethrow;
      try {
        return await _downloadOwn(id, pathWithoutExt);
      } on OnlineException {
        throw e;
      }
    }
  }

  Future<String> _downloadOwn(String id, String pathWithoutExt) async {
    final best = await _guard(() => _resolve(id), limit: const Duration(seconds: 90));
    final ext = best.container == yte.StreamContainer.mp4 ? 'm4a' : best.container.name;
    final total = best.size.totalBytes;
    final part = File('$pathWithoutExt.$ext.part');
    await part.parent.create(recursive: true);
    final file = await part.open(mode: FileMode.write);
    try {
      var url = best.url;
      var next = 0;
      var refreshed = false;
      Future<void> worker() async {
        while (next < total) {
          final from = next;
          final to = math.min(from + downloadChunk, total) - 1;
          next = to + 1;
          List<int>? bytes;
          for (var attempt = 0; bytes == null; attempt++) {
            try {
              final r = await _http
                  .get(url, headers: {HttpHeaders.rangeHeader: 'bytes=$from-$to'})
                  .timeout(const Duration(seconds: 30));
              if (r.statusCode == 403 && !refreshed) {
                // The URL went stale: ask once more for a fresh one.
                refreshed = true;
                url = (await _guard(() => _resolve(id), limit: const Duration(seconds: 90))).url;
                continue;
              }
              if (r.statusCode != 206 && r.statusCode != 200) {
                throw OnlineException(
                  r.statusCode == 429 ? OnlineErrorKind.rateLimited : OnlineErrorKind.badResponse,
                  service: OnlineService.youtube,
                  message: l10n.youtubeExtractorFailedYoutubeMayHave('HTTP ${r.statusCode}'),
                );
              }
              bytes = r.bodyBytes.length > to - from + 1 ? r.bodyBytes.sublist(0, to - from + 1) : r.bodyBytes;
            } on OnlineException {
              rethrow;
            } on Object {
              if (attempt >= 3) {
                throw OnlineException(OnlineErrorKind.offline, service: OnlineService.youtube);
              }
              await Future<void>.delayed(Duration(milliseconds: 500 * (attempt + 1)));
            }
          }
          await file.setPosition(from);
          await file.writeFrom(bytes);
        }
      }

      await Future.wait([for (var i = 0; i < downloadParallel; i++) worker()]);
    } finally {
      await file.close();
    }
    if (await part.length() != total) {
      await part.delete();
      throw OnlineException(OnlineErrorKind.badResponse, service: OnlineService.youtube);
    }
    await part.rename('$pathWithoutExt.$ext');
    return ext;
  }

  @override
  void close() {
    _yt.close();
    _http.close();
    saver?.close();
  }
}

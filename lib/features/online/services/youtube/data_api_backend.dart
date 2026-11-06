import '../../data/online_http.dart';
import '../../domain/external_track.dart';
import '../../domain/online_error.dart';
import 'youtube_backend.dart';
import '../../../../l10n/l10n.dart';

/// Calls one Data API endpoint (`search`, `videos`…) with either the API key
/// or the logged-in user's token.
typedef DataApiGet = Future<Map<String, dynamic>> Function(String endpoint, Map<String, String> params);

/// Official YouTube Data API v3. Quota: 10,000 units/day per key – a search
/// costs 100 (≈100 searches/day), playlist pages and video details cost 1.
/// It has no audio streams; playback needs the extractor flag.
class DataApiBackend extends YoutubeBackend {
  DataApiBackend(this._get);

  /// API-key access: `?key=…` on every call.
  factory DataApiBackend.withKey(String apiKey, OnlineHttp http) => DataApiBackend(
    (endpoint, params) => http.getJson(
      Uri.https('www.googleapis.com', '/youtube/v3/$endpoint', {...params, 'key': apiKey}),
      service: OnlineService.youtube,
    ),
  );

  final DataApiGet _get;

  @override
  String get name => l10n.youtubeDataApiOfficial2;

  @override
  bool get canStream => false;

  @override
  Future<List<YtVideo>> search(String query, {int limit = 20}) async {
    final j = await _get('search', {
      'part': 'snippet',
      'type': 'video',
      'maxResults': '${limit.clamp(1, 50)}',
      'q': query,
    });
    final ids = [
      for (final i in (j['items'] as List? ?? const []))
        if (i is Map && i['id'] is Map && (i['id'] as Map)['videoId'] is String) (i['id'] as Map)['videoId'] as String,
    ];
    return videos(ids);
  }

  /// Full details (with durations) for up to 50 ids per call.
  Future<List<YtVideo>> videos(List<String> ids) async {
    final out = <YtVideo>[];
    for (var i = 0; i < ids.length; i += 50) {
      final chunk = ids.sublist(i, (i + 50).clamp(0, ids.length));
      final j = await _get('videos', {'part': 'snippet,contentDetails', 'id': chunk.join(','), 'maxResults': '50'});
      final byId = {for (final v in (j['items'] as List? ?? const []).whereType<Map>()) v['id'] as String: v};
      for (final id in chunk) {
        final v = byId[id];
        if (v != null) out.add(_map(v));
      }
    }
    return out;
  }

  YtVideo _map(Map v) {
    final sn = v['snippet'] as Map? ?? const {};
    final th = sn['thumbnails'] as Map? ?? const {};
    return YtVideo(
      id: v['id'] as String,
      title: unescapeHtml(sn['title'] as String? ?? ''),
      channel: unescapeHtml(sn['channelTitle'] as String? ?? ''),
      durationMs: parseIsoDuration((v['contentDetails'] as Map?)?['duration'] as String? ?? ''),
      thumbnailUrl: ((th['medium'] ?? th['default']) as Map?)?['url'] as String?,
    );
  }

  @override
  Future<YtPlaylist> playlist(String id, {int max = 5000}) async {
    final meta = await _get('playlists', {'part': 'snippet', 'id': id});
    final items = meta['items'] as List? ?? const [];
    if (items.isEmpty) throw OnlineException(OnlineErrorKind.notFound, service: OnlineService.youtube);
    final sn = (items.first as Map)['snippet'] as Map? ?? const {};
    return YtPlaylist(
      id: id,
      title: unescapeHtml(sn['title'] as String? ?? l10n.youtubePlaylist),
      author: sn['channelTitle'] as String?,
      videos: await playlistVideos(id, max: max),
    );
  }

  Future<List<YtVideo>> playlistVideos(String id, {int max = 5000}) async {
    final ids = <String>[];
    String? page;
    do {
      final j = await _get('playlistItems', {
        'part': 'contentDetails',
        'playlistId': id,
        'maxResults': '50',
        'pageToken': ?page,
      });
      for (final i in (j['items'] as List? ?? const []).whereType<Map>()) {
        final vid = (i['contentDetails'] as Map?)?['videoId'];
        if (vid is String) ids.add(vid);
      }
      page = j['nextPageToken'] as String?;
    } while (page != null && ids.length < max);
    // Deleted / private videos simply don't come back from `videos`.
    return videos(ids.take(max).toList());
  }

  @override
  Future<YtVideo> video(String id) async {
    final list = await videos([id]);
    if (list.isEmpty) throw OnlineException(OnlineErrorKind.notFound, service: OnlineService.youtube);
    return list.first;
  }
}

/// `PT1H2M3S` → ms.
int parseIsoDuration(String iso) {
  final m = RegExp(r'^P(?:(\d+)D)?T?(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$').firstMatch(iso);
  if (m == null) return 0;
  int g(int i) => int.tryParse(m[i] ?? '') ?? 0;
  return (((g(1) * 24 + g(2)) * 60 + g(3)) * 60 + g(4)) * 1000;
}

String unescapeHtml(String s) => s
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&');

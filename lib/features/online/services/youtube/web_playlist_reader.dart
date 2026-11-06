import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/external_track.dart';
import '../../domain/online_error.dart';
import 'youtube_backend.dart';
import '../../../../l10n/l10n.dart';

/// Reads a public playlist from YouTube's web page (unofficial, part of the
/// extractor). Used when youtube_explode can't parse the current layout
/// (Nov 2026: rows are `lockupViewModel`, the library expects the old
/// `playlistVideoRenderer`). Walks the JSON looking for either shape, so a
/// moved node doesn't break it; follows `continuationCommand` tokens.
class WebPlaylistReader {
  WebPlaylistReader([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;
  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36';
  static final _initialData = RegExp(r'ytInitialData\s*=\s*(\{.*?\});\s*</script>', dotAll: true);
  static final _clientVersion = RegExp(r'"INNERTUBE_CLIENT_VERSION":"([^"]+)"');

  Future<YtPlaylist> read(String id, {int max = 5000}) async {
    final res = await _client.get(
      Uri.parse('https://www.youtube.com/playlist?list=$id&hl=en'),
      headers: {'User-Agent': _ua, 'Accept-Language': 'en'},
    );
    if (res.statusCode != 200) throw OnlineException(OnlineErrorKind.notFound, service: OnlineService.youtube);
    final html = utf8.decode(res.bodyBytes);
    final m = _initialData.firstMatch(html);
    if (m == null) throw OnlineException(OnlineErrorKind.badResponse, service: OnlineService.youtube);
    final data = jsonDecode(m[1]!);
    final version = _clientVersion.firstMatch(html)?[1] ?? '2.20261101.00.00';

    final videos = <YtVideo>[];
    final seen = <String>{};
    var token = collect(data, videos, seen);
    while (token != null && videos.length < max) {
      final more = await _client.post(
        Uri.parse('https://www.youtube.com/youtubei/v1/browse?prettyPrint=false'),
        headers: {'User-Agent': _ua, 'Content-Type': 'application/json'},
        body: jsonEncode({
          'context': {
            'client': {'clientName': 'WEB', 'clientVersion': version, 'hl': 'en'},
          },
          'continuation': token,
        }),
      );
      if (more.statusCode != 200) break;
      final before = videos.length;
      token = collect(jsonDecode(utf8.decode(more.bodyBytes)), videos, seen);
      if (videos.length == before) break;
    }
    return YtPlaylist(id: id, title: _title(data) ?? l10n.youtubePlaylist, videos: videos.take(max).toList());
  }

  void close() => _client.close();

  /// Adds every video row under [node]; returns the continuation token of the
  /// list that holds the videos (other shelves, e.g. "related playlists",
  /// have their own tokens that must not be followed).
  static String? collect(Object? node, List<YtVideo> out, Set<String> seen) {
    String? token;
    void walk(Object? n) {
      if (n is Map) {
        final lockup = n['lockupViewModel'];
        final old = n['playlistVideoRenderer'];
        if (lockup is Map) {
          final v = _fromLockup(lockup);
          if (v != null && seen.add(v.id)) out.add(v);
          return;
        }
        if (old is Map) {
          final v = _fromRenderer(old);
          if (v != null && seen.add(v.id)) out.add(v);
          return;
        }
        n.values.forEach(walk);
      } else if (n is List) {
        final before = out.length;
        n.forEach(walk);
        // Innermost list with videos wins (outer shelves have other tokens).
        if (out.length > before) token ??= _continuationIn(n);
      }
    }

    walk(node);
    return token;
  }

  static String? _continuationIn(List items) {
    for (final i in items) {
      final c = i is Map ? (i['continuationItemViewModel'] ?? i['continuationItemRenderer']) : null;
      if (c is! Map) continue;
      String? t;
      void find(Object? n) {
        if (t != null) return;
        if (n is Map) {
          final cmd = n['continuationCommand'];
          if (cmd is Map && cmd['token'] is String) {
            t = cmd['token'] as String;
            return;
          }
          n.values.forEach(find);
        } else if (n is List) {
          n.forEach(find);
        }
      }

      find(c);
      if (t != null) return t;
    }
    return null;
  }

  static YtVideo? _fromLockup(Map l) {
    if (l['contentType'] != null && l['contentType'] != 'LOCKUP_CONTENT_TYPE_VIDEO') return null;
    final id = l['contentId'];
    if (id is! String) return null;
    final meta = (l['metadata'] as Map?)?['lockupMetadataViewModel'] as Map?;
    final title = ((meta?['title'] as Map?)?['content']) as String?;
    if (title == null) return null;
    // First metadata part is the channel name.
    String channel = '';
    final rows = ((((meta?['metadata'] as Map?)?['contentMetadataViewModel']) as Map?)?['metadataRows']) as List?;
    for (final r in rows ?? const []) {
      final parts = (r as Map)['metadataParts'] as List?;
      final text = parts == null || parts.isEmpty ? null : ((parts.first as Map)['text'] as Map?)?['content'];
      if (text is String && text.isNotEmpty) {
        channel = text;
        break;
      }
    }
    String? badge;
    String? thumb;
    void findBadge(Object? n) {
      if (n is Map) {
        final b = n['thumbnailBadgeViewModel'];
        if (b is Map && b['text'] is String) badge ??= b['text'] as String;
        if (n['sources'] is List && thumb == null) {
          final s = (n['sources'] as List).whereType<Map>().where((x) => x['url'] is String).toList();
          if (s.isNotEmpty) thumb = s.last['url'] as String;
        }
        n.values.forEach(findBadge);
      } else if (n is List) {
        n.forEach(findBadge);
      }
    }

    findBadge(l['contentImage']);
    return YtVideo(id: id, title: title, channel: channel, durationMs: _clock(badge), thumbnailUrl: thumb);
  }

  static YtVideo? _fromRenderer(Map r) {
    final id = r['videoId'];
    if (id is! String) return null;
    final title = ((r['title'] as Map?)?['runs'] as List?)?.whereType<Map>().map((x) => x['text']).join() ?? '';
    final channel =
        ((r['shortBylineText'] as Map?)?['runs'] as List?)?.whereType<Map>().map((x) => x['text']).join() ?? '';
    final secs = int.tryParse('${r['lengthSeconds'] ?? ''}') ?? 0;
    return YtVideo(id: id, title: title, channel: channel, durationMs: secs * 1000);
  }

  /// "3:55" / "1:02:03" → ms.
  static int _clock(String? s) {
    if (s == null || !s.contains(':')) return 0;
    var total = 0;
    for (final p in s.split(':')) {
      final n = int.tryParse(p.trim());
      if (n == null) return 0;
      total = total * 60 + n;
    }
    return total * 1000;
  }

  static String? _title(Object? data) {
    if (data is! Map) return null;
    final header = data['header'];
    String? found;
    void walk(Object? n) {
      if (found != null) return;
      if (n is Map) {
        final t = n['pageHeaderViewModel'];
        if (t is Map && (t['title'] as Map?)?['dynamicTextViewModel'] is Map) {
          found = ((((t['title'] as Map)['dynamicTextViewModel'] as Map)['text'] as Map?)?['content']) as String?;
          return;
        }
        n.values.forEach(walk);
      } else if (n is List) {
        n.forEach(walk);
      }
    }

    walk(header);
    if (found != null) return found;
    return (((data['metadata'] as Map?)?['playlistMetadataRenderer'] as Map?)?['title']) as String?;
  }
}

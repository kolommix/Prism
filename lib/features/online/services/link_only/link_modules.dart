import 'dart:convert';
import 'dart:io';

import '../../data/online_http.dart';
import '../../domain/external_track.dart';
import '../../domain/link_parser.dart';
import '../../domain/matching.dart';
import '../../domain/online_error.dart';
import '../music_service_module.dart';
import '../youtube/data_api_backend.dart';
import '../../../../l10n/l10n.dart';

/// Follows a short link (deezer.page.link, on.soundcloud.com, spotify.link)
/// without downloading the page; returns the final URL.
Future<Uri> followRedirects(Uri url, {int max = 6}) async {
  final client = HttpClient()..userAgent = OnlineHttp.userAgent;
  try {
    var current = url;
    for (var i = 0; i < max; i++) {
      final req = await client.getUrl(current)
        ..followRedirects = false;
      final res = await req.close().timeout(const Duration(seconds: 15));
      await res.drain<void>();
      final loc = res.headers.value(HttpHeaders.locationHeader);
      if (!res.isRedirect || loc == null) return current;
      current = current.resolve(loc);
    }
    return current;
  } on SocketException {
    throw OnlineException(OnlineErrorKind.offline);
  } finally {
    client.close(force: true);
  }
}

/// Deezer: public API, no key, no login. Imports public playlists, albums
/// and single tracks from links (metadata only – Deezer audio is never used).
class DeezerModule extends MusicServiceModule {
  DeezerModule(this._http);
  final OnlineHttp _http;

  @override
  OnlineService get service => OnlineService.deezer;
  @override
  Set<ModuleFeature> get features => const {ModuleFeature.links};

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? q]) async {
    final j = await _http.getJson(Uri.https('api.deezer.com', path, q), service: service);
    // Deezer answers errors with HTTP 200 + {"error": {...}}.
    final err = j['error'];
    if (err is Map) {
      final code = (err['code'] as num?)?.toInt();
      throw OnlineException(
        code == 4
            ? OnlineErrorKind.rateLimited
            : (code == 800 ? OnlineErrorKind.notFound : OnlineErrorKind.badResponse),
        service: service,
        message: code == 800 || code == 4 ? null : l10n.deezer(err['message']),
      );
    }
    return j;
  }

  @override
  Future<ImportedList> openLink(ParsedLink link) async {
    if (link.kind == LinkKind.shortLink) {
      final full = parseMusicLink((await followRedirects(link.url)).toString());
      if (full == null || full.kind == LinkKind.shortLink || full.service != service) {
        throw OnlineException(
          OnlineErrorKind.notFound,
          service: service,
          message: l10n.couldNotOpenThisDeezerShort,
        );
      }
      return openLink(full);
    }
    switch (link.kind) {
      case LinkKind.playlist:
        final p = await _get('/playlist/${link.id}');
        final rows = await _pages('/playlist/${link.id}/tracks');
        return ImportedList(
          name: p['title'] as String? ?? l10n.deezerPlaylist,
          origin: service,
          sourceUrl: link.url.toString(),
          tracks: [for (final t in rows) ?_track(t)],
        );
      case LinkKind.album:
        final a = await _get('/album/${link.id}');
        final rows = await _pages('/album/${link.id}/tracks');
        final album = a['title'] as String? ?? '';
        return ImportedList(
          name: '$album – ${(a['artist'] as Map?)?['name'] ?? ''}',
          origin: service,
          sourceUrl: link.url.toString(),
          tracks: [for (final t in rows) ?_track(t, album: album, art: (a['cover_xl'] ?? a['cover_medium']) as String?)],
        );
      case LinkKind.track:
        final t = _track(await _get('/track/${link.id}'));
        if (t == null) throw OnlineException(OnlineErrorKind.notFound, service: service);
        return ImportedList(name: t.title, origin: service, tracks: [t], sourceUrl: link.url.toString());
      default:
        throw unsupported(l10n.openThisLink);
    }
  }

  Future<List<Map<String, dynamic>>> _pages(String path) async {
    final out = <Map<String, dynamic>>[];
    var index = 0;
    while (out.length < 10000) {
      final j = await _get(path, {'index': '$index', 'limit': '100'});
      final data = (j['data'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
      out.addAll(data);
      if (data.isEmpty || j['next'] == null) break;
      index += data.length;
    }
    return out;
  }

  ExternalTrack? _track(Map<String, dynamic> t, {String? album, String? art}) {
    final title = t['title'] as String?;
    if (title == null) return null;
    final al = t['album'] as Map?;
    return ExternalTrack(
      service: service,
      title: title,
      artists: [if ((t['artist'] as Map?)?['name'] case final String a) a],
      album: album ?? al?['title'] as String? ?? '',
      durationMs: ((t['duration'] as num?)?.toInt() ?? 0) * 1000,
      externalId: '${t['id']}',
      isrc: t['isrc'] as String?,
      url: t['link'] as String?,
      artworkUrl: art ?? (al?['cover_xl'] ?? al?['cover_medium']) as String?,
    );
  }
}

/// Apple Music: no official access without a paid Apple developer token, so
/// this reads the *public web page* of a playlist/album (its schema.org data).
/// Best effort, personal use only; it may break when Apple changes the page.
class AppleMusicModule extends MusicServiceModule {
  AppleMusicModule(this._http);
  final OnlineHttp _http;

  @override
  OnlineService get service => OnlineService.appleMusic;
  @override
  Set<ModuleFeature> get features => const {ModuleFeature.links};

  @override
  Future<ImportedList> openLink(ParsedLink link) async {
    final html = await _http.getText(link.url, service: service);
    final list = parseAppleMusicPage(html, sourceUrl: link.url.toString());
    if (list == null || list.tracks.isEmpty) {
      throw OnlineException(
        OnlineErrorKind.badResponse,
        service: service,
        message:
            l10n.couldNotReadSongsFromThis,
      );
    }
    return list;
  }
}

final _ldJson = RegExp(r'<script[^>]*type="application/ld\+json"[^>]*>(.*?)</script>', dotAll: true);
final _serverData = RegExp(r'<script[^>]*id="serialized-server-data"[^>]*>(.*?)</script>', dotAll: true);

/// Reads an Apple Music page: schema.org `MusicPlaylist` / `MusicAlbum`
/// first, then the page's embedded app data (song rows with `title`,
/// `artistName`, `duration`).
ImportedList? parseAppleMusicPage(String html, {String? sourceUrl}) {
  String? name;
  final tracks = <ExternalTrack>[];
  for (final m in _ldJson.allMatches(html)) {
    Object? j;
    try {
      j = jsonDecode(unescapeHtml(m[1]!.trim()));
    } on FormatException {
      continue;
    }
    if (j is! Map) continue;
    final type = '${j['@type']}';
    if (!type.contains('MusicPlaylist') && !type.contains('MusicAlbum')) continue;
    name ??= j['name'] as String?;
    final albumArtist = _ldArtist(j['byArtist']);
    for (final t in (j['track'] as List? ?? (j['tracks'] as List?) ?? const []).whereType<Map>()) {
      final tn = t['name'] as String?;
      if (tn == null) continue;
      final artist = _ldArtist(t['byArtist']) ?? albumArtist;
      tracks.add(
        ExternalTrack(
          service: OnlineService.appleMusic,
          title: tn,
          artists: artist == null ? const [] : splitArtists(artist),
          album: (t['inAlbum'] as Map?)?['name'] as String? ?? (type.contains('MusicAlbum') ? name ?? '' : ''),
          durationMs: parseIsoDuration('${t['duration'] ?? ''}'),
          url: t['url'] as String?,
        ),
      );
    }
  }
  // Playlist pages list songs without artists in schema.org; the embedded
  // app data has them.
  if (tracks.isEmpty || tracks.any((t) => t.artists.isEmpty)) {
    final m = _serverData.firstMatch(html);
    if (m != null) {
      final fromApp = <ExternalTrack>[];
      try {
        _walkServerData(jsonDecode(m[1]!), fromApp, (n) => name ??= n);
      } on FormatException {
        // ignore
      }
      if (fromApp.length >= tracks.length) {
        tracks
          ..clear()
          ..addAll(fromApp);
      }
    }
  }
  if (tracks.isEmpty) return null;
  return ImportedList(
    name: name ?? l10n.appleMusicPlaylist,
    origin: OnlineService.appleMusic,
    tracks: tracks,
    sourceUrl: sourceUrl,
  );
}

String? _ldArtist(Object? a) {
  if (a is Map) return a['name'] as String?;
  if (a is List) return a.whereType<Map>().map((x) => x['name']).whereType<String>().join(', ');
  return null;
}

void _walkServerData(Object? node, List<ExternalTrack> out, void Function(String) onName, [int depth = 0]) {
  if (depth > 40) return;
  if (node is Map) {
    final title = node['title'];
    final artist = node['artistName'];
    final dur = node['duration'];
    if (title is String && artist is String && dur is num && dur > 0) {
      out.add(
        ExternalTrack(
          service: OnlineService.appleMusic,
          title: title,
          artists: splitArtists(artist),
          album: node['albumName'] as String? ?? '',
          durationMs: dur.toInt(),
        ),
      );
      return;
    }
    if (node['contentDescriptor'] is Map && title is String && out.isEmpty) onName(title);
    for (final v in node.values) {
      _walkServerData(v, out, onName, depth + 1);
    }
  } else if (node is List) {
    for (final v in node) {
      _walkServerData(v, out, onName, depth + 1);
    }
  }
}

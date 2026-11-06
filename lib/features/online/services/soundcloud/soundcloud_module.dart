import 'dart:convert';

import '../../../library/domain/track.dart';
import '../../data/oauth.dart';
import '../../data/online_http.dart';
import '../../domain/external_track.dart';
import '../../domain/link_parser.dart';
import '../../domain/online_error.dart';
import '../music_service_module.dart';
import '../../../../l10n/l10n.dart';

const soundcloudSourceId = 'soundcloud';

/// SoundCloud through the **official** API (app registered at
/// soundcloud.com/you/apps): search, playlists/likes import and playback of
/// tracks the uploader made streamable ("stream where permitted": tracks with
/// `access != playable` are skipped). No scraping of web client ids.
///
/// Without login, search uses an app token (client credentials, needs the
/// client secret from the config file); with login, the user's token.
class SoundcloudModule extends MusicServiceModule {
  SoundcloudModule({
    required this.clientId,
    required this.clientSecret,
    required int port,
    required TokenStore store,
    required OnlineHttp http,
    required BrowserLauncher launch,
  }) : _http = http,
       _auth = OAuthClient(
         service: OnlineService.soundcloud,
         authorizeUrl: Uri.parse('https://secure.soundcloud.com/authorize'),
         tokenUrl: Uri.parse('https://secure.soundcloud.com/oauth/token'),
         clientId: clientId,
         clientSecret: clientSecret,
         scopes: const [],
         port: port,
         store: store,
         http: http,
         launch: launch,
       );

  final String clientId;
  final String clientSecret;
  final OnlineHttp _http;
  final OAuthClient _auth;
  static final _host = 'api.soundcloud.com';

  String get redirectUri => _auth.redirectUri;

  String? _appToken;
  DateTime _appTokenExpiry = DateTime(0);

  @override
  OnlineService get service => OnlineService.soundcloud;

  @override
  Set<ModuleFeature> get features => {
    ModuleFeature.login,
    ModuleFeature.myPlaylists,
    ModuleFeature.likes,
    ModuleFeature.links,
    ModuleFeature.search,
    ModuleFeature.stream,
  };

  @override
  String? get playableSourceId => soundcloudSourceId;

  Future<String> _token() async {
    if (await _auth.isLoggedIn) return _auth.accessToken();
    if (_appToken != null && DateTime.now().isBefore(_appTokenExpiry)) return _appToken!;
    if (clientSecret.isEmpty) {
      throw OnlineException(
        OnlineErrorKind.notConfigured,
        service: service,
        message: l10n.soundcloudLogInOrAddThe,
      );
    }
    final j = await _http.postForm(
      Uri.https('secure.soundcloud.com', '/oauth/token'),
      {'grant_type': 'client_credentials'},
      service: service,
      headers: {'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}'},
    );
    _appToken = j['access_token'] as String;
    _appTokenExpiry = DateTime.now().add(Duration(seconds: ((j['expires_in'] as num?)?.toInt() ?? 3600) - 60));
    return _appToken!;
  }

  Future<Map<String, dynamic>> _get(String pathOrUrl, [Map<String, String>? q]) async {
    final uri = pathOrUrl.startsWith('http') ? Uri.parse(pathOrUrl) : Uri.https(_host, pathOrUrl, q);
    try {
      return await _http.getJson(uri, service: service, headers: {'Authorization': 'Bearer ${await _token()}'});
    } on OnlineException catch (e) {
      if (e.kind != OnlineErrorKind.auth) rethrow;
      _appToken = null;
      if (await _auth.isLoggedIn) await _auth.refresh();
      return _http.getJson(uri, service: service, headers: {'Authorization': 'Bearer ${await _token()}'});
    }
  }

  /// `linked_partitioning` pages: `{collection, next_href}`.
  Future<List<Map<String, dynamic>>> _all(String path, Map<String, String> q, {int max = 5000}) async {
    final out = <Map<String, dynamic>>[];
    String? next;
    var page = await _get(path, {...q, 'linked_partitioning': 'true', 'limit': '200'});
    while (true) {
      out.addAll((page['collection'] as List? ?? page['items'] as List? ?? const []).whereType<Map<String, dynamic>>());
      next = page['next_href'] as String?;
      if (next == null || out.length >= max) break;
      page = await _get(next);
    }
    return out;
  }

  // ------------------------------------------------------------- account

  @override
  Future<AccountInfo?> account() async {
    if (!await _auth.isLoggedIn) return null;
    try {
      final me = await _get('/me');
      return AccountInfo(name: me['username'] as String? ?? l10n.soundcloudUser);
    } on OnlineException catch (e) {
      if (e.isTransient) return AccountInfo(name: l10n.connected, detail: 'offline');
      rethrow;
    }
  }

  @override
  Future<AccountInfo> connect() async {
    await _auth.login();
    return (await account())!;
  }

  @override
  Future<void> disconnect() => _auth.logout();

  @override
  Future<List<RemotePlaylistInfo>> myPlaylists() async => [
    for (final p in await _all('/me/playlists', {'show_tracks': 'false'}))
      RemotePlaylistInfo(
        service: service,
        id: '${p['id']}',
        name: p['title'] as String? ?? l10n.playlist2,
        trackCount: (p['track_count'] as num?)?.toInt(),
        artworkUrl: p['artwork_url'] as String?,
      ),
  ];

  @override
  Future<ImportedList> likedSongs() async => ImportedList(
    name: l10n.likesSoundcloud,
    origin: service,
    tracks: [for (final t in await _all('/me/likes/tracks', const {})) ?_external(t)],
  );

  @override
  Future<ImportedList> fetchList(RemotePlaylistInfo info, {bool album = false}) => _playlist(info.id);

  Future<ImportedList> _playlist(String id, {String? url}) async {
    final p = await _get('/playlists/$id', {'show_tracks': 'false'});
    final tracks = await _all('/playlists/$id/tracks', const {});
    return ImportedList(
      name: p['title'] as String? ?? l10n.soundcloudPlaylist,
      origin: service,
      sourceUrl: url ?? p['permalink_url'] as String?,
      tracks: [for (final t in tracks) ?_external(t)],
    );
  }

  @override
  Future<ImportedList> openLink(ParsedLink link) async {
    final r = await _get('/resolve', {'url': link.url.toString()});
    switch (r['kind']) {
      case 'playlist':
        return _playlist('${r['id']}', url: link.url.toString());
      case 'track':
        final t = _external(r) ?? (throw OnlineException(OnlineErrorKind.notFound, service: service));
        return ImportedList(name: t.title, origin: service, tracks: [t], sourceUrl: link.url.toString());
      case 'user':
        // ".../likes" resolves to the user; read their public likes.
        final likes = await _all('/users/${r['id']}/likes/tracks', const {});
        return ImportedList(
          name: l10n.likesOf(r['username']),
          origin: service,
          sourceUrl: link.url.toString(),
          tracks: [for (final t in likes) ?_external(t)],
        );
      default:
        throw unsupported(l10n.openThisLink);
    }
  }

  // ------------------------------------------------------------- catalog

  @override
  Future<List<Track>> search(String query, {int limit = 20}) async {
    final j = await _get('/tracks', {
      'q': query,
      'limit': '$limit',
      'access': 'playable',
      'linked_partitioning': 'true',
    });
    return [
      for (final t in (j['collection'] as List? ?? const []).whereType<Map<String, dynamic>>())
        if (_playable(t)) trackFrom(t),
    ];
  }

  static bool _playable(Map<String, dynamic> t) =>
      t['access'] == null ? t['streamable'] != false : t['access'] == 'playable';

  /// Stored uri: the permalink with the numeric id in the fragment.
  static Track trackFrom(Map<String, dynamic> t) {
    final user = t['user'] as Map? ?? const {};
    final meta = t['publisher_metadata'] as Map? ?? const {};
    return Track(
      id: 0,
      sourceId: soundcloudSourceId,
      uri: '${t['permalink_url'] ?? 'https://soundcloud.com/'}#sc=${t['id']}',
      title: t['title'] as String? ?? '',
      artist: (meta['artist'] as String?)?.trim().isNotEmpty == true
          ? meta['artist'] as String
          : user['username'] as String? ?? '',
      album: meta['album_title'] as String? ?? '',
      genre: t['genre'] as String? ?? '',
      durationMs: (t['duration'] as num?)?.toInt() ?? 0,
      artworkPath: t['artwork_url'] as String? ?? user['avatar_url'] as String?,
    );
  }

  ExternalTrack? _external(Map<String, dynamic> t) {
    final title = t['title'] as String?;
    if (title == null) return null;
    final tr = trackFrom(t);
    return ExternalTrack(
      service: service,
      title: tr.title,
      artists: [if (tr.artist.isNotEmpty) tr.artist],
      album: tr.album,
      durationMs: tr.durationMs,
      externalId: '${t['id']}',
      url: t['permalink_url'] as String?,
      artworkUrl: tr.artworkPath,
      isrc: (t['publisher_metadata'] as Map?)?['isrc'] as String?,
    );
  }

  static String? idOf(Track t) => Uri.tryParse(t.uri)?.fragment.replaceFirst('sc=', '');

  @override
  Future<Uri> streamUri(Track track) async {
    final id = idOf(track);
    if (id == null || id.isEmpty) throw OnlineException(OnlineErrorKind.notFound, service: service);
    final s = await _get('/tracks/$id/streams');
    final url = s['http_mp3_128_url'] as String? ?? s['hls_mp3_128_url'] as String?;
    if (url == null) {
      throw OnlineException(
        OnlineErrorKind.forbidden,
        service: service,
        message: l10n.theUploaderDoesNotAllowStreaming,
      );
    }
    return Uri.parse(url);
  }

  @override
  Future<Map<String, String>> streamHeaders(Track track) async => {'Authorization': 'Bearer ${await _token()}'};
}

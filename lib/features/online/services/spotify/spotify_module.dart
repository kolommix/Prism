import '../../data/oauth.dart';
import '../../data/online_http.dart';
import '../../domain/external_track.dart';
import '../../domain/link_parser.dart';
import '../../domain/online_error.dart';
import '../music_service_module.dart';
import '../../../../l10n/l10n.dart';

/// Spotify: login (PKCE, no client secret), then playlists, liked songs and
/// saved albums as *metadata*. Prism never plays or extracts Spotify audio –
/// imported songs are matched to local files / YouTube / SoundCloud.
///
/// Spotify Development Mode (Feb 2026 rules): up to 5 allow-listed users per
/// app, and playlist contents only for playlists the user owns or
/// collaborates on. The newer `/playlists/{id}/items` endpoint is used with a
/// fallback to `/tracks`; rows may carry the song under `item` or `track`.
class SpotifyModule extends MusicServiceModule {
  SpotifyModule({
    required String clientId,
    required int port,
    required TokenStore store,
    required OnlineHttp http,
    required BrowserLauncher launch,
  }) : _auth = OAuthClient(
         service: OnlineService.spotify,
         authorizeUrl: Uri.parse('https://accounts.spotify.com/authorize'),
         tokenUrl: Uri.parse('https://accounts.spotify.com/api/token'),
         clientId: clientId,
         scopes: const ['playlist-read-private', 'playlist-read-collaborative', 'user-library-read'],
         port: port,
         store: store,
         http: http,
         launch: launch,
       );

  final OAuthClient _auth;
  static final _api = Uri.parse('https://api.spotify.com/v1/');

  String get redirectUri => _auth.redirectUri;

  @override
  OnlineService get service => OnlineService.spotify;

  @override
  Set<ModuleFeature> get features => const {
    ModuleFeature.login,
    ModuleFeature.myPlaylists,
    ModuleFeature.likes,
    ModuleFeature.savedAlbums,
    ModuleFeature.links,
  };

  Future<Map<String, dynamic>> _get(String pathOrUrl) =>
      _auth.getJson(pathOrUrl.startsWith('http') ? Uri.parse(pathOrUrl) : _api.resolve(pathOrUrl));

  @override
  Future<AccountInfo?> account() async {
    if (!await _auth.isLoggedIn) return null;
    try {
      final me = await _get('me');
      return AccountInfo(
        name: me['display_name'] as String? ?? me['id'] as String? ?? l10n.spotifyUser,
        detail: me['email'] as String?,
      );
    } on OnlineException catch (e) {
      // Offline: still connected, just can't show the name right now.
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

  /// Follows `next` links (Spotify pages are 50/100 items).
  Future<List<Map<String, dynamic>>> _all(String first, {int max = 10000}) async {
    final out = <Map<String, dynamic>>[];
    String? next = first;
    while (next != null && out.length < max) {
      final page = await _get(next);
      final items = page['items'];
      if (items is List) out.addAll(items.whereType<Map<String, dynamic>>());
      next = page['next'] as String?;
    }
    return out;
  }

  @override
  Future<List<RemotePlaylistInfo>> myPlaylists() async => [
    for (final p in await _all('me/playlists?limit=50'))
      RemotePlaylistInfo(
        service: service,
        id: p['id'] as String,
        name: p['name'] as String? ?? l10n.playlist2,
        trackCount: _total(p['items']) ?? _total(p['tracks']),
        owner: (p['owner'] as Map?)?['display_name'] as String?,
        artworkUrl: _image(p['images']),
      ),
  ];

  @override
  Future<List<RemotePlaylistInfo>> savedAlbums() async => [
    for (final row in await _all('me/albums?limit=50'))
      if (row['album'] case final Map<String, dynamic> a)
        RemotePlaylistInfo(
          service: service,
          id: a['id'] as String,
          name: a['name'] as String? ?? l10n.album,
          trackCount: (a['total_tracks'] as num?)?.toInt(),
          owner: _artists(a['artists']).join(', '),
          artworkUrl: _image(a['images']),
        ),
  ];

  @override
  Future<ImportedList> likedSongs() async => ImportedList(
    name: l10n.likedSongsSpotify,
    origin: service,
    sourceUrl: 'https://open.spotify.com/collection/tracks',
    tracks: [for (final row in await _all('me/tracks?limit=50')) ?_rowTrack(row)],
  );

  @override
  Future<ImportedList> fetchList(RemotePlaylistInfo info, {bool album = false}) =>
      album ? _album(info.id) : _playlist(info.id);

  @override
  Future<ImportedList> openLink(ParsedLink link) async {
    switch (link.kind) {
      case LinkKind.playlist:
        return _playlist(link.id);
      case LinkKind.album:
        return _album(link.id);
      case LinkKind.likes:
        return likedSongs();
      case LinkKind.track:
        final t = _track(await _get('tracks/${link.id}'));
        if (t == null) throw OnlineException(OnlineErrorKind.notFound, service: service);
        return ImportedList(name: t.title, origin: service, tracks: [t], sourceUrl: link.url.toString());
      case LinkKind.shortLink:
        throw OnlineException(
          OnlineErrorKind.unsupported,
          service: service,
          message: l10n.openTheSpotifyLinkInA,
        );
    }
  }

  Future<ImportedList> _playlist(String id) async {
    final Map<String, dynamic> meta;
    try {
      meta = await _get('playlists/$id?fields=name,owner(display_name)');
    } on OnlineException catch (e) {
      throw _devModeHint(e);
    }
    List<Map<String, dynamic>> rows;
    try {
      rows = await _all('playlists/$id/items?limit=100');
    } on OnlineException catch (e) {
      if (e.kind != OnlineErrorKind.notFound) throw _devModeHint(e);
      try {
        rows = await _all('playlists/$id/tracks?limit=100');
      } on OnlineException catch (e2) {
        throw _devModeHint(e2);
      }
    }
    return ImportedList(
      name: meta['name'] as String? ?? l10n.spotifyPlaylist,
      origin: service,
      sourceUrl: 'https://open.spotify.com/playlist/$id',
      tracks: [for (final r in rows) ?_rowTrack(r)],
    );
  }

  OnlineException _devModeHint(OnlineException e) =>
      e.kind == OnlineErrorKind.forbidden || e.kind == OnlineErrorKind.notFound
      ? OnlineException(
          e.kind,
          service: service,
          message:
              l10n.spotifyOnlyLetsSmallDevelopmentMode,
        )
      : e;

  Future<ImportedList> _album(String id) async {
    final a = await _get('albums/$id');
    final albumName = a['name'] as String? ?? '';
    final art = _image(a['images']);
    final first = a['tracks'] as Map<String, dynamic>? ?? const {};
    final rows = [...(first['items'] as List? ?? const []).whereType<Map<String, dynamic>>()];
    if (first['next'] is String) rows.addAll(await _all(first['next'] as String));
    return ImportedList(
      name: '$albumName – ${_artists(a['artists']).join(', ')}',
      origin: service,
      sourceUrl: 'https://open.spotify.com/album/$id',
      tracks: [for (final t in rows) ?_track(t, albumName: albumName, art: art)],
    );
  }

  /// A playlist / library row: song under `item` (2026) or `track` (older).
  ExternalTrack? _rowTrack(Map<String, dynamic> row) {
    final t = row['item'] is Map ? row['item'] : row['track'];
    return t is Map<String, dynamic> ? _track(t) : null;
  }

  ExternalTrack? _track(Map<String, dynamic> t, {String? albumName, String? art}) {
    // Skip podcast episodes and empty rows.
    if (t['type'] != null && t['type'] != 'track') return null;
    final name = t['name'] as String?;
    if (name == null || name.isEmpty) return null;
    final album = t['album'] as Map<String, dynamic>?;
    final id = t['id'] as String?;
    return ExternalTrack(
      service: service,
      title: name,
      artists: _artists(t['artists']),
      album: albumName ?? album?['name'] as String? ?? '',
      durationMs: (t['duration_ms'] as num?)?.toInt() ?? 0,
      externalId: id,
      isrc: (t['external_ids'] as Map?)?['isrc'] as String?,
      url: id == null ? null : 'https://open.spotify.com/track/$id',
      artworkUrl: art ?? _image(album?['images']),
    );
  }

  static List<String> _artists(Object? list) => [
    for (final a in (list as List? ?? const []))
      if (a is Map && a['name'] is String) a['name'] as String,
  ];

  static String? _image(Object? images) {
    if (images is! List || images.isEmpty) return null;
    final first = images.first;
    return first is Map ? first['url'] as String? : null;
  }

  static int? _total(Object? o) => o is Map ? (o['total'] as num?)?.toInt() : null;
}

import '../../../../l10n/l10n.dart';
import '../../data/oauth.dart';
import '../../data/online_http.dart';
import '../../domain/external_track.dart';
import '../../domain/link_parser.dart';
import '../../domain/online_error.dart';
import '../music_service_module.dart';

/// Yandex Music: public playlists and albums by link, own playlists and likes
/// with a token the user brings. Song names only, never audio.
///
/// **There is no official API.** This uses the undocumented one that Yandex's own
/// apps use, as described by the community project MarshalX/yandex-music-api, so
/// it can change or stop at any time, and it answers only from some countries
/// (HTTP 451 elsewhere). Behind a flag, off by default. Every failure ends in a
/// message that points to the CSV/JSON import, which always works.
class YandexModule extends MusicServiceModule {
  YandexModule(this._http, this._store);

  final OnlineHttp _http;
  final TokenStore _store;

  static const tokenKey = 'prism.oauth.yandex';
  static const _host = 'api.music.yandex.net';

  /// The API refuses requests without this header. It names a client type, it is
  /// not a key; the token is the user's own.
  static const _clientHeader = 'YandexMusicAndroid/24023621';
  static const _batch = 200;

  String? _token;
  String? _uid;

  @override
  OnlineService get service => OnlineService.yandex;

  @override
  Set<ModuleFeature> get features => const {ModuleFeature.login, ModuleFeature.links, ModuleFeature.likes, ModuleFeature.myPlaylists};

  Future<String?> _readToken() async => _token ??= await _store.read(tokenKey);

  Future<Map<String, String>> _headers() async {
    final t = await _readToken();
    return {'X-Yandex-Music-Client': _clientHeader, 'Authorization': ?(t == null ? null : 'OAuth $t')};
  }

  /// Keeps "it may have changed" errors useful: they say what still works.
  Future<T> _guard<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on OnlineException catch (e) {
      if (e.kind == OnlineErrorKind.badResponse) {
        throw OnlineException(OnlineErrorKind.badResponse, service: service, message: l10n.yandexChanged);
      }
      rethrow;
    } on TypeError {
      throw OnlineException(OnlineErrorKind.badResponse, service: service, message: l10n.yandexChanged);
    }
  }

  Future<dynamic> _get(String path) => _guard(() async {
        final j = await _http.getJson(Uri.https(_host, path), service: service, headers: await _headers());
        return j['result'] ?? (throw OnlineException(OnlineErrorKind.badResponse, service: service));
      });

  Future<dynamic> _post(String path, Map<String, String> fields) => _guard(() async {
        final j = await _http.postForm(Uri.https(_host, path), fields, service: service, headers: await _headers());
        return j['result'] ?? (throw OnlineException(OnlineErrorKind.badResponse, service: service));
      });

  // ------------------------------------------------------------- account

  /// Saves a token after checking that Yandex accepts it. A bad one isn't kept.
  Future<AccountInfo> setToken(String token) async {
    final previous = _token;
    _token = token.trim();
    _uid = null;
    try {
      final info = await _status();
      if (info == null) throw OnlineException(OnlineErrorKind.auth, service: service);
      await _store.write(tokenKey, _token!);
      return info;
    } on Object {
      _token = previous;
      rethrow;
    }
  }

  Future<AccountInfo?> _status() async {
    final r = await _get('/account/status') as Map<String, dynamic>;
    final a = r['account'] as Map<String, dynamic>? ?? const {};
    final uid = a['uid'];
    if (uid == null) return null;
    _uid = '$uid';
    final name = a['displayName'] ?? a['login'] ?? a['fullName'] ?? '$uid';
    return AccountInfo(name: '$name');
  }

  @override
  Future<AccountInfo?> account() async {
    if (await _readToken() == null) return null;
    try {
      return await _status();
    } on OnlineException catch (e) {
      if (e.isTransient) return AccountInfo(name: l10n.connected, detail: 'offline');
      if (e.kind == OnlineErrorKind.auth) return null;
      rethrow;
    }
  }

  /// A token is pasted, not logged into: the settings page asks for it.
  @override
  Future<AccountInfo> connect() async {
    final a = await account();
    if (a == null) throw OnlineException(OnlineErrorKind.auth, service: service, message: l10n.yandexNeedsToken);
    return a;
  }

  @override
  Future<void> disconnect() async {
    _token = null;
    _uid = null;
    await _store.delete(tokenKey);
  }

  Future<String> _myUid() async {
    if (_uid != null) return _uid!;
    final a = await account();
    if (a == null || _uid == null) throw OnlineException(OnlineErrorKind.auth, service: service, message: l10n.yandexNeedsToken);
    return _uid!;
  }

  // -------------------------------------------------------------- import

  @override
  Future<List<RemotePlaylistInfo>> myPlaylists() => _guard(_myPlaylists);

  Future<List<RemotePlaylistInfo>> _myPlaylists() async {
    final uid = await _myUid();
    final list = await _get('/users/$uid/playlists/list') as List;
    return [
      for (final p in list.whereType<Map<String, dynamic>>())
        RemotePlaylistInfo(
          service: service,
          id: '${(p['owner'] as Map?)?['uid'] ?? p['uid'] ?? uid}:${p['kind']}',
          name: p['title'] as String? ?? l10n.yandexPlaylist,
          trackCount: (p['trackCount'] as num?)?.toInt(),
          owner: (p['owner'] as Map?)?['name'] as String?,
          artworkUrl: _cover(p['ogImage'] as String?),
        ),
    ];
  }

  @override
  Future<ImportedList> fetchList(RemotePlaylistInfo info, {bool album = false}) => _guard(() {
        final (owner, kind) = _split(info.id);
        return _playlist(owner, kind, null);
      });

  @override
  Future<ImportedList> likedSongs() => _guard(() async => _likes(await _myUid(), null));

  Future<ImportedList> _likes(String uid, String? url) async {
    final r = await _get('/users/$uid/likes/tracks') as Map<String, dynamic>;
    final lib = r['library'] as Map<String, dynamic>? ?? r;
    return ImportedList(
      name: l10n.yandexLikes,
      origin: service,
      sourceUrl: url,
      tracks: await _resolve((lib['tracks'] as List? ?? const []).whereType<Map<String, dynamic>>().toList()),
    );
  }

  @override
  Future<ImportedList> openLink(ParsedLink link) => _guard(() => _open(link));

  Future<ImportedList> _open(ParsedLink link) async {
    final url = link.url.toString();
    switch (link.kind) {
      case LinkKind.playlist:
        if (link.id.contains(':')) {
          final (owner, kind) = _split(link.id);
          return _playlist(owner, kind, url);
        }
        final p = await _get('/playlist/${link.id}') as Map<String, dynamic>;
        return _fromPlaylist(p, url);
      case LinkKind.album:
        final a = await _get('/albums/${link.id}/with-tracks') as Map<String, dynamic>;
        final volumes = a['volumes'] as List? ?? const [];
        final album = a['title'] as String? ?? '';
        final artist = (a['artists'] as List?)?.whereType<Map<String, dynamic>>().map((x) => x['name']).join(', ') ?? '';
        return ImportedList(
          name: artist.isEmpty ? album : '$album – $artist',
          origin: service,
          sourceUrl: url,
          tracks: [
            for (final v in volumes.whereType<List>())
              for (final t in v.whereType<Map<String, dynamic>>()) ?yandexTrack(t),
          ],
        );
      case LinkKind.track:
        final list = await _post('/tracks', {'track-ids': link.id}) as List;
        final tracks = [for (final t in list.whereType<Map<String, dynamic>>()) ?yandexTrack(t)];
        if (tracks.isEmpty) throw OnlineException(OnlineErrorKind.notFound, service: service);
        return ImportedList(name: tracks.first.title, origin: service, tracks: tracks, sourceUrl: url);
      case LinkKind.likes:
        return _likes(link.id, url);
      case LinkKind.shortLink:
        throw unsupported(l10n.openThisLink);
    }
  }

  (String, String) _split(String id) {
    final i = id.lastIndexOf(':');
    return (id.substring(0, i), id.substring(i + 1));
  }

  Future<ImportedList> _playlist(String owner, String kind, String? url) async {
    final list = await _post('/users/$owner/playlists', {'kinds': kind}) as List;
    final p = list.whereType<Map<String, dynamic>>().firstOrNull;
    if (p == null) throw OnlineException(OnlineErrorKind.notFound, service: service);
    return _fromPlaylist(p, url);
  }

  Future<ImportedList> _fromPlaylist(Map<String, dynamic> p, String? url) async => ImportedList(
        name: p['title'] as String? ?? l10n.yandexPlaylist,
        origin: service,
        sourceUrl: url,
        tracks: await _resolve((p['tracks'] as List? ?? const []).whereType<Map<String, dynamic>>().toList()),
      );

  /// A list holds full tracks or only ids (`id` + `albumId`): the rest are asked
  /// for in batches, keeping the order.
  Future<List<ExternalTrack>> _resolve(List<Map<String, dynamic>> shorts) async {
    final out = List<ExternalTrack?>.filled(shorts.length, null);
    final missing = <int>[];
    for (var i = 0; i < shorts.length; i++) {
      final full = shorts[i]['track'];
      if (full is Map<String, dynamic>) {
        out[i] = yandexTrack(full);
      } else {
        missing.add(i);
      }
    }
    for (var b = 0; b < missing.length; b += _batch) {
      final part = missing.sublist(b, b + _batch < missing.length ? b + _batch : missing.length);
      final ids = [
        for (final i in part) shorts[i]['albumId'] == null ? '${shorts[i]['id']}' : '${shorts[i]['id']}:${shorts[i]['albumId']}',
      ];
      final list = await _post('/tracks', {'track-ids': ids.join(',')}) as List;
      final byId = {for (final t in list.whereType<Map<String, dynamic>>()) '${t['id']}': t};
      for (final i in part) {
        final t = byId['${shorts[i]['id']}'];
        if (t != null) out[i] = yandexTrack(t);
      }
    }
    return [for (final t in out) ?t];
  }

  static String? _cover(String? uri) {
    if (uri == null || uri.isEmpty) return null;
    final s = uri.replaceAll('%%', '200x200');
    return s.startsWith('http') ? s : 'https://$s';
  }
}

/// A track from the API; null for one without a title (removed from the
/// catalogue).
ExternalTrack? yandexTrack(Map<String, dynamic> t) {
  final title = t['title'] as String?;
  if (title == null || title.isEmpty) return null;
  final version = t['version'] as String?;
  final albums = (t['albums'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
  final album = albums.firstOrNull;
  final id = '${t['id']}';
  return ExternalTrack(
    service: OnlineService.yandex,
    title: version == null || version.isEmpty ? title : '$title ($version)',
    artists: [
      for (final a in (t['artists'] as List? ?? const []).whereType<Map<String, dynamic>>())
        if (a['name'] is String) a['name'] as String,
    ],
    album: album?['title'] as String? ?? '',
    durationMs: (t['durationMs'] as num?)?.toInt() ?? 0,
    externalId: id,
    url: album == null ? 'https://music.yandex.ru/track/$id' : 'https://music.yandex.ru/album/${album['id']}/track/$id',
    artworkUrl: YandexModule._cover(t['coverUri'] as String?),
  );
}

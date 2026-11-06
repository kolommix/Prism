import '../../../library/domain/track.dart';
import '../../data/oauth.dart';
import '../../data/online_http.dart';
import '../../data/stream_proxy.dart';
import '../../domain/external_track.dart';
import '../../domain/link_parser.dart';
import '../../domain/matching.dart';
import '../../domain/online_error.dart';
import '../music_service_module.dart';
import 'data_api_backend.dart';
import 'youtube_backend.dart';
import '../../../../l10n/l10n.dart';

const youtubeSourceId = 'youtube';

/// Video id from a stored YouTube track uri (`https://www.youtube.com/watch?v=ID`).
String? youtubeIdOf(Track t) => parseMusicLink(t.uri)?.id;

/// YouTube / YouTube Music: search, playlists by link, optional Google login
/// for your own playlists + liked videos, playback and offline cache.
///
/// [catalog] answers search / playlists (official Data API when an API key is
/// configured, else the extractor); [streamer] resolves audio (extractor only,
/// null when the extractor flag is off). Both are [YoutubeBackend]s, so the
/// extractor can be swapped without touching this class.
class YoutubeModule extends MusicServiceModule {
  YoutubeModule({required this.catalog, this.streamer, this.google, this.proxy});

  /// Google login (Data API with the user's token), when an OAuth client id
  /// is in the config file.
  factory YoutubeModule.create({
    required YoutubeBackend? catalog,
    YoutubeBackend? streamer,
    StreamProxy? proxy,
    String googleClientId = '',
    String googleClientSecret = '',
    required TokenStore store,
    required OnlineHttp http,
    required BrowserLauncher launch,
  }) => YoutubeModule(
    catalog: catalog,
    streamer: streamer,
    proxy: proxy,
    google: googleClientId.isEmpty
        ? null
        : OAuthClient(
            service: OnlineService.youtube,
            authorizeUrl: Uri.parse('https://accounts.google.com/o/oauth2/v2/auth'),
            tokenUrl: Uri.parse('https://oauth2.googleapis.com/token'),
            clientId: googleClientId,
            clientSecret: googleClientSecret,
            scopes: const ['https://www.googleapis.com/auth/youtube.readonly'],
            // Google allows any loopback port for desktop clients.
            port: 43823,
            store: store,
            http: http,
            launch: launch,
            extraAuthParams: const {'access_type': 'offline', 'prompt': 'consent'},
          ),
  );

  final YoutubeBackend? catalog;
  final YoutubeBackend? streamer;

  /// Serves streams to the player in bounded chunks (see [StreamProxy]).
  final StreamProxy? proxy;
  final OAuthClient? google;

  DataApiBackend? get _mine => google == null
      ? null
      : DataApiBackend(
          (endpoint, params) => google!.getJson(Uri.https('www.googleapis.com', '/youtube/v3/$endpoint', params)),
        );

  @override
  OnlineService get service => OnlineService.youtube;

  @override
  Set<ModuleFeature> get features => {
    if (catalog != null) ...{ModuleFeature.search, ModuleFeature.links},
    if (streamer != null) ModuleFeature.stream,
    if (google != null) ...{ModuleFeature.login, ModuleFeature.myPlaylists, ModuleFeature.likes},
  };

  @override
  String? get setupHint => catalog == null
      ? l10n.addAYoutubeDataApiKey
      : streamer == null
      ? l10n.searchAndImportWorkPlaybackNeeds
      : null;

  @override
  String? get playableSourceId => youtubeSourceId;

  YoutubeBackend get _catalog =>
      catalog ?? (throw OnlineException(OnlineErrorKind.notConfigured, service: service, message: setupHint));

  // ------------------------------------------------------------- account

  @override
  Future<AccountInfo?> account() async {
    final g = google;
    if (g == null || !await g.isLoggedIn) return null;
    try {
      final j = await g.getJson(
        Uri.https('www.googleapis.com', '/youtube/v3/channels', {'part': 'snippet', 'mine': 'true'}),
      );
      final items = j['items'] as List? ?? const [];
      final title = items.isEmpty ? null : ((items.first as Map)['snippet'] as Map?)?['title'] as String?;
      return AccountInfo(name: title ?? l10n.googleAccount);
    } on OnlineException catch (e) {
      if (e.isTransient) return AccountInfo(name: l10n.connected, detail: 'offline');
      rethrow;
    }
  }

  @override
  Future<AccountInfo> connect() async {
    final g = google ?? (throw unsupported(l10n.logInNoGoogleOauthClient));
    await g.login();
    return (await account())!;
  }

  @override
  Future<void> disconnect() async => google?.logout();

  @override
  Future<List<RemotePlaylistInfo>> myPlaylists() async {
    final g = google ?? (throw unsupported(l10n.listYourPlaylistsWithoutAGoogle));
    final out = <RemotePlaylistInfo>[];
    String? page;
    do {
      final j = await g.getJson(
        Uri.https('www.googleapis.com', '/youtube/v3/playlists', {
          'part': 'snippet,contentDetails',
          'mine': 'true',
          'maxResults': '50',
          'pageToken': ?page,
        }),
      );
      for (final p in (j['items'] as List? ?? const []).whereType<Map>()) {
        final sn = p['snippet'] as Map? ?? const {};
        out.add(
          RemotePlaylistInfo(
            service: service,
            id: p['id'] as String,
            name: unescapeHtml(sn['title'] as String? ?? l10n.playlist2),
            trackCount: ((p['contentDetails'] as Map?)?['itemCount'] as num?)?.toInt(),
            artworkUrl: (((sn['thumbnails'] as Map?)?['medium']) as Map?)?['url'] as String?,
          ),
        );
      }
      page = j['nextPageToken'] as String?;
    } while (page != null);
    return out;
  }

  @override
  Future<ImportedList> likedSongs() async {
    final g = google ?? (throw unsupported(l10n.readLikedVideosWithoutAGoogle));
    final videos = <YtVideo>[];
    String? page;
    do {
      final j = await g.getJson(
        Uri.https('www.googleapis.com', '/youtube/v3/videos', {
          'part': 'snippet,contentDetails',
          'myRating': 'like',
          'maxResults': '50',
          'pageToken': ?page,
        }),
      );
      videos.addAll(
        await _mine!.videos([for (final v in (j['items'] as List? ?? const []).whereType<Map>()) v['id'] as String]),
      );
      page = j['nextPageToken'] as String?;
    } while (page != null && videos.length < 5000);
    return ImportedList(
      name: l10n.likedVideosYoutube,
      origin: service,
      tracks: [for (final v in videos) externalFromVideo(v)],
    );
  }

  @override
  Future<ImportedList> fetchList(RemotePlaylistInfo info, {bool album = false}) async {
    // Own (possibly private) playlists go through the login.
    final pl = await (_mine ?? _catalog).playlist(info.id);
    return _toList(pl);
  }

  @override
  Future<ImportedList> openLink(ParsedLink link) async {
    switch (link.kind) {
      case LinkKind.playlist:
        YtPlaylist pl;
        try {
          pl = await _catalog.playlist(link.id);
        } on OnlineException catch (e) {
          // Private / unlisted playlist of the logged-in user.
          if (e.kind != OnlineErrorKind.notFound || _mine == null || !await google!.isLoggedIn) rethrow;
          pl = await _mine!.playlist(link.id);
        }
        return _toList(pl);
      case LinkKind.track:
        final v = await _catalog.video(link.id);
        return ImportedList(name: v.title, origin: service, tracks: [externalFromVideo(v)], sourceUrl: v.url);
      case _:
        throw unsupported(l10n.openThisKindOfLink);
    }
  }

  ImportedList _toList(YtPlaylist pl) => ImportedList(
    name: pl.title,
    origin: service,
    sourceUrl: 'https://www.youtube.com/playlist?list=${pl.id}',
    tracks: [for (final v in pl.videos) externalFromVideo(v)],
  );

  // ------------------------------------------------------------- catalog

  @override
  Future<List<Track>> search(String query, {int limit = 20}) async => [
    for (final v in await _catalog.search(query, limit: limit)) trackFromVideo(v),
  ];

  @override
  Future<Uri> streamUri(Track track) async {
    final s = _streamer();
    final id = _id(track);
    // Resolve now, so a removed video fails here (player skips it with a
    // message) instead of inside the proxy.
    final first = await s.audioStream(id);
    final p = proxy;
    if (p == null) return first.url;
    return p.register('yt:$id', ({bool refresh = false}) async {
      final a = refresh ? await s.audioStream(id, refresh: true) : await s.audioStream(id);
      return ProxiedStream(url: a.url, length: a.length, mimeType: a.mimeType, headers: a.headers);
    });
  }

  @override
  Future<Map<String, String>> streamHeaders(Track track) async =>
      proxy != null ? const {} : (await _streamer().audioStream(_id(track))).headers;

  String _id(Track track) => youtubeIdOf(track) ?? (throw OnlineException(OnlineErrorKind.notFound, service: service));

  YoutubeBackend _streamer() {
    final s = streamer;
    if (s == null) {
      throw OnlineException(
        OnlineErrorKind.disabled,
        service: service,
        message:
            l10n.youtubePlaybackIsOffTurnOn,
      );
    }
    return s;
  }

  @override
  Future<String> download(Track track, String targetPathWithoutExt) {
    final s = streamer ?? (throw unsupported(l10n.saveSongsOfflineWithoutTheExtractor));
    return s.download(youtubeIdOf(track)!, targetPathWithoutExt);
  }

  static final _topic = RegExp(r'\s*-\s*Topic$');
  static final _vevo = RegExp(r'VEVO$');

  /// A playable Prism track (not saved yet: id 0).
  static Track trackFromVideo(YtVideo v) => Track(
    id: 0,
    sourceId: youtubeSourceId,
    uri: v.url,
    title: v.title,
    artist: v.channel,
    durationMs: v.durationMs,
    artworkPath: v.thumbnailUrl,
  );

  /// Import metadata: "Artist - Title (Official Video)" is split, a
  /// "Artist - Topic" / "ArtistVEVO" channel becomes the artist.
  static ExternalTrack externalFromVideo(YtVideo v) {
    final dash = RegExp(r'\s+[-–—]\s+').firstMatch(v.title);
    final channel = v.channel.replaceFirst(_topic, '').replaceFirst(_vevo, '').trim();
    return ExternalTrack(
      service: OnlineService.youtube,
      title: dash == null ? v.title : v.title.substring(dash.end),
      artists: dash == null ? [if (channel.isNotEmpty) channel] : splitArtists(v.title.substring(0, dash.start)),
      durationMs: v.durationMs,
      externalId: v.id,
      url: v.url,
      artworkUrl: v.thumbnailUrl,
    );
  }

  @override
  void dispose() {
    catalog?.close();
    if (!identical(streamer, catalog)) streamer?.close();
  }
}

import 'dart:convert';

import '../../../../l10n/l10n.dart';
import '../../data/online_http.dart';
import '../../domain/external_track.dart';
import '../../domain/link_parser.dart';
import '../../domain/matching.dart';
import '../../domain/online_error.dart';
import '../music_service_module.dart';
import '../youtube/web_playlist_reader.dart';
import '../youtube/youtube_backend.dart';
import '../youtube/youtube_module.dart';

/// Spotify without a key or a login: reads the text of the public embed page of
/// a playlist, album or song. Names only, never audio. Spotify's embed shows at
/// most about 100 songs of a list; bigger lists need a login or a file.
class SpotifyPublicReader extends MusicServiceModule {
  SpotifyPublicReader(this._http);
  final OnlineHttp _http;

  /// The embed page stops around here.
  static const embedLimit = 100;

  @override
  OnlineService get service => OnlineService.spotify;
  @override
  Set<ModuleFeature> get features => const {ModuleFeature.links};

  @override
  Future<ImportedList> openLink(ParsedLink link) async {
    final kind = switch (link.kind) {
      LinkKind.playlist => 'playlist',
      LinkKind.album => 'album',
      LinkKind.track => 'track',
      // Liked songs are private: only a login can read them.
      _ => throw OnlineException(OnlineErrorKind.auth, service: service),
    };
    final html = await _http.getText(Uri.https('open.spotify.com', '/embed/$kind/${link.id}'), service: service);
    final list = parseSpotifyEmbed(html, sourceUrl: link.canonicalUrl);
    if (list == null) throw OnlineException(OnlineErrorKind.notFound, service: service);
    return list;
  }
}

final _nextData = RegExp(r'<script[^>]*id="__NEXT_DATA__"[^>]*>(.*?)</script>', dotAll: true);

/// The list inside a Spotify embed page, or null when there is none (private
/// or deleted). [sourceUrl] is kept on the result.
ImportedList? parseSpotifyEmbed(String html, {String? sourceUrl}) {
  final m = _nextData.firstMatch(html);
  if (m == null) throw OnlineException(OnlineErrorKind.badResponse, service: OnlineService.spotify);
  final Object? json;
  try {
    json = jsonDecode(m[1]!);
  } on FormatException {
    throw OnlineException(OnlineErrorKind.badResponse, service: OnlineService.spotify);
  }
  Object? at(Object? node, List<String> path) {
    var n = node;
    for (final key in path) {
      if (n is! Map) return null;
      n = n[key];
    }
    return n;
  }

  final entity = at(json, const ['props', 'pageProps', 'state', 'data', 'entity']);
  if (entity is! Map) return null;
  final name = (entity['name'] ?? entity['title']) as String?;
  final rows = entity['trackList'];
  final tracks = <ExternalTrack>[];
  if (rows is List) {
    final isAlbum = entity['type'] == 'album';
    for (final t in rows.whereType<Map>()) {
      final title = t['title'] as String?;
      if (title == null || title.isEmpty) continue;
      final artist = t['subtitle'] as String? ?? '';
      final uri = t['uri'] as String?;
      final id = uri?.split(':').last;
      tracks.add(ExternalTrack(
        service: OnlineService.spotify,
        title: title,
        artists: artist.isEmpty ? const [] : splitArtists(artist),
        album: isAlbum ? name ?? '' : '',
        durationMs: (t['duration'] as num?)?.toInt() ?? 0,
        externalId: id,
        url: id == null ? null : 'https://open.spotify.com/track/$id',
      ));
    }
  } else if (entity['type'] == 'track' && name != null) {
    final artists = [
      for (final a in (entity['artists'] as List? ?? const []).whereType<Map>())
        if (a['name'] is String) a['name'] as String,
    ];
    final id = entity['id'] as String?;
    tracks.add(ExternalTrack(
      service: OnlineService.spotify,
      title: name,
      artists: artists,
      durationMs: (entity['duration'] as num?)?.toInt() ?? 0,
      externalId: id,
      url: id == null ? null : 'https://open.spotify.com/track/$id',
    ));
  }
  if (tracks.isEmpty) return null;
  return ImportedList(
    name: name ?? l10n.importedPlaylist,
    origin: OnlineService.spotify,
    tracks: tracks,
    sourceUrl: sourceUrl,
  );
}

/// Spotify links: a connected account first (it can read long and private lists),
/// otherwise, or if Spotify refuses the account, the public page.
class SpotifyLinkReader extends MusicServiceModule {
  SpotifyLinkReader(this._public, this._account);
  final MusicServiceModule _public;
  final MusicServiceModule? _account;

  @override
  OnlineService get service => OnlineService.spotify;
  @override
  Set<ModuleFeature> get features => const {ModuleFeature.links};

  @override
  Future<ImportedList> openLink(ParsedLink link) async {
    final account = _account;
    if (account != null) {
      try {
        if (await account.account() != null) return await account.openLink(link);
      } on OnlineException catch (e) {
        if (e.isTransient || link.kind == LinkKind.likes) rethrow;
      }
    }
    return _public.openLink(link);
  }
}

/// YouTube without a key or the extractor switch: the text of a public playlist
/// page, or the official oEmbed answer for one video. Names only.
class YoutubePublicReader extends MusicServiceModule {
  YoutubePublicReader(this._http);
  final OnlineHttp _http;

  @override
  OnlineService get service => OnlineService.youtube;
  @override
  Set<ModuleFeature> get features => const {ModuleFeature.links};

  @override
  Future<ImportedList> openLink(ParsedLink link) async {
    switch (link.kind) {
      case LinkKind.playlist:
        final reader = WebPlaylistReader();
        try {
          final YtPlaylist pl;
          try {
            pl = await reader.read(link.id);
          } on OnlineException {
            rethrow;
          } on Object {
            throw OnlineException(OnlineErrorKind.offline, service: service);
          }
          if (pl.videos.isEmpty) throw OnlineException(OnlineErrorKind.notFound, service: service);
          return ImportedList(
            name: pl.title,
            origin: service,
            sourceUrl: link.canonicalUrl,
            tracks: [for (final v in pl.videos) YoutubeModule.externalFromVideo(v)],
          );
        } finally {
          reader.close();
        }
      case LinkKind.track:
        final j = await _http.getJson(
          Uri.https('www.youtube.com', '/oembed', {'url': link.canonicalUrl, 'format': 'json'}),
          service: service,
        );
        final v = YtVideo(id: link.id, title: j['title'] as String? ?? '', channel: j['author_name'] as String? ?? '');
        if (v.title.isEmpty) throw OnlineException(OnlineErrorKind.notFound, service: service);
        return ImportedList(name: v.title, origin: service, sourceUrl: link.canonicalUrl, tracks: [YoutubeModule.externalFromVideo(v)]);
      case _:
        throw unsupported(l10n.openThisKindOfLink);
    }
  }
}

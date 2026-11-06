import 'external_track.dart';

enum LinkKind { playlist, album, track, likes, shortLink }

/// A pasted link, understood. [id] is the service's id; for [LinkKind.likes]
/// it's the user name, for [LinkKind.shortLink] it's empty (follow [url]).
class ParsedLink {
  const ParsedLink(this.service, this.kind, this.id, this.url);

  final OnlineService service;
  final LinkKind kind;
  final String id;
  final Uri url;

  @override
  bool operator ==(Object other) =>
      other is ParsedLink && other.service == service && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(service, kind, id);

  @override
  String toString() => 'ParsedLink(${service.name}, ${kind.name}, $id)';
}

final _spotifyUri = RegExp(r'^spotify:(playlist|album|track):([A-Za-z0-9]+)$');

/// Recognises Spotify, YouTube / YouTube Music, SoundCloud, Apple Music and
/// Deezer links. Returns null for anything else.
ParsedLink? parseMusicLink(String input) {
  final text = input.trim();
  final su = _spotifyUri.firstMatch(text);
  if (su != null) {
    return ParsedLink(OnlineService.spotify, LinkKind.values.byName(su[1]!), su[2]!, Uri.parse(text));
  }
  var uri = Uri.tryParse(text);
  if (uri == null) return null;
  if (!uri.hasScheme) uri = Uri.tryParse('https://$text');
  if (uri == null || uri.host.isEmpty) return null;
  final host = uri.host.toLowerCase().replaceFirst(RegExp(r'^(www|m)\.'), '');
  final seg = uri.pathSegments.where((s) => s.isNotEmpty).toList();

  // ---------------------------------------------------------------- Spotify
  if (host == 'open.spotify.com' || host == 'play.spotify.com') {
    final s = seg.isNotEmpty && seg.first.startsWith('intl-') ? seg.sublist(1) : seg;
    if (s.length >= 2 && s[0] == 'collection' && s[1] == 'tracks') {
      return ParsedLink(OnlineService.spotify, LinkKind.likes, 'me', uri);
    }
    if (s.length >= 2) {
      final kind = switch (s[0]) {
        'playlist' => LinkKind.playlist,
        'album' => LinkKind.album,
        'track' => LinkKind.track,
        _ => null,
      };
      if (kind != null) return ParsedLink(OnlineService.spotify, kind, s[1], uri);
    }
    return null;
  }
  if (host == 'spotify.link') return ParsedLink(OnlineService.spotify, LinkKind.shortLink, '', uri);

  // ---------------------------------------------------------------- YouTube
  if (host == 'youtube.com' || host == 'music.youtube.com') {
    final list = uri.queryParameters['list'];
    // Mixes ("RD…") are generated per viewer and can't be imported.
    if (list != null && list.isNotEmpty && !list.startsWith('RD')) {
      return ParsedLink(OnlineService.youtube, LinkKind.playlist, list, uri);
    }
    if (seg.length >= 2 && seg[0] == 'browse' && seg[1].startsWith('VL')) {
      return ParsedLink(OnlineService.youtube, LinkKind.playlist, seg[1].substring(2), uri);
    }
    final v = uri.queryParameters['v'];
    if (seg.isNotEmpty && seg[0] == 'watch' && v != null && v.isNotEmpty) {
      return ParsedLink(OnlineService.youtube, LinkKind.track, v, uri);
    }
    if (seg.length >= 2 && (seg[0] == 'shorts' || seg[0] == 'embed' || seg[0] == 'live')) {
      return ParsedLink(OnlineService.youtube, LinkKind.track, seg[1], uri);
    }
    return null;
  }
  if (host == 'youtu.be' && seg.isNotEmpty) {
    return ParsedLink(OnlineService.youtube, LinkKind.track, seg[0], uri);
  }

  // ------------------------------------------------------------- SoundCloud
  if (host == 'soundcloud.com') {
    if (seg.length >= 3 && seg[1] == 'sets') {
      return ParsedLink(OnlineService.soundcloud, LinkKind.playlist, '${seg[0]}/sets/${seg[2]}', uri);
    }
    if (seg.length == 2 && seg[1] == 'likes') return ParsedLink(OnlineService.soundcloud, LinkKind.likes, seg[0], uri);
    if (seg.length == 2 && !const {'discover', 'search', 'you', 'stream', 'charts'}.contains(seg[0])) {
      return ParsedLink(OnlineService.soundcloud, LinkKind.track, '${seg[0]}/${seg[1]}', uri);
    }
    return null;
  }
  if (host == 'on.soundcloud.com') return ParsedLink(OnlineService.soundcloud, LinkKind.shortLink, '', uri);

  // ------------------------------------------------------------ Apple Music
  if (host == 'music.apple.com' || host == 'itunes.apple.com') {
    // /{country}/playlist/{slug}/{pl.id} or /{country}/album/{slug}/{id}
    final i = seg.indexWhere((s) => s == 'playlist' || s == 'album');
    if (i >= 0 && seg.length > i + 1) {
      final id = seg.last;
      final song = uri.queryParameters['i'];
      if (seg[i] == 'album' && song != null) return ParsedLink(OnlineService.appleMusic, LinkKind.track, song, uri);
      return ParsedLink(OnlineService.appleMusic, seg[i] == 'playlist' ? LinkKind.playlist : LinkKind.album, id, uri);
    }
    return null;
  }

  // ----------------------------------------------------------------- Deezer
  if (host == 'deezer.com') {
    final s = seg.isNotEmpty && seg.first.length == 2 ? seg.sublist(1) : seg;
    if (s.length >= 2) {
      final kind = switch (s[0]) {
        'playlist' => LinkKind.playlist,
        'album' => LinkKind.album,
        'track' => LinkKind.track,
        _ => null,
      };
      if (kind != null && int.tryParse(s[1]) != null) return ParsedLink(OnlineService.deezer, kind, s[1], uri);
    }
    return null;
  }
  if (host == 'deezer.page.link' || host == 'link.deezer.com') {
    return ParsedLink(OnlineService.deezer, LinkKind.shortLink, '', uri);
  }
  // ------------------------------------------------------------ Yandex Music
  if (RegExp(r'^music\.yandex\.[a-z.]+$').hasMatch(host)) {
    if (seg.length >= 4 && seg[0] == 'users' && seg[2] == 'playlists') {
      return ParsedLink(OnlineService.yandex, LinkKind.playlist, '${seg[1]}:${seg[3]}', uri);
    }
    if (seg.length >= 3 && seg[0] == 'users' && seg[2] == 'tracks') {
      return ParsedLink(OnlineService.yandex, LinkKind.likes, seg[1], uri);
    }
    if (seg.length >= 2 && seg[0] == 'playlists') return ParsedLink(OnlineService.yandex, LinkKind.playlist, seg[1], uri);
    if (seg.length >= 4 && seg[0] == 'album' && seg[2] == 'track') {
      return ParsedLink(OnlineService.yandex, LinkKind.track, '${seg[3]}:${seg[1]}', uri);
    }
    if (seg.length >= 2 && seg[0] == 'album') return ParsedLink(OnlineService.yandex, LinkKind.album, seg[1], uri);
    if (seg.length >= 2 && seg[0] == 'track') return ParsedLink(OnlineService.yandex, LinkKind.track, seg[1], uri);
    return null;
  }
  return null;
}

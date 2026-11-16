import 'youtube_backend.dart';

/// YouTube Music's song search (the "Songs" tab of music.youtube.com): the
/// official audio uploads with the song's real name, its artists, album and
/// exact length. Far better to match against than video titles ("Artist -
/// Song (Official Video) [4K]" with a minute of intro). Same internal web
/// API as the rest of the extractor, so it lives behind the same switch.
abstract final class YtMusicSongs {
  static final endpoint = Uri.parse('https://music.youtube.com/youtubei/v1/search?prettyPrint=false');

  /// The "Songs" filter of the search page.
  static const songsFilter = 'EgWKAQIIAWoQEAMQBBAJEAoQBRAREBAQFQ%3D%3D';

  /// What the music.youtube.com page itself sends.
  static Map<String, Object> body(String query) => {
        'context': {
          'client': {'clientName': 'WEB_REMIX', 'clientVersion': '1.20251110.01.00', 'hl': 'en', 'gl': 'US'},
        },
        'query': query,
        'params': songsFilter,
      };

  static const headers = {
    'content-type': 'application/json',
    'origin': 'https://music.youtube.com',
    'referer': 'https://music.youtube.com/',
  };

  static final _duration = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$');

  /// Songs in a search answer, in YouTube Music's order.
  static List<YtVideo> parse(Map<String, dynamic> json, {int limit = 10}) {
    final out = <YtVideo>[];
    for (final shelf in _list(_at(json, ['contents', 'tabbedSearchResultsRenderer', 'tabs', 0, 'tabRenderer', 'content', 'sectionListRenderer', 'contents']))) {
      for (final item in _list(_at(shelf, ['musicShelfRenderer', 'contents']))) {
        final song = _song(_at(item, ['musicResponsiveListItemRenderer']));
        if (song != null) out.add(song);
        if (out.length >= limit) return out;
      }
    }
    return out;
  }

  static YtVideo? _song(Object? r) {
    if (r is! Map) return null;
    final columns = _list(r['flexColumns']);
    if (columns.length < 2) return null;
    final titleRuns = _runs(columns[0]);
    final id = '${_at(r, ['playlistItemData', 'videoId']) ?? _at(titleRuns.firstOrNull, ['navigationEndpoint', 'watchEndpoint', 'videoId']) ?? ''}';
    final title = titleRuns.map((x) => '${x['text'] ?? ''}').join().trim();
    if (id.length != 11 || title.isEmpty) return null;

    // "Artist & Other • Album • 3:44", runs split by " • ".
    final groups = <List<Map>>[[]];
    for (final run in _runs(columns[1])) {
      if ('${run['text']}'.trim() == '•') {
        groups.add([]);
      } else {
        groups.last.add(run);
      }
    }
    String text(List<Map> g) => g.map((x) => '${x['text'] ?? ''}').join().trim();
    String pageType(Map run) =>
        '${_at(run, ['navigationEndpoint', 'browseEndpoint', 'browseEndpointContextSupportedConfigs', 'browseEndpointContextMusicConfig', 'pageType']) ?? ''}';
    var artists = '', album = '';
    var durationMs = 0;
    for (final g in groups) {
      final t = text(g);
      if (t.isEmpty) continue;
      final d = _duration.firstMatch(t);
      if (d != null) {
        final a = int.parse(d[1]!), b = int.parse(d[2]!), c = d[3] == null ? null : int.parse(d[3]!);
        durationMs = (c == null ? a * 60 + b : (a * 60 + b) * 60 + c) * 1000;
      } else if (g.any((x) => pageType(x) == 'MUSIC_PAGE_TYPE_ALBUM')) {
        album = t;
      } else if (artists.isEmpty && t != 'Song') {
        artists = t;
      }
    }
    final thumbs = _list(_at(r, ['thumbnail', 'musicThumbnailRenderer', 'thumbnail', 'thumbnails']));
    final thumb = thumbs.isEmpty ? null : '${(thumbs.last as Map)['url'] ?? ''}';
    return YtVideo(
      id: id,
      title: title,
      channel: artists,
      durationMs: durationMs,
      // Square cover; ask for a bigger one than the list's 120 px.
      thumbnailUrl: thumb == null || thumb.isEmpty ? null : thumb.replaceFirst(RegExp(r'=w\d+-h\d+'), '=w544-h544'),
      album: album,
      song: true,
    );
  }

  static List<Map> _runs(Object? column) =>
      _list(_at(column, ['musicResponsiveListItemFlexColumnRenderer', 'text', 'runs'])).whereType<Map>().toList();

  static List<Object?> _list(Object? v) => v is List ? v : const [];

  static Object? _at(Object? v, List<Object> path) {
    var cur = v;
    for (final k in path) {
      if (k is int) {
        if (cur is! List || k >= cur.length) return null;
        cur = cur[k];
      } else {
        if (cur is! Map) return null;
        cur = cur[k];
      }
    }
    return cur;
  }
}

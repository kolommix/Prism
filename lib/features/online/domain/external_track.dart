import '../../../l10n/l10n.dart';

/// Online services Prism can talk to. Each one lives in its own module under
/// `features/online/services/` and can be switched off on its own.
enum OnlineService {
  spotify,
  youtube,
  soundcloud,
  deezer,
  appleMusic,
  yandex,
  file;

  String get label => switch (this) {
        OnlineService.spotify => 'Spotify',
        OnlineService.youtube => l10n.youtube,
        OnlineService.soundcloud => 'SoundCloud',
        OnlineService.deezer => 'Deezer',
        OnlineService.appleMusic => 'Apple Music',
        OnlineService.yandex => l10n.yandexLabel,
        OnlineService.file => l10n.xFile,
      };
  static OnlineService? byName(String? name) => values.where((s) => s.name == name).firstOrNull;
}

/// A song as another service (or an import file) describes it: metadata only,
/// never audio. Imports are lists of these; the matcher turns each one into a
/// playable Prism `Track` (local file, YouTube or SoundCloud).
class ExternalTrack {
  const ExternalTrack({
    required this.service,
    required this.title,
    this.artists = const [],
    this.album = '',
    this.durationMs = 0,
    this.externalId,
    this.isrc,
    this.url,
    this.artworkUrl,
    this.guessed = false,
    this.altTitle,
    this.altArtists = const [],
  });

  factory ExternalTrack.fromJson(Map<String, dynamic> j) => ExternalTrack(
    guessed: j['guessed'] == true,
    altTitle: j['altTitle'] as String?,
    altArtists: [for (final a in (j['altArtists'] as List? ?? const [])) '$a'],
    service: OnlineService.byName(j['service'] as String?) ?? OnlineService.file,
    title: j['title'] as String? ?? '',
    artists: [for (final a in (j['artists'] as List? ?? const [])) '$a'],
    album: j['album'] as String? ?? '',
    durationMs: (j['durationMs'] as num?)?.toInt() ?? 0,
    externalId: j['externalId'] as String?,
    isrc: j['isrc'] as String?,
    url: j['url'] as String?,
    artworkUrl: j['artworkUrl'] as String?,
  );

  final OnlineService service;
  final String title;
  final List<String> artists;
  final String album;

  /// 0 when unknown (M3U without #EXTINF, some CSVs).
  final int durationMs;

  /// Service-specific id (Spotify track id, YouTube video id, …).
  final String? externalId;
  final String? isrc;
  final String? url;
  final String? artworkUrl;

  /// Names read off a picture: may be misspelled, so a sure match's own
  /// spelling replaces them.
  final bool guessed;

  /// Another reading of the title / artists (the picture's other text
  /// reader), tried too when looking the song up.
  final String? altTitle;
  final List<String> altArtists;

  String get artist => artists.join(', ');

  /// This song and its other readings (each without further readings).
  List<ExternalTrack> get spellings {
    if (altTitle == null && altArtists.isEmpty) return [this];
    final titles = {title, ?altTitle}, names = [artists, if (altArtists.isNotEmpty) altArtists];
    return [
      for (final t in titles)
        for (final a in names) copyWith(title: t, artists: a, noAlts: true),
    ];
  }

  /// [noAlts] drops the other readings.
  ExternalTrack copyWith({String? title, List<String>? artists, int? durationMs, bool noAlts = false}) =>
      ExternalTrack(
        service: service,
        title: title ?? this.title,
        artists: artists ?? this.artists,
        album: album,
        durationMs: durationMs ?? this.durationMs,
        externalId: externalId,
        isrc: isrc,
        url: url,
        artworkUrl: artworkUrl,
        guessed: guessed,
        altTitle: noAlts ? null : altTitle,
        altArtists: noAlts ? const [] : altArtists,
      );

  Map<String, Object?> toJson() => {
    'service': service.name,
    'title': title,
    'artists': artists,
    if (album.isNotEmpty) 'album': album,
    if (durationMs > 0) 'durationMs': durationMs,
    'externalId': ?externalId,
    'isrc': ?isrc,
    'url': ?url,
    'artworkUrl': ?artworkUrl,
    if (guessed) 'guessed': true,
    'altTitle': ?altTitle,
    if (altArtists.isNotEmpty) 'altArtists': altArtists,
  };

  @override
  String toString() => '$artist – $title';
}

/// A playlist (or liked songs, or an album) fetched from a service or a file.
class ImportedList {
  const ImportedList({required this.name, required this.origin, required this.tracks, this.sourceUrl});

  final String name;
  final OnlineService origin;
  final List<ExternalTrack> tracks;

  /// Link or file path it came from – used to spot "already imported".
  final String? sourceUrl;
}

/// Short summary of a playlist the user can pick in the import screen.
class RemotePlaylistInfo {
  const RemotePlaylistInfo({
    required this.service,
    required this.id,
    required this.name,
    this.trackCount,
    this.owner,
    this.artworkUrl,
  });

  final OnlineService service;
  final String id;
  final String name;
  final int? trackCount;
  final String? owner;
  final String? artworkUrl;
}

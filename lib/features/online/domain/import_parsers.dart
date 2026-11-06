import 'dart:convert';

import 'package:path/path.dart' as p;

import 'external_track.dart';
import 'matching.dart';
import '../../../l10n/l10n.dart';

import '../../playlists/domain/playlist_share.dart';
/// Thrown when a file can't be read as a playlist.
class ImportFormatException implements Exception {
  ImportFormatException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Reads a playlist export. Supported:
/// * CSV – Exportify, TuneMyMusic and any CSV with title/artist columns
///   (`,` `;` or tab separated). A "Playlist name" column splits the file
///   into several playlists.
/// * JSON – a list of songs, `{name, tracks}`, Spotify data-export files
///   (`YourLibrary.json`, `Playlist1.json`).
/// * M3U / M3U8 – `#EXTINF` lines and file paths / URLs.
List<ImportedList> parseImportFile(String fileName, String content) {
  final text = content.startsWith('﻿') ? content.substring(1) : content;
  final ext = p.extension(fileName).toLowerCase();
  final base = p.basenameWithoutExtension(fileName);
  if (ext == '.$shareExtension' || isSharedPlaylistText(text)) {
    try {
      return [decodeSharedPlaylist(text, sourceUrl: fileName)];
    } on ShareFormatException catch (e) {
      throw ImportFormatException(e.message);
    }
  }
  final lists = switch (ext) {
    '.m3u' || '.m3u8' => [parseM3u(text, fallbackName: base, path: fileName)],
    '.json' => parseJsonPlaylists(text, fallbackName: base, path: fileName),
    '.csv' || '.tsv' || '.txt' => parseCsvPlaylists(text, fallbackName: base, path: fileName),
    _ =>
      text.trimLeft().startsWith('#EXTM3U')
          ? [parseM3u(text, fallbackName: base, path: fileName)]
          : (text.trimLeft().startsWith('{') || text.trimLeft().startsWith('['))
          ? parseJsonPlaylists(text, fallbackName: base, path: fileName)
          : parseCsvPlaylists(text, fallbackName: base, path: fileName),
  };
  final nonEmpty = lists.where((l) => l.tracks.isNotEmpty).toList();
  if (nonEmpty.isEmpty) throw ImportFormatException(l10n.noSongsFoundIn(fileName));
  return nonEmpty;
}

// ------------------------------------------------------------------- CSV

/// RFC 4180 CSV: quoted fields, `""` escapes, newlines inside quotes.
List<List<String>> parseCsv(String text, {String? delimiter}) {
  final d = delimiter ?? _guessDelimiter(text);
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        field.write(c);
      }
    } else if (c == '"' && field.isEmpty) {
      quoted = true;
    } else if (c == d) {
      row.add(field.toString());
      field.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(field.toString());
      field.clear();
      if (row.any((f) => f.trim().isNotEmpty)) rows.add(row);
      row = <String>[];
    } else {
      field.write(c);
    }
  }
  row.add(field.toString());
  if (row.any((f) => f.trim().isNotEmpty)) rows.add(row);
  return rows;
}

String _guessDelimiter(String text) {
  final firstLine = text.split('\n').first;
  final counts = {
    for (final d in [',', ';', '\t']) d: d.allMatches(firstLine).length,
  };
  return counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
}

int _col(List<String> header, List<String> names) {
  for (final n in names) {
    final i = header.indexOf(n);
    if (i >= 0) return i;
  }
  return -1;
}

/// "3:25", "1:02:03", "205000" (ms), "205" (s) → ms.
int parseDurationText(String raw, {bool millis = false}) {
  final s = raw.trim();
  if (s.isEmpty) return 0;
  if (s.contains(':')) {
    var total = 0;
    for (final part in s.split(':')) {
      total = total * 60 + (int.tryParse(part.trim().split('.').first) ?? 0);
    }
    return total * 1000;
  }
  final n = double.tryParse(s);
  if (n == null) return 0;
  if (millis || n > 10000) return n.round();
  return (n * 1000).round();
}

List<ImportedList> parseCsvPlaylists(String text, {required String fallbackName, String? path}) {
  final rows = parseCsv(text);
  if (rows.length < 2) throw ImportFormatException(l10n.theCsvFileHasNoSong);
  final header = [for (final h in rows.first) h.trim().toLowerCase()];
  final title = _col(header, ['track name', 'track_name', 'title', 'song', 'song name', 'track', 'name', 'trackname', 'название', 'трек', 'песня']);
  final artist = _col(header, [
    'artist name(s)',
    'artist name',
    'artist names',
    'artists',
    'artist',
    'artist_name',
    'artistname',
    'исполнитель',
    'исполнители',
    'артист',
  ]);
  if (title < 0) {
    throw ImportFormatException(l10n.couldNotFindATitleColumn);
  }
  final album = _col(header, ['album name', 'album', 'album title', 'album_name', 'albumname', 'альбом']);
  final durMs = _col(header, ['track duration (ms)', 'duration (ms)', 'duration_ms', 'duration ms']);
  final dur = _col(header, ['duration', 'length', 'time', 'длительность', 'время']);
  final isrc = _col(header, ['isrc']);
  final uri = _col(header, ['track uri', 'spotify uri', 'uri', 'url', 'link', 'spotify - id', 'spotify id']);
  final playlist = _col(header, ['playlist name', 'playlist', 'playlist_name']);
  final exportify = header.contains('track uri') || header.contains('artist name(s)');

  String cell(List<String> r, int i) => i >= 0 && i < r.length ? r[i].trim() : '';
  final grouped = <String, List<ExternalTrack>>{};
  for (final r in rows.skip(1)) {
    final t = cell(r, title);
    if (t.isEmpty) continue;
    final rawArtist = cell(r, artist);
    // Exportify joins artists with "," – but names like "Tyler, The Creator"
    // also contain commas, so only split on ", " when it's not Exportify.
    final artists = rawArtist.isEmpty
        ? const <String>[]
        : exportify
        ? rawArtist.split(RegExp(r',(?! )')).map((a) => a.trim()).where((a) => a.isNotEmpty).toList()
        : splitArtists(rawArtist);
    final link = cell(r, uri);
    final spotifyId =
        RegExp(r'(?:spotify:track:|open\.spotify\.com/track/)([A-Za-z0-9]+)').firstMatch(link)?[1] ??
        (RegExp(r'^[A-Za-z0-9]{22}$').hasMatch(link) ? link : null);
    final track = ExternalTrack(
      service: spotifyId != null ? OnlineService.spotify : OnlineService.file,
      title: t,
      artists: artists,
      album: cell(r, album),
      durationMs: durMs >= 0 ? parseDurationText(cell(r, durMs), millis: true) : parseDurationText(cell(r, dur)),
      isrc: cell(r, isrc).isEmpty ? null : cell(r, isrc),
      externalId: spotifyId,
      url: link.startsWith('http') ? link : (spotifyId != null ? 'https://open.spotify.com/track/$spotifyId' : null),
    );
    (grouped[playlist >= 0 && cell(r, playlist).isNotEmpty ? cell(r, playlist) : fallbackName] ??= []).add(track);
  }
  return [
    for (final e in grouped.entries)
      ImportedList(
        name: e.key,
        origin: OnlineService.file,
        tracks: e.value,
        sourceUrl: path == null ? null : '$path#${e.key}',
      ),
  ];
}

// ------------------------------------------------------------------ JSON

List<ImportedList> parseJsonPlaylists(String text, {required String fallbackName, String? path}) {
  final Object? data;
  try {
    data = jsonDecode(text);
  } on FormatException catch (e) {
    throw ImportFormatException(l10n.notValidJson(e.message));
  }
  ImportedList list(String name, Iterable<Object?> items) => ImportedList(
    name: name,
    origin: OnlineService.file,
    tracks: [for (final i in items) ?_jsonTrack(i)],
    sourceUrl: path == null ? null : '$path#$name',
  );

  if (data is List) return [list(fallbackName, data)];
  if (data is! Map) throw ImportFormatException(l10n.unknownJsonLayout);
  // Spotify data export: Playlist1.json
  final playlists = data['playlists'];
  if (playlists is List) {
    return [
      for (final pl in playlists.whereType<Map>())
        list('${pl['name'] ?? fallbackName}', (pl['items'] ?? pl['tracks'] ?? const []) as List),
    ];
  }
  final tracks = data['tracks'] ?? data['items'] ?? data['songs'];
  if (tracks is List) return [list('${data['name'] ?? data['title'] ?? fallbackName}', tracks)];
  if (tracks is Map && tracks['items'] is List) {
    return [list('${data['name'] ?? fallbackName}', tracks['items'] as List)];
  }
  throw ImportFormatException(l10n.couldNotFindASongList);
}

ExternalTrack? _jsonTrack(Object? raw) {
  if (raw is! Map) return null;
  // Unwrap {track: {...}} / {item: {...}} (Spotify API + data export shapes).
  final inner = raw['track'] is Map ? raw['track'] as Map : (raw['item'] is Map ? raw['item'] as Map : raw);
  String s(List<String> keys) {
    for (final k in keys) {
      final v = inner[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is Map && v['name'] is String) return (v['name'] as String).trim();
    }
    return '';
  }

  final title = s(['title', 'name', 'trackName', 'track', 'song']);
  if (title.isEmpty) return null;
  final artistsRaw = inner['artists'];
  final artists = artistsRaw is List
      ? [
          for (final a in artistsRaw)
            if (a is Map) '${a['name'] ?? ''}'.trim() else '$a'.trim(),
        ].where((a) => a.isNotEmpty).toList()
      : splitArtists(s(['artist', 'artistName', 'artists', 'artist_name', 'uploader']));
  final dur = inner['durationMs'] ?? inner['duration_ms'] ?? inner['msPlayed'];
  final durS = inner['duration'] ?? inner['length'];
  final uri = s(['uri', 'trackUri', 'url', 'link', 'spotify_uri']);
  final spotifyId = RegExp(r'(?:spotify:track:|open\.spotify\.com/track/)([A-Za-z0-9]+)').firstMatch(uri)?[1];
  return ExternalTrack(
    service: spotifyId != null ? OnlineService.spotify : OnlineService.file,
    title: title,
    artists: artists,
    album: _albumOf(inner, s(['album', 'albumName', 'album_name'])),
    durationMs: dur is num
        ? dur.toInt()
        : (durS is num ? parseDurationText('$durS') : parseDurationText(durS is String ? durS : '')),
    isrc: s(['isrc']).isEmpty ? null : s(['isrc']),
    externalId: spotifyId,
    url: uri.startsWith('http') ? uri : (spotifyId != null ? 'https://open.spotify.com/track/$spotifyId' : null),
  );
}

// ------------------------------------------------------------------- M3U

final _extinf = RegExp(r'^#EXTINF:\s*(-?\d+(?:\.\d+)?)[^,]*,(.*)$');

/// Extended M3U. File entries keep their path in [ExternalTrack.url] so the
/// matcher can find the exact file first.
ImportedList parseM3u(String text, {required String fallbackName, String? path}) {
  var name = fallbackName;
  final tracks = <ExternalTrack>[];
  int? pendingDuration;
  String? pendingTitle;
  for (final raw in const LineSplitter().convert(text)) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('#PLAYLIST:')) {
      name = line.substring(10).trim();
      continue;
    }
    final inf = _extinf.firstMatch(line);
    if (inf != null) {
      final secs = double.tryParse(inf[1]!) ?? -1;
      pendingDuration = secs > 0 ? (secs * 1000).round() : 0;
      pendingTitle = inf[2]!.trim();
      continue;
    }
    if (line.startsWith('#')) continue;
    // Location line.
    final location = line;
    var title = pendingTitle ?? '';
    var artists = <String>[];
    if (title.isEmpty) {
      final file = Uri.tryParse(location)?.pathSegments.lastOrNull ?? location;
      title = p.basenameWithoutExtension(Uri.decodeComponent(file.replaceAll('\\', '/').split('/').last));
    }
    final dash = RegExp(r'\s+[-–—]\s+').firstMatch(title);
    if (dash != null) {
      artists = splitArtists(title.substring(0, dash.start));
      title = title.substring(dash.end);
    }
    tracks.add(
      ExternalTrack(
        service: OnlineService.file,
        title: title,
        artists: artists,
        durationMs: pendingDuration ?? 0,
        url: _resolveLocation(location, path),
      ),
    );
    pendingTitle = null;
    pendingDuration = null;
  }
  return ImportedList(name: name, origin: OnlineService.file, tracks: tracks, sourceUrl: path);
}

/// Relative paths in an M3U are relative to the playlist file.
String _resolveLocation(String location, String? playlistPath) {
  if (location.contains('://')) return location;
  if (p.isAbsolute(location) || playlistPath == null || !p.isAbsolute(playlistPath)) return location;
  return p.normalize(p.join(p.dirname(playlistPath), location));
}

/// `albums: [{title: …}]`, as Yandex Music exports have it.
String _albumOf(Map<dynamic, dynamic> inner, String found) {
  if (found.isNotEmpty) return found;
  final albums = inner['albums'];
  if (albums is List && albums.isNotEmpty && albums.first is Map) return '${(albums.first as Map)['title'] ?? ''}'.trim();
  return '';
}

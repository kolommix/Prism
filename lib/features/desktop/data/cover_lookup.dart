import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../library/data/search_text.dart';
import '../../library/domain/track.dart';
import '../../online/domain/external_track.dart';
import '../../online/domain/matching.dart';
import '../../../l10n/l10n.dart';

/// What the public catalogues know about a song, for the Discord status.
class CoverInfo {
  CoverInfo({
    this.coverUrl,
    this.title,
    this.artist,
    this.album,
    this.linkUrl,
    String? linkLabel,
    this.genre,
    this.year,
  }) : linkLabel = linkLabel ?? l10n.open;
  final String? coverUrl;
  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? year;
  final String? linkUrl;
  final String linkLabel;
}

/// `19_Sunset_of_Seven_Suns.mp3` → `Sunset of Seven Suns`. File names used as
/// titles shouldn't reach a public profile as they are.
String cleanSongTitle(String title) {
  var s = title.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  s = s.replaceFirst(RegExp(r'\.(mp3|flac|m4a|ogg|wav)$', caseSensitive: false), '');
  final noNumber = s.replaceFirst(RegExp(r'^\d{1,3}[\s.\-]+'), '');
  return noNumber.length >= 2 ? noNumber : s;
}

Set<String> _words(String s) =>
    normalizeForSearch(s).split(RegExp(r'[^\p{L}\p{N}]+', unicode: true)).where((w) => w.isNotEmpty).toSet();

/// For a song without tags all we have is its file name, so a guess must not
/// put a wrong artist on someone's profile. A result counts only when the file
/// name holds its whole title and artist ("Black Knife" by "Toby Fox" in
/// `Black_Knife_DELTARUNE_Soundtrack_Toby_Fox`), or when the name is exactly its
/// title. Either way the length has to fit: other versions usually differ.
bool fileNameMatches(String fileTitle, int durationMs, Track candidate) {
  if (durationMs > 0 && candidate.durationMs > 0 && (durationMs - candidate.durationMs).abs() > 6000) return false;
  final name = _words(fileTitle);
  final title = _words(candidate.title);
  if (title.isEmpty) return false;
  if (name.length == title.length && name.containsAll(title)) return true;
  final artist = _words(candidate.artist);
  return artist.isNotEmpty && name.containsAll(title) && name.containsAll(artist);
}

/// The first words of a long file name: catalogues find "Black Knife Deltarune"
/// where "… Chapter 3+4 Soundtrack Toby Fox" gives nothing.
String shortQuery(String title, {int words = 4}) =>
    title.split(RegExp(r'[^\p{L}\p{N}]+', unicode: true)).where((w) => w.isNotEmpty).take(words).join(' ');

/// Parses an iTunes Search API answer into candidate tracks + their info.
List<(Track, CoverInfo)> parseITunes(String body) {
  final json = jsonDecode(body);
  if (json is! Map || json['results'] is! List) return const [];
  return [
    for (final r in (json['results'] as List).whereType<Map<String, dynamic>>())
      if (r['trackName'] is String && r['artworkUrl100'] is String)
        (
          Track(
            id: 0,
            uri: '',
            title: r['trackName'] as String,
            artist: r['artistName'] as String? ?? '',
            album: r['collectionName'] as String? ?? '',
            durationMs: (r['trackTimeMillis'] as num?)?.toInt() ?? 0,
          ),
          CoverInfo(
            // The API offers 100 px; the same URL serves any size.
            coverUrl: (r['artworkUrl100'] as String).replaceFirst('100x100bb', '1200x1200bb'),
            title: r['trackName'] as String,
            artist: r['artistName'] as String?,
            album: r['collectionName'] as String?,
            linkUrl: r['trackViewUrl'] as String?,
            linkLabel: l10n.openInAppleMusic,
            genre: r['primaryGenreName'] as String?,
            year: int.tryParse(((r['releaseDate'] as String?) ?? '').split('-').first),
          ),
        ),
  ];
}

/// Parses a Deezer search answer the same way.
List<(Track, CoverInfo)> parseDeezer(String body) {
  final json = jsonDecode(body);
  if (json is! Map || json['data'] is! List) return const [];
  return [
    for (final r in (json['data'] as List).whereType<Map<String, dynamic>>())
      if (r['title'] is String && r['album'] is Map && (r['album'] as Map)['cover_big'] is String)
        (
          Track(
            id: 0,
            uri: '',
            title: r['title'] as String,
            artist: (r['artist'] as Map?)?['name'] as String? ?? '',
            album: (r['album'] as Map)['title'] as String? ?? '',
            durationMs: ((r['duration'] as num?)?.toInt() ?? 0) * 1000,
          ),
          CoverInfo(
            coverUrl: ((r['album'] as Map)['cover_xl'] ?? (r['album'] as Map)['cover_big']) as String,
            title: r['title'] as String,
            artist: (r['artist'] as Map?)?['name'] as String?,
            album: (r['album'] as Map)['title'] as String?,
            linkUrl: r['link'] as String?,
            linkLabel: l10n.openOnDeezer,
          ),
        ),
  ];
}

/// Finds album art through Apple's and Deezer's public search (no key).
/// Local covers can't go on Discord: it only shows images from a web address.
/// Only title + artist leave the PC, and only while the Discord status is on.
class CoverLookup {
  CoverLookup({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _cache = <int, CoverInfo?>{};

  static const _minScore = 0.6;

  /// The last search couldn't reach a service or was refused: no answer says
  /// nothing about the song.
  bool lastFailed = false;

  void forget(Track t) => _cache.remove(t.id);

  CoverInfo? cached(Track t) => _cache[t.id];

  /// Already looked up (found or not).
  bool isSettled(Track t) => _cache.containsKey(t.id);

  Future<CoverInfo?> find(Track t) async {
    if (_cache.containsKey(t.id)) return _cache[t.id];
    final title = cleanSongTitle(t.title);
    final hasArtist = t.artist.isNotEmpty || t.albumArtist.isNotEmpty;
    final wanted = ExternalTrack(
      service: OnlineService.file,
      title: title,
      artists: hasArtist ? [t.displayArtist] : const [],
      durationMs: t.durationMs,
    );
    final queries = {
      if (hasArtist) '${t.displayArtist} $title' else title,
      if (!hasArtist) shortQuery(title),
    };
    CoverInfo? found;
    var answered = false, failed = false;
    search:
    for (final query in queries) {
      for (final source in [_itunes, _deezer]) {
        try {
          found = _best(wanted, await source(query));
          answered = true;
        } on Object {
          failed = true;
          continue; // offline or the service is down: no cover, no problem
        }
        if (found != null) break search;
      }
    }
    lastFailed = found == null && failed && !answered;
    _cache[t.id] = found;
    return found;
  }

  CoverInfo? _best(ExternalTrack wanted, List<(Track, CoverInfo)> results) {
    if (results.isEmpty) return null;
    if (wanted.artists.isEmpty) {
      for (final r in results) {
        if (fileNameMatches(wanted.title, wanted.durationMs, r.$1)) return r.$2;
      }
      return null;
    }
    final best = MatchScorer.best(wanted, [for (final r in results) r.$1]);
    if (best == null || best.score.value < _minScore) return null;
    return results.firstWhere((r) => identical(r.$1, best.track)).$2;
  }

  Future<List<(Track, CoverInfo)>> _itunes(String q) async {
    final uri = Uri.https('itunes.apple.com', '/search', {'term': q, 'entity': 'song', 'limit': '8'});
    final res = await _client.get(uri).timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) throw http.ClientException('Apple: ${res.statusCode}');
    return parseITunes(utf8.decode(res.bodyBytes));
  }

  Future<List<(Track, CoverInfo)>> _deezer(String q) async {
    final uri = Uri.https('api.deezer.com', '/search', {'q': q, 'limit': '8'});
    final res = await _client.get(uri).timeout(const Duration(seconds: 6));
    if (res.statusCode != 200) throw http.ClientException(l10n.deezer(res.statusCode));
    return parseDeezer(utf8.decode(res.bodyBytes));
  }

  void close() => _client.close();
}

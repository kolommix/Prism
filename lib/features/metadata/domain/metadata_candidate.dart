import 'dart:convert';

import '../../library/domain/track.dart';
import '../../online/domain/external_track.dart';
import '../../online/domain/matching.dart';

/// What a catalogue says about a song.
class MetaCandidate {
  const MetaCandidate({
    required this.source,
    required this.title,
    this.artist = '',
    this.album = '',
    this.year,
    this.trackNumber,
    this.genre,
    this.durationMs = 0,
    this.coverUrls = const [],
    this.releaseId,
    this.score = 0,
  });

  /// `MusicBrainz`, `iTunes`, `AcoustID`.
  final String source;
  final String title;
  final String artist;
  final String album;
  final int? year;
  final int? trackNumber;
  final String? genre;
  final int durationMs;

  /// Where a cover might be, best first (some may not exist).
  final List<String> coverUrls;
  final String? releaseId;

  /// 0..1, how likely this is the song.
  final double score;

  MetaCandidate withScore(double s) => MetaCandidate(
        source: source,
        title: title,
        artist: artist,
        album: album,
        year: year,
        trackNumber: trackNumber,
        genre: genre,
        durationMs: durationMs,
        coverUrls: coverUrls,
        releaseId: releaseId,
        score: s,
      );
}

/// The fields the fixer can change.
enum MetaField { title, artist, album, year, track, genre, cover }

/// Query for MusicBrainz's search: Lucene syntax, so its special characters
/// have to be escaped.
String musicBrainzQuery(String title, String artist) {
  String esc(String s) => s.replaceAllMapped(RegExp(r'[+\-!(){}\[\]^"~*?:\\/&|]'), (m) => '\\${m[0]}');
  final t = esc(cleanTitle(title).isEmpty ? title : cleanTitle(title));
  final parts = ['recording:"$t"', if (artist.trim().isNotEmpty) 'artist:"${esc(artist.trim())}"'];
  return parts.join(' AND ');
}

/// Parses a MusicBrainz `recording` search answer.
List<MetaCandidate> parseMusicBrainz(String body) {
  final json = jsonDecode(body);
  if (json is! Map || json['recordings'] is! List) return const [];
  final out = <MetaCandidate>[];
  for (final r in (json['recordings'] as List).whereType<Map<String, dynamic>>()) {
    final title = r['title'] as String?;
    if (title == null) continue;
    final artist = [
      for (final c in (r['artist-credit'] as List? ?? const []).whereType<Map<String, dynamic>>())
        '${c['name'] ?? (c['artist'] as Map?)?['name'] ?? ''}${c['joinphrase'] ?? ''}',
    ].join();
    final tags = (r['tags'] as List? ?? const []).whereType<Map<String, dynamic>>().toList()
      ..sort((a, b) => ((b['count'] as num?) ?? 0).compareTo((a['count'] as num?) ?? 0));
    final genre = tags.isEmpty ? null : tags.first['name'] as String?;
    final releases = (r['releases'] as List? ?? const []).whereType<Map<String, dynamic>>().toList()..sort(_betterRelease);
    final length = (r['length'] as num?)?.toInt() ?? 0;
    if (releases.isEmpty) {
      out.add(MetaCandidate(source: 'MusicBrainz', title: title, artist: artist, genre: genre, durationMs: length));
      continue;
    }
    // A song is on many releases: offer the first few different albums.
    final seen = <String>{};
    for (final rel in releases) {
      final album = rel['title'] as String? ?? '';
      if (!seen.add(album.toLowerCase())) continue;
      if (seen.length > 3) break;
      final id = rel['id'] as String?;
      final group = (rel['release-group'] as Map?)?['id'] as String?;
      out.add(MetaCandidate(
        source: 'MusicBrainz',
        title: title,
        artist: artist,
        album: album,
        year: int.tryParse(((rel['date'] as String?) ?? '').split('-').first),
        trackNumber: _trackNumber(rel),
        genre: genre,
        durationMs: length,
        releaseId: id,
        coverUrls: [
          if (id != null) 'https://coverartarchive.org/release/$id/front-500',
          if (group != null) 'https://coverartarchive.org/release-group/$group/front-500',
        ],
      ));
    }
  }
  return out;
}

int? _trackNumber(Map<String, dynamic> release) {
  for (final m in (release['media'] as List? ?? const []).whereType<Map<String, dynamic>>()) {
    for (final t in (m['track'] as List? ?? const []).whereType<Map<String, dynamic>>()) {
      final n = int.tryParse('${t['number'] ?? ''}');
      if (n != null) return n;
    }
  }
  return null;
}

/// Official albums first, then the earliest.
int _betterRelease(Map<String, dynamic> a, Map<String, dynamic> b) {
  int rank(Map<String, dynamic> r) {
    final official = r['status'] == 'Official' ? 0 : 2;
    final type = (r['release-group'] as Map?)?['primary-type'];
    return official + (type == 'Album' ? 0 : 1);
  }

  final byRank = rank(a).compareTo(rank(b));
  if (byRank != 0) return byRank;
  final da = (a['date'] as String?) ?? '9999', db = (b['date'] as String?) ?? '9999';
  return da.compareTo(db);
}

/// Parses an AcoustID lookup answer (`meta=recordings+releasegroups`). Its score
/// is how sure the audio fingerprint is.
List<MetaCandidate> parseAcoustId(String body) {
  final json = jsonDecode(body);
  if (json is! Map || json['results'] is! List) return const [];
  final out = <MetaCandidate>[];
  for (final res in (json['results'] as List).whereType<Map<String, dynamic>>()) {
    final score = (res['score'] as num?)?.toDouble() ?? 0;
    for (final rec in (res['recordings'] as List? ?? const []).whereType<Map<String, dynamic>>()) {
      final title = rec['title'] as String?;
      if (title == null) continue;
      final artist = [
        for (final a in (rec['artists'] as List? ?? const []).whereType<Map<String, dynamic>>()) a['name'] ?? '',
      ].join(', ');
      final groups = (rec['releasegroups'] as List? ?? const []).whereType<Map<String, dynamic>>().toList();
      final g = groups.firstWhere((x) => x['type'] == 'Album', orElse: () => groups.isEmpty ? const {} : groups.first);
      final gid = g['id'] as String?;
      out.add(MetaCandidate(
        source: 'AcoustID',
        title: title,
        artist: artist,
        album: g['title'] as String? ?? '',
        durationMs: (((rec['duration'] as num?) ?? 0) * 1000).toInt(),
        coverUrls: [if (gid != null) 'https://coverartarchive.org/release-group/$gid/front-500'],
        score: score,
      ));
    }
  }
  return out;
}

/// How likely [c] is the song in [t], using the same scorer as playlist
/// imports. When the file has no artist the file name has to carry the match.
double scoreCandidate(Track t, MetaCandidate c) {
  final wanted = ExternalTrack(
    service: OnlineService.file,
    title: t.title,
    artists: t.artist.isEmpty ? const [] : [t.artist],
    album: t.album,
    durationMs: t.durationMs,
  );
  final candidate = Track(id: 0, uri: '', title: c.title, artist: c.artist, album: c.album, durationMs: c.durationMs);
  final s = MatchScorer.score(wanted, candidate).value;
  if (t.artist.isNotEmpty) return s;
  // No artist to compare: the artist named in the file name counts.
  final name = t.title.toLowerCase();
  return c.artist.isNotEmpty && name.contains(c.artist.toLowerCase()) ? (s + 0.2).clamp(0.0, 1.0) : s;
}

/// Scored and sorted, fingerprint matches keeping their own score.
List<MetaCandidate> rankCandidates(Track t, Iterable<MetaCandidate> all) {
  final out = [
    for (final c in all) c.source == 'AcoustID' ? c : c.withScore(scoreCandidate(t, c)),
  ]..sort(_byScoreThenDetail);
  return out;
}

/// Equal scores are common for a well-known song on many releases: the one with
/// more info wins, then the earliest (the original, not a later best-of).
int _byScoreThenDetail(MetaCandidate a, MetaCandidate b) {
  final byScore = b.score.compareTo(a.score);
  if (byScore != 0) return byScore;
  int detail(MetaCandidate c) =>
      (c.album.isNotEmpty ? 1 : 0) + (c.year != null ? 1 : 0) + (c.coverUrls.isNotEmpty ? 1 : 0) + (c.genre != null ? 1 : 0);
  final byDetail = detail(b).compareTo(detail(a));
  if (byDetail != 0) return byDetail;
  return (a.year ?? 9999).compareTo(b.year ?? 9999);
}

/// When fixing an album, a release most songs agree on should win: a song found
/// on the album and on a best-of then ends up on the album like its neighbours.
List<List<MetaCandidate>> preferCommonAlbum(List<List<MetaCandidate>> perTrack, {double bonus = 0.08}) {
  final votes = <String, int>{};
  for (final list in perTrack) {
    final albums = <String>{};
    for (final c in list.where((c) => c.score >= MatchScorer.acceptThreshold && c.album.isNotEmpty)) {
      albums.add(c.album.toLowerCase());
    }
    for (final a in albums) {
      votes[a] = (votes[a] ?? 0) + 1;
    }
  }
  if (votes.isEmpty) return perTrack;
  final top = votes.entries.reduce((a, b) => b.value > a.value ? b : a);
  if (top.value < 2) return perTrack;
  return [
    for (final list in perTrack)
      ([
        for (final c in list) c.album.toLowerCase() == top.key ? c.withScore((c.score + bonus).clamp(0.0, 1.0)) : c,
      ]..sort(_byScoreThenDetail)),
  ];
}

/// One row of the side-by-side view.
class MetaDiff {
  const MetaDiff(this.field, this.current, this.proposed);
  final MetaField field;
  final String current;
  final String proposed;
  bool get changes => proposed.isNotEmpty && proposed != current;
}

/// Current values next to [c]'s, without the cover.
List<MetaDiff> diffOf(Track t, MetaCandidate c) => [
      MetaDiff(MetaField.title, t.title, c.title),
      MetaDiff(MetaField.artist, t.artist, c.artist),
      MetaDiff(MetaField.album, t.album, c.album),
      MetaDiff(MetaField.year, t.year?.toString() ?? '', c.year?.toString() ?? ''),
      MetaDiff(MetaField.track, t.trackNumber?.toString() ?? '', c.trackNumber?.toString() ?? ''),
      MetaDiff(MetaField.genre, t.genre, c.genre ?? ''),
    ];

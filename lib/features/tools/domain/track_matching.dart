import '../../library/data/search_text.dart';
import '../../library/domain/track.dart';

/// Portable reference to a song (for backups and listen-together): works
/// across devices where the file paths differ.
class TrackRef {
  const TrackRef({required this.uri, required this.title, required this.artist, required this.durationMs});

  factory TrackRef.of(Track t) => TrackRef(uri: t.uri, title: t.title, artist: t.displayArtist, durationMs: t.durationMs);

  factory TrackRef.fromJson(Map<String, dynamic> j) => TrackRef(
        uri: j['uri'] as String? ?? '',
        title: j['title'] as String? ?? '',
        artist: j['artist'] as String? ?? '',
        durationMs: j['durationMs'] as int? ?? 0,
      );

  final String uri;
  final String title;
  final String artist;
  final int durationMs;

  Map<String, Object> toJson() => {'uri': uri, 'title': title, 'artist': artist, 'durationMs': durationMs};
}

String _key(String title, String artist) => '${normalizeForSearch(title)}|${normalizeForSearch(artist)}';

/// Finds library tracks for refs: same path first, else same title + artist
/// with a length within 3 s.
class TrackMatcher {
  TrackMatcher(Iterable<Track> library) {
    for (final t in library) {
      _byUri[t.uri] = t;
      (_byKey[_key(t.title, t.displayArtist)] ??= []).add(t);
    }
  }

  final _byUri = <String, Track>{};
  final _byKey = <String, List<Track>>{};

  Track? match(TrackRef r) {
    final exact = _byUri[r.uri];
    if (exact != null) return exact;
    final candidates = _byKey[_key(r.title, r.artist)];
    if (candidates == null) return null;
    Track? best;
    var bestDiff = 1 << 30;
    for (final c in candidates) {
      final diff = (c.durationMs - r.durationMs).abs();
      if (r.durationMs == 0 || c.durationMs == 0 || diff <= 3000) {
        if (diff < bestDiff) {
          best = c;
          bestDiff = diff;
        }
      }
    }
    return best;
  }
}

/// Groups of tracks that are probably the same song (same normalised title
/// and artist, length within 2 s). Each group has ≥ 2 tracks; groups are
/// sorted by title, tracks inside by file path.
List<List<Track>> findDuplicates(Iterable<Track> tracks) {
  final byKey = <String, List<Track>>{};
  for (final t in tracks) {
    if (normalizeForSearch(t.title).isEmpty) continue;
    (byKey[_key(t.title, t.displayArtist)] ??= []).add(t);
  }
  final groups = <List<Track>>[];
  for (final list in byKey.values) {
    if (list.length < 2) continue;
    // Split by duration so different versions (live, extended) stay apart.
    list.sort((a, b) => a.durationMs.compareTo(b.durationMs));
    var current = <Track>[list.first];
    for (final t in list.skip(1)) {
      if ((t.durationMs - current.last.durationMs).abs() <= 2000) {
        current.add(t);
      } else {
        if (current.length > 1) groups.add(current);
        current = [t];
      }
    }
    if (current.length > 1) groups.add(current);
  }
  for (final g in groups) {
    g.sort((a, b) => a.uri.compareTo(b.uri));
  }
  groups.sort((a, b) => a.first.title.toLowerCase().compareTo(b.first.title.toLowerCase()));
  return groups;
}

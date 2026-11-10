import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../library/data/search_text.dart';
import '../../online/domain/matching.dart' show cleanTitle;
import '../../library/domain/track.dart';

/// Portable reference to a song (for backups and listen-together): works
/// across devices where the file paths differ.
class TrackRef {
  const TrackRef({required this.uri, required this.title, required this.artist, required this.durationMs});

  factory TrackRef.of(Track t) => TrackRef(uri: t.uri, title: t.title, artist: t.displayArtist, durationMs: t.durationMs);

  /// For other people (listen together): a local file goes as a fingerprint
  /// of its path, never the path itself (it holds the user name and folders,
  /// and the default link is a public server). The same file on the same PC
  /// still matches exactly; online songs keep their id.
  factory TrackRef.shared(Track t) =>
      TrackRef(uri: sharedUri(t), title: t.title, artist: t.displayArtist, durationMs: t.durationMs);

  static String sharedUri(Track t) =>
      t.sourceId == 'local' ? 'h:${sha256.convert(utf8.encode(t.uri)).toString().substring(0, 32)}' : t.uri;

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
      _byUri[TrackRef.sharedUri(t)] = t;
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

/// What a song is, for spotting copies: its cleaned title (no "(Official
/// Video)", "feat. …", "_" for spaces) and its artist. Files from the web
/// often have no artist tag and "Artist - Title" as the title: that is split.
(String, String) _identity(Track t) {
  var title = t.title.replaceAll('_', ' ');
  var artist = (t.artist.isNotEmpty ? t.artist : t.albumArtist).trim();
  final dash = RegExp(r'\s[-–—]\s').firstMatch(title);
  if (dash != null) {
    final left = title.substring(0, dash.start).trim();
    if (left.isNotEmpty && (artist.isEmpty || _sameArtist(left, artist))) {
      if (artist.isEmpty) artist = left;
      title = title.substring(dash.end);
    }
  }
  return (cleanTitle(title).replaceAll(' ', ''), artist);
}

final _artistSplit = RegExp(r'\s*(?:,|&|/|;|\bx\b|\bfeat\.?|\bft\.?|\band\b|\sи\s)\s*');

/// Same artist, or one of several names in common ("VILLIAN, madk1d" and
/// "madk1d"). An unknown artist fits anyone: then title and length decide.
bool _sameArtist(String a, String b) {
  if (a.isEmpty || b.isEmpty) return true;
  Set<String> names(String s) => {
        for (final n in s.toLowerCase().split(_artistSplit))
          if (normalizeForSearch(n).isNotEmpty) normalizeForSearch(n),
      };
  final x = names(a), y = names(b);
  return x.intersection(y).isNotEmpty;
}

/// Groups of tracks that are probably the same recording: same cleaned title,
/// fitting artists, length within 3 s (so live / extended versions stay
/// apart, and so do songs whose length is unknown). Each group has ≥ 2
/// tracks; groups are sorted by title, tracks inside by file path.
List<List<Track>> findDuplicates(Iterable<Track> tracks) {
  final byTitle = <String, List<(Track, String)>>{};
  for (final t in tracks) {
    if (t.durationMs <= 0) continue;
    final (core, artist) = _identity(t);
    if (core.isEmpty) continue;
    (byTitle[core] ??= []).add((t, artist));
  }
  final groups = <List<Track>>[];
  for (final list in byTitle.values) {
    if (list.length < 2) continue;
    // Joins copies that fit each other (union-find over the few with this
    // title). Known artists first; a copy without an artist then joins the
    // one group it fits, so it never ties two different artists together.
    final parent = List<int>.generate(list.length, (i) => i);
    int root(int i) => parent[i] == i ? i : parent[i] = root(parent[i]);
    bool close(int i, int j) => (list[i].$1.durationMs - list[j].$1.durationMs).abs() <= 3000;
    final known = [for (var i = 0; i < list.length; i++) if (list[i].$2.isNotEmpty) i];
    final unknown = [for (var i = 0; i < list.length; i++) if (list[i].$2.isEmpty) i];
    for (final i in known) {
      for (final j in known) {
        if (i < j && close(i, j) && _sameArtist(list[i].$2, list[j].$2)) parent[root(i)] = root(j);
      }
    }
    for (final i in unknown) {
      final fits = {for (final j in known) if (close(i, j)) root(j)};
      if (fits.length == 1) parent[root(i)] = fits.single;
    }
    for (final i in unknown) {
      for (final j in unknown) {
        // Two copies without an artist, unless one already went to an artist's group.
        if (i < j && close(i, j) && (root(i) == i || root(j) == j)) parent[root(i)] = root(j);
      }
    }
    final sets = <int, List<Track>>{};
    for (var i = 0; i < list.length; i++) {
      (sets[root(i)] ??= []).add(list[i].$1);
    }
    groups.addAll(sets.values.where((g) => g.length > 1));
  }
  for (final g in groups) {
    g.sort((a, b) => a.uri.compareTo(b.uri));
  }
  groups.sort((a, b) => a.first.title.toLowerCase().compareTo(b.first.title.toLowerCase()));
  return groups;
}

const _lossless = {'.flac', '.wav', '.alac', '.aiff', '.ape', '.wv'};

/// How good a copy is to keep: lossless first, then the higher bitrate (file
/// size per second), then the one with a cover and real tags.
double keepScore(Track t, int bytes) {
  final ext = t.uri.contains('.') ? t.uri.substring(t.uri.lastIndexOf('.')).toLowerCase() : '';
  final kbps = t.durationMs > 0 ? bytes * 8 / t.durationMs : 0.0;
  var score = kbps.clamp(0, 2000).toDouble();
  if (_lossless.contains(ext)) score += 10000;
  if (t.artworkPath != null) score += 40;
  if (t.artist.isNotEmpty) score += 20;
  if (t.album.isNotEmpty) score += 10;
  return score;
}

/// The copy Prism keeps when nobody picked one.
Track bestCopy(List<Track> group, int Function(Track) sizeOf) {
  var best = group.first;
  var bestScore = keepScore(best, sizeOf(best));
  for (final t in group.skip(1)) {
    final s = keepScore(t, sizeOf(t));
    if (s > bestScore) {
      best = t;
      bestScore = s;
    }
  }
  return best;
}

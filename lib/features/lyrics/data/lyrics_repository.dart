import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../core/db/app_database.dart';
import '../../library/domain/track.dart';
import '../../online/domain/external_track.dart';
import '../../online/domain/matching.dart';
import '../../online/domain/song_identity.dart';
import '../domain/lrc.dart';

/// Result of an LRCLIB lookup.
sealed class LrclibResult {
  const LrclibResult();
}

class LrclibFound extends LrclibResult {
  const LrclibFound({this.synced, this.plain});
  final String? synced;
  final String? plain;
}

/// The service answered "no lyrics" – safe to cache.
class LrclibNotFound extends LrclibResult {
  const LrclibNotFound();
}

/// Network/server problem – do not cache, try again later.
class LrclibUnavailable extends LrclibResult {
  const LrclibUnavailable(this.reason);
  final String reason;
}

/// What to ask LRCLIB for (see [songAsNamed]).
ExternalTrack lyricsWanted(Track t) => songAsNamed(t);

/// Minimal client for https://lrclib.net (free, no key). Sends only title,
/// artist, album and duration.
class LrclibClient {
  LrclibClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _base = 'https://lrclib.net/api';
  static const _headers = {'User-Agent': 'Prism music player (personal project; github.com/kolommix)'};

  /// Below this a search result is someone else's song.
  static const _accept = 0.7;

  Future<LrclibResult> lookup(Track t) async {
    final want = lyricsWanted(t);
    final title = cleanTitleText(want.title);
    if (title.isEmpty) return const LrclibNotFound();
    final artist = want.artists.isEmpty ? '' : want.artists.first;
    try {
      // 1) Exact match (title + artist + album + duration ±2 s on their side).
      if (artist.isNotEmpty && t.durationMs > 0) {
        final get = Uri.parse('$_base/get').replace(queryParameters: {
          'track_name': want.title,
          'artist_name': artist,
          if (want.album.isNotEmpty) 'album_name': want.album,
          'duration': '${(t.durationMs / 1000).round()}',
        });
        final r = await _client.get(get, headers: _headers).timeout(const Duration(seconds: 8));
        if (r.statusCode == 200) {
          final found = _parse(jsonDecode(r.body) as Map<String, dynamic>);
          if (found is LrclibFound) return found;
        }
        // The service is down: try again another time, don't hammer it.
        if (r.statusCode >= 500) return LrclibUnavailable('HTTP ${r.statusCode}');
      }

      // 2) Searches, from the most to the least precise; every answer is
      // scored like an import match (title, artist, length), the best wins.
      final queries = <Map<String, String>>[
        if (artist.isNotEmpty) {'track_name': title, 'artist_name': artist},
        {'q': '$artist $title'.trim()},
        if (artist.isNotEmpty) {'track_name': title},
      ];
      final seen = <Object?>{};
      Map<String, dynamic>? best;
      var bestScore = 0.0;
      for (final q in queries) {
        final s = await _client
            .get(Uri.parse('$_base/search').replace(queryParameters: q), headers: _headers)
            .timeout(const Duration(seconds: 8));
        if (s.statusCode >= 500) return LrclibUnavailable('HTTP ${s.statusCode}');
        if (s.statusCode != 200) continue;
        for (final m in (jsonDecode(s.body) as List).whereType<Map<String, dynamic>>()) {
          if (!seen.add(m['id'] ?? '${m['trackName']}|${m['artistName']}|${m['duration']}')) continue;
          final score = lyricsCandidateScore(want, m);
          if (score > bestScore) {
            bestScore = score;
            best = m;
          }
        }
        // A sure match with timed lyrics: no need to ask more.
        if (best != null && bestScore >= 0.9 && best['syncedLyrics'] != null) break;
      }
      if (best != null && bestScore >= _accept) {
        if (best['instrumental'] == true) return const LrclibNotFound();
        return _parse(best);
      }
      return const LrclibNotFound();
    } on Exception catch (e) {
      return LrclibUnavailable('$e');
    }
  }

  static LrclibResult _parse(Map<String, dynamic> m) {
    final synced = m['syncedLyrics'] as String?;
    final plain = m['plainLyrics'] as String?;
    if ((synced == null || synced.trim().isEmpty) && (plain == null || plain.trim().isEmpty)) {
      return const LrclibNotFound();
    }
    return LrclibFound(synced: synced, plain: plain);
  }
}

/// How well one LRCLIB search answer fits [want] (0..1.04): the import matcher's
/// score, a small plus for timed lyrics, nothing for an empty entry, and a
/// different length (another version, timing would be off) pushed down.
double lyricsCandidateScore(ExternalTrack want, Map<String, dynamic> m) {
  final synced = (m['syncedLyrics'] as String?)?.trim() ?? '';
  final plain = (m['plainLyrics'] as String?)?.trim() ?? '';
  if (synced.isEmpty && plain.isEmpty && m['instrumental'] != true) return 0;
  final durMs = (((m['duration'] as num?)?.toDouble() ?? 0) * 1000).round();
  final candidate = Track(
    id: 0,
    uri: '',
    title: '${m['trackName'] ?? m['name'] ?? ''}',
    artist: '${m['artistName'] ?? ''}',
    album: '${m['albumName'] ?? ''}',
    durationMs: durMs,
  );
  var score = MatchScorer.score(want, candidate).value;
  if (want.durationMs > 0 && durMs > 0) {
    final diff = (want.durationMs - durMs).abs();
    if (diff > 15000) {
      score *= 0.5;
    } else if (diff > 8000) {
      score *= 0.85;
    }
  }
  // Timed lyrics win a tie (so the score can pass 1).
  return score.clamp(0, 1).toDouble() + (synced.isNotEmpty ? 0.04 : 0);
}

/// Finds lyrics for a track, in this order:
/// 1. cache (`lyrics_cache` table),
/// 2. a `.lrc` file next to the audio file (same name),
/// 3. lyrics embedded in the file's tags,
/// 4. LRCLIB (only when [online] is true).
/// "Nothing found" is cached for a week so we don't hammer the service.
class LyricsRepository {
  LyricsRepository(this._db, {LrclibClient? lrclib}) : _lrclib = lrclib ?? LrclibClient();

  final AppDatabase _db;
  final LrclibClient _lrclib;

  static const _retryNone = Duration(days: 7);

  /// "Nothing found" by the current way of looking. Older "none" rows
  /// ('none', from the simpler lookup) are asked again once.
  static const _none = 'none2';
  static bool _isNone(String source) => source == 'none' || source == _none;

  Future<Lyrics?> lyricsFor(Track t, {required bool online}) async {
    final cached = await (_db.select(_db.lyricsCache)..where((c) => c.trackId.equals(t.id))).getSingleOrNull();
    if (cached != null) {
      if (!_isNone(cached.source)) return _build(cached.synced, cached.plain, cached.source);
      if (!online) return null;
      if (cached.source == _none && DateTime.now().difference(cached.fetchedAt) < _retryNone) return null;
    }

    final local = await _fromLocal(t);
    if (local != null) return _store(t.id, local.$1, local.$2, local.$3);

    if (!online) return null;
    switch (await _lrclib.lookup(t)) {
      case LrclibFound(:final synced, :final plain):
        return _store(t.id, synced, plain, 'lrclib');
      case LrclibNotFound():
        await _save(t.id, null, null, _none);
        return null;
      case LrclibUnavailable():
        return null; // try again next time
    }
  }

  /// Timing fix saved for this song (0 = none).
  Future<int> offsetMs(int trackId) async =>
      (await (_db.select(_db.lyricsCache)..where((c) => c.trackId.equals(trackId))).getSingleOrNull())?.offsetMs ?? 0;

  Future<void> setOffset(int trackId, int ms) =>
      (_db.update(_db.lyricsCache)..where((c) => c.trackId.equals(trackId))).write(LyricsCacheCompanion(offsetMs: Value(ms)));

  /// Forget cached lyrics (e.g. after the user added an .lrc file).
  Future<void> clear(int trackId) => (_db.delete(_db.lyricsCache)..where((c) => c.trackId.equals(trackId))).go();

  Future<(String?, String?, String)?> _fromLocal(Track t) async {
    if (t.sourceId != 'local') return null;
    final lrc = File(p.setExtension(t.uri, '.lrc'));
    if (await lrc.exists()) {
      final text = await lrc.readAsString().catchError((_) => '');
      if (text.trim().isNotEmpty) {
        return parseLrc(text).isNotEmpty ? (text, null, 'lrc-file') : (null, text, 'lrc-file');
      }
    }
    try {
      // Off the UI thread: reading tags is blocking file IO, and for some MP3s
      // it scans the whole file (measured: ~0.5 s UI freeze on each new song).
      final path = t.uri;
      final text = await Isolate.run(() => readMetadata(File(path)).lyrics);
      if (text != null && text.trim().isNotEmpty) {
        return parseLrc(text).isNotEmpty ? (text, null, 'embedded') : (null, text, 'embedded');
      }
    } catch (_) {
      // Unreadable tags: just no embedded lyrics.
    }
    return null;
  }

  Future<Lyrics?> _store(int id, String? synced, String? plain, String source) async {
    await _save(id, synced, plain, source);
    return _build(synced, plain, source);
  }

  Future<void> _save(int id, String? synced, String? plain, String source) =>
      _db.into(_db.lyricsCache).insertOnConflictUpdate(LyricsCacheCompanion.insert(
            trackId: Value(id),
            synced: Value(synced),
            plain: Value(plain),
            source: source,
            fetchedAt: Value(DateTime.now()),
          ));

  static Lyrics? _build(String? synced, String? plain, String source) {
    final lines = synced == null ? const <LyricLine>[] : parseLrc(synced);
    final l = Lyrics(lines: lines, plain: plain ?? (lines.isEmpty ? synced : null), source: source);
    return l.isEmpty ? null : l;
  }
}

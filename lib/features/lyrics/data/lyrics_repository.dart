import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../core/db/app_database.dart';
import '../../library/domain/track.dart';
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

/// Minimal client for https://lrclib.net (free, no key). Sends only title,
/// artist, album and duration.
class LrclibClient {
  LrclibClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _base = 'https://lrclib.net/api';
  static const _headers = {'User-Agent': 'Prism music player (personal project; github.com/kolommix)'};

  Future<LrclibResult> lookup(Track t) async {
    try {
      // 1) Exact match (title + artist + album + duration ±2 s on their side).
      final get = Uri.parse('$_base/get').replace(queryParameters: {
        'track_name': t.title,
        'artist_name': t.displayArtist,
        if (t.album.isNotEmpty) 'album_name': t.album,
        if (t.durationMs > 0) 'duration': '${(t.durationMs / 1000).round()}',
      });
      final r = await _client.get(get, headers: _headers).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) return _parse(jsonDecode(r.body) as Map<String, dynamic>);
      if (r.statusCode >= 500) return LrclibUnavailable('HTTP ${r.statusCode}');

      // 2) Fuzzy search, pick the closest duration that has synced lyrics.
      final search = Uri.parse('$_base/search').replace(queryParameters: {
        'track_name': t.title,
        if (t.artist.isNotEmpty) 'artist_name': t.artist,
      });
      final s = await _client.get(search, headers: _headers).timeout(const Duration(seconds: 8));
      if (s.statusCode >= 500) return LrclibUnavailable('HTTP ${s.statusCode}');
      if (s.statusCode != 200) return const LrclibNotFound();
      final list = (jsonDecode(s.body) as List).cast<Map<String, dynamic>>();
      if (list.isEmpty) return const LrclibNotFound();
      final secs = t.durationMs / 1000;
      list.sort((a, b) {
        double score(Map<String, dynamic> m) {
          final d = ((m['duration'] as num?)?.toDouble() ?? 0) - secs;
          return d.abs() + (m['syncedLyrics'] == null ? 30 : 0);
        }

        return score(a).compareTo(score(b));
      });
      final best = list.first;
      final dur = (best['duration'] as num?)?.toDouble();
      if (t.durationMs > 0 && dur != null && (dur - secs).abs() > 6) return const LrclibNotFound();
      return _parse(best);
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

  Future<Lyrics?> lyricsFor(Track t, {required bool online}) async {
    final cached = await (_db.select(_db.lyricsCache)..where((c) => c.trackId.equals(t.id))).getSingleOrNull();
    if (cached != null) {
      if (cached.source != 'none') return _build(cached.synced, cached.plain, cached.source);
      if (!online || DateTime.now().difference(cached.fetchedAt) < _retryNone) return null;
    }

    final local = await _fromLocal(t);
    if (local != null) return _store(t.id, local.$1, local.$2, local.$3);

    if (!online) return null;
    switch (await _lrclib.lookup(t)) {
      case LrclibFound(:final synced, :final plain):
        return _store(t.id, synced, plain, 'lrclib');
      case LrclibNotFound():
        await _save(t.id, null, null, 'none');
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

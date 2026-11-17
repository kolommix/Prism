import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../core/app_version.dart';
import '../../desktop/data/cover_lookup.dart';
import '../../library/domain/track.dart';
import '../domain/metadata_candidate.dart';

/// MusicBrainz identifies apps by this; a generic one gets blocked. No personal
/// data: only the app's name, version and home page.
String metadataUserAgent() => 'Prism/$appVersion ( https://github.com/kolommix/Prism )';

/// A lookup service didn't answer.
class MetadataLookupException implements Exception {
  MetadataLookupException(this.service, this.detail);
  final String service;
  final String detail;
  @override
  String toString() => '$service: $detail';
}

/// Runs jobs one at a time, at least [gap] apart. MusicBrainz allows one request
/// a second per client and blocks those who don't keep to it.
class RateLimiter {
  RateLimiter(this.gap);
  final Duration gap;
  Future<void> _last = Future.value();
  DateTime _lastAt = DateTime.fromMillisecondsSinceEpoch(0);

  Future<T> run<T>(Future<T> Function() job) {
    final done = Completer<T>();
    _last = _last.then((_) async {
      final wait = gap - DateTime.now().difference(_lastAt);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      _lastAt = DateTime.now();
      try {
        done.complete(await job());
      } on Object catch (e, st) {
        done.completeError(e, st);
      }
    });
    return done.future;
  }
}

/// Searches MusicBrainz + iTunes, optionally AcoustID, and fetches covers.
class MetadataSearch {
  MetadataSearch({http.Client? client, RateLimiter? musicBrainzLimit, this.acoustIdKey = '', this.fingerprinter})
      : _client = client ?? http.Client(),
        _mb = musicBrainzLimit ?? RateLimiter(const Duration(milliseconds: 1100));

  final http.Client _client;
  final RateLimiter _mb;
  final String acoustIdKey;

  /// Makes a Chromaprint fingerprint: (seconds, fingerprint). Null = not
  /// possible on this machine.
  final Future<(int, String)?> Function(String path)? fingerprinter;

  Map<String, String> get _headers => {'User-Agent': metadataUserAgent(), 'Accept': 'application/json'};

  /// Everything found for [t] (or for what the user typed), best first. A dead
  /// service only costs its own results; if all are dead this throws.
  Future<List<MetaCandidate>> search(Track t, {String? title, String? artist}) async {
    final wantTitle = (title ?? t.title).trim();
    final wantArtist = (artist ?? t.artist).trim();
    final results = <MetaCandidate>[];
    Object? failure;
    var ok = 0;
    Future<void> guard(Future<List<MetaCandidate>> Function() f) async {
      try {
        results.addAll(await f());
        ok++;
      } on Object catch (e) {
        failure = e;
      }
    }

    await Future.wait([
      guard(() => _musicBrainz(wantTitle, wantArtist)),
      guard(() => _itunes(wantTitle, wantArtist)),
      // The US store misses many local songs: also ask the Russian one.
      if (RegExp('[Ѐ-ӿ]').hasMatch('$wantTitle $wantArtist')) guard(() => _itunes(wantTitle, wantArtist, country: 'RU')),
      guard(() => _deezer(wantTitle, wantArtist)),
      if (title == null && acoustIdKey.isNotEmpty && t.sourceId == 'local') guard(() => _acoustId(t)),
    ]);
    if (results.isEmpty && ok == 0 && failure != null) throw failure!;
    return rankCandidates(t.copyWith(title: wantTitle, artist: wantArtist), results);
  }

  Future<List<MetaCandidate>> _musicBrainz(String title, String artist) => _mb.run(() async {
        final uri = Uri.https('musicbrainz.org', '/ws/2/recording', {
          'query': musicBrainzQuery(title, artist),
          'fmt': 'json',
          'limit': '12',
        });
        var res = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
        for (var i = 1; res.statusCode == 503 && i <= 3; i++) {
          // Over their limit (or busy): back off and try again.
          await Future<void>.delayed(Duration(seconds: 2 * i));
          res = await _client.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
        }
        if (res.statusCode != 200) throw MetadataLookupException('MusicBrainz', 'HTTP ${res.statusCode}');
        return parseMusicBrainz(utf8.decode(res.bodyBytes));
      });

  /// Deezer's public search (no key): title, artist, album, length, big cover.
  Future<List<MetaCandidate>> _deezer(String title, String artist) async {
    final uri = Uri.https('api.deezer.com', '/search', {'q': '$artist $title'.trim(), 'limit': '8'});
    final res = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) throw MetadataLookupException('Deezer', 'HTTP ${res.statusCode}');
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final data = body is Map ? body['data'] : null;
    if (data is! List) return const [];
    return [
      for (final d in data.whereType<Map>())
        if (d['title'] is String)
          MetaCandidate(
            source: 'Deezer',
            title: d['title'] as String,
            artist: ((d['artist'] as Map?)?['name'] as String?) ?? '',
            album: ((d['album'] as Map?)?['title'] as String?) ?? '',
            durationMs: ((d['duration'] as num?) ?? 0).toInt() * 1000,
            coverUrls: [?((d['album'] as Map?)?['cover_xl'] as String?)],
          ),
    ];
  }

  Future<List<MetaCandidate>> _itunes(String title, String artist, {String country = 'US'}) async {
    final uri = Uri.https('itunes.apple.com', '/search', {'term': '$artist $title'.trim(), 'entity': 'song', 'limit': '8', 'country': country});
    final res = await _client.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) throw MetadataLookupException('iTunes', 'HTTP ${res.statusCode}');
    return [
      for (final (track, info) in parseITunes(utf8.decode(res.bodyBytes)))
        MetaCandidate(
          source: 'iTunes',
          title: track.title,
          artist: track.artist,
          album: track.album,
          year: info.year,
          genre: info.genre,
          durationMs: track.durationMs,
          coverUrls: [?info.coverUrl],
        ),
    ];
  }

  Future<List<MetaCandidate>> _acoustId(Track t) async {
    final make = fingerprinter;
    if (make == null) return const [];
    final fp = await make(t.uri);
    if (fp == null) return const [];
    final res = await _client
        .post(Uri.https('api.acoustid.org', '/v2/lookup'), headers: {'User-Agent': metadataUserAgent()}, body: {
      'client': acoustIdKey,
      'duration': '${fp.$1}',
      'fingerprint': fp.$2,
      'meta': 'recordings releasegroups',
    }).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) throw MetadataLookupException('AcoustID', 'HTTP ${res.statusCode}');
    return parseAcoustId(utf8.decode(res.bodyBytes));
  }

  /// First cover in [urls] that really is a picture.
  Future<Uint8List?> fetchCover(List<String> urls) async {
    for (final url in urls) {
      try {
        final res = await _client.get(Uri.parse(url), headers: {'User-Agent': metadataUserAgent()}).timeout(const Duration(seconds: 15));
        final b = res.bodyBytes;
        final jpeg = b.length > 3 && b[0] == 0xFF && b[1] == 0xD8;
        final png = b.length > 3 && b[0] == 0x89 && b[1] == 0x50;
        if (res.statusCode == 200 && (jpeg || png) && b.length < 12 * 1024 * 1024) return b;
      } on Object {
        // Try the next one.
      }
    }
    return null;
  }

  void close() => _client.close();
}

/// Chromaprint through `fpcalc.exe` next to the app or on PATH. Neither the
/// bundled FFmpeg nor FFmpegKit has Chromaprint, so without that file AcoustID
/// is simply not offered.
Future<(int, String)?> fpcalcFingerprint(String path) async {
  if (!Platform.isWindows) return null;
  final beside = p.join(p.dirname(Platform.resolvedExecutable), 'fpcalc.exe');
  final exe = File(beside).existsSync() ? beside : 'fpcalc';
  try {
    final res = await Process.run(exe, ['-json', path]);
    if (res.exitCode != 0) return null;
    final j = jsonDecode('${res.stdout}') as Map<String, dynamic>;
    final seconds = (j['duration'] as num?)?.round();
    final fp = j['fingerprint'] as String?;
    return seconds == null || fp == null ? null : (seconds, fp);
  } on Object {
    return null;
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../../l10n/l10n.dart';
import '../../library/domain/track.dart';
import '../../online/domain/external_track.dart';

/// Scheme of shared playlists: `liner://p/<data>`, no server involved. A `.liner`
/// file holds the same text.
const shareScheme = 'liner';
const shareExtension = 'liner';
const _prefix = '$shareScheme://p/';

/// A link longer than this may not survive chat apps: offer the file instead.
const shareLinkSafeLength = 8000;

/// Limits for what we accept from outside (a tiny code could unpack to gigabytes).
const _maxUnpacked = 32 * 1024 * 1024;
const _maxTracks = 50000;

class ShareFormatException implements Exception {
  ShareFormatException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Packs a playlist into a code: gzip of a small JSON, base64url. Holds only
/// what's needed to find each song. File paths stay private; a streamed song
/// keeps its public link.
String encodeSharedPlaylist(String name, Iterable<Track> tracks) {
  final rows = [
    for (final t in tracks)
      [
        t.title,
        t.artist,
        t.album,
        (t.durationMs / 1000).round(),
        if (t.sourceId != 'local' && t.uri.startsWith('http')) t.uri,
      ],
  ];
  final json = utf8.encode(jsonEncode({'v': 1, 'n': name, 't': rows}));
  final packed = GZipCodec(level: 9).encode(json);
  return '$_prefix${base64Url.encode(packed).replaceAll('=', '')}';
}

/// True for text that looks like a shared playlist (also with stray spaces, or
/// inside a message).
bool isSharedPlaylistText(String text) => text.contains(_prefix);

/// Reads a code back. Throws [ShareFormatException] with a message for the user.
ImportedList decodeSharedPlaylist(String text, {String? sourceUrl}) {
  final start = text.indexOf(_prefix);
  if (start < 0) throw ShareFormatException(l10n.shareBadCode);
  final tail = text.substring(start + _prefix.length);
  final data = RegExp(r'^[A-Za-z0-9_\-]+').stringMatch(tail) ?? '';
  if (data.isEmpty) throw ShareFormatException(l10n.shareBadCode);
  final Map<String, dynamic> json;
  try {
    final packed = base64Url.decode(base64Url.normalize(data));
    final out = BytesBuilder(copy: false);
    final sink = _LimitSink(out);
    final conv = gzip.decoder.startChunkedConversion(sink);
    conv.add(packed);
    conv.close();
    json = jsonDecode(utf8.decode(out.takeBytes())) as Map<String, dynamic>;
  } on ShareFormatException {
    rethrow;
  } on Object {
    throw ShareFormatException(l10n.shareBadCode);
  }
  final version = json['v'];
  if (version is! int) throw ShareFormatException(l10n.shareBadCode);
  if (version > 1) throw ShareFormatException(l10n.shareNewerVersion);
  final rows = json['t'];
  if (rows is! List) throw ShareFormatException(l10n.shareBadCode);
  if (rows.length > _maxTracks) throw ShareFormatException(l10n.shareTooBig);
  final tracks = <ExternalTrack>[];
  for (final r in rows.whereType<List>()) {
    if (r.isEmpty || r[0] is! String || (r[0] as String).trim().isEmpty) continue;
    final artist = r.length > 1 && r[1] is String ? r[1] as String : '';
    final link = r.length > 4 && r[4] is String ? r[4] as String : null;
    tracks.add(ExternalTrack(
      service: OnlineService.file,
      title: r[0] as String,
      artists: artist.isEmpty ? const [] : [artist],
      album: r.length > 2 && r[2] is String ? r[2] as String : '',
      durationMs: r.length > 3 && r[3] is num ? (r[3] as num).toInt() * 1000 : 0,
      // Only web links: a code must never be able to point at a local file.
      url: link != null && link.startsWith('https://') ? link : null,
    ));
  }
  if (tracks.isEmpty) throw ShareFormatException(l10n.shareEmpty);
  final name = json['n'] is String && (json['n'] as String).trim().isNotEmpty ? json['n'] as String : l10n.shareDefaultName;
  return ImportedList(name: name, origin: OnlineService.file, tracks: tracks, sourceUrl: sourceUrl);
}

class _LimitSink implements Sink<List<int>> {
  _LimitSink(this._out);
  final BytesBuilder _out;

  @override
  void add(List<int> data) {
    if (_out.length + data.length > _maxUnpacked) throw ShareFormatException(l10n.shareTooBig);
    _out.add(data);
  }

  @override
  void close() {}
}

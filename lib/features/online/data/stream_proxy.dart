import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// What the proxy needs to serve one remote audio stream.
class ProxiedStream {
  const ProxiedStream({required this.url, required this.length, required this.mimeType, this.headers = const {}});
  final Uri url;

  /// Total size in bytes (needed to answer range requests).
  final int length;
  final String mimeType;
  final Map<String, String> headers;
}

/// Resolves (or, with `refresh`, re-resolves an expired) stream.
typedef StreamResolver = Future<ProxiedStream> Function({bool refresh});

/// Loopback HTTP proxy between the audio engine and a remote stream.
///
/// Why: since 2026 googlevideo answers `403` to open-ended requests
/// (`Range: bytes=0-`, or no range), which is exactly what libmpv and
/// ExoPlayer send. The proxy accepts any request from the player and fetches
/// the data upstream in bounded chunks (`bytes=a-b`), like yt-dlp's chunked
/// downloads. Seeking works (each player range request is honoured), an
/// expired URL is re-resolved once, and nothing ever leaves 127.0.0.1.
class StreamProxy {
  StreamProxy({http.Client? client, this.chunkSize = 1024 * 1024}) : _client = client ?? http.Client();

  final http.Client _client;
  final int chunkSize;
  HttpServer? _server;
  Future<HttpServer>? _starting;
  final _streams = <String, StreamResolver>{};

  /// Random part of every URL: other programs on this PC (or a web page
  /// reaching 127.0.0.1) can't guess a stream's address.
  final String _secret = _randomSecret();

  static String _randomSecret() {
    final r = math.Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }
  final _resolved = <String, ProxiedStream>{};

  /// Local URL the engine can open for [key] (e.g. `yt:VIDEOID`).
  Future<Uri> register(String key, StreamResolver resolve) async {
    final server = await (_starting ??= _start());
    _streams[key] = resolve;
    _resolved.remove(key);
    return Uri(scheme: 'http', host: '127.0.0.1', port: server.port, path: '/$_secret/${Uri.encodeComponent(key)}');
  }

  Future<HttpServer> _start() async {
    final s = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    s.listen((req) => unawaited(_handle(req)));
    return _server = s;
  }

  Future<ProxiedStream> _get(String key, {bool refresh = false}) async {
    final known = _resolved[key];
    if (!refresh && known != null) return known;
    final r = _streams[key]!;
    return _resolved[key] = await r(refresh: refresh);
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    final seg = req.uri.pathSegments;
    final key = seg.length == 2 && seg[0] == _secret ? Uri.decodeComponent(seg[1]) : null;
    // Only addressed as 127.0.0.1 / localhost (a web page using DNS rebinding
    // would send its own host name).
    final host = req.headers.host;
    final local = host == null || host == '127.0.0.1' || host == 'localhost';
    if (key == null || !local || !_streams.containsKey(key)) {
      res.statusCode = HttpStatus.notFound;
      await res.close();
      return;
    }
    var headersSent = false;
    try {
      var stream = await _get(key);
      final total = stream.length;
      final range = RegExp(r'bytes=(\d*)-(\d*)').firstMatch(req.headers.value(HttpHeaders.rangeHeader) ?? '');
      var start = range == null || range[1]!.isEmpty ? 0 : int.parse(range[1]!);
      var end = range == null || range[2]!.isEmpty ? total - 1 : math.min(int.parse(range[2]!), total - 1);
      if (range != null && range[1]!.isEmpty && range[2]!.isNotEmpty) {
        // Suffix range "bytes=-N": the last N bytes.
        start = math.max(0, total - int.parse(range[2]!));
        end = total - 1;
      }
      if (start >= total || start > end) {
        res.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        res.headers.set(HttpHeaders.contentRangeHeader, 'bytes */$total');
        await res.close();
        return;
      }
      res.statusCode = range == null ? HttpStatus.ok : HttpStatus.partialContent;
      res.headers
        ..contentType = ContentType.parse(stream.mimeType)
        ..contentLength = end - start + 1
        ..set(HttpHeaders.acceptRangesHeader, 'bytes');
      if (range != null) res.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/$total');
      headersSent = true;
      if (req.method == 'HEAD') {
        await res.close();
        return;
      }

      var pos = start;
      var refreshed = false;
      while (pos <= end) {
        // Small first chunk = fast start; then bigger chunks.
        final size = pos == start ? math.min(chunkSize, 256 * 1024) : chunkSize;
        final chunkEnd = math.min(pos + size - 1, end);
        final up = await _client.send(
          http.Request('GET', stream.url)
            ..headers.addAll(stream.headers)
            ..headers[HttpHeaders.rangeHeader] = 'bytes=$pos-$chunkEnd',
        );
        if ((up.statusCode == 403 || up.statusCode == 410) && !refreshed) {
          // Expired / rejected URL: resolve once more and continue there.
          await up.stream.drain<void>();
          refreshed = true;
          stream = await _get(key, refresh: true);
          continue;
        }
        if (up.statusCode != 206 && up.statusCode != 200) {
          await up.stream.drain<void>();
          throw HttpException('upstream ${up.statusCode}');
        }
        await res.addStream(
          up.stream.map((data) {
            pos += data.length;
            return data;
          }),
        );
        if (up.statusCode == 200) break; // server ignored the range: it sent everything
      }
      await res.close();
    } on Object catch (e) {
      // Player went away (seek / stop) or upstream failed.
      if (!headersSent) {
        debugPrint('Stream proxy: $e');
        try {
          res.statusCode = HttpStatus.badGateway;
          await res.close();
        } on Object {
          // already closed
        }
      } else {
        try {
          await res.close();
        } on Object {
          // client disconnected
        }
      }
    }
  }

  Future<void> close() async {
    await _server?.close(force: true);
    _client.close();
  }
}

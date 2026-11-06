import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../domain/external_track.dart';
import '../domain/online_error.dart';
import '../../../l10n/l10n.dart';

/// HTTP for online services: timeouts, retries with backoff, `Retry-After`
/// on 429, and every failure turned into an [OnlineException].
///
/// * offline / timeout / 5xx → up to [maxAttempts] tries (0.5 s, 1 s, 2 s…)
/// * 429 → waits `Retry-After` (capped at [maxRetryWait]) and tries again
/// * 401 → [OnlineErrorKind.auth] at once (callers refresh the token and retry)
class OnlineHttp {
  OnlineHttp({
    http.Client? client,
    this.maxAttempts = 3,
    this.timeout = const Duration(seconds: 20),
    this.maxRetryWait = const Duration(seconds: 30),
    Future<void> Function(Duration)? sleep,
  }) : _client = client ?? http.Client(),
       _sleep = sleep ?? Future<void>.delayed;

  final http.Client _client;
  final int maxAttempts;
  final Duration timeout;
  final Duration maxRetryWait;
  final Future<void> Function(Duration) _sleep;

  static const userAgent = 'Prism/1.1 (personal music player)';

  Future<http.Response> send(
    String method,
    Uri uri, {
    required OnlineService service,
    Map<String, String> headers = const {},
    Object? body,
  }) async {
    OnlineException? last;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      final http.Response res;
      try {
        final req = http.Request(method, uri)
          ..headers.addAll({'User-Agent': userAgent, 'Accept': 'application/json', ...headers});
        if (body is Map<String, String>) {
          req.bodyFields = body;
        } else if (body is String) {
          req.body = body;
        }
        res = await http.Response.fromStream(await _client.send(req).timeout(timeout)).timeout(timeout);
      } on SocketException {
        last = OnlineException(OnlineErrorKind.offline, service: service);
        await _backoff(attempt);
        continue;
      } on TimeoutException {
        last = OnlineException(
          OnlineErrorKind.offline,
          service: service,
          message: l10n.didNotAnswerInTimeCheck(service.label),
        );
        await _backoff(attempt);
        continue;
      } on http.ClientException {
        last = OnlineException(OnlineErrorKind.offline, service: service);
        await _backoff(attempt);
        continue;
      } on HandshakeException {
        last = OnlineException(
          OnlineErrorKind.offline,
          service: service,
          message: l10n.secureConnectionToFailedCheckThe(service.label),
        );
        await _backoff(attempt);
        continue;
      }

      final code = res.statusCode;
      if (code >= 200 && code < 300) return res;
      if (code == 429 || (code == 403 && _isQuota(res.body))) {
        final wait = _retryAfter(res) ?? Duration(seconds: 2 * attempt);
        last = OnlineException(OnlineErrorKind.rateLimited, service: service, retryAfter: wait);
        if (wait > maxRetryWait || attempt == maxAttempts) break;
        await _sleep(wait);
        continue;
      }
      if (code >= 500) {
        last = OnlineException(OnlineErrorKind.server, service: service);
        await _backoff(attempt);
        continue;
      }
      throw switch (code) {
        401 => OnlineException(OnlineErrorKind.auth, service: service),
        403 => OnlineException(OnlineErrorKind.forbidden, service: service, message: _apiMessage(res, service)),
        404 => OnlineException(OnlineErrorKind.notFound, service: service),
        451 => OnlineException(OnlineErrorKind.forbidden, service: service, message: l10n.regionBlocked(service.label)),
        _ => OnlineException(OnlineErrorKind.badResponse, service: service, message: _apiMessage(res, service)),
      };
    }
    throw last ?? OnlineException(OnlineErrorKind.server, service: service);
  }

  Future<Map<String, dynamic>> getJson(
    Uri uri, {
    required OnlineService service,
    Map<String, String> headers = const {},
  }) async => decodeJson(await send('GET', uri, service: service, headers: headers), service);

  Future<Map<String, dynamic>> postForm(
    Uri uri,
    Map<String, String> fields, {
    required OnlineService service,
    Map<String, String> headers = const {},
  }) async => decodeJson(await send('POST', uri, service: service, headers: headers, body: fields), service);

  /// Plain text (HTML pages for best-effort link import).
  Future<String> getText(Uri uri, {required OnlineService service}) async => utf8.decode(
    (await send('GET', uri, service: service, headers: const {'Accept': 'text/html,*/*'})).bodyBytes,
    allowMalformed: true,
  );

  static Map<String, dynamic> decodeJson(http.Response res, OnlineService service) {
    try {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is Map<String, dynamic>) return data;
      return {'items': data};
    } on FormatException {
      throw OnlineException(OnlineErrorKind.badResponse, service: service);
    }
  }

  Future<void> _backoff(int attempt) =>
      attempt >= maxAttempts ? Future.value() : _sleep(Duration(milliseconds: 500 * math.pow(2, attempt - 1).toInt()));

  static Duration? _retryAfter(http.Response res) {
    final v = res.headers['retry-after'];
    if (v == null) return null;
    final secs = int.tryParse(v.trim());
    if (secs != null) return Duration(seconds: secs);
    try {
      final at = HttpDate.parse(v);
      final d = at.difference(DateTime.now());
      return d.isNegative ? Duration.zero : d;
    } on Object {
      return null;
    }
  }

  /// YouTube Data API signals quota with 403 + reason "quotaExceeded".
  static bool _isQuota(String body) => body.contains('quotaExceeded') || body.contains('rateLimitExceeded');

  /// Error message from a JSON error body, if the API sent one.
  static String? _apiMessage(http.Response res, OnlineService service) {
    try {
      final j = jsonDecode(res.body);
      final err = j is Map ? j['error'] : null;
      final msg = err is Map ? err['message'] : (j is Map ? j['error_description'] ?? j['message'] : null);
      if (msg is String && msg.isNotEmpty) return '${service.label}: $msg';
    } on Object {
      // not JSON
    }
    return null;
  }

  void close() => _client.close();
}

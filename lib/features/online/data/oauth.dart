import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/external_track.dart';
import '../domain/online_error.dart';
import 'online_http.dart';
import '../../../l10n/l10n.dart';

/// Where login tokens live. The real one is the OS keychain
/// (Windows Credential Manager / Android Keystore) via flutter_secure_storage.
abstract class TokenStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _s;

  @override
  Future<String?> read(String key) async {
    try {
      return await _s.read(key: key);
    } on Object {
      // A corrupted keystore entry (e.g. after an Android backup restore) must
      // not break the app: treat it as "logged out".
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) => _s.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _s.delete(key: key);
}

class MemoryTokenStore implements TokenStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

class OAuthToken {
  const OAuthToken({required this.accessToken, this.refreshToken, required this.expiresAt, this.scope = ''});

  factory OAuthToken.fromResponse(Map<String, dynamic> j, {String? previousRefresh}) => OAuthToken(
    accessToken: j['access_token'] as String,
    // Some providers only send a refresh token the first time.
    refreshToken: j['refresh_token'] as String? ?? previousRefresh,
    expiresAt: DateTime.now().add(Duration(seconds: (j['expires_in'] as num?)?.toInt() ?? 3600)),
    scope: j['scope'] as String? ?? '',
  );

  factory OAuthToken.fromJson(Map<String, dynamic> j) => OAuthToken(
    accessToken: j['a'] as String,
    refreshToken: j['r'] as String?,
    expiresAt: DateTime.fromMillisecondsSinceEpoch(j['e'] as int),
    scope: j['s'] as String? ?? '',
  );

  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final String scope;

  bool get expiresSoon => DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 60)));

  Map<String, Object?> toJson() => {
    'a': accessToken,
    'r': refreshToken,
    'e': expiresAt.millisecondsSinceEpoch,
    's': scope,
  };
}

/// PKCE helpers (RFC 7636).
abstract final class Pkce {
  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  static String verifier([Random? random]) {
    final r = random ?? Random.secure();
    return List.generate(64, (_) => _chars[r.nextInt(_chars.length)]).join();
  }

  static String challenge(String verifier) =>
      base64UrlEncode(sha256.convert(ascii.encode(verifier)).bytes).replaceAll('=', '');
}

/// Opens a URL in the system browser (url_launcher in the app, fake in tests).
typedef BrowserLauncher = Future<bool> Function(Uri url);

/// Authorization-code + PKCE login with a loopback redirect
/// (`http://127.0.0.1:<port>/callback`): Prism listens on that port, the
/// browser comes back to it with the code. Works on Windows and Android, no
/// custom URL scheme needed. The redirect URI must be registered exactly in
/// the service's developer dashboard.
class OAuthClient {
  OAuthClient({
    required this.service,
    required this.authorizeUrl,
    required this.tokenUrl,
    required this.clientId,
    this.clientSecret,
    required this.scopes,
    required this.port,
    required this.store,
    required this.http,
    required this.launch,
    this.extraAuthParams = const {},
  });

  final OnlineService service;
  final Uri authorizeUrl;
  final Uri tokenUrl;
  final String clientId;

  /// Only for providers that insist on one for desktop apps (Google,
  /// SoundCloud). Comes from the local config file.
  final String? clientSecret;
  final List<String> scopes;
  final int port;
  final TokenStore store;
  final OnlineHttp http;
  final BrowserLauncher launch;
  final Map<String, String> extraAuthParams;

  String get _key => 'prism.oauth.${service.name}';
  String get redirectUri => 'http://127.0.0.1:$port/callback';

  OAuthToken? _cached;
  Future<OAuthToken?>? _refreshing;

  Future<OAuthToken?> stored() async {
    if (_cached != null) return _cached;
    final raw = await store.read(_key);
    if (raw == null) return null;
    try {
      return _cached = OAuthToken.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      await store.delete(_key);
      return null;
    }
  }

  Future<bool> get isLoggedIn async => await stored() != null;

  Future<void> logout() async {
    _cached = null;
    await store.delete(_key);
  }

  /// Runs the browser login. Throws [OnlineException] on cancel/timeout.
  Future<OAuthToken> login({Duration timeout = const Duration(minutes: 5)}) async {
    final verifier = Pkce.verifier();
    final state = Pkce.verifier().substring(0, 24);
    final HttpServer server;
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    } on SocketException {
      throw OnlineException(
        OnlineErrorKind.badResponse,
        service: service,
        message: l10n.portIsBusyCloseTheOther(port),
      );
    }
    try {
      final url = authorizeUrl.replace(
        queryParameters: {
          ...authorizeUrl.queryParameters,
          'client_id': clientId,
          'response_type': 'code',
          'redirect_uri': redirectUri,
          'code_challenge_method': 'S256',
          'code_challenge': Pkce.challenge(verifier),
          'state': state,
          'scope': scopes.join(' '),
          ...extraAuthParams,
        },
      );
      if (!await launch(url)) {
        throw OnlineException(OnlineErrorKind.badResponse, service: service, message: l10n.couldNotOpenTheBrowser);
      }
      final code = await _waitForCode(server, state).timeout(
        timeout,
        onTimeout: () {
          throw OnlineException(OnlineErrorKind.auth, service: service, message: l10n.loginTimedOut(service.label));
        },
      );
      final j = await http.postForm(tokenUrl, {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': verifier,
        if (clientSecret != null && clientSecret!.isNotEmpty) 'client_secret': clientSecret!,
      }, service: service);
      final token = OAuthToken.fromResponse(j);
      await _save(token);
      return token;
    } finally {
      await server.close(force: true);
    }
  }

  Future<String> _waitForCode(HttpServer server, String state) async {
    await for (final req in server) {
      if (req.uri.path != '/callback') {
        req.response.statusCode = 404;
        await req.response.close();
        continue;
      }
      final q = req.uri.queryParameters;
      final ok = q['state'] == state && q['code'] != null;
      req.response.headers.contentType = ContentType.html;
      req.response.write(
        '<!doctype html><meta charset="utf-8"><title>Prism</title>'
        '<body style="font-family:sans-serif;background:#111;color:#eee;display:grid;place-items:center;height:90vh">'
        '<div><h2>${ok ? l10n.oauthConnected(service.label) : l10n.oauthFailed}</h2>'
        '<p>${ok ? l10n.oauthCloseTab : _escape(q['error'] ?? l10n.oauthWrongState)}</p></div>',
      );
      await req.response.close();
      if (ok) return q['code']!;
      throw OnlineException(
        OnlineErrorKind.auth,
        service: service,
        message: q['error'] == 'access_denied'
            ? l10n.loginWasCancelled
            : l10n.loginFailed(service.label, q['error'] ?? 'state mismatch'),
      );
    }
    throw OnlineException(OnlineErrorKind.auth, service: service, message: l10n.loginWasCancelled);
  }

  static String _escape(String s) => s.replaceAll('<', '&lt;').replaceAll('>', '&gt;');

  /// A token that is valid for at least a minute, refreshing if needed.
  Future<String> accessToken() async {
    final t = await stored();
    if (t == null) {
      throw OnlineException(
        OnlineErrorKind.auth,
        service: service,
        message: l10n.connectFirstSettingsOnlineServices(service.label),
      );
    }
    if (!t.expiresSoon) return t.accessToken;
    return (await refresh())!.accessToken;
  }

  /// Refreshes once even if called from several requests at the same time.
  Future<OAuthToken?> refresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<OAuthToken?> _doRefresh() async {
    final t = await stored();
    final rt = t?.refreshToken;
    if (rt == null) {
      await logout();
      throw OnlineException(OnlineErrorKind.auth, service: service);
    }
    try {
      final j = await http.postForm(tokenUrl, {
        'grant_type': 'refresh_token',
        'refresh_token': rt,
        'client_id': clientId,
        if (clientSecret != null && clientSecret!.isNotEmpty) 'client_secret': clientSecret!,
      }, service: service);
      final fresh = OAuthToken.fromResponse(j, previousRefresh: rt);
      await _save(fresh);
      return fresh;
    } on OnlineException catch (e) {
      // 400 invalid_grant = revoked: forget it. Network errors: keep it.
      if (!e.isTransient) {
        await logout();
        throw OnlineException(OnlineErrorKind.auth, service: service);
      }
      rethrow;
    }
  }

  Future<void> _save(OAuthToken t) async {
    _cached = t;
    await store.write(_key, jsonEncode(t.toJson()));
  }

  /// GET JSON with the bearer token; on 401 refreshes once and retries.
  Future<Map<String, dynamic>> getJson(Uri uri, {String scheme = 'Bearer'}) async {
    try {
      return await http.getJson(uri, service: service, headers: {'Authorization': '$scheme ${await accessToken()}'});
    } on OnlineException catch (e) {
      if (e.kind != OnlineErrorKind.auth) rethrow;
      final t = await refresh();
      return http.getJson(uri, service: service, headers: {'Authorization': '$scheme ${t!.accessToken}'});
    }
  }
}

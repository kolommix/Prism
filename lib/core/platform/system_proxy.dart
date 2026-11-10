import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// Makes every web request of Prism go the way the browser goes.
///
/// Dart's HttpClient ignores Windows' proxy setting. Many people reach
/// YouTube and other services only through a proxy that a VPN app sets for
/// the whole system (Clash, v2rayN, Hiddify and others in "system proxy"
/// mode): the browser works, Prism went straight out, got nothing, and said
/// "you seem to be offline". Now Prism reads the same setting the browser
/// does (Windows → Settings → Network → Proxy, "Use a proxy server"), and the
/// usual `HTTPS_PROXY` / `HTTP_PROXY` / `NO_PROXY` environment variables.
///
/// Not covered: a proxy given only as a setup script (PAC) and SOCKS-only
/// proxies (HttpClient can't speak SOCKS). Home network addresses and
/// localhost always go direct (listen together, the stream proxy).
class SystemProxy {
  SystemProxy._();

  static final instance = SystemProxy._();

  ProxySetting _setting = const ProxySetting.none();
  DateTime _readAt = DateTime(0);

  /// The setting is read again at most this often (a VPN can be switched on
  /// while Prism runs).
  static const refresh = Duration(seconds: 3);

  ProxySetting get current {
    final now = DateTime.now();
    if (now.difference(_readAt) > refresh) {
      _readAt = now;
      try {
        _setting = ProxySetting.fromEnvironment(Platform.environment) ?? (Platform.isWindows ? _readWindows() : null) ?? const ProxySetting.none();
      } on Object {
        _setting = const ProxySetting.none();
      }
    }
    return _setting;
  }

  /// For HttpClient.findProxy.
  String findProxy(Uri url) {
    final p = current.forUrl(url);
    return p == null ? 'DIRECT' : 'PROXY $p; DIRECT';
  }

  /// `host:port` for [url], or null for a direct connection (yt-dlp gets it).
  String? proxyFor(Uri url) => current.forUrl(url);

  static ProxySetting? _readWindows() {
    const key = r'Software\Microsoft\Windows\CurrentVersion\Internet Settings';
    final enabled = _regDword(key, 'ProxyEnable');
    if (enabled != 1) return null;
    final server = _regString(key, 'ProxyServer');
    if (server == null || server.trim().isEmpty) return null;
    return ProxySetting.parseWindows(server, _regString(key, 'ProxyOverride') ?? '');
  }

  // ------------------------------------------------------------- registry

  static final _advapi = DynamicLibrary.open('advapi32.dll');
  static final _regGetValue = _advapi.lookupFunction<
      Int32 Function(IntPtr, Pointer<Utf16>, Pointer<Utf16>, Uint32, Pointer<Uint32>, Pointer<Void>, Pointer<Uint32>),
      int Function(int, Pointer<Utf16>, Pointer<Utf16>, int, Pointer<Uint32>, Pointer<Void>, Pointer<Uint32>)>('RegGetValueW');

  /// HKEY_CURRENT_USER: 0x80000001 as a sign-extended handle.
  static const _hkcu = -2147483647;
  static const _rrfRtRegSz = 0x00000002;
  static const _rrfRtDword = 0x00000018;

  static int? _regDword(String key, String name) => using((arena) {
        final data = arena<Uint32>();
        final size = arena<Uint32>()..value = 4;
        final r = _regGetValue(_hkcu, key.toNativeUtf16(allocator: arena), name.toNativeUtf16(allocator: arena), _rrfRtDword,
            nullptr, data.cast(), size);
        return r == 0 ? data.value : null;
      });

  static String? _regString(String key, String name) => using((arena) {
        final size = arena<Uint32>()..value = 0;
        final k = key.toNativeUtf16(allocator: arena), n = name.toNativeUtf16(allocator: arena);
        if (_regGetValue(_hkcu, k, n, _rrfRtRegSz, nullptr, nullptr, size) != 0 || size.value == 0) return null;
        final buf = arena<Uint8>(size.value + 2);
        if (_regGetValue(_hkcu, k, n, _rrfRtRegSz, nullptr, buf.cast(), size) != 0) return null;
        return buf.cast<Utf16>().toDartString();
      });
}

/// One proxy setting: where http and https requests go, and what stays direct.
class ProxySetting {
  const ProxySetting({this.http, this.https, this.bypass = const []});
  const ProxySetting.none() : http = null, https = null, bypass = const [];

  /// `host:port`, or null for direct.
  final String? http;
  final String? https;

  /// Host patterns that go direct (`*.example.com`, `<local>`, `10.*`).
  final List<String> bypass;

  bool get isNone => http == null && https == null;

  String? forUrl(Uri url) {
    final host = url.host.toLowerCase();
    if (host.isEmpty || isAlwaysDirect(host) || _bypassed(host)) return null;
    final secure = url.scheme == 'https' || url.scheme == 'wss';
    return secure ? (https ?? http) : http;
  }

  bool _bypassed(String host) {
    for (final raw in bypass) {
      final b = raw.trim().toLowerCase();
      if (b.isEmpty) continue;
      if (b == '<local>') {
        if (!host.contains('.')) return true;
        continue;
      }
      final pattern = RegExp('^${RegExp.escape(b).replaceAll(r'\*', '.*')}\$');
      if (pattern.hasMatch(host) || (b.startsWith('.') && host.endsWith(b))) return true;
    }
    return false;
  }

  /// Loopback and home network addresses never use a proxy.
  static bool isAlwaysDirect(String host) {
    if (host == 'localhost' || host.endsWith('.local') || host == '::1' || host == '[::1]') return true;
    final ip = InternetAddress.tryParse(host);
    if (ip == null || ip.type != InternetAddressType.IPv4) return false;
    final b = ip.rawAddress;
    return b[0] == 127 ||
        b[0] == 10 ||
        (b[0] == 192 && b[1] == 168) ||
        (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||
        (b[0] == 169 && b[1] == 254);
  }

  /// Windows' `ProxyServer` value: `host:port` for everything, or
  /// `http=host:port;https=host:port;socks=host:port`.
  static ProxySetting? parseWindows(String server, String override) {
    String? http, https, any;
    for (final part in server.split(';')) {
      final p = part.trim();
      if (p.isEmpty) continue;
      final eq = p.indexOf('=');
      if (eq < 0) {
        any = _hostPort(p);
        continue;
      }
      final scheme = p.substring(0, eq).trim().toLowerCase();
      final value = _hostPort(p.substring(eq + 1));
      if (scheme == 'http') http = value;
      if (scheme == 'https') https = value;
    }
    http ??= any;
    https ??= any ?? http;
    if (http == null && https == null) return null; // SOCKS only
    return ProxySetting(http: http, https: https, bypass: override.split(';'));
  }

  /// `HTTPS_PROXY` / `HTTP_PROXY` / `NO_PROXY` (any case).
  static ProxySetting? fromEnvironment(Map<String, String> env) {
    String? read(String name) {
      final v = env[name] ?? env[name.toLowerCase()];
      return v == null || v.trim().isEmpty ? null : _hostPort(v);
    }

    final https = read('HTTPS_PROXY'), http = read('HTTP_PROXY');
    if (https == null && http == null) return null;
    final no = env['NO_PROXY'] ?? env['no_proxy'] ?? '';
    return ProxySetting(http: http, https: https ?? http, bypass: no.split(','));
  }

  /// `http://user@host:port/` or `host:port` → `host:port`; null when it
  /// isn't an http proxy.
  static String? _hostPort(String raw) {
    var v = raw.trim();
    if (v.isEmpty) return null;
    if (v.contains('://')) {
      final u = Uri.tryParse(v);
      if (u == null || u.host.isEmpty || !(u.scheme == 'http' || u.scheme == 'https')) return null;
      return '${u.host}:${u.hasPort ? u.port : 80}';
    }
    v = v.split('/').first;
    return v.contains(':') ? v : '$v:80';
  }
}

/// Installs [SystemProxy] for every HttpClient the app creates (also the
/// ones inside packages).
class SystemProxyOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)..findProxy = SystemProxy.instance.findProxy;
}

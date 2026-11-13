import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/platform/system_proxy.dart';
import '../domain/external_track.dart';
import '../domain/online_error.dart';
import '../../../l10n/l10n.dart';

/// Tells "no internet" apart from "this one service can't be reached".
///
/// Friends were told "you seem to be offline" while their internet worked:
/// YouTube was blocked or slowed on their network, or answered too slowly.
/// When a service fails like that, Prism asks the addresses systems themselves
/// use for their own "am I online" check (Windows: msftconnecttest.com,
/// Android: connectivitycheck.gstatic.com), so nothing new learns about the
/// user. Both are asked at once and one answer is enough: a network that
/// blocks one of them must not look like "no internet" again. The answer is
/// kept for a minute.
class NetworkCheck {
  NetworkCheck({http.Client Function()? client, this.timeout = const Duration(seconds: 6)})
      : _client = client ?? http.Client.new;

  final http.Client Function() _client;
  final Duration timeout;

  static final probes = [
    Uri.parse('http://www.msftconnecttest.com/connecttest.txt'),
    Uri.parse('https://connectivitycheck.gstatic.com/generate_204'),
  ];

  /// The service's own address (the one Prism was talking to anyway). Saving
  /// YouTube songs also needs the servers that hold the audio.
  static List<Uri> addressesOf(OnlineService service, {bool saving = false}) => switch (service) {
        OnlineService.youtube => [
            Uri.parse('https://www.youtube.com/generate_204'),
            if (saving) Uri.parse('https://redirector.googlevideo.com/generate_204'),
          ],
        OnlineService.spotify => [Uri.parse('https://api.spotify.com/')],
        OnlineService.soundcloud => [Uri.parse('https://api.soundcloud.com/')],
        OnlineService.deezer => [Uri.parse('https://api.deezer.com/infos')],
        OnlineService.appleMusic => [Uri.parse('https://music.apple.com/robots.txt')],
        OnlineService.yandex => [Uri.parse('https://api.music.yandex.net/')],
        OnlineService.file => const [],
      };

  bool? _last;
  DateTime _at = DateTime(0);
  Future<bool>? _running;

  /// True when the internet works.
  Future<bool> internetWorks() {
    if (_last != null && DateTime.now().difference(_at) < const Duration(minutes: 1)) return Future.value(_last);
    return _running ??= _ask().whenComplete(() => _running = null);
  }

  /// Any answer at all from [url] in time.
  Future<bool> _answers(Uri url, {bool Function(int status)? ok}) async {
    final c = _client();
    try {
      final r = await c.get(url).timeout(timeout);
      return ok == null || ok(r.statusCode);
    } on Object {
      return false;
    } finally {
      c.close();
    }
  }

  Future<bool> _ask() async {
    final done = Completer<bool>();
    var left = probes.length;
    for (final p in probes) {
      unawaited(_answers(p, ok: (s) => s == 204 || s == 200).then((yes) {
        left--;
        if (done.isCompleted) return;
        if (yes || left == 0) done.complete(yes);
      }));
    }
    _last = await done.future;
    _at = DateTime.now();
    return _last!;
  }

  /// True when [service] answers from here right now (any answer counts, also
  /// an error page: the point is that the connection gets through). Not kept:
  /// asked when a request just failed, to decide between "try once more" and
  /// "blocked here, stop".
  Future<bool> reachable(OnlineService service, {bool saving = false}) async {
    final urls = addressesOf(service, saving: saving);
    if (urls.isEmpty) return true;
    final answers = await Future.wait([for (final u in urls) _answers(u)]);
    return answers.every((a) => a);
  }

  /// [e] with a truer message: an "offline" error while the internet works
  /// becomes "can't reach this service on this network".
  Future<OnlineException> explain(OnlineException e) async {
    if (e.kind != OnlineErrorKind.offline) return e;
    if (!await internetWorks()) return OnlineException(OnlineErrorKind.offline, service: e.service);
    final name = e.service?.label ?? l10n.theService;
    return OnlineException(
      OnlineErrorKind.offline,
      service: e.service,
      message: l10n.serviceUnreachableInternetWorks(name),
      internetWorks: true,
    );
  }

  /// For any error: [explain] for online ones, the plain message otherwise.
  Future<String> describe(Object e) async => e is OnlineException ? (await explain(e)).message : describeOnlineError(e);
}

final networkCheckProvider = Provider<NetworkCheck>((ref) => NetworkCheck());

/// Makes a [NetworkWatch] (tests give their own).
final networkWatchFactoryProvider = Provider<NetworkWatch Function()>((ref) => NetworkWatch.new);

/// Notices that the way out to the internet changed: a VPN switched on or
/// off, another Wi-Fi, a proxy set. A paused import then tries again at once
/// instead of waiting minutes. Looks only at this device's own network
/// adapters and proxy setting; nothing is sent anywhere.
class NetworkWatch {
  NetworkWatch({Future<String> Function()? signature, this.every = const Duration(seconds: 5)}) : _signature = signature ?? currentSignature;

  final Future<String> Function() _signature;
  final Duration every;

  Timer? _timer;
  String? _was;
  bool _busy = false;

  bool get watching => _timer != null;

  /// The adapters that are up with their addresses, and the proxy in use.
  static Future<String> currentSignature() async {
    final parts = <String>[];
    try {
      for (final i in await NetworkInterface.list(includeLoopback: false, includeLinkLocal: false)) {
        parts.add('${i.name}=${(i.addresses.map((a) => a.address).toList()..sort()).join(',')}');
      }
    } on Object {
      // Not allowed or not supported here: the proxy alone still counts.
    }
    parts.sort();
    final proxy = SystemProxy.instance.current;
    return '${parts.join(';')}|${proxy.http}|${proxy.https}';
  }

  /// Calls [onChange] once, the first time the network differs from now, and
  /// stops. Starting again replaces the earlier watch.
  void start(void Function() onChange) {
    stop();
    _was = null;
    _timer = Timer.periodic(every, (_) async {
      if (_busy) return;
      _busy = true;
      try {
        final now = await _signature();
        if (_timer == null) return;
        if (_was == null) {
          _was = now;
        } else if (now != _was) {
          stop();
          onChange();
        }
      } on Object {
        // Try again at the next tick.
      } finally {
        _busy = false;
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../domain/online_error.dart';
import '../../../l10n/l10n.dart';

/// Tells "no internet" apart from "this one service can't be reached".
///
/// Friends were told "you seem to be offline" while their internet worked:
/// YouTube was blocked or slowed on their network, or answered too slowly.
/// When a service fails like that, Prism asks the address the system itself
/// uses for its own "am I online" check (Windows: msftconnecttest.com, Android:
/// connectivitycheck.gstatic.com), so nothing new learns about the user. The
/// answer is kept for a minute.
class NetworkCheck {
  NetworkCheck({http.Client Function()? client, this.timeout = const Duration(seconds: 6)})
      : _client = client ?? http.Client.new;

  final http.Client Function() _client;
  final Duration timeout;


  static Uri get probe => Platform.isAndroid
      ? Uri.parse('https://connectivitycheck.gstatic.com/generate_204')
      : Uri.parse('http://www.msftconnecttest.com/connecttest.txt');

  bool? _last;
  DateTime _at = DateTime(0);
  Future<bool>? _running;

  /// True when the internet works.
  Future<bool> internetWorks() {
    if (_last != null && DateTime.now().difference(_at) < const Duration(minutes: 1)) return Future.value(_last);
    return _running ??= _ask().whenComplete(() => _running = null);
  }

  Future<bool> _ask() async {
    final c = _client();
    try {
      final r = await c.get(probe).timeout(timeout);
      _last = r.statusCode == 204 || r.statusCode == 200;
    } on Object {
      _last = false;
    } finally {
      c.close();
    }
    _at = DateTime.now();
    return _last!;
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

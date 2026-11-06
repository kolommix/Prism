import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../../../l10n/l10n.dart';

/// A session seen on this network.
class NearbySession {
  const NearbySession({required this.room, required this.name, required this.song, required this.address, required this.seen});
  final String room;
  final String name;
  final String song;
  final InternetAddress address;
  final DateTime seen;
}

const nearbyPort = 47801;

/// Host: shouts "I have a session" on the local network every 2 s (UDP), so
/// friends on the same Wi-Fi just see it in a list. No code, no setup.
class NearbyBeacon {
  NearbyBeacon._(this._socket);

  final RawDatagramSocket _socket;
  Timer? _timer;
  List<InternetAddress> _targets = const [];

  static Future<NearbyBeacon?> start({required String room, required String name, required String Function() song}) async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      final beacon = NearbyBeacon._(socket);
      beacon._targets = await _broadcastTargets();
      void send() {
        final data = utf8.encode(jsonEncode({'prism': 1, 'room': room, 'name': name, 'song': song()}));
        for (final t in beacon._targets) {
          try {
            socket.send(data, t, nearbyPort);
          } on Object {
            // Network went away for a moment.
          }
        }
      }

      send();
      beacon._timer = Timer.periodic(const Duration(seconds: 2), (_) => send());
      return beacon;
    } on Object {
      return null; // No network or blocked: codes still work.
    }
  }

  /// The general broadcast address + each network's own (assumes /24, which
  /// home networks are; Windows may send the general one out of one adapter only).
  static Future<List<InternetAddress>> _broadcastTargets() async {
    final out = <InternetAddress>[InternetAddress('255.255.255.255')];
    for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
      for (final a in i.addresses) {
        if (a.isLoopback) continue;
        final parts = a.address.split('.');
        out.add(InternetAddress('${parts[0]}.${parts[1]}.${parts[2]}.255'));
      }
    }
    return out;
  }

  void stop() {
    _timer?.cancel();
    _socket.close();
  }
}

/// Listens for beacons while the listen-together sheet is open.
class NearbyScanner {
  NearbyScanner._(this._socket);

  final RawDatagramSocket _socket;
  final _found = <String, NearbySession>{};
  final _out = StreamController<List<NearbySession>>.broadcast();
  Timer? _sweep;

  Stream<List<NearbySession>> get sessions => _out.stream;

  /// Null when the port can't be opened (the list just stays empty).
  static Future<NearbyScanner?> start({String? ignoreRoom}) async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, nearbyPort, reuseAddress: true);
      final scanner = NearbyScanner._(socket);
      socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final d = socket.receive();
        if (d != null) scanner._onData(d, ignoreRoom);
      });
      scanner._sweep = Timer.periodic(const Duration(seconds: 2), (_) => scanner._drop());
      return scanner;
    } on Object {
      return null;
    }
  }

  void _onData(Datagram d, String? ignoreRoom) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(d.data));
    } on FormatException {
      return;
    }
    if (json is! Map<String, dynamic> || json['prism'] != 1) return;
    final room = json['room'];
    if (room is! String || room.isEmpty || room == ignoreRoom) return;
    _found['${d.address.address}|$room'] = NearbySession(
      room: room,
      name: json['name'] as String? ?? l10n.someone,
      song: json['song'] as String? ?? '',
      address: d.address,
      seen: DateTime.now(),
    );
    _emit();
  }

  void _drop() {
    final limit = DateTime.now().subtract(const Duration(seconds: 7));
    final before = _found.length;
    _found.removeWhere((_, s) => s.seen.isBefore(limit));
    if (_found.length != before) _emit();
  }

  void _emit() {
    if (!_out.isClosed) _out.add(_found.values.toList());
  }

  void stop() {
    _sweep?.cancel();
    _socket.close();
    unawaited(_out.close());
  }
}

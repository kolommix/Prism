import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Minimal WebSocket relay for "Listen together" (pure dart:io, no Flutter).
///
/// Clients connect to `ws://host:port/` and send
/// `{"t":"hello","room":"K7QX","role":"host"|"guest"}` first. After that:
/// * messages from the host go to every guest of the room,
/// * messages from a guest go to the host,
/// * everyone gets `{"t":"peers","guests":n}` when the room changes.
/// One host per room; a second host is rejected. Rooms vanish when empty.
///
/// Runs inside the host's app (LAN mode) or standalone: `dart run tool/relay.dart`.
class ListenTogetherRelay {
  ListenTogetherRelay._(this._server);

  final HttpServer _server;
  final _rooms = <String, _Room>{};

  int get port => _server.port;

  static Future<ListenTogetherRelay> start({int port = 47800, InternetAddress? address}) async {
    final server = await HttpServer.bind(address ?? InternetAddress.anyIPv4, port, shared: true);
    final relay = ListenTogetherRelay._(server);
    server.listen(relay._onRequest);
    return relay;
  }

  Future<void> _onRequest(HttpRequest req) async {
    if (!WebSocketTransformer.isUpgradeRequest(req)) {
      req.response
        ..statusCode = HttpStatus.ok
        ..write('Prism listen-together relay')
        ..close();
      return;
    }
    final ws = await WebSocketTransformer.upgrade(req);
    ws.pingInterval = const Duration(seconds: 15);
    _Room? room;
    var isHost = false;
    ws.listen(
      (data) {
        if (data is! String || data.length > 512 * 1024) return;
        if (room == null) {
          final Map<String, dynamic> hello;
          try {
            hello = jsonDecode(data) as Map<String, dynamic>;
          } on FormatException {
            ws.close(4000, 'bad hello');
            return;
          }
          final code = (hello['room'] as String? ?? '').toUpperCase();
          if (hello['t'] != 'hello' || code.length < 4 || code.length > 12) {
            ws.close(4000, 'bad hello');
            return;
          }
          final r = _rooms.putIfAbsent(code, _Room.new);
          isHost = hello['role'] == 'host';
          if (isHost) {
            if (r.host != null) {
              ws.close(4001, 'room already has a host');
              return;
            }
            r.host = ws;
          } else {
            r.guests.add(ws);
          }
          room = r;
          r.broadcastPeers();
          return;
        }
        final r = room!;
        if (isHost) {
          for (final g in r.guests) {
            g.add(data);
          }
        } else {
          r.host?.add(data);
        }
      },
      onDone: () {
        final r = room;
        if (r == null) return;
        if (isHost) {
          r.host = null;
          for (final g in r.guests) {
            g.add(jsonEncode({'t': 'ended'}));
          }
        } else {
          r.guests.remove(ws);
        }
        r.broadcastPeers();
        _rooms.removeWhere((_, v) => v.host == null && v.guests.isEmpty);
      },
      cancelOnError: true,
    );
  }

  Future<void> close() async {
    // Copies: closing a socket runs its onDone, which edits rooms and guests
    // (iterating the live collections crashed with "concurrent modification").
    for (final r in _rooms.values.toList()) {
      await r.host?.close();
      for (final g in r.guests.toList()) {
        await g.close();
      }
    }
    await _server.close(force: true);
  }
}

class _Room {
  WebSocket? host;
  final guests = <WebSocket>{};

  void broadcastPeers() {
    final msg = jsonEncode({'t': 'peers', 'guests': guests.length, 'host': host != null});
    host?.add(msg);
    for (final g in guests) {
      g.add(msg);
    }
  }
}

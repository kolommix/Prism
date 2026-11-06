import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'mqtt_lite.dart';

/// One way to reach the other people in a session. The controller doesn't
/// care which: a relay on this PC, your own relay, or the public server.
abstract class TogetherLink {
  Stream<Map<String, dynamic>> get messages;

  /// Completes when the connection is lost or closed.
  Future<void> get done;

  void send(Map<String, Object?> message);

  Future<void> close();
}

Map<String, dynamic>? _decode(String text) {
  try {
    final v = jsonDecode(text);
    return v is Map<String, dynamic> ? v : null;
  } on FormatException {
    return null;
  }
}

/// A `ListenTogetherRelay` over a WebSocket (in this app or on a server).
class RelayLink implements TogetherLink {
  RelayLink._(this._ws) {
    _sub = _ws.listen(
      (data) {
        if (data is! String) return;
        final m = _decode(data);
        if (m != null) _out.add(m);
      },
      onDone: _finish,
      onError: (Object _) => _finish(),
      cancelOnError: true,
    );
  }

  static Future<RelayLink> connect(Uri url, String room, String role) async {
    final ws = await WebSocket.connect(url.toString()).timeout(const Duration(seconds: 5));
    final link = RelayLink._(ws);
    ws.add(jsonEncode({'t': 'hello', 'room': room, 'role': role}));
    return link;
  }

  final WebSocket _ws;
  late final StreamSubscription<Object?> _sub;
  final _out = StreamController<Map<String, dynamic>>.broadcast();
  final _done = Completer<void>();

  void _finish() {
    if (!_done.isCompleted) _done.complete();
    if (!_out.isClosed) unawaited(_out.close());
  }

  @override
  Stream<Map<String, dynamic>> get messages => _out.stream;

  @override
  Future<void> get done => _done.future;

  @override
  void send(Map<String, Object?> message) {
    if (_done.isCompleted) return;
    try {
      _ws.add(jsonEncode(message));
    } on Object {
      _finish();
    }
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    _finish();
    await _ws.close().timeout(const Duration(seconds: 1), onTimeout: () {});
  }
}

// ---------------------------------------------------------- public server

/// Song names don't travel in the clear over a public server: messages are
/// scrambled with a keystream from the session code (SHA-256 in counter mode).
/// This stops strangers reading along; it isn't meant to stop someone who has
/// the code or wants to guess it, and nothing in a session is secret anyway.
List<int> scramble(String room, List<int> nonce, List<int> data) {
  final key = sha256.convert(utf8.encode('prism-together|$room')).bytes;
  final out = Uint8List(data.length);
  var block = const <int>[];
  for (var i = 0; i < data.length; i++) {
    if (i % 32 == 0) {
      final n = i ~/ 32;
      block = sha256.convert([...key, ...nonce, n >> 24 & 255, n >> 16 & 255, n >> 8 & 255, n & 255]).bytes;
    }
    out[i] = data[i] ^ block[i % 32];
  }
  return out;
}

Uint8List sealMessage(String room, Map<String, Object?> message, [math.Random? rnd]) {
  final r = rnd ?? math.Random.secure();
  final nonce = List<int>.generate(8, (_) => r.nextInt(256));
  return Uint8List.fromList([...nonce, ...scramble(room, nonce, utf8.encode(jsonEncode(message)))]);
}

Map<String, dynamic>? openMessage(String room, List<int> bytes) {
  if (bytes.length < 9 || bytes.length > 512 * 1024) return null;
  final clear = scramble(room, bytes.sublist(0, 8), bytes.sublist(8));
  try {
    return _decode(utf8.decode(clear));
  } on FormatException {
    return null; // not ours / wrong code
  }
}

/// A free public MQTT broker, tried in this order.
class CloudBroker {
  const CloudBroker(this.host, this.port, {this.secure = true});
  final String host;
  final int port;
  final bool secure;
}

/// Free public brokers: no account, no setup, and they may go away one day,
/// which is why there are several and a relay URL in Settings still wins.
const cloudBrokers = [
  CloudBroker('broker.emqx.io', 8883),
  CloudBroker('broker.hivemq.com', 8883),
];

/// Topic for one direction of a session; the code itself isn't in the name.
String cloudTopic(String room, String direction) {
  final hash = sha256.convert(utf8.encode('prism-together/v1|$room')).toString().substring(0, 28);
  return 'prism-together/v1/$hash/$direction';
}

/// A session over a public MQTT broker.
///
/// The host publishes on `/h` and listens on `/g`, guests the other way round.
/// If a host's connection dies, the broker sends its last will: "ended".
class CloudLink implements TogetherLink {
  CloudLink._(this._mqtt, this._room, this._sendTopic, String listen, this.broker) {
    _sub = _mqtt.messages.listen((m) {
      final decoded = openMessage(_room, m.payload);
      if (decoded != null) _out.add(decoded);
    });
    unawaited(_mqtt.done.whenComplete(() {
      if (!_out.isClosed) unawaited(_out.close());
    }));
    _mqtt.subscribe(listen);
  }

  static Future<CloudLink> connect(String room, {required bool host, required CloudBroker broker}) async {
    final rnd = math.Random.secure();
    final id = 'prism-${List.generate(12, (_) => rnd.nextInt(36).toRadixString(36)).join()}';
    final send = cloudTopic(room, host ? 'h' : 'g');
    final listen = cloudTopic(room, host ? 'g' : 'h');
    final mqtt = await MqttLite.connect(
      host: broker.host,
      port: broker.port,
      secure: broker.secure,
      clientId: id,
      willTopic: host ? send : null,
      willPayload: host ? sealMessage(room, {'t': 'ended'}) : null,
    );
    return CloudLink._(mqtt, room, send, listen, broker);
  }

  final MqttLite _mqtt;
  final String _room;
  final String _sendTopic;
  final CloudBroker broker;
  late final StreamSubscription<MqttMessage> _sub;
  final _out = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get messages => _out.stream;

  @override
  Future<void> get done => _mqtt.done;

  @override
  void send(Map<String, Object?> message) => _mqtt.publish(_sendTopic, sealMessage(_room, message));

  @override
  Future<void> close() async {
    await _sub.cancel();
    if (!_out.isClosed) unawaited(_out.close());
    await _mqtt.close();
  }
}

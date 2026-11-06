import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Length field of an MQTT packet: 7 bits per byte, top bit = more follows.
List<int> encodeRemainingLength(int length) {
  final out = <int>[];
  var x = length;
  do {
    var b = x % 128;
    x ~/= 128;
    if (x > 0) b |= 0x80;
    out.add(b);
  } while (x > 0);
  return out;
}

Uint8List _utf8Field(String s) {
  final bytes = utf8.encode(s);
  return Uint8List.fromList([bytes.length >> 8, bytes.length & 255, ...bytes]);
}

Uint8List _packet(int header, List<int> body) =>
    Uint8List.fromList([header, ...encodeRemainingLength(body.length), ...body]);

/// CONNECT (MQTT 3.1.1, clean session, optional last will at QoS 0).
Uint8List mqttConnect(String clientId, {int keepAliveSeconds = 30, String? willTopic, List<int>? willPayload}) {
  final will = willTopic != null && willPayload != null;
  return _packet(0x10, [
    ..._utf8Field('MQTT'),
    4,
    0x02 | (will ? 0x04 : 0),
    keepAliveSeconds >> 8,
    keepAliveSeconds & 255,
    ..._utf8Field(clientId),
    if (will) ..._utf8Field(willTopic),
    if (will) ...[willPayload.length >> 8, willPayload.length & 255, ...willPayload],
  ]);
}

Uint8List mqttSubscribe(int packetId, String topic) =>
    _packet(0x82, [packetId >> 8, packetId & 255, ..._utf8Field(topic), 0]);

/// PUBLISH at QoS 0: fire and forget; the host repeats its state anyway.
Uint8List mqttPublish(String topic, List<int> payload) => _packet(0x30, [..._utf8Field(topic), ...payload]);

/// A packet read from the stream.
class MqttPacket {
  const MqttPacket(this.type, this.flags, this.body);
  final int type;
  final int flags;
  final Uint8List body;
}

/// Cuts a TCP byte stream into packets (a read can hold half a packet or many).
class MqttDecoder {
  final _buffer = BytesBuilder(copy: false);
  Uint8List _pending = Uint8List(0);

  List<MqttPacket> add(List<int> chunk) {
    _buffer
      ..add(_pending)
      ..add(chunk is Uint8List ? chunk : Uint8List.fromList(chunk));
    final data = _buffer.takeBytes();
    final out = <MqttPacket>[];
    var i = 0;
    while (i < data.length) {
      var at = i + 1, multiplier = 1, length = 0;
      var complete = false;
      while (at < data.length) {
        final b = data[at++];
        length += (b & 127) * multiplier;
        multiplier *= 128;
        if (b & 128 == 0) {
          complete = true;
          break;
        }
      }
      if (!complete || at + length > data.length) break;
      out.add(MqttPacket(data[i] >> 4, data[i] & 15, Uint8List.sublistView(data, at, at + length)));
      i = at + length;
    }
    _pending = i == data.length ? Uint8List(0) : Uint8List.sublistView(data, i);
    return out;
  }
}

class MqttMessage {
  const MqttMessage(this.topic, this.payload);
  final String topic;
  final Uint8List payload;
}

/// Just enough MQTT 3.1.1 for pub/sub over a public broker (no package).
class MqttLite {
  MqttLite._(this._socket);

  final Socket _socket;
  final _messages = StreamController<MqttMessage>.broadcast();
  final _decoder = MqttDecoder();
  final _closed = Completer<void>();
  Timer? _ping;
  var _nextId = 1;

  Stream<MqttMessage> get messages => _messages.stream;

  /// Completes when the connection is gone.
  Future<void> get done => _closed.future;

  bool get isClosed => _closed.isCompleted;

  static Future<MqttLite> connect({
    required String host,
    required int port,
    required String clientId,
    bool secure = true,
    int keepAliveSeconds = 30,
    String? willTopic,
    List<int>? willPayload,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final Socket socket = secure
        ? await SecureSocket.connect(host, port, timeout: timeout)
        : await Socket.connect(host, port, timeout: timeout);
    socket.setOption(SocketOption.tcpNoDelay, true);
    final client = MqttLite._(socket);
    final ack = Completer<void>();
    client._listen(ack);
    socket.add(mqttConnect(clientId, keepAliveSeconds: keepAliveSeconds, willTopic: willTopic, willPayload: willPayload));
    try {
      await ack.future.timeout(timeout);
    } on Object {
      await client.close();
      rethrow;
    }
    client._ping = Timer.periodic(Duration(seconds: keepAliveSeconds), (_) {
      if (!client.isClosed) socket.add(const [0xC0, 0x00]);
    });
    return client;
  }

  void _listen(Completer<void> ack) {
    // Writing to a dropped connection reports here; the listener below handles the drop.
    _socket.done.ignore();
    _socket.listen(
      (chunk) {
        for (final p in _decoder.add(chunk)) {
          switch (p.type) {
            case 2: // CONNACK
              if (ack.isCompleted) break;
              if (p.body.length >= 2 && p.body[1] == 0) {
                ack.complete();
              } else {
                ack.completeError(SocketException('Broker refused the connection (${p.body.lastOrNull})'));
              }
            case 3: // PUBLISH (QoS 0 only: we never subscribe higher)
              if (p.body.length < 2) break;
              final n = (p.body[0] << 8) | p.body[1];
              if (2 + n > p.body.length) break;
              _messages.add(MqttMessage(
                utf8.decode(Uint8List.sublistView(p.body, 2, 2 + n), allowMalformed: true),
                Uint8List.sublistView(p.body, 2 + n),
              ));
          }
        }
      },
      onError: (Object e) {
        if (!ack.isCompleted) ack.completeError(e);
        _finish();
      },
      onDone: () {
        if (!ack.isCompleted) ack.completeError(const SocketException('Connection closed'));
        _finish();
      },
      cancelOnError: true,
    );
  }

  void _finish() {
    _ping?.cancel();
    if (!_closed.isCompleted) _closed.complete();
    if (!_messages.isClosed) unawaited(_messages.close());
    _socket.destroy();
  }

  void subscribe(String topic) {
    if (isClosed) return;
    _socket.add(mqttSubscribe(_nextId++, topic));
  }

  void publish(String topic, List<int> payload) {
    if (isClosed) return;
    _socket.add(mqttPublish(topic, payload));
  }

  Future<void> close() async {
    if (isClosed) return;
    try {
      _socket.add(const [0xE0, 0x00]); // DISCONNECT (a clean leave: no last will)
      await _socket.flush().timeout(const Duration(seconds: 1));
    } on Object {
      // Going away anyway.
    }
    _finish();
  }
}

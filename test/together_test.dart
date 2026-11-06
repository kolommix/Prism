import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/together/data/relay.dart';
import 'package:prism/features/together/domain/together_protocol.dart';
import 'package:prism/features/tools/domain/track_matching.dart';

void main() {
  group('protocol', () {
    test('LAN code round trip and short codes', () {
      final code = lanCode('K7QX', InternetAddress('192.168.1.5'));
      expect(code, 'K7QX-C0A80105');
      final (room, ip) = parseJoinCode(' k7qx-c0a80105 ')!;
      expect((room, ip?.address), ('K7QX', '192.168.1.5'));
      expect(parseJoinCode('K7QX')!.$2, isNull);
      expect(parseJoinCode('hello world'), isNull);
      expect(randomRoom(Random(1)), hasLength(5));
    });

    test('expected position, drift and clock offset', () {
      const s = SharedState(queue: [], index: 0, positionMs: 10000, playing: true, speed: 1.5, sentAtMs: 1000000);
      // Guest clock is 300 ms behind the host.
      expect(s.expectedPosition(guestNowMs: 1000000 + 2000 - 300, clockOffsetMs: 300), const Duration(milliseconds: 13000));
      expect(needsSeek(const Duration(milliseconds: 13500), const Duration(milliseconds: 13000)), isFalse);
      expect(needsSeek(const Duration(milliseconds: 14000), const Duration(milliseconds: 13000)), isTrue);
      // Ping sent at 0, answered by host at 5300 (its clock), received at 200 → offset 5200.
      expect(clockOffsetMs(sentMs: 0, receivedMs: 200, hostMs: 5300), 5200);
      final back = SharedState.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
      expect((back.positionMs, back.speed, back.playing), (10000, 1.5, true));
    });
  });

  group('relay (real WebSockets on localhost)', () {
    late ListenTogetherRelay relay;
    setUp(() async => relay = await ListenTogetherRelay.start(port: 0, address: InternetAddress.loopbackIPv4));
    tearDown(() => relay.close());

    Future<(WebSocket, StreamQueue)> client(String room, String role) async {
      final ws = await WebSocket.connect('ws://127.0.0.1:${relay.port}/');
      final q = StreamQueue(ws.map((e) => jsonDecode(e as String) as Map<String, dynamic>));
      ws.add(jsonEncode({'t': 'hello', 'room': room, 'role': role}));
      return (ws, q);
    }

    test('host ↔ guests forwarding, peers, second host rejected, end of session', () async {
      final (host, hq) = await client('ABCD', 'host');
      expect((await hq.next)['guests'], 0);
      final (g1, g1q) = await client('ABCD', 'guest');
      expect((await hq.next)['guests'], 1);
      expect((await g1q.next)['t'], 'peers');

      const state = SharedState(
        queue: [TrackRef(uri: '/a.mp3', title: 'A', artist: 'X', durationMs: 1000)],
        index: 0,
        positionMs: 42,
        playing: true,
        speed: 1,
        sentAtMs: 7,
      );
      host.add(jsonEncode(state.toJson()));
      final got = await g1q.next;
      expect((got['t'], got['pos'], (got['queue'] as List).length), ('state', 42, 1));

      g1.add(jsonEncode({'t': 'ping', 'at': 5}));
      expect((await hq.next)['t'], 'ping');

      // Other rooms are isolated; a second host for the room is refused.
      final (other, oq) = await client('ZZZZ', 'guest');
      expect((await oq.next)['host'], isFalse);
      final intruder = await WebSocket.connect('ws://127.0.0.1:${relay.port}/');
      intruder.listen((_) {}); // the close frame is only processed while listening
      intruder.add(jsonEncode({'t': 'hello', 'room': 'ABCD', 'role': 'host'}));
      await intruder.done;
      expect(intruder.closeCode, 4001);

      await host.close();
      final ended = await g1q.next;
      expect(ended['t'], 'ended');
      await g1.close();
      await other.close();
    });
  });
}

/// Tiny pull-based reader over a stream (avoids an extra package).
class StreamQueue {
  StreamQueue(Stream<Map<String, dynamic>> s) {
    s.listen((e) => _waiting.isEmpty ? _buffer.add(e) : _waiting.removeAt(0).complete(e));
  }
  final _buffer = <Map<String, dynamic>>[];
  final _waiting = <Completer<Map<String, dynamic>>>[];

  Future<Map<String, dynamic>> get next {
    if (_buffer.isNotEmpty) return Future.value(_buffer.removeAt(0));
    final c = Completer<Map<String, dynamic>>();
    _waiting.add(c);
    return c.future.timeout(const Duration(seconds: 5));
  }
}

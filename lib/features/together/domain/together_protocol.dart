import 'dart:io';
import 'dart:math' as math;

import '../../tools/domain/track_matching.dart';

/// What the host broadcasts.
class SharedState {
  const SharedState({
    required this.queue,
    required this.index,
    required this.positionMs,
    required this.playing,
    required this.speed,
    required this.sentAtMs,
    this.queueVersion = 0,
    this.hostName = '',
    this.people = const [],
  });

  final List<TrackRef> queue;
  final int index;
  final int positionMs;
  final bool playing;
  final double speed;

  /// Host clock (ms since epoch) when the position was read.
  final int sentAtMs;

  /// Changes with the queue. Most messages leave [queue] empty and only carry
  /// this; a guest who missed the last queue asks for it again.
  final int queueVersion;

  final String hostName;

  /// Everyone listening with the host.
  final List<String> people;

  Map<String, Object> toJson() => {
        't': 'state',
        'queue': [for (final r in queue) r.toJson()],
        'index': index,
        'pos': positionMs,
        'playing': playing,
        'speed': speed,
        'at': sentAtMs,
        'qv': queueVersion,
        'name': hostName,
        'people': people,
      };

  factory SharedState.fromJson(Map<String, dynamic> j) => SharedState(
        queue: [for (final r in (j['queue'] as List? ?? const [])) TrackRef.fromJson(r as Map<String, dynamic>)],
        index: j['index'] as int? ?? 0,
        positionMs: j['pos'] as int? ?? 0,
        playing: j['playing'] as bool? ?? false,
        speed: (j['speed'] as num?)?.toDouble() ?? 1,
        sentAtMs: j['at'] as int? ?? 0,
        queueVersion: j['qv'] as int? ?? 0,
        hostName: j['name'] as String? ?? '',
        people: [for (final p in (j['people'] as List? ?? const [])) '$p'],
      );

  /// Where the host is *now* (guest time + [clockOffsetMs] = host time).
  Duration expectedPosition({required int guestNowMs, required int clockOffsetMs}) {
    if (!playing) return Duration(milliseconds: positionMs);
    final elapsed = math.max(0, guestNowMs + clockOffsetMs - sentAtMs);
    return Duration(milliseconds: positionMs + (elapsed * speed).round());
  }
}

/// Guest seeks when it is more than this far off.
const maxDrift = Duration(milliseconds: 700);

/// Should the guest seek? (pure, tested)
bool needsSeek(Duration local, Duration expected) => (local - expected).abs() > maxDrift;

/// Clock offset from one ping round trip (NTP-style, symmetric delay).
int clockOffsetMs({required int sentMs, required int receivedMs, required int hostMs}) =>
    hostMs + ((receivedMs - sentMs) ~/ 2) - receivedMs;

// ------------------------------------------------------------ session codes

const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O/1/I

/// Five characters: easy to read out, hard to bump into on a shared server.
String randomRoom([math.Random? r]) {
  final rnd = r ?? math.Random.secure();
  return List.generate(5, (_) => _alphabet[rnd.nextInt(_alphabet.length)]).join();
}

/// Which of [count] public servers a session is on, read from its code. The
/// host picks a code that points at the server it reached, so a guest goes
/// straight there, even when another server happens to answer for the guest.
int brokerOfRoom(String room, int count) {
  if (count <= 1 || room.isEmpty) return 0;
  return math.max(0, _alphabet.indexOf(room[0])) % count;
}

/// A random code that points at server [broker].
String randomRoomOn(int broker, int count, [math.Random? r]) {
  final rnd = r ?? math.Random.secure();
  while (true) {
    final room = randomRoom(rnd);
    if (brokerOfRoom(room, count) == broker) return room;
  }
}

/// The part of the queue guests get: a few songs back, more ahead. Big queues
/// stay small on the wire. (start, end) of [length] around [index].
(int, int) sharedWindow(int index, int length, {int before = 5, int after = 40}) =>
    (math.max(0, index - before), math.min(length, index + after + 1));

/// Same-Wi-Fi join code when the internet is off: room + host IPv4 in hex, e.g.
/// `K7QX-C0A80105`.
String lanCode(String room, InternetAddress ip) =>
    '$room-${ip.rawAddress.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase()}';

/// Parses a join code. `K7QX-C0A80105` → (room, host IP); `K7QXA` → (room, null)
/// meaning "find it on this network or on the server". Null = invalid.
(String, InternetAddress?)? parseJoinCode(String input) {
  final s = input.trim().toUpperCase().replaceAll(' ', '');
  final m = RegExp(r'^([A-Z0-9]{4,8})(?:-([0-9A-F]{8}))?$').firstMatch(s);
  if (m == null) return null;
  final hex = m.group(2);
  if (hex == null) return (m.group(1)!, null);
  final b = [for (var i = 0; i < 8; i += 2) int.parse(hex.substring(i, i + 2), radix: 16)];
  return (m.group(1)!, InternetAddress('${b[0]}.${b[1]}.${b[2]}.${b[3]}'));
}

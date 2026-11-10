import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/together/data/relay.dart';
import 'package:prism/features/tools/domain/track_matching.dart';

import 'helpers.dart';

void main() {
  test('listen together never sends a local file path, and still matches it', () {
    final song = t(1, title: 'Song', artist: 'Band').copyWith(uri: r'C:\Users\someone\Music\Band - Song.mp3');
    final ref = TrackRef.shared(song);
    final wire = jsonEncode(ref.toJson());
    expect(wire, isNot(contains('someone')));
    expect(wire, isNot(contains('Music')));
    expect(ref.uri, startsWith('h:'));
    // Same file on this PC: exact match even with a different title in the tags.
    final renamed = song.copyWith(title: 'Other');
    expect(TrackMatcher([renamed]).match(ref), renamed);
  });

  test('the relay closes bad or oversized hellos instead of failing', () async {
    final relay = await ListenTogetherRelay.start(port: 0, address: InternetAddress.loopbackIPv4);
    addTearDown(relay.close);
    for (final hello in ['[1,2]', '{"t":"hello","room":5}', 'not json', '{"t":"hello","room":"AB"}']) {
      final ws = await WebSocket.connect('ws://127.0.0.1:${relay.port}/');
      ws.add(hello);
      await ws.drain<void>().timeout(const Duration(seconds: 5));
      expect(ws.closeCode, 4000, reason: hello);
    }
  });
}

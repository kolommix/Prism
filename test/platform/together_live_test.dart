@Tags(['network'])
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/desktop/data/cover_lookup.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/together/data/together_link.dart';
import 'package:prism/features/together/domain/together_protocol.dart';

void main() {
  for (final broker in cloudBrokers) {
    test('public server ${broker.host}: host and guest reach each other', () async {
      final room = randomRoom();
      final host = await CloudLink.connect(room, host: true, broker: broker);
      final guest = await CloudLink.connect(room, host: false, broker: broker);
      addTearDown(host.close);
      addTearDown(guest.close);
      final toHost = host.messages.first;
      final sw = Stopwatch()..start();
      // Subscriptions need a moment; the app pings once a second as well.
      final timer = Timer.periodic(const Duration(milliseconds: 500), (_) => guest.send({'t': 'ping', 'id': 'g'}));
      addTearDown(timer.cancel);
      final got = await toHost.timeout(const Duration(seconds: 10));
      // ignore: avoid_print
      print('${broker.host}: guest -> host in ${sw.elapsedMilliseconds} ms');
      expect(got['id'], 'g');

      final toGuest = guest.messages.first;
      final big = [for (var i = 0; i < 46; i++) {'uri': 'C:/Music/song number $i.mp3', 'title': 'Song number $i', 'artist': 'Artist', 'durationMs': 1}];
      host.send({'t': 'state', 'queue': big});
      final state = await toGuest.timeout(const Duration(seconds: 10));
      expect((state['queue'] as List).length, 46, reason: 'a full queue message fits through');
    }, timeout: const Timeout(Duration(seconds: 40)));
  }

  test('album art lookup finds a known song', () async {
    final lookup = CoverLookup();
    addTearDown(lookup.close);
    final info = await lookup.find(const Track(id: 1, uri: 'x', title: 'Bohemian Rhapsody', artist: 'Queen', durationMs: 354000));
    // ignore: avoid_print
    print('cover: ${info?.coverUrl} | ${info?.title} | ${info?.artist} | ${info?.album}');
    expect(info?.coverUrl, startsWith('https://'));
  });
}

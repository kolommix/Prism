import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/db/app_database.dart';
import 'package:prism/core/providers.dart';
import 'package:prism/features/library/application/library_providers.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/online/application/online_providers.dart';
import 'package:prism/features/player/application/player_controller.dart';
import 'package:prism/features/player/application/player_providers.dart';
import 'package:prism/features/settings/application/settings_controller.dart';
import 'package:prism/features/settings/domain/app_settings.dart';
import 'package:prism/features/together/application/together_controller.dart';
import 'package:prism/features/together/data/mqtt_lite.dart';
import 'package:prism/features/together/data/nearby.dart';
import 'package:prism/features/together/data/together_link.dart';
import 'package:prism/features/together/domain/together_protocol.dart';

import 'player_controller_test.dart' show FakeEngine, MemoryStore;

/// A tiny real MQTT broker on localhost: CONNECT, SUBSCRIBE, PUBLISH fan-out.
class FakeBroker {
  late final ServerSocket _server;
  final _clients = <Socket, Set<String>>{};
  int get port => _server.port;

  Future<void> start() async {
    _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen((s) {
      final decoder = MqttDecoder();
      _clients[s] = {};
      s.done.ignore();
      s.handleError((Object _) {}).listen((chunk) {
        for (final p in decoder.add(chunk)) {
          switch (p.type) {
            case 1:
              s.add(const [0x20, 2, 0, 0]);
            case 8:
              final n = (p.body[2] << 8) | p.body[3];
              _clients[s]!.add(String.fromCharCodes(p.body.sublist(4, 4 + n)));
              s.add([0x90, 3, p.body[0], p.body[1], 0]);
            case 3:
              final n = (p.body[0] << 8) | p.body[1];
              final topic = String.fromCharCodes(p.body.sublist(2, 2 + n));
              for (final e in _clients.entries) {
                if (e.value.contains(topic)) e.key.add(mqttPublish(topic, p.body.sublist(2 + n)));
              }
            case 12:
              s.add(const [0xD0, 0]);
          }
        }
      }, onDone: () => _clients.remove(s), onError: (_) => _clients.remove(s), cancelOnError: true);
    });
  }

  /// Every connection drops, the server stays: what a network hiccup looks like.
  void kickEveryone() {
    for (final s in _clients.keys.toList()) {
      s.destroy();
    }
    _clients.clear();
  }

  Future<void> stop() async {
    kickEveryone();
    await _server.close();
  }
}

void main() {
  group('MQTT packets', () {
    test('remaining length', () {
      expect(encodeRemainingLength(0), [0]);
      expect(encodeRemainingLength(127), [127]);
      expect(encodeRemainingLength(128), [0x80, 1]);
      expect(encodeRemainingLength(16383), [0xFF, 0x7F]);
    });

    test('decoder handles split and joined packets', () {
      final a = mqttPublish('t/a', [1, 2, 3]);
      final big = mqttPublish('t/b', List.filled(300, 7));
      final both = Uint8List.fromList([...a, ...big]);
      final d = MqttDecoder();
      final first = d.add(both.sublist(0, 4));
      final rest = d.add(both.sublist(4, both.length - 10));
      final last = d.add(both.sublist(both.length - 10));
      expect(first, isEmpty);
      expect(rest.length, 1);
      expect(rest.single.type, 3);
      expect(last.length, 1);
      expect(last.single.body.length, 2 + 3 + 300);
    });
  });

  group('scrambled messages', () {
    test('round trip, wrong code gets nothing, nonce changes the bytes', () {
      final a = sealMessage('K7QXA', {'t': 'state', 'song': 'Лето'}, Random(1));
      final b = sealMessage('K7QXA', {'t': 'state', 'song': 'Лето'}, Random(2));
      expect(a, isNot(b));
      expect(String.fromCharCodes(a).contains('state'), isFalse, reason: 'not readable on the wire');
      expect(openMessage('K7QXA', a)?['song'], 'Лето');
      expect(openMessage('WRONG', a), isNull);
      expect(openMessage('K7QXA', const [1, 2]), isNull);
    });

    test('topic does not contain the code, each session and direction differs', () {
      expect(cloudTopic('K7QXA', 'h'), isNot(contains('K7QXA')));
      expect(cloudTopic('K7QXA', 'h'), isNot(cloudTopic('K7QXB', 'h')));
      expect(cloudTopic('K7QXA', 'h'), isNot(cloudTopic('K7QXA', 'g')));
    });
  });

  group('protocol', () {
    test('shared window is around the current song', () {
      expect(sharedWindow(0, 500), (0, 41));
      expect(sharedWindow(100, 500), (95, 141));
      expect(sharedWindow(499, 500), (494, 500));
      expect(sharedWindow(0, 0), (0, 0));
    });

    test('state round trip keeps queue version and people', () {
      const s = SharedState(
        queue: [],
        index: 2,
        positionMs: 1,
        playing: true,
        speed: 1,
        sentAtMs: 2,
        queueVersion: 9,
        hostName: 'Ivan',
        people: ['Max', 'Ann'],
      );
      final back = SharedState.fromJson(s.toJson());
      expect((back.queueVersion, back.hostName), (9, 'Ivan'));
      expect(back.people, ['Max', 'Ann']);
    });

    test('the code says which server the session is on', () {
      for (var broker = 0; broker < 2; broker++) {
        for (var i = 0; i < 50; i++) {
          final room = randomRoomOn(broker, 2, Random(i));
          expect(room, hasLength(5));
          expect(brokerOfRoom(room, 2), broker);
        }
      }
      expect(brokerOfRoom('K7QXA', 1), 0);
      expect(brokerOfRoom('', 2), 0);
      expect(brokerOfRoom('0OOOO', 2), 0, reason: 'characters outside the alphabet');
    });

    test('finds a code in pasted text', () {
      expect(findJoinCode('K7QXA'), 'K7QXA');
      expect(findJoinCode(' join me: K7QXA thanks '), 'K7QXA');
      expect(findJoinCode('K7QX-C0A80105'), isNull, reason: 'old 4-letter LAN room is typed by hand');
      expect(findJoinCode('hello there'), isNull);
      expect(findJoinCode(null), isNull);
    });
  });

  test('host and guest talk through a real MQTT connection', () async {
    final broker = FakeBroker();
    await broker.start();
    addTearDown(broker.stop);
    final cb = CloudBroker('127.0.0.1', broker.port, secure: false);
    final host = await CloudLink.connect('ROOMA', host: true, broker: cb);
    final guest = await CloudLink.connect('ROOMA', host: false, broker: cb);
    final other = await CloudLink.connect('OTHER', host: false, broker: cb);
    final toHost = host.messages.first;
    final toGuest = guest.messages.first;
    var strangerGot = 0;
    other.messages.listen((_) => strangerGot++);
    await Future<void>.delayed(const Duration(milliseconds: 100)); // subscriptions land

    guest.send({'t': 'ping', 'id': 'g1'});
    expect((await toHost.timeout(const Duration(seconds: 3)))['id'], 'g1');
    host.send({'t': 'state', 'pos': 42});
    expect((await toGuest.timeout(const Duration(seconds: 3)))['pos'], 42);
    expect(strangerGot, 0, reason: 'other sessions see nothing');

    await guest.close();
    await other.close();
    await host.close();
    await host.done.timeout(const Duration(seconds: 2));
  });

  group('a whole session through a server', () {
    late FakeBroker broker;
    setUp(() async {
      broker = FakeBroker();
      await broker.start();
    });
    tearDown(() => broker.stop());

    ProviderContainer device(String name, AppDatabase db) {
      final c = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          playerControllerProvider.overrideWithValue(PlayerController(engine: FakeEngine(), store: MemoryStore())),
          initialSettingsProvider.overrideWithValue(AppSettings(togetherName: name)),
          onlineHubProvider.overrideWith((ref) => throw UnimplementedError('no online services')),
          cloudBrokersProvider.overrideWithValue([CloudBroker('127.0.0.1', broker.port, secure: false)]),
          togetherRetryDelayProvider.overrideWithValue(const Duration(milliseconds: 50)),
        ],
      );
      addTearDown(() async {
        await c.read(togetherProvider.notifier).leave();
        c.dispose();
        await db.close();
      });
      return c;
    }

    Future<void> until(bool Function() check, String what) async {
      final sw = Stopwatch()..start();
      while (!check()) {
        if (sw.elapsed > const Duration(seconds: 10)) fail('Timed out waiting for $what');
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    Future<void> addSongs(ProviderContainer c, String folder) => c.read(libraryRepositoryProvider).upsertTracks([
          for (final title in ['One', 'Two'])
            TracksCompanion.insert(
              uri: '$folder/$title.mp3',
              folder: folder,
              title: title,
              artist: const Value('Band'),
              durationMs: const Value(200000),
              searchText: Value(title.toLowerCase()),
            ),
        ]);

    Future<void> addTitles(ProviderContainer c, String folder, List<String> titles) =>
        c.read(libraryRepositoryProvider).upsertTracks([
          for (final title in titles)
            TracksCompanion.insert(
              uri: '$folder/$title.mp3',
              folder: folder,
              title: title,
              artist: const Value('Band'),
              durationMs: const Value(200000),
              searchText: Value(title.toLowerCase()),
            ),
        ]);

    test('both come back after the connection drops, and the guest follows again', () async {
      final host = device('Ivan', AppDatabase(NativeDatabase.memory()));
      final guest = device('Max', AppDatabase(NativeDatabase.memory()));
      await addSongs(host, 'C:/host');
      await addSongs(guest, '/friend');
      final hostPlayer = host.read(playerControllerProvider);
      final guestPlayer = guest.read(playerControllerProvider);
      final songs = await host.read(libraryRepositoryProvider).watchTracks().first;
      await hostPlayer.playTracks(songs, startIndex: 0, shuffle: false);

      await host.read(togetherProvider.notifier).host();
      final code = host.read(togetherProvider).code!;
      expect(code, hasLength(5));
      await guest.read(togetherProvider.notifier).join(code);
      expect(guest.read(togetherProvider).role, TogetherRole.guest, reason: guest.read(togetherProvider).status);
      await until(() => host.read(togetherProvider).people.contains('Max'), 'host to see Max');
      await until(() => guestPlayer.queue.current?.title == 'One', 'guest to play One');

      broker.kickEveryone();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // The next song reaches the guest over the new connections.
      await hostPlayer.playTracks(songs, startIndex: 1, shuffle: false);
      await until(() => guestPlayer.queue.current?.title == 'Two', 'guest to follow after the drop');
      expect(guest.read(togetherProvider).role, TogetherRole.guest);
      await until(() => guest.read(togetherProvider).status == 'Following the host', 'guest status');
      expect(guest.read(togetherProvider).hostName, 'Ivan');

      // Leaving on purpose doesn't come back.
      await guest.read(togetherProvider.notifier).leave();
      await until(() => host.read(togetherProvider).guests == 0, 'host to see Max leave');
      expect(guest.read(togetherProvider).role, TogetherRole.none);
    });

    Future<List<Track>> songsOf(ProviderContainer c) => c.read(libraryRepositoryProvider).watchTracks().first;

    Future<(ProviderContainer, ProviderContainer)> session({
      List<String> hostSongs = const ['One', 'Two'],
      List<String> guestSongs = const ['One', 'Two'],
    }) async {
      final host = device('Ivan', AppDatabase(NativeDatabase.memory()));
      final guest = device('Max', AppDatabase(NativeDatabase.memory()));
      await addTitles(host, 'C:/host', hostSongs);
      await addTitles(guest, '/friend', guestSongs);
      final songs = (await songsOf(host))..sort((a, b) => hostSongs.indexOf(a.title).compareTo(hostSongs.indexOf(b.title)));
      await host.read(playerControllerProvider).playTracks(songs, startIndex: 0, shuffle: false);
      await host.read(togetherProvider.notifier).host();
      await guest.read(togetherProvider.notifier).join(host.read(togetherProvider).code!);
      expect(guest.read(togetherProvider).role, TogetherRole.guest, reason: guest.read(togetherProvider).status);
      await until(() => host.read(togetherProvider).people.contains('Max'), 'host to see Max');
      return (host, guest);
    }

    test('a friend\'s pause, skip and "play next" change the host\'s music', () async {
      final (host, guest) = await session(hostSongs: ['One', 'Two', 'Three'], guestSongs: ['One', 'Two', 'Three']);
      final hostPlayer = host.read(playerControllerProvider);
      final guestPlayer = guest.read(playerControllerProvider);
      await until(() => guestPlayer.queue.current?.title == 'One', 'guest to play One');
      await until(() => guest.read(togetherProvider).control, 'guest to hear control is on');

      await guestPlayer.pause();
      await until(() => !hostPlayer.state.playing, 'host paused by the friend');
      await guestPlayer.play();
      await until(() => hostPlayer.state.playing, 'host playing again');

      await guestPlayer.skipNext();
      await until(() => hostPlayer.queue.current?.title == 'Two', 'host skipped by the friend');
      await until(() => guestPlayer.queue.current?.title == 'Two', 'guest follows');

      final three = (await songsOf(guest)).firstWhere((t) => t.title == 'Three');
      final queueBefore = hostPlayer.queue.tracks.length;
      await guestPlayer.playNext([three]);
      await until(() => hostPlayer.queue.tracks.length == queueBefore + 1, 'song added on the host');
      final next = hostPlayer.queue.tracks[hostPlayer.queue.index + 1];
      expect(next.title, 'Three');
      expect(next.uri, startsWith('C:/host'), reason: 'the host plays its own copy');
      expect(host.read(togetherProvider).notice, contains('Max'));
    });

    test('with control off, a friend\'s buttons change nothing and say why', () async {
      final (host, guest) = await session();
      final hostPlayer = host.read(playerControllerProvider);
      final guestPlayer = guest.read(playerControllerProvider);
      host.read(togetherProvider.notifier).setGuestControl(false);
      await until(() => !guest.read(togetherProvider).control, 'guest to hear control is off');
      final noticeBefore = guest.read(togetherProvider).noticeId;
      await guestPlayer.skipNext();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(hostPlayer.queue.current?.title, 'One');
      expect(guest.read(togetherProvider).noticeId, greaterThan(noticeBefore));
      expect(guest.read(togetherProvider).notice, contains('Ivan'));
    });

    test('everyone sees who is missing the song', () async {
      final (host, guest) = await session(hostSongs: ['One', 'Secret'], guestSongs: ['One']);
      final hostPlayer = host.read(playerControllerProvider);
      await hostPlayer.skipNext();
      await until(
        () => host.read(togetherProvider).who.any((p) => p.name == 'Max' && p.status == PersonStatus.missing),
        'host to see Max missing the song',
      );
      await until(() => guest.read(togetherProvider).missingSong != null, 'guest to say what is missing');
      await hostPlayer.jumpTo(0);
      await until(
        () => host.read(togetherProvider).who.any((p) => p.name == 'Max' && p.status == PersonStatus.listening),
        'host to see Max listening again',
      );
    });

    test('leaving gives the player its own buttons back', () async {
      final (host, guest) = await session();
      final guestPlayer = guest.read(playerControllerProvider);
      expect(guestPlayer.remote, isNotNull);
      await guest.read(togetherProvider.notifier).leave();
      expect(guestPlayer.remote, isNull);
      expect(host.read(togetherProvider).role, TogetherRole.host);
    });
  });

  test('nearby: a beacon shows up in the scanner and goes away', () async {
    final scanner = await NearbyScanner.start();
    if (scanner == null) return markTestSkipped('port $nearbyPort is busy');
    addTearDown(scanner.stop);
    final beacon = await NearbyBeacon.start(room: 'NEARB', name: 'Test PC', song: () => 'Song');
    if (beacon == null) return markTestSkipped('no network');
    addTearDown(beacon.stop);
    final found = await scanner.sessions.first.timeout(
      const Duration(seconds: 5),
      onTimeout: () => const <NearbySession>[],
    );
    if (found.isEmpty) return markTestSkipped('UDP broadcast is blocked on this machine');
    expect((found.first.room, found.first.name, found.first.song), ('NEARB', 'Test PC', 'Song'));
  });
}

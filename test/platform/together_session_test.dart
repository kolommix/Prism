@Tags(['network'])
library;

import 'dart:io';

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

import '../player_controller_test.dart' show FakeEngine, MemoryStore;

/// A whole Prism minus the UI: real controllers, real database, fake audio.
class _Device {
  _Device(this.name, {bool internet = true}) {
    db = AppDatabase(NativeDatabase.memory());
    player = PlayerController(engine: FakeEngine(), store: MemoryStore());
    c = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        playerControllerProvider.overrideWithValue(player),
        initialSettingsProvider.overrideWithValue(AppSettings(togetherName: name, togetherInternet: internet)),
        onlineHubProvider.overrideWith((ref) => throw UnimplementedError('no online services here')),
      ],
    );
  }

  final String name;
  late final AppDatabase db;
  late final PlayerController player;
  late final ProviderContainer c;

  TogetherController get together => c.read(togetherProvider.notifier);
  TogetherState get state => c.read(togetherProvider);

  Future<void> addSongs(List<Track> tracks) => c.read(libraryRepositoryProvider).upsertTracks([
        for (final t in tracks)
          TracksCompanion.insert(
            uri: t.uri,
            folder: '/music',
            title: t.title,
            artist: Value(t.artist),
            durationMs: Value(t.durationMs),
            searchText: Value(t.title.toLowerCase()),
          ),
      ]);

  Future<List<Track>> songs() => c.read(libraryRepositoryProvider).watchTracks().first;

  Future<void> close() async {
    await together.leave();
    c.dispose();
    await db.close();
  }
}

Future<void> until(bool Function() check, {String? what, Duration limit = const Duration(seconds: 15)}) async {
  final sw = Stopwatch()..start();
  while (!check()) {
    if (sw.elapsed > limit) fail('Timed out waiting for ${what ?? 'condition'}');
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

void main() {
  const songs = [
    Track(id: 0, uri: 'C:/host/one.mp3', title: 'One', artist: 'Band', durationMs: 200000),
    Track(id: 0, uri: 'C:/host/two.mp3', title: 'Two', artist: 'Band', durationMs: 180000),
  ];
  // The same songs in a different place, as on a friend's PC.
  const friendSongs = [
    Track(id: 0, uri: '/friend/Music/one.mp3', title: 'One', artist: 'Band', durationMs: 200500),
    Track(id: 0, uri: '/friend/Music/two.mp3', title: 'Two', artist: 'Band', durationMs: 180000),
  ];

  Future<void> session({required Future<void> Function(_Device host, _Device guest) joinUp, bool internet = true}) async {
    final host = _Device('Ivan', internet: internet);
    final guest = _Device('Max', internet: internet);
    addTearDown(guest.close);
    addTearDown(host.close);
    await host.addSongs(songs);
    await guest.addSongs(friendSongs);

    await host.player.playTracks(await host.songs(), startIndex: 0, shuffle: false);
    await host.together.host();
    expect(host.state.role, TogetherRole.host, reason: host.state.status);

    await joinUp(host, guest);
    expect(guest.state.role, TogetherRole.guest, reason: guest.state.status);

    // Both see each other by name.
    await until(() => host.state.people.contains('Max'), what: 'host to see the guest');
    await until(() => guest.state.hostName == 'Ivan', what: 'guest to see the host');
    expect(host.state.guests, 1);

    // The guest plays its own copy of the host's song.
    await until(() => guest.player.queue.current?.uri == '/friend/Music/one.mp3', what: 'guest to start the song');

    // The host changes the song: the guest follows.
    final hostSongs = await host.songs();
    await host.player.playTracks(hostSongs, startIndex: hostSongs.indexWhere((t) => t.title == 'Two'), shuffle: false);
    await until(() => guest.player.queue.current?.uri == '/friend/Music/two.mp3', what: 'guest to follow the next song');

    // Leaving tells the host right away, ending tells the guest.
    await guest.together.leave();
    await until(() => host.state.guests == 0, what: 'host to see the guest leave');
  }

  test('over the public server: typing the short code is all it takes', () async {
    await session(joinUp: (host, guest) async {
      expect(host.state.overInternet, isTrue);
      expect(host.state.code, hasLength(5), reason: 'short code');
      await guest.together.join(host.state.code!);
    });
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('on the same network without any server', () async {
    await session(
      internet: false,
      joinUp: (host, guest) async {
        expect(host.state.overInternet, isFalse);
        await guest.together.join(host.state.code!.split('-').first, direct: InternetAddress.loopbackIPv4);
      },
    );
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('a wrong code says so instead of hanging', () async {
    final guest = _Device('Max');
    addTearDown(guest.close);
    await guest.together.join('ZZZZZ');
    expect(guest.state.role, TogetherRole.none);
    expect(guest.state.status, contains('No session'));
    expect(guest.state.error, isTrue);
  }, timeout: const Timeout(Duration(minutes: 1)));

  test('when the host ends the session the guest is told', () async {
    final host = _Device('Ivan');
    final guest = _Device('Max');
    addTearDown(guest.close);
    addTearDown(host.close);
    await host.addSongs(songs);
    await guest.addSongs(friendSongs);
    await host.player.playTracks(await host.songs(), startIndex: 0, shuffle: false);
    await host.together.host();
    await guest.together.join(host.state.code!);
    expect(guest.state.connected, isTrue);
    await host.together.leave();
    await until(() => guest.state.role == TogetherRole.none, what: 'guest to be told');
    expect(guest.state.status, contains('ended'));
  }, timeout: const Timeout(Duration(minutes: 1)));
}

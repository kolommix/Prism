@Tags(['audio'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/sources/track_source.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/player/engine/just_audio_deck_engine.dart';
import 'package:prism/features/player/engine/playback_engine.dart';

import '../support/wav.dart';

class _FileSource extends TrackSource {
  @override
  String get id => 'local';
  @override
  String get displayName => 'test';
  @override
  Set<TrackSourceCapability> get capabilities => const {};
  @override
  Future<Uri> resolvePlaybackUri(Track track) async => Uri.file(track.uri);
  @override
  Future<List<Track>> search(String query, {int limit = 50}) async => const [];
}

/// A song that can't be opened (gone, or held by another program for a
/// moment, like an antivirus scan of a just-saved import) must never jam the
/// player: the engine says "failed" (the controller skips it) and the next
/// song still plays. Before the fix mpv's open error left `setAudioSources`
/// waiting forever and every later command queued behind it.
///
/// Run: flutter test --tags audio test/platform/engine_unplayable_test.dart
void main() {
  final dll = p.absolute('windows/third_party/libmpv/libmpv-2.dll');
  final skip = Platform.isWindows && File(dll).existsSync() ? null : 'Windows + full libmpv only';
  late Directory dir;
  late Track good;
  final sources = TrackSourceRegistry([_FileSource()]);

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    JustAudioMediaKit.pitch = false;
    JustAudioMediaKit.prefetchPlaylist = true;
    JustAudioMediaKit.ensureInitialized(windows: true, libmpv: dll);
    await JustAudioMediaKit.setGlobalProperty('ao', 'null');
    dir = await Directory.systemTemp.createTemp('prism_unplayable_');
    final input = p.join(dir.path, 'good.wav');
    writeWav(input, tones([440], seconds: 2, sampleRate: 48000));
    good = Track(id: 1, uri: input, title: 'good', durationMs: 2000);
  });
  tearDownAll(() => dir.delete(recursive: true));

  Future<void> expectStillPlays(JustAudioDeckEngine engine) async {
    final ended = engine.events.firstWhere((e) => e == EngineEvent.ended).timeout(const Duration(seconds: 20));
    await engine.load(good).timeout(const Duration(seconds: 20), onTimeout: () => fail('the next load never finished'));
    await ended;
  }

  test('a missing file fails and the next one plays', () async {
    final engine = JustAudioDeckEngine(sources: sources);
    final missing = Track(id: 2, uri: p.join(dir.path, 'gone.m4a'), title: 'gone', durationMs: 2000);
    final failed = engine.events.firstWhere((e) => e == EngineEvent.failed).timeout(const Duration(seconds: 20));
    unawaited(engine.load(missing, next: good));
    await failed;
    await expectStillPlays(engine);
    await engine.dispose();
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('a file locked by another program fails (or plays once free), never jams', () async {
    final engine = JustAudioDeckEngine(sources: sources);
    final lockedPath = p.join(dir.path, 'locked.wav');
    writeWav(lockedPath, tones([880], seconds: 2, sampleRate: 48000));
    final raf = await File(lockedPath).open(mode: FileMode.append);
    await raf.lock(FileLock.blockingExclusive);
    final locked = Track(id: 3, uri: lockedPath, title: 'locked', durationMs: 2000);
    final outcome = engine.events
        .firstWhere((e) => e == EngineEvent.failed || e == EngineEvent.ended)
        .timeout(const Duration(seconds: 25));
    unawaited(engine.load(locked));
    // Like an antivirus scan: free again after a moment.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    await raf.unlock();
    await raf.close();
    // ignore: avoid_print
    print('locked file: ${await outcome}');
    await expectStillPlays(engine);
    await engine.dispose();
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}

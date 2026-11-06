@Tags(['audio', 'network'])
library;

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/sources/track_source.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/online/data/stream_proxy.dart';
import 'package:prism/features/online/domain/external_track.dart';
import 'package:prism/features/online/domain/online_error.dart';
import 'package:prism/features/player/engine/just_audio_deck_engine.dart';
import 'package:prism/features/player/engine/playback_engine.dart';
import 'package:prism/features/online/services/youtube/explode_backend.dart';
import 'package:prism/features/online/services/youtube/youtube_module.dart';

import '../support/wav.dart';

/// Plays through the YouTube module (extractor) like `RemoteTrackSource`.
class _YtSource extends TrackSource {
  _YtSource(this.module);
  final YoutubeModule module;
  @override
  String get id => youtubeSourceId;
  @override
  String get displayName => 'YouTube';
  @override
  Set<TrackSourceCapability> get capabilities => const {};
  @override
  Future<Uri> resolvePlaybackUri(Track track) => module.streamUri(track);
  @override
  Future<List<Track>> search(String query, {int limit = 50}) => module.search(query, limit: limit);
}

/// Real network + real libmpv: search YouTube, resolve the audio stream and
/// play it through the actual `JustAudioDeckEngine`; mpv's output goes to a
/// WAV (`ao=pcm`) that must contain sound. A removed video must be reported
/// as `failed` with an [OnlineException], not crash.
///
/// Run: flutter test --tags network test/platform/youtube_stream_test.dart
void main() {
  final dll = p.absolute('windows/third_party/libmpv/libmpv-2.dll');
  final skip = Platform.isWindows && File(dll).existsSync() ? null : 'Windows + full libmpv only';
  late Directory dir;
  final module = YoutubeModule(catalog: ExplodeBackend(), streamer: ExplodeBackend(), proxy: StreamProxy());
  final sources = TrackSourceRegistry([_YtSource(module)]);

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    JustAudioMediaKit.pitch = false;
    JustAudioMediaKit.prefetchPlaylist = true;
    JustAudioMediaKit.ensureInitialized(windows: true, libmpv: dll);
    await JustAudioMediaKit.setGlobalProperty('ytdl', 'no');
    dir = await Directory.systemTemp.createTemp('prism_yt_');
  });
  tearDownAll(() => dir.delete(recursive: true));

  test('search → stream → audible output', () async {
    final found = await module.search('Daft Punk One More Time audio', limit: 5);
    expect(found, isNotEmpty);
    final track = found.first.copyWith(id: 1);
    final out = p.join(dir.path, 'yt.wav');
    await JustAudioMediaKit.setGlobalProperty('ao', 'pcm');
    await JustAudioMediaKit.setGlobalProperty('ao-pcm-file', out);
    final engine = JustAudioDeckEngine(sources: sources);
    final sw = Stopwatch()..start();
    await engine.load(track);
    await engine.stateStream
        .firstWhere((s) => s.position > const Duration(seconds: 4))
        .timeout(const Duration(seconds: 40));
    final startup = sw.elapsedMilliseconds;
    await engine.dispose();
    final pcm = readWav(out);
    final rms = math.sqrt(pcm.samples.fold<double>(0, (a, s) => a + s * s) / math.max(1, pcm.samples.length));
    // ignore: avoid_print
    print('"${track.title}" by ${track.artist}: ${pcm.samples.length / pcm.sampleRate} s rendered, '
        'rms ${rms.toStringAsFixed(3)}, $startup ms until 4 s played');
    expect(pcm.samples.length / pcm.sampleRate, greaterThan(3));
    expect(rms, greaterThan(0.01));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('removed video → failed event with a clear reason', () async {
    final engine = JustAudioDeckEngine(sources: sources);
    final failed = engine.events.firstWhere((e) => e == EngineEvent.failed).timeout(const Duration(seconds: 60));
    await engine.load(const Track(id: 2, sourceId: 'youtube', uri: 'https://www.youtube.com/watch?v=aaaaaaaaaaa', title: 'gone'));
    await failed;
    expect(engine.lastError, isA<OnlineException>().having((e) => e.service, 'service', OnlineService.youtube));
    await engine.dispose();
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}

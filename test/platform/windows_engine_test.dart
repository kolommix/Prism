@Tags(['audio'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/sources/track_source.dart';
import 'package:prism/features/audio_fx/domain/eq_math.dart';
import 'package:prism/features/audio_fx/domain/eq_settings.dart';
import 'package:prism/features/audio_fx/platform/mpv_audio_effects.dart';
import 'package:prism/features/editor/domain/edit_decision_list.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/player/domain/playback_plan.dart';
import 'package:prism/features/player/engine/just_audio_deck_engine.dart';
import 'package:prism/features/player/engine/playback_engine.dart';

import '../support/wav.dart';

/// Plays files straight from disk.
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

/// End-to-end on Windows: the real JustAudioDeckEngine + MpvAudioEffects on
/// the bundled full libmpv. mpv's audio output is redirected to a WAV file
/// (`ao=pcm`), which we then measure.
///
/// Run: flutter test --tags audio test/platform/windows_engine_test.dart
void main() {
  final dll = p.absolute('windows/third_party/libmpv/libmpv-2.dll');
  final skip = Platform.isWindows && File(dll).existsSync() ? null : 'Windows + full libmpv only';
  late Directory dir;
  late Track track;
  final sources = TrackSourceRegistry([_FileSource()]);

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    JustAudioMediaKit.pitch = false;
    JustAudioMediaKit.prefetchPlaylist = true;
    JustAudioMediaKit.ensureInitialized(windows: true, libmpv: dll);
    dir = await Directory.systemTemp.createTemp('prism_engine_');
    final input = p.join(dir.path, 'in.wav');
    writeWav(input, tones([100, 1000, 8000], seconds: 6, sampleRate: 48000));
    track = Track(id: 1, uri: input, title: 'tones', durationMs: 6000);
  });
  tearDownAll(() => dir.delete(recursive: true));

  /// Plays [track] through a fresh engine into a WAV and returns it.
  Future<Pcm> render(
    String name, {
    EqSettings eq = const EqSettings(),
    PlaybackPlan plan = PlaybackPlan.plain,
    double speed = 1,
    double pitch = 0,
  }) async {
    final out = p.join(dir.path, '$name.wav');
    await JustAudioMediaKit.setGlobalProperty('ao', 'pcm');
    await JustAudioMediaKit.setGlobalProperty('ao-pcm-file', out);
    final effects = MpvAudioEffects();
    await effects.setEq(eq);
    final engine = JustAudioDeckEngine(sources: sources, effects: effects, planFor: (_) async => plan);
    await engine.setSpeed(speed);
    await engine.setPitchSemitones(pitch);
    await Future<void>.delayed(const Duration(milliseconds: 300)); // debounced af
    final ended = engine.events.firstWhere((e) => e == EngineEvent.ended).timeout(const Duration(seconds: 30));
    await engine.load(track);
    await ended;
    await engine.dispose(); // closes the AO → WAV header written
    return readWav(out);
  }

  test('EQ changes the sound exactly like the shared model says', () async {
    final flat = await render('flat');
    final eq = const EqSettings(enabled: true).withBand(0, 9).withBand(5, -9).withBand(8, 6);
    final eqd = await render('eq', eq: eq);
    for (final f in [100.0, 1000.0, 8000.0]) {
      final measured = toneDb(eqd, f) - toneDb(flat, f);
      final model = eqResponseDb(eq, f, includePreamp: false, sampleRate: 48000);
      // ignore: avoid_print
      print('EQ ${f.round()} Hz: model ${model.toStringAsFixed(2)} dB, measured ${measured.toStringAsFixed(2)} dB');
      expect(measured, closeTo(model, 0.6), reason: '$f Hz');
    }
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('pitch +12 st moves 1 kHz to 2 kHz, speed stays', () async {
    final pcm = await render('pitch', pitch: 12);
    final plain = await render('pitch_ref');
    // Rubberband's phase vocoder smears a pure sine over neighbouring bins,
    // so also check the overall level stays close to the original.
    var peak2k = -999.0;
    for (var f = 1950.0; f <= 2050; f += 5) {
      final v = toneDb(pcm, f);
      if (v > peak2k) peak2k = v;
    }
    // ignore: avoid_print
    print('pitch: len=${(pcm.samples.length / pcm.sampleRate).toStringAsFixed(2)} s, '
        '1k=${toneDb(pcm, 1000).toStringAsFixed(1)} 2k=${toneDb(pcm, 2000).toStringAsFixed(1)} '
        'peak≈2k=${peak2k.toStringAsFixed(1)} rms=${rmsDb(pcm).toStringAsFixed(1)} vs ${rmsDb(plain).toStringAsFixed(1)}');
    expect(rmsDb(pcm), closeTo(rmsDb(plain), 3), reason: 'pitch shift keeps the level');
    expect(toneDb(pcm, 2000), greaterThan(toneDb(pcm, 1000) + 15));
    expect(pcm.samples.length / pcm.sampleRate, closeTo(6, 0.4));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('speed 1.5x keeps pitch and shortens playback', () async {
    final pcm = await render('speed', speed: 1.5);
    final len = pcm.samples.length / pcm.sampleRate;
    // ignore: avoid_print
    print('speed: len=${len.toStringAsFixed(2)} s, 1k=${toneDb(pcm, 1000).toStringAsFixed(1)}');
    expect(len, closeTo(4, 0.4));
    expect(toneDb(pcm, 1000), greaterThan(toneDb(pcm, 1500) + 15), reason: 'pitch preserved');
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('live edit preset: cut + gain −6 dB through the real clip plan', () async {
    final plain = await render('plain');
    // Output: source 0–2 s, then source 4–6 s at −6 dB  → 4 s.
    final plan = const EditDecisionList(sourceUri: '', sourceDurationMs: 6000, ops: [
      EditOp.cut(startMs: 2000, endMs: 4000),
      EditOp.gain(startMs: 2000, endMs: 4000, db: -6),
    ]).build().toPlan();
    final pcm = await render('live', plan: plan);
    final len = pcm.samples.length / pcm.sampleRate;
    final quiet = toneDb(slice(pcm, 2.6, 3.6), 1000) - toneDb(slice(plain, 2.6, 3.6), 1000);
    // ignore: avoid_print
    print('live preset: len=${len.toStringAsFixed(2)} s, second clip ${quiet.toStringAsFixed(2)} dB');
    expect(len, closeTo(4, 0.4));
    expect(quiet, closeTo(-6, 1));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));
}

@Tags(['audio'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/ffmpeg/ffmpeg_runner.dart';
import 'package:prism/features/editor/data/peak_cache.dart';
import 'package:prism/features/editor/domain/edit_decision_list.dart';
import 'package:prism/features/editor/domain/export_command.dart';
import 'package:prism/features/editor/domain/timeline.dart';

import '../support/wav.dart';

/// Every new editor feature rendered by the real ffmpeg.exe and measured.
/// Run: flutter test --tags audio test/platform/editor_v2_export_test.dart
void main() {
  final exe = p.absolute('windows/third_party/ffmpeg/ffmpeg.exe');
  final skip = File(exe).existsSync() ? null : 'needs windows/third_party/ffmpeg/ffmpeg.exe';
  late Directory dir;
  late String input, other;
  final ff = ProcessFfmpegRunner(exe);

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('prism_editor_');
    input = p.join(dir.path, 'in.wav');
    other = p.join(dir.path, 'other.wav');
    writeWav(input, tones([1000], seconds: 12, sampleRate: 48000, amplitude: 0.3));
    writeWav(other, tones([500], seconds: 4, sampleRate: 48000, amplitude: 0.3));
  });
  tearDownAll(() => dir.delete(recursive: true));

  Future<Pcm> render(List<EditOp> ops, String name, {PitchEngine engine = PitchEngine.resample}) async {
    final t = Timeline.fromOps(const Duration(seconds: 12), ops);
    final out = p.join(dir.path, '$name.wav');
    final res = await ff.run(buildExportArgs(timeline: t, input: input, output: out, format: ExportFormat.wav, pitchEngine: engine));
    expect(res.ok, isTrue, reason: res.log);
    final pcm = readWav(out);
    expect(pcm.samples.length / pcm.sampleRate, closeTo(t.duration.inMilliseconds / 1000, 0.1), reason: 'file length = timeline');
    return pcm;
  }

  test('delete leaves real silence, later audio in place', () async {
    final pcm = await render(const [EditOp.silence(startMs: 4000, endMs: 6000)], 'gap');
    expect(rmsDb(slice(pcm, 4.2, 5.8)), lessThan(-80));
    expect(toneDb(slice(pcm, 7, 8), 1000), greaterThan(-20));
  }, skip: skip);

  test('duplicate + loop lengths', () async {
    await render(const [EditOp.duplicate(startMs: 2000, endMs: 4000)], 'dup');
    await render(const [EditOp.loop(startMs: 2000, endMs: 3000, times: 4)], 'loop');
  }, skip: skip);

  test('reverse of a rising tone falls', () async {
    final rising = p.join(dir.path, 'rising.wav');
    final a = tones([500], seconds: 2, sampleRate: 48000, amplitude: 0.3);
    final b = tones([2000], seconds: 2, sampleRate: 48000, amplitude: 0.3);
    final joined = Pcm(Float64List.fromList([...a.samples, ...b.samples]), 48000);
    writeWav(rising, joined);
    const t = Timeline(segments: [Segment(sourceStart: Duration.zero, sourceEnd: Duration(seconds: 4), reverse: true)]);
    final out = p.join(dir.path, 'rev.wav');
    final res = await ff.run(buildExportArgs(timeline: t, input: rising, output: out, format: ExportFormat.wav, pitchEngine: PitchEngine.resample));
    expect(res.ok, isTrue, reason: res.log);
    final pcm = readWav(out);
    expect(toneDb(slice(pcm, 0.5, 1.5), 2000), greaterThan(toneDb(slice(pcm, 0.5, 1.5), 500) + 20));
    expect(toneDb(slice(pcm, 2.5, 3.5), 500), greaterThan(toneDb(slice(pcm, 2.5, 3.5), 2000) + 20));
  }, skip: skip);

  test('speed ramp from 1x to 4x: file length matches the timeline', () async {
    await render(const [EditOp.ramp(startMs: 0, endMs: 12000, from: 1, to: 4)], 'ramp');
  }, skip: skip);

  test('speed range limits 0.25x and 4x', () async {
    await render(const [EditOp.speed(startMs: 0, endMs: 2000, factor: 0.25)], 'slow');
    await render(const [EditOp.speed(startMs: 0, endMs: 4000, factor: 4)], 'fast');
  }, skip: skip);

  test('crossfade with each curve', () async {
    for (final c in FadeCurve.values) {
      await render([const EditOp.split(atMs: 6000), EditOp.crossfade(segment: 0, ms: 1000, curve: c.name)], 'xf_${c.name}');
    }
  }, skip: skip);

  test('crossfade next to a plain join', () async {
    await render(const [EditOp.split(atMs: 4000), EditOp.split(atMs: 8000), EditOp.crossfade(segment: 1, ms: 500)], 'mixed');
  }, skip: skip);

  test('segment fades: quiet at the edge', () async {
    final pcm = await render(const [EditOp.segmentFade(startMs: 0, endMs: 6000, inMs: 1000, outMs: 1000, curve: 'smooth')], 'segfade');
    expect(rmsDb(slice(pcm, 0, 0.05)), lessThan(rmsDb(slice(pcm, 3, 4)) - 20));
  }, skip: skip);

  test('segment EQ cuts the band it should', () async {
    final pcm = await render(const [EditOp.segmentEq(startMs: 0, endMs: 6000, lowDb: 0, midDb: -12, highDb: 0)], 'eq');
    expect(toneDb(slice(pcm, 1, 5), 1000), lessThan(toneDb(slice(pcm, 7, 11), 1000) - 8));
  }, skip: skip);

  test('noise gate really closes on what is under its level', () async {
    // The tone peaks at about -10 dB: a gate at -6 dB shuts it, and only there.
    final pcm = await render(const [EditOp.gate(startMs: 0, endMs: 6000, db: -6)], 'gate');
    expect(rmsDb(slice(pcm, 1, 5)), lessThan(rmsDb(slice(pcm, 7, 11)) - 30));
  }, skip: skip);

  test('master gain and loudness', () async {
    await render(const [EditOp.masterGain(db: -6), EditOp.loudness(lufs: -20)], 'loud');
  }, skip: skip);

  test('merge joins two files, each with its own tone', () async {
    final t = Timeline.fromOps(const Duration(seconds: 12), [EditOp.merge(uri: other, durationMs: 4000)]);
    final out = p.join(dir.path, 'merged.wav');
    final res = await ff.run(buildExportArgs(timeline: t, input: input, output: out, format: ExportFormat.wav, pitchEngine: PitchEngine.resample));
    expect(res.ok, isTrue, reason: res.log);
    final pcm = readWav(out);
    expect(pcm.samples.length / pcm.sampleRate, closeTo(16, 0.1));
    expect(toneDb(slice(pcm, 13, 15), 500), greaterThan(toneDb(slice(pcm, 13, 15), 1000) + 20));
  }, skip: skip);

  for (final (format, st) in [
    (ExportFormat.mp3, const ExportSettings(mp3Vbr: false, mp3Kbps: 192)),
    (ExportFormat.mp3, const ExportSettings(mp3VbrQuality: 4)),
    (ExportFormat.m4a, const ExportSettings(m4aKbps: 128)),
    (ExportFormat.wav, const ExportSettings(wavBits: 24)),
    (ExportFormat.flac, const ExportSettings(flacLevel: 8, tags: {'title': 'T', 'artist': 'A'})),
  ]) {
    test('encodes ${format.name} with settings', () async {
      final out = p.join(dir.path, 'enc_${format.name}_${st.hashCode}.${format.extension}');
      final res = await ff.run(buildExportArgs(
        timeline: Timeline.initial(const Duration(seconds: 12)),
        input: input,
        output: out,
        format: format,
        pitchEngine: PitchEngine.resample,
        settings: st,
      ));
      expect(res.ok, isTrue, reason: res.log);
      expect(File(out).lengthSync(), greaterThan(10000));
    }, skip: skip);
  }

  test('cancel stops FFmpeg', () async {
    final out = p.join(dir.path, 'cancel.wav');
    final cancel = FfmpegCancel();
    final run = ff.run(
      ['-y', '-f', 'lavfi', '-i', 'sine=frequency=440:duration=36000', '-c:a', 'pcm_s16le', out],
      cancel: cancel,
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    cancel.cancel();
    final res = await run.timeout(const Duration(seconds: 10));
    expect(res.ok, isFalse);
  }, skip: skip);

  test('peak cache: decodes once, then reads from disk', () async {
    final cache = PeakCache(Directory(p.join(dir.path, 'peaks')), ff);
    final first = await cache.load(input);
    expect(first!.pyramid.duration.inMilliseconds, closeTo(12000, 50));
    expect(first.pyramid.peak(1, 2), closeTo(0.3, 0.02));
    final files = Directory(p.join(dir.path, 'peaks')).listSync();
    expect(files.length, 1);
    // No FFmpeg needed the second time.
    final second = await PeakCache(Directory(p.join(dir.path, 'peaks')), null).load(input);
    expect(second!.pyramid.duration, first.pyramid.duration);
  }, skip: skip);
}

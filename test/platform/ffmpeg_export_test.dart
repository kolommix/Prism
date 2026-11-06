@Tags(['audio'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/ffmpeg/ffmpeg_runner.dart';
import 'package:prism/features/audio_fx/domain/loudness.dart';
import 'package:prism/features/editor/domain/edit_decision_list.dart';
import 'package:prism/features/editor/domain/export_command.dart';

import '../support/wav.dart';

/// Renders real edits with the bundled ffmpeg.exe and measures the result.
/// Run: flutter test --tags audio test/platform/ffmpeg_export_test.dart
void main() {
  final exe = p.absolute('windows/third_party/ffmpeg/ffmpeg.exe');
  final skip = File(exe).existsSync() ? null : 'needs windows/third_party/ffmpeg/ffmpeg.exe';
  late Directory dir;
  late String input;
  final ff = ProcessFfmpegRunner(exe);

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('prism_export_');
    input = p.join(dir.path, 'in.wav');
    writeWav(input, tones([1000], seconds: 12, sampleRate: 48000, amplitude: 0.3));
  });
  tearDownAll(() => dir.delete(recursive: true));

  // Output timeline (seconds):
  //  cut source 2–4            → 10 s left
  //  output 4–6  at 2x speed   → 1 s  (source 6–8)   total 9 s
  //  output 5–7  pitch +12 st  → source 8–10 is one octave up (2 kHz)
  //  output 7–9  gain −6 dB    → source 10–12 is 6 dB quieter
  const edl = EditDecisionList(sourceUri: '', sourceDurationMs: 12000, ops: [
    EditOp.cut(startMs: 2000, endMs: 4000),
    EditOp.speed(startMs: 4000, endMs: 6000, factor: 2),
    EditOp.pitch(startMs: 5000, endMs: 7000, semitones: 12),
    EditOp.gain(startMs: 7000, endMs: 9000, db: -6),
  ]);

  for (final engine in PitchEngine.values) {
    test('wav render with ${engine.name}: length, pitch and gain are applied', () async {
      final out = p.join(dir.path, 'out_${engine.name}.wav');
      final t = edl.build();
      final res = await ff.run(buildExportArgs(
        timeline: t,
        input: input,
        output: out,
        format: ExportFormat.wav,
        pitchEngine: engine,
      ));
      expect(res.ok, isTrue, reason: res.tail);
      final pcm = readWav(out);
      final len = pcm.samples.length / pcm.sampleRate;
      expect(len, closeTo(t.duration.inMilliseconds / 1000, 0.08), reason: 'output length = timeline');

      final normal = toneDb(slice(pcm, 0.5, 1.5), 1000);
      final pitched = slice(pcm, 5.3, 6.7);
      final quiet = slice(pcm, 7.3, 8.7);
      // ignore: avoid_print
      print('${engine.name}: len=${len.toStringAsFixed(3)} 1k=${normal.toStringAsFixed(1)} '
          'pitched 1k=${toneDb(pitched, 1000).toStringAsFixed(1)} 2k=${toneDb(pitched, 2000).toStringAsFixed(1)} '
          'quiet=${toneDb(quiet, 1000).toStringAsFixed(1)}');
      expect(toneDb(pitched, 2000), greaterThan(toneDb(pitched, 1000) + 20), reason: 'octave up');
      expect(toneDb(quiet, 1000) - normal, closeTo(-6, 0.5), reason: '−6 dB segment');
    }, skip: skip);
  }

  test('fades: silent at the very start, full level later', () async {
    final out = p.join(dir.path, 'fade.wav');
    final t = const EditDecisionList(sourceUri: '', sourceDurationMs: 12000, ops: [
      EditOp.fadeIn(durationMs: 2000),
      EditOp.fadeOut(durationMs: 2000),
    ]).build();
    final res = await ff.run(buildExportArgs(
        timeline: t, input: input, output: out, format: ExportFormat.wav, pitchEngine: PitchEngine.rubberband));
    expect(res.ok, isTrue, reason: res.tail);
    final pcm = readWav(out);
    expect(rmsDb(slice(pcm, 0, 0.1)), lessThan(rmsDb(slice(pcm, 5, 6)) - 25));
    expect(rmsDb(slice(pcm, 11.9, 12)), lessThan(rmsDb(slice(pcm, 5, 6)) - 25));
  }, skip: skip);

  for (final format in [ExportFormat.mp3, ExportFormat.m4a]) {
    test('encodes ${format.name}', () async {
      final out = p.join(dir.path, 'enc.${format.extension}');
      final res = await ff.run(buildExportArgs(
          timeline: edl.build(), input: input, output: out, format: format, pitchEngine: PitchEngine.resample, title: 'T'));
      expect(res.ok, isTrue, reason: res.tail);
      expect(File(out).lengthSync(), greaterThan(10000));
    }, skip: skip);
  }

  test('ebur128 loudness measurement parses', () async {
    final res = await ff.run(['-nostats', '-i', input, '-af', 'ebur128=peak=true', '-f', 'null', '-']);
    final m = parseEbur128Summary(res.log);
    expect(m, isNotNull, reason: res.tail);
    // 0.3 amplitude 1 kHz sine ≈ −10.5 dBFS RMS → about −13.5 LUFS, peak ≈ −10.5 dBTP.
    expect(m!.integratedLufs, inInclusiveRange(-16, -11));
    expect(m.truePeakDb, closeTo(-10.5, 1));
  }, skip: skip);
}

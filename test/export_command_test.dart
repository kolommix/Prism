import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/editor/domain/edit_decision_list.dart';
import 'package:prism/features/editor/domain/export_command.dart';
import 'package:prism/features/editor/domain/timeline.dart';

void main() {
  const src = Duration(seconds: 60);
  Timeline run(List<EditOp> ops) => Timeline.fromOps(src, ops);

  test('atempo chains below 0.5 and skips 1.0', () {
    expect(atempoChain(1), isEmpty);
    expect(atempoChain(1.5), ['atempo=1.5']);
    expect(atempoChain(0.25), ['atempo=0.5', 'atempo=0.5']);
    expect(atempoChain(4), ['atempo=4']);
  });

  test('pitch: rubberband ratio vs resample fallback', () {
    expect(pitchFilters(12, PitchEngine.rubberband), ['rubberband=pitch=2']);
    final r = pitchFilters(12, PitchEngine.resample);
    expect(r, ['aresample=48000', 'asetrate=96000', 'aresample=48000', 'atempo=0.5']);
    expect(pitchFilters(0, PitchEngine.resample), isEmpty);
  });

  test('unedited source is one trimmed segment', () {
    final g = buildFilterGraph(run(const []), pitchEngine: PitchEngine.rubberband);
    expect(g, startsWith('[0:a]atrim=start=0:end=60,asetpts=PTS-STARTPTS'));
    expect(g, endsWith('[s0]anull[out]'));
  });

  test('cut + speed + gain + fades produce segments, concat and afade', () {
    final t = run(const [
      EditOp.cut(startMs: 10000, endMs: 20000),
      EditOp.speed(startMs: 0, endMs: 10000, factor: 1.25),
      EditOp.gain(startMs: 20000, endMs: 30000, db: -6),
      EditOp.fadeIn(durationMs: 1500),
      EditOp.fadeOut(durationMs: 2000),
    ]);
    final g = buildFilterGraph(t, pitchEngine: PitchEngine.rubberband);
    expect(RegExp(r'\[s\d\]').allMatches(g).length, greaterThanOrEqualTo(t.segments.length * 2));
    expect(g, contains('atrim=start=0:end=10,asetpts=PTS-STARTPTS,atempo=1.25'));
    expect(g, contains('atrim=start=20:end='));
    expect(g, contains('volume=volume=-6dB'));
    expect(g, contains('concat=n=${t.segments.length}:v=0:a=1[c];[c]afade=t=in:st=0:d=1.5'));
    // 0–10 s at 1.25x = 8 s, + 40 s kept = 48 s → fade out starts at 46 s.
    expect(t.duration, const Duration(seconds: 48));
    expect(g, contains('afade=t=out:st=46:d=2[out]'));
    // Output 20–30 s lands on source 32–42 s (mapped through the faster part).
    expect(g, contains('atrim=start=32:end=42,asetpts=PTS-STARTPTS,volume=volume=-6dB'));
  });

  test('export args per format', () {
    final t = run(const []);
    List<String> args(ExportFormat f) =>
        buildExportArgs(timeline: t, input: 'in.flac', output: 'out.${f.extension}', format: f, pitchEngine: PitchEngine.resample, title: 'Song (edit)');
    expect(args(ExportFormat.mp3), containsAllInOrder(['-i', 'in.flac', '-map', '[out]', '-c:a', 'libmp3lame', 'out.mp3']));
    expect(args(ExportFormat.m4a), containsAllInOrder(['-c:a', 'aac', '-b:a', '256k']));
    expect(args(ExportFormat.wav), containsAllInOrder(['-c:a', 'pcm_s16le', 'out.wav']));
    expect(args(ExportFormat.wav), isNot(contains('0:v?')), reason: 'WAV cannot hold cover art');
    expect(args(ExportFormat.mp3), containsAllInOrder(['-metadata', 'title=Song (edit)']));
  });
}

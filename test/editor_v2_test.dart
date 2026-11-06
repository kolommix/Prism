import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/editor/domain/audio_analysis.dart';
import 'package:prism/features/editor/domain/edit_decision_list.dart';
import 'package:prism/features/editor/domain/editor_tools.dart';
import 'package:prism/features/editor/domain/export_command.dart';
import 'package:prism/features/editor/domain/timeline.dart';

Duration s(num seconds) => Duration(milliseconds: (seconds * 1000).round());
int ms(num seconds) => (seconds * 1000).round();

void main() {
  final src = s(60);
  Timeline run(List<EditOp> ops) => Timeline.fromOps(src, ops);

  group('new operations', () {
    test('delete leaves a silent gap of the same length', () {
      final t = run([EditOp.silence(startMs: ms(10), endMs: ms(20))]);
      expect(t.duration, src);
      expect(t.segments.map((x) => x.silent), [false, true, false]);
      expect(t.segments[1].outputLength, s(10));
      expect(t.locate(s(25)).$2, s(25), reason: 'later audio stays where it was');
    });

    test('ripple delete closes the gap', () {
      final t = run([EditOp.cut(startMs: ms(10), endMs: ms(20))]);
      expect(t.duration, s(50));
      expect(t.locate(s(15)).$2, s(25));
    });

    test('duplicate inserts a copy right after the range', () {
      final t = run([EditOp.duplicate(startMs: ms(10), endMs: ms(20))]);
      expect(t.duration, s(70));
      expect(t.locate(s(15)).$2, s(15));
      expect(t.locate(s(25)).$2, s(15), reason: 'the copy');
      expect(t.locate(s(35)).$2, s(25));
    });

    test('loop repeats the range N times', () {
      final t = run([EditOp.loop(startMs: ms(0), endMs: ms(10), times: 3)]);
      expect(t.duration, s(80));
      expect(t.locate(s(25)).$2, s(5));
      expect(t.locate(s(35)).$2, s(15));
    });

    test('move reorders segments', () {
      final t = run([EditOp.split(atMs: ms(10)), EditOp.split(atMs: ms(30)), const EditOp.move(from: 2, to: 0)]);
      expect(t.duration, src);
      expect(t.segments.first.sourceStart, s(30));
      expect(t.locate(Duration.zero).$2, s(30));
    });

    test('moving to a bad index does nothing', () {
      expect(run([const EditOp.move(from: 0, to: 5)]), run(const []));
    });

    test('merge adds another file at the end', () {
      final t = run([const EditOp.merge(uri: 'b.mp3', durationMs: 30000)]);
      expect(t.duration, s(90));
      expect(t.segments.last.input, 'b.mp3');
      expect(t.isLiveCompatible, isFalse);
    });

    test('batch undoes as one step', () {
      final h = const EditHistory().push(EditOp.batch(ops: [
        EditOp.cut(startMs: ms(50), endMs: ms(60)),
        EditOp.cut(startMs: ms(0), endMs: ms(10)),
      ]));
      expect(Timeline.fromOps(src, h.applied).duration, s(40));
      expect(Timeline.fromOps(src, h.undo().applied).duration, src);
    });

    test('all new ops survive JSON', () {
      final ops = <EditOp>[
        EditOp.silence(startMs: 1000, endMs: 2000),
        EditOp.duplicate(startMs: 1000, endMs: 2000),
        EditOp.loop(startMs: 1000, endMs: 2000, times: 3),
        const EditOp.move(from: 0, to: 1),
        const EditOp.merge(uri: 'x', durationMs: 5000),
        EditOp.ramp(startMs: 0, endMs: 1000, from: 1, to: 2),
        EditOp.reverse(startMs: 0, endMs: 1000),
        EditOp.segmentFade(startMs: 0, endMs: 1000, inMs: 100, outMs: 200, curve: 'smooth'),
        const EditOp.crossfade(segment: 0, ms: 100),
        EditOp.segmentEq(startMs: 0, endMs: 1000, lowDb: 1, midDb: 2, highDb: 3),
        EditOp.gate(startMs: 0, endMs: 1000, db: -40),
        const EditOp.fadeCurve(curve: 'smooth'),
        const EditOp.masterGain(db: 1.5),
        const EditOp.loudness(lufs: -14),
        EditOp.batch(ops: [EditOp.cut(startMs: 0, endMs: 1000)]),
      ];
      final edl = EditDecisionList(sourceUri: 'a', sourceDurationMs: 60000, ops: ops, redoOps: ops.take(1).toList(), cursorMs: 5, viewStartMs: 6, viewLengthMs: 7);
      final back = EditDecisionList.fromJson(jsonDecode(jsonEncode(edl.toJson())) as Map<String, dynamic>);
      expect(back, edl);
    });

    test('an edit saved by the old version still loads', () {
      final old = {
        'version': 1,
        'sourceUri': 'a',
        'sourceDurationMs': 60000,
        'ops': [
          {'op': 'cut', 'startMs': 0, 'endMs': 1000},
        ],
      };
      final edl = EditDecisionList.fromJson(old);
      expect(edl.build().duration, s(59));
      expect(edl.redoOps, isEmpty);
    });
  });

  group('time mapping when speed changes', () {
    test('steady speed: output and source map both ways', () {
      final t = run([EditOp.speed(startMs: ms(0), endMs: ms(20), factor: 2)]);
      expect(t.duration, s(50));
      expect(t.locate(s(5)).$2, s(10));
      expect(t.sourceToOutput(s(10)), s(5));
      expect(t.locate(s(15)).$2, s(25));
    });

    test('ramp: length is the sum of its steps, and mapping round-trips', () {
      final t = run([EditOp.ramp(startMs: ms(0), endMs: ms(20), from: 1, to: 2)]);
      final seg = t.segments.first;
      expect(seg.isRamp, isTrue);
      expect(seg.steps.length, greaterThan(10));
      expect(seg.outputLength, seg.steps.fold(Duration.zero, (Duration d, x) => d + x.outputLength));
      // Between 20 s (all at 1x) and 10 s (all at 2x).
      expect(seg.outputLength, lessThan(s(20)));
      expect(seg.outputLength, greaterThan(s(10)));
      for (final src in [s(1), s(7), s(13), s(19)]) {
        final back = t.locate(t.sourceToOutput(src)).$2;
        expect((back - src).abs(), lessThan(const Duration(milliseconds: 2)));
      }
    });

    test('ramp speeds up over time: the second half takes less time', () {
      final t = run([EditOp.ramp(startMs: ms(0), endMs: ms(20), from: 1, to: 4)]);
      final half = t.sourceToOutput(s(10));
      expect(half * 2, greaterThan(t.segments.first.outputLength));
    });

    test('splitting a ramp keeps the speeds continuous', () {
      final t = run([EditOp.ramp(startMs: ms(0), endMs: ms(20), from: 1, to: 2), EditOp.split(atMs: ms(5))]);
      expect(t.segments[0].speedEnd, closeTo(t.segments[1].speed, 1e-9));
    });

    test('reverse: time runs backwards through the source', () {
      final t = run([EditOp.reverse(startMs: ms(10), endMs: ms(20))]);
      expect(t.duration, src);
      expect(t.locate(s(11)).$2, s(19));
      expect(t.locate(s(19)).$2, s(11));
      expect(t.sourceToOutput(s(19)), s(11));
    });

    test('reversing twice gives the original', () {
      final t = run([EditOp.reverse(startMs: ms(10), endMs: ms(20)), EditOp.reverse(startMs: ms(10), endMs: ms(20))]);
      expect(t.locate(s(11)).$2, s(11));
    });

    test('crossfade shortens the result by the overlap', () {
      final t = run([EditOp.split(atMs: ms(30)), const EditOp.crossfade(segment: 0, ms: 2000)]);
      expect(t.duration, s(58));
      expect(t.segmentStarts[1], s(28));
      // In the overlap the segment fading in counts.
      expect(t.locate(s(29)).$1, 1);
      expect(t.locate(s(29)).$2, s(31));
    });

    test('crossfade is limited to half of the shorter segment', () {
      final t = run([EditOp.split(atMs: ms(2)), const EditOp.crossfade(segment: 0, ms: 9000)]);
      expect(t.xfadeAfter(0), s(1));
    });

    test('live compatibility', () {
      expect(run([EditOp.cut(startMs: 0, endMs: 1000), EditOp.speed(startMs: 0, endMs: 1000, factor: 2)]).isLiveCompatible, isTrue);
      expect(run([EditOp.reverse(startMs: 0, endMs: 1000)]).isLiveCompatible, isFalse);
      expect(run([EditOp.ramp(startMs: 0, endMs: 1000, from: 1, to: 2)]).isLiveCompatible, isFalse);
      expect(run([const EditOp.loudness(lufs: -14)]).isLiveCompatible, isFalse);
      expect(run([const EditOp.masterGain(db: 2)]).isLiveCompatible, isTrue);
    });

    test('master gain reaches the player plan', () {
      final plan = run([const EditOp.masterGain(db: 3)]).toPlan();
      expect(plan.clips.single.gainDb, 3);
    });
  });

  group('export command generation', () {
    test('reverse goes before the tempo', () {
      final g = buildFilterGraph(run([EditOp.reverse(startMs: 0, endMs: 10000), EditOp.speed(startMs: 0, endMs: 10000, factor: 2)]),
          pitchEngine: PitchEngine.resample);
      expect(g, contains('asetpts=PTS-STARTPTS,areverse,atempo=2'));
    });

    test('a ramp becomes steady pieces with growing tempo', () {
      final t = run([EditOp.ramp(startMs: 0, endMs: 2000, from: 1, to: 2)]);
      final g = buildFilterGraph(t, pitchEngine: PitchEngine.resample);
      expect(g, contains('[r0_0]'));
      final n = t.segments.first.steps.length;
      expect(g, contains('concat=n=$n:v=0:a=1'));
      final tempos = RegExp(r'atempo=([\d.]+)').allMatches(g).map((m) => double.parse(m[1]!)).toList();
      expect(tempos.length, n);
      expect(tempos.first, lessThan(tempos.last));
    });

    test('silence uses anullsrc', () {
      final g = buildFilterGraph(run([EditOp.silence(startMs: 1000, endMs: 2000)]), pitchEngine: PitchEngine.resample);
      expect(g, contains('anullsrc=r=48000:cl=stereo,atrim=duration=1'));
    });

    test('crossfade uses acrossfade with the chosen curve', () {
      final t = run([EditOp.split(atMs: ms(30)), const EditOp.crossfade(segment: 0, ms: 2000, curve: 'smooth')]);
      final g = buildFilterGraph(t, pitchEngine: PitchEngine.resample);
      expect(g, contains('[s0][s1]acrossfade=d=2:c1=qsin:c2=qsin'));
    });

    test('mixed joins chain concat and crossfade', () {
      final t = run([EditOp.split(atMs: ms(20)), EditOp.split(atMs: ms(40)), const EditOp.crossfade(segment: 1, ms: 1000)]);
      final g = buildFilterGraph(t, pitchEngine: PitchEngine.resample);
      expect(g, contains('[s0][s1]concat=n=2:v=0:a=1[j1]'));
      expect(g, contains('[j1][s2]acrossfade=d=1'));
    });

    test('segment fades, EQ and gate are in the chain', () {
      final t = run([
        EditOp.segmentFade(startMs: 0, endMs: 10000, inMs: 500, outMs: 1000, curve: 'sCurve'),
        EditOp.segmentEq(startMs: 0, endMs: 10000, lowDb: 3, midDb: -2, highDb: 1),
        EditOp.gate(startMs: 0, endMs: 10000, db: -40),
      ]);
      final g = buildFilterGraph(t, pitchEngine: PitchEngine.resample);
      expect(g, contains('afade=t=in:st=0:d=0.5:curve=esin'));
      expect(g, contains('afade=t=out:st=9:d=1:curve=esin'));
      expect(g, contains('bass=g=3:f=200'));
      expect(g, contains('equalizer=f=1000:t=o:w=1.5:g=-2'));
      expect(g, contains('treble=g=1:f=4000'));
      expect(g, contains('agate=threshold=0.01'));
    });

    test('master gain, loudness and global EQ come after the join', () {
      final t = run([const EditOp.masterGain(db: 2), const EditOp.loudness(lufs: -14)]);
      final g = buildFilterGraph(t, pitchEngine: PitchEngine.resample, globalFilters: const ['equalizer=f=100:t=q:w=1:g=3']);
      expect(g, contains('[s0]volume=volume=2dB,equalizer=f=100:t=q:w=1:g=3,loudnorm=I=-14:TP=-1:LRA=11'));
    });

    test('merged files become extra inputs', () {
      final t = run([const EditOp.merge(uri: 'b.mp3', durationMs: 5000), const EditOp.merge(uri: 'b.mp3', durationMs: 5000)]);
      expect(timelineInputs(t, 'a.mp3'), ['a.mp3', 'b.mp3']);
      final args = buildExportArgs(timeline: t, input: 'a.mp3', output: 'o.mp3', format: ExportFormat.mp3, pitchEngine: PitchEngine.resample);
      expect(args, containsAllInOrder(['-i', 'a.mp3', '-i', 'b.mp3']));
      final graph = args[args.indexOf('-filter_complex') + 1];
      expect(graph, contains('[1:a]atrim=start=0:end=5'));
    });

    test('bitrate, VBR, bits and FLAC settings', () {
      final t = run(const []);
      List<String> a(ExportFormat f, ExportSettings st) =>
          buildExportArgs(timeline: t, input: 'i', output: 'o', format: f, pitchEngine: PitchEngine.resample, settings: st);
      expect(a(ExportFormat.mp3, const ExportSettings(mp3VbrQuality: 0)), containsAllInOrder(['-c:a', 'libmp3lame', '-q:a', '0']));
      expect(a(ExportFormat.mp3, const ExportSettings(mp3Vbr: false, mp3Kbps: 192)), containsAllInOrder(['-b:a', '192k']));
      expect(a(ExportFormat.m4a, const ExportSettings(m4aKbps: 128)), containsAllInOrder(['-c:a', 'aac', '-b:a', '128k']));
      expect(a(ExportFormat.wav, const ExportSettings(wavBits: 24)), containsAllInOrder(['-c:a', 'pcm_s24le']));
      expect(a(ExportFormat.flac, const ExportSettings(flacLevel: 8)), containsAllInOrder(['-c:a', 'flac', '-compression_level', '8']));
    });

    test('tags and cover: carried over, edited or replaced', () {
      final t = run(const []);
      List<String> a(ExportSettings st, [ExportFormat f = ExportFormat.mp3]) =>
          buildExportArgs(timeline: t, input: 'i', output: 'o', format: f, pitchEngine: PitchEngine.resample, settings: st);
      expect(a(const ExportSettings()), containsAllInOrder(['-map', '0:v?', '-map_metadata', '0']));
      expect(a(const ExportSettings(keepMetadata: false)), containsAllInOrder(['-map_metadata', '-1']));
      expect(a(const ExportSettings(keepMetadata: false)), isNot(contains('0:v?')));
      expect(a(const ExportSettings(removeCover: true)), isNot(contains('0:v?')));
      final withCover = a(const ExportSettings(coverPath: 'c.jpg'));
      expect(withCover, containsAllInOrder(['-i', 'i', '-i', 'c.jpg', '-filter_complex']));
      expect(withCover, containsAllInOrder(['-map', '1:v', '-c:v', 'copy', '-disposition:v', 'attached_pic']));
      expect(a(const ExportSettings(tags: {'artist': 'X'})), containsAllInOrder(['-metadata', 'artist=X']));
      expect(a(const ExportSettings(coverPath: 'c.jpg'), ExportFormat.wav), isNot(contains('c.jpg')));
    });

    test('global EQ filters for export', () {
      final f = eqExportFilters(frequencies: const [100, 1000], gainsDb: const [3, 0], q: 1.4, bassDb: 2, preampDb: -1);
      expect(f, ['volume=volume=-1dB', 'equalizer=f=100:t=q:w=1.4:g=3', 'bass=g=2:f=100:t=q:w=0.7']);
    });

    test('format of a path', () {
      expect(ExportFormat.ofPath('a/b.FLAC'), ExportFormat.flac);
      expect(ExportFormat.ofPath('a/b.ogg'), isNull);
    });
  });

  group('waveform analysis', () {
    Uint8List pcm(List<int> samples) {
      final b = ByteData(samples.length * 2);
      for (var i = 0; i < samples.length; i++) {
        b.setInt16(i * 2, samples[i], Endian.little);
      }
      return b.buffer.asUint8List();
    }

    test('bucket peaks from PCM', () {
      final p = peaksFromPcmBytes(pcm([0, 100, -32768, 3200, 0, 0]), 2);
      expect(p, [100 >> 7, 255, 0]);
    });

    test('the pyramid answers from a coarser level with the same peak', () {
      final base = Uint8List(4096);
      base[1000] = 200;
      final py = PeakPyramid(100, base);
      expect(py.levels.length, greaterThan(2));
      expect(py.peak(0, 40.96), closeTo(200 / 255, 1e-9));
      expect(py.peak(9.5, 10.5), closeTo(200 / 255, 1e-9));
      expect(py.peak(20, 21), 0);
      expect(py.duration, const Duration(milliseconds: 40960));
    });

    test('silences are found above a minimum length', () {
      final p = Uint8List(1000)..fillRange(0, 1000, 200);
      p.fillRange(100, 300, 0); // 2 s at 100 per second
      p.fillRange(500, 510, 0); // 0.1 s, too short
      final found = detectSilences(p, 100);
      expect(found, [(s(1), s(3))]);
    });

    test('beats of a steady pulse', () {
      // 120 BPM at 200 values per second: a loud hit every 100 values.
      final p = Uint8List(200 * 20);
      for (var i = 0; i < p.length; i++) {
        p[i] = i % 100 < 10 ? 220 : 20;
      }
      final beats = detectBeats(p, 200);
      expect(beats.length, greaterThan(20));
      final gap = (beats[5] - beats[4]).inMilliseconds;
      expect(gap, closeTo(500, 25));
    });

    test('no pulse, no beats', () {
      expect(detectBeats(Uint8List(200 * 20), 200), isEmpty);
    });

    test('nearest zero crossing', () {
      final samples = Int16List.fromList([100, 90, 50, 10, -10, -50, -90, -100, -50, 40, 90]);
      expect(nearestZeroCrossing(samples, 2), 3);
      expect(nearestZeroCrossing(samples, 8), 8);
      expect(nearestZeroCrossing(Int16List.fromList([5, 5, 5, 5]), 2), 2);
    });

    test('snapping picks the nearest point inside the tolerance', () {
      final pts = [s(1), s(2), s(3)];
      expect(nearestSnap(pts, s(2.04), const Duration(milliseconds: 100)), s(2));
      expect(nearestSnap(pts, s(2.5), const Duration(milliseconds: 100)), isNull);
    });
  });

  group('quick tools', () {
    PeakPyramid wave(Duration total, List<(num, num)> quiet) {
      final n = (total.inMilliseconds / 10).round();
      final p = Uint8List(n)..fillRange(0, n, 180);
      for (final (a, b) in quiet) {
        p.fillRange((a * 100).round(), (b * 100).round(), 0);
      }
      return PeakPyramid(100, p);
    }

    test('auto-trim removes silence at both ends only', () {
      final reader = peakReader(wave(src, [(0, 2), (20, 25), (55, 60)]), const {});
      final op = autoTrimOp(run(const []), reader) as TrimOp;
      expect(op.startMs, closeTo(2000, 40));
      expect(op.endMs, closeTo(55000, 40));
    });

    test('auto-trim with nothing to trim', () {
      expect(autoTrimOp(run(const []), peakReader(wave(src, const []), const {})), isNull);
    });

    test('remove silence cuts the middle, keeps a little on each side', () {
      final reader = peakReader(wave(src, [(0, 2), (20, 25), (40, 42)]), const {});
      final op = removeSilenceOp(run(const []), reader) as BatchOp;
      expect(op.ops.length, 2);
      final t = run([op]);
      expect(t.duration.inMilliseconds, closeTo(60000 - (5000 - 240) - (2000 - 240), 100));
      // The start's silence stays: that belongs to auto-trim.
      expect(t.segments.first.sourceStart, Duration.zero);
    });

    test('normalize brings the peak to -1 dB', () {
      final reader = peakReader(wave(src, const []), const {});
      final db = normalizeGainDb(run(const []), reader)!;
      // 180/255 is about -3 dB.
      expect(db, closeTo(2.03, 0.05));
    });

    test('ringtone ops trim and fade', () {
      final ops = ringtoneOps(s(5), s(35));
      final t = Timeline.fromOps(src, ops);
      expect(t.duration, s(30));
      expect(t.fadeIn, const Duration(milliseconds: 300));
      expect(t.fadeOut, const Duration(milliseconds: 500));
    });

    test('silent segments read as silent', () {
      final reader = peakReader(wave(src, const []), const {});
      const seg = Segment(sourceStart: Duration.zero, sourceEnd: Duration(seconds: 1), silent: true);
      expect(reader(seg, Duration.zero, const Duration(seconds: 1)), 0);
    });
  });
}

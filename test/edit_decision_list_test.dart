import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/editor/domain/edit_decision_list.dart';
import 'package:prism/features/editor/domain/timeline.dart';

Duration s(num seconds) => Duration(milliseconds: (seconds * 1000).round());
int ms(num seconds) => (seconds * 1000).round();

/// Source ranges in seconds, e.g. [(0, 10), (20, 60)].
List<(double, double)> ranges(Timeline t) => [
      for (final seg in t.segments) (seg.sourceStart.inMilliseconds / 1000, seg.sourceEnd.inMilliseconds / 1000),
    ];

void main() {
  final src = s(60);
  Timeline run(List<EditOp> ops) => Timeline.fromOps(src, ops);

  group('basic operations', () {
    test('no ops = untouched source', () {
      final t = run(const []);
      expect(t.duration, src);
      expect(t.isUnedited, isTrue);
    });

    test('split makes two segments with the same total length', () {
      final t = run([EditOp.split(atMs: ms(20))]);
      expect(ranges(t), [(0.0, 20.0), (20.0, 60.0)]);
      expect(t.duration, src);
    });

    test('split at an edge, an existing boundary or too close is a no-op', () {
      expect(run([EditOp.split(atMs: 0)]).segments.length, 1);
      expect(run([EditOp.split(atMs: ms(60))]).segments.length, 1);
      expect(run([EditOp.split(atMs: ms(20)), EditOp.split(atMs: ms(20))]).segments.length, 2);
      expect(run([EditOp.split(atMs: 5)]).segments.length, 1, reason: '< minSegment from the start');
    });

    test('cut removes the range', () {
      final t = run([EditOp.cut(startMs: ms(10), endMs: ms(20))]);
      expect(ranges(t), [(0.0, 10.0), (20.0, 60.0)]);
      expect(t.duration, s(50));
    });

    test('trim keeps only the range', () {
      final t = run([EditOp.trim(startMs: ms(5), endMs: ms(15))]);
      expect(ranges(t), [(5.0, 15.0)]);
      expect(t.duration, s(10));
    });

    test('reversed ranges are normalised, out-of-range ends are clamped', () {
      expect(ranges(run([EditOp.cut(startMs: ms(20), endMs: ms(10))])), [(0.0, 10.0), (20.0, 60.0)]);
      expect(ranges(run([EditOp.trim(startMs: -500, endMs: ms(999))])), [(0.0, 60.0)]);
    });

    test('cutting everything or an empty range changes nothing', () {
      expect(run([EditOp.cut(startMs: 0, endMs: ms(60))]), run(const []));
      expect(run([EditOp.cut(startMs: ms(10), endMs: ms(10))]), run(const []));
    });
  });

  group('segment parameters', () {
    test('speed changes only the range; output gets shorter, source unchanged', () {
      final t = run([EditOp.speed(startMs: ms(10), endMs: ms(30), factor: 2)]);
      expect(ranges(t), [(0.0, 10.0), (10.0, 30.0), (30.0, 60.0)]);
      expect(t.segments.map((x) => x.speed), [1, 2, 1]);
      expect(t.duration, s(50)); // 20 s at 2x = 10 s
    });

    test('pitch and gain only touch the range and keep the length', () {
      final t = run([
        EditOp.pitch(startMs: ms(0), endMs: ms(30), semitones: 3),
        EditOp.gain(startMs: ms(20), endMs: ms(40), db: -6),
      ]);
      expect(t.duration, src);
      expect(t.segments.map((x) => x.pitchSemitones), [3, 3, 0, 0]);
      expect(t.segments.map((x) => x.gainDb), [0, -6, -6, 0]);
    });

    test('values are clamped to safe limits', () {
      final t = run([
        EditOp.speed(startMs: 0, endMs: ms(10), factor: 50),
        EditOp.pitch(startMs: 0, endMs: ms(10), semitones: -40),
        EditOp.gain(startMs: 0, endMs: ms(10), db: 99),
      ]);
      final first = t.segments.first;
      expect((first.speed, first.pitchSemitones, first.gainDb), (maxSpeed, minPitch, maxGainDb));
    });

    test('a later speed op on the same range replaces the factor (absolute)', () {
      final t = run([
        EditOp.speed(startMs: ms(10), endMs: ms(20), factor: 2),
        EditOp.speed(startMs: ms(10), endMs: ms(15), factor: 0.5),
      ]);
      // After the first op, output 10–15 s is the 2x segment (source 10–20).
      expect(t.segments[1].speed, 0.5);
      expect(t.segments[1].sourceStart, s(10));
      expect(t.segments[1].sourceEnd, s(20));
    });
  });

  group('operations are in output time', () {
    test('two cuts of the same output range remove consecutive source ranges', () {
      final t = run([
        EditOp.cut(startMs: 0, endMs: ms(10)),
        EditOp.cut(startMs: 0, endMs: ms(10)),
      ]);
      expect(ranges(t), [(20.0, 60.0)]);
    });

    test('ranges after a speed change map through the faster segment', () {
      // 0–20 s at 2x lasts 10 s, so output 10–20 s is source 20–30 s.
      final t = run([
        EditOp.speed(startMs: 0, endMs: ms(20), factor: 2),
        EditOp.cut(startMs: ms(10), endMs: ms(20)),
      ]);
      expect(ranges(t), [(0.0, 20.0), (30.0, 60.0)]);
    });
  });

  group('fades', () {
    test('fade lengths are kept and clamped to half the duration', () {
      final t = run([EditOp.fadeIn(durationMs: ms(2)), EditOp.fadeOut(durationMs: ms(100))]);
      expect(t.fadeIn, s(2));
      expect(t.fadeOut, s(30));
    });

    test('a later trim shrinks fades that no longer fit', () {
      final t = run([EditOp.fadeOut(durationMs: ms(20)), EditOp.trim(startMs: 0, endMs: ms(10))]);
      expect(t.fadeOut, s(5));
    });
  });

  group('time mapping (A/B preview)', () {
    final t = run([
      EditOp.cut(startMs: ms(10), endMs: ms(20)),
      EditOp.speed(startMs: ms(20), endMs: ms(30), factor: 2), // source 30–40 at 2x
    ]);

    test('output → source', () {
      expect(t.outputToSource(s(5)), s(5));
      expect(t.outputToSource(s(12)), s(22)); // after the cut
      expect(t.outputToSource(s(25)), s(40)); // inside the 2x segment
    });

    test('source → output; cut audio maps to the next kept audio', () {
      expect(t.sourceToOutput(s(5)), s(5));
      expect(t.sourceToOutput(s(15)), s(10)); // was cut
      expect(t.sourceToOutput(s(34)), s(22));
    });

    test('round trip for kept audio', () {
      for (final out in [1, 9, 14, 21, 33, 44]) {
        final back = t.sourceToOutput(t.outputToSource(s(out)));
        expect((back - s(out)).inMilliseconds.abs(), lessThanOrEqualTo(1), reason: '$out s');
      }
    });
  });

  group('playback plan', () {
    test('plan clips mirror segments and have the same total length', () {
      final t = run([
        EditOp.cut(startMs: ms(10), endMs: ms(20)),
        EditOp.pitch(startMs: 0, endMs: ms(5), semitones: 2),
        EditOp.fadeIn(durationMs: 500),
      ]);
      final plan = t.toPlan();
      expect(plan.clips.length, t.segments.length);
      expect(plan.clips.first.pitchSemitones, 2);
      expect(plan.fadeIn, const Duration(milliseconds: 500));
      expect(plan.outputDuration(), t.duration);
      expect(plan.isEdited, isTrue);
    });

    test('plan locate/toOutput agree with the timeline', () {
      final t = run([EditOp.speed(startMs: ms(10), endMs: ms(30), factor: 1.5)]);
      final plan = t.toPlan();
      final (clip, inClip) = plan.locate(s(20));
      expect(plan.toOutput(clip, inClip).inMilliseconds, closeTo(20000, 1));
      expect(plan.clips[clip].sourceStart + inClip, t.outputToSource(s(20)));
    });

    test('plan fade factor ramps in and out', () {
      final plan = run([EditOp.fadeIn(durationMs: 1000), EditOp.fadeOut(durationMs: 1000)]).toPlan();
      expect(plan.fadeFactor(Duration.zero, src), 0);
      expect(plan.fadeFactor(s(0.5), src), closeTo(0.5, 1e-9));
      expect(plan.fadeFactor(s(30), src), 1);
      expect(plan.fadeFactor(s(59.5), src), closeTo(0.5, 1e-9));
    });
  });

  group('history + storage', () {
    test('undo/redo; a new op drops the redo tail', () {
      var h = const EditHistory();
      h = h.push(const EditOp.split(atMs: 1000)).push(const EditOp.cut(startMs: 0, endMs: 500));
      expect(h.applied.length, 2);
      h = h.undo();
      expect((h.applied.length, h.canRedo), (1, true));
      h = h.redo();
      expect(h.applied.length, 2);
      h = h.undo().push(const EditOp.fadeIn(durationMs: 300));
      expect(h.applied.last, const EditOp.fadeIn(durationMs: 300));
      expect(h.canRedo, isFalse);
      expect(const EditHistory().undo().cursor, 0);
    });

    test('JSON round trip keeps every operation type', () {
      const edl = EditDecisionList(sourceUri: '/m/a.mp3', sourceDurationMs: 60000, ops: [
        EditOp.trim(startMs: 1, endMs: 59000),
        EditOp.cut(startMs: 1000, endMs: 2000),
        EditOp.split(atMs: 3000),
        EditOp.speed(startMs: 0, endMs: 100, factor: 1.25),
        EditOp.pitch(startMs: 0, endMs: 100, semitones: -2),
        EditOp.gain(startMs: 0, endMs: 100, db: 3),
        EditOp.fadeIn(durationMs: 500),
        EditOp.fadeOut(durationMs: 700),
      ]);
      final back = EditDecisionList.fromJson(jsonDecode(jsonEncode(edl.toJson())) as Map<String, dynamic>);
      expect(back, edl);
      expect(back.build(), edl.build());
      expect(jsonEncode(edl.toJson()), contains('"op":"speed"'));
    });

    test('unknown operation in stored JSON is rejected', () {
      expect(
        () => EditDecisionList.fromJson({
          'sourceUri': 'x',
          'sourceDurationMs': 1,
          'ops': [
            {'op': 'reverse'},
          ],
        }),
        throwsA(anything),
      );
    });
  });
}

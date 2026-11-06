import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/player/domain/playback_queue.dart';

import 'helpers.dart';

void main() {
  final five = [for (var i = 1; i <= 5; i++) t(i)];

  group('load / navigation', () {
    test('load starts at the requested index', () {
      final q = PlaybackQueue.empty.load(five, startIndex: 2);
      expect(q.current!.id, 3);
      expect(q.nextIndex, 3);
      expect(q.previousIndex, 1);
    });

    test('empty queue has no current/next', () {
      expect(PlaybackQueue.empty.current, isNull);
      expect(PlaybackQueue.empty.nextIndex, isNull);
      expect(PlaybackQueue.empty.load(const []).isEmpty, isTrue);
    });

    test('advance stops at the end with repeat off', () {
      final q = PlaybackQueue.empty.load(five, startIndex: 4);
      expect(q.hasNext, isFalse);
      expect(q.advance().index, 4);
    });

    test('repeat all wraps both ways', () {
      final q = PlaybackQueue.empty.load(five, startIndex: 4).setRepeat(QueueRepeatMode.all);
      expect(q.advance().index, 0);
      expect(q.jumpTo(0).skipPrevious().index, 4);
    });

    test('repeat one: natural advance stays, next button moves on', () {
      final q = PlaybackQueue.empty.load(five, startIndex: 1).setRepeat(QueueRepeatMode.one);
      expect(q.advance().index, 1);
      expect(q.skipNext().index, 2);
    });

    test('cycleRepeat goes off → all → one → off', () {
      var q = PlaybackQueue.empty;
      final seen = <QueueRepeatMode>[];
      for (var i = 0; i < 3; i++) {
        q = q.cycleRepeat();
        seen.add(q.repeatMode);
      }
      expect(seen, [QueueRepeatMode.all, QueueRepeatMode.one, QueueRepeatMode.off]);
    });
  });

  group('editing', () {
    test('addNext inserts right after current', () {
      final q = PlaybackQueue.empty.load(five, startIndex: 1).addNext(t(9));
      expect(ids(q.tracks), [1, 2, 9, 3, 4, 5]);
      expect(q.current!.id, 2);
      expect(q.next!.id, 9);
    });

    test('addNext on empty queue starts it', () {
      final q = PlaybackQueue.empty.addAllNext([t(7), t(8)]);
      expect(q.current!.id, 7);
      expect(q.length, 2);
    });

    test('addToEnd appends', () {
      final q = PlaybackQueue.empty.load(five).addToEnd([t(6)]);
      expect(ids(q.tracks).last, 6);
      expect(q.index, 0);
    });

    test('removing before current shifts index, current stays the same', () {
      final q = PlaybackQueue.empty.load(five, startIndex: 3).removeAt(0);
      expect(q.current!.id, 4);
      expect(q.index, 2);
    });

    test('removing the current track selects the following one', () {
      final q = PlaybackQueue.empty.load(five, startIndex: 2).removeAt(2);
      expect(q.current!.id, 4);
    });

    test('removing the last current track selects the new last', () {
      final q = PlaybackQueue.empty.load(five, startIndex: 4).removeAt(4);
      expect(q.current!.id, 4);
    });

    test('removing the only track empties the queue', () {
      final q = PlaybackQueue.empty.load([t(1)]).removeAt(0);
      expect(q.isEmpty, isTrue);
      expect(q.index, -1);
    });

    group('move keeps the same song playing', () {
      final base = PlaybackQueue.empty.load(five, startIndex: 2); // current = 3

      test('move the current item', () {
        final q = base.move(2, 0);
        expect(ids(q.tracks), [3, 1, 2, 4, 5]);
        expect(q.current!.id, 3);
      });

      test('move an item from before to after current', () {
        final q = base.move(0, 4);
        expect(ids(q.tracks), [2, 3, 4, 5, 1]);
        expect(q.current!.id, 3);
      });

      test('move an item from after to before current', () {
        final q = base.move(4, 0);
        expect(ids(q.tracks), [5, 1, 2, 3, 4]);
        expect(q.current!.id, 3);
      });

      test('move after current only changes what is next', () {
        final q = base.move(4, 3);
        expect(q.current!.id, 3);
        expect(q.next!.id, 5);
      });

      test('out of range is a no-op', () {
        expect(identical(base.move(0, 99), base), isTrue);
      });
    });
  });

  group('shuffle', () {
    test('shuffle keeps current first and contains every track once', () {
      final q = PlaybackQueue.empty.load(five, startIndex: 2).setShuffle(true, random: Random(1));
      expect(q.shuffled, isTrue);
      expect(q.index, 0);
      expect(q.current!.id, 3);
      expect(ids(q.tracks)..sort(), [1, 2, 3, 4, 5]);
    });

    test('unshuffle restores original order and keeps current', () {
      final shuffled = PlaybackQueue.empty.load(five).setShuffle(true, random: Random(7)).jumpTo(3);
      final cur = shuffled.current!.id;
      final q = shuffled.setShuffle(false);
      expect(ids(q.tracks), [1, 2, 3, 4, 5]);
      expect(q.current!.id, cur);
    });

    test('load while shuffled puts the tapped song first', () {
      final q = PlaybackQueue.empty.setShuffle(true).load(five, startIndex: 3, random: Random(3));
      expect(q.current!.id, 4);
      expect(q.index, 0);
      expect(ids(q.originalOrder), [1, 2, 3, 4, 5]);
    });

    test('songs added while shuffled survive unshuffle', () {
      final q = PlaybackQueue.empty
          .load(five)
          .setShuffle(true, random: Random(2))
          .addNext(t(9))
          .setShuffle(false);
      expect(ids(q.tracks), [1, 9, 2, 3, 4, 5]);
    });
  });
}

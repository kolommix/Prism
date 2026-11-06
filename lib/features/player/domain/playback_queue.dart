import 'dart:math';

import '../../library/domain/track.dart';

import 'reorder.dart';
/// How the queue behaves when it reaches the end (or the end of a track).
enum QueueRepeatMode {
  /// Stop after the last track.
  off,

  /// Wrap around to the first track after the last one.
  all,

  /// Repeat the current track forever.
  one,
}

/// Pure, immutable model of the play queue.
///
/// This class contains **no audio code** – it only answers "what is playing,
/// what comes next, what comes before". The playback engine mirrors whatever
/// this model says, which keeps all queue rules unit-testable.
///
/// * [tracks] is the *play order* (already shuffled when [shuffled] is true).
/// * [originalOrder] remembers the un-shuffled order so shuffle can be undone.
/// * [index] points into [tracks]; it is `-1` when the queue is empty.
class PlaybackQueue {
  const PlaybackQueue({
    this.tracks = const [],
    this.originalOrder = const [],
    this.index = -1,
    this.repeatMode = QueueRepeatMode.off,
    this.shuffled = false,
  });

  /// An empty queue with nothing playing.
  static const empty = PlaybackQueue();

  final List<Track> tracks;
  final List<Track> originalOrder;
  final int index;
  final QueueRepeatMode repeatMode;
  final bool shuffled;

  bool get isEmpty => tracks.isEmpty;
  bool get isNotEmpty => tracks.isNotEmpty;
  int get length => tracks.length;

  /// The track at [index], or `null` when the queue is empty.
  Track? get current =>
      index >= 0 && index < tracks.length ? tracks[index] : null;

  /// Index of the track that plays after the current one finishes naturally,
  /// honouring [repeatMode]. `null` means playback stops.
  int? get nextIndex {
    if (isEmpty) return null;
    if (repeatMode == QueueRepeatMode.one) return index;
    if (index + 1 < tracks.length) return index + 1;
    return repeatMode == QueueRepeatMode.all ? 0 : null;
  }

  /// Track that plays after the current one (see [nextIndex]).
  Track? get next => nextIndex == null ? null : tracks[nextIndex!];

  bool get hasNext => nextIndex != null;

  /// Index used by the "previous" button. Always wraps on [QueueRepeatMode.all].
  int? get previousIndex {
    if (isEmpty) return null;
    if (index > 0) return index - 1;
    return repeatMode == QueueRepeatMode.all ? tracks.length - 1 : null;
  }

  PlaybackQueue copyWith({
    List<Track>? tracks,
    List<Track>? originalOrder,
    int? index,
    QueueRepeatMode? repeatMode,
    bool? shuffled,
  }) {
    return PlaybackQueue(
      tracks: tracks ?? this.tracks,
      originalOrder: originalOrder ?? this.originalOrder,
      index: index ?? this.index,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffled: shuffled ?? this.shuffled,
    );
  }

  /// Replaces the whole queue, starting at [startIndex].
  ///
  /// If shuffle is on, the chosen start track stays first and the rest is
  /// shuffled behind it (this is what users expect when tapping a song).
  PlaybackQueue load(List<Track> newTracks, {int startIndex = 0, Random? random}) {
    if (newTracks.isEmpty) {
      return PlaybackQueue(repeatMode: repeatMode, shuffled: shuffled);
    }
    final start = startIndex.clamp(0, newTracks.length - 1);
    final original = List<Track>.unmodifiable(newTracks);
    if (!shuffled) {
      return copyWith(tracks: original, originalOrder: original, index: start);
    }
    final first = newTracks[start];
    final rest = [...newTracks]..removeAt(start);
    rest.shuffle(random);
    return copyWith(
      tracks: List.unmodifiable([first, ...rest]),
      originalOrder: original,
      index: 0,
    );
  }

  /// Jumps directly to [newIndex] (e.g. user tapped an item in the queue).
  PlaybackQueue jumpTo(int newIndex) {
    if (newIndex < 0 || newIndex >= tracks.length) return this;
    return copyWith(index: newIndex);
  }

  /// Moves to the natural next track. Returns `this` unchanged at the end of a
  /// non-repeating queue; check [hasNext] first if you need to know.
  PlaybackQueue advance() {
    final n = nextIndex;
    return n == null ? this : copyWith(index: n);
  }

  /// "Next" button: like [advance] but skips over [QueueRepeatMode.one], because a
  /// user pressing next wants a different song.
  PlaybackQueue skipNext() {
    if (isEmpty) return this;
    if (index + 1 < tracks.length) return copyWith(index: index + 1);
    return repeatMode == QueueRepeatMode.off ? this : copyWith(index: 0);
  }

  /// "Previous" button.
  PlaybackQueue skipPrevious() {
    final p = previousIndex;
    return p == null ? this : copyWith(index: p);
  }

  /// Inserts [track] right after the current one ("Play next").
  PlaybackQueue addNext(Track track) => addAllNext([track]);

  /// Inserts several tracks right after the current one, keeping their order.
  PlaybackQueue addAllNext(List<Track> items) {
    if (items.isEmpty) return this;
    if (isEmpty) return load(items);
    final insertAt = index + 1;
    final newTracks = [...tracks]..insertAll(insertAt, items);
    // In the original order we place them after the current track as well so
    // that un-shuffling keeps them close to where the user put them.
    final cur = current!;
    final origPos = originalOrder.indexOf(cur);
    final newOriginal = [...originalOrder]
      ..insertAll(origPos < 0 ? originalOrder.length : origPos + 1, items);
    return copyWith(
      tracks: List.unmodifiable(newTracks),
      originalOrder: List.unmodifiable(newOriginal),
    );
  }

  /// Appends tracks to the end of the queue.
  PlaybackQueue addToEnd(List<Track> items) {
    if (items.isEmpty) return this;
    if (isEmpty) return load(items);
    return copyWith(
      tracks: List.unmodifiable([...tracks, ...items]),
      originalOrder: List.unmodifiable([...originalOrder, ...items]),
    );
  }

  /// Removes the item at [removeIndex]. Removing the current track makes the
  /// following track current (or the previous one if it was the last).
  PlaybackQueue removeAt(int removeIndex) {
    if (removeIndex < 0 || removeIndex >= tracks.length) return this;
    final removed = tracks[removeIndex];
    final newTracks = [...tracks]..removeAt(removeIndex);
    final newOriginal = [...originalOrder];
    final origPos = newOriginal.indexOf(removed);
    if (origPos >= 0) newOriginal.removeAt(origPos);

    if (newTracks.isEmpty) {
      return PlaybackQueue(repeatMode: repeatMode, shuffled: shuffled);
    }
    var newIndex = index;
    if (removeIndex < index) {
      newIndex = index - 1;
    } else if (removeIndex == index) {
      newIndex = min(index, newTracks.length - 1);
    }
    return copyWith(
      tracks: List.unmodifiable(newTracks),
      originalOrder: List.unmodifiable(newOriginal),
      index: newIndex,
    );
  }

  /// Moves an item, keeping the *same track* current.
  ///
  /// [to] is the final index of the item after the move – exactly what
  /// `ReorderableListView.onReorderItem` passes.
  PlaybackQueue move(int from, int to) {
    if (from == to ||
        from < 0 ||
        to < 0 ||
        from >= tracks.length ||
        to >= tracks.length) {
      return this;
    }
    final cur = current;
    final newTracks = [...tracks];
    final item = newTracks.removeAt(from);
    newTracks.insert(to, item);
    var newIndex = index;
    if (from == index) {
      newIndex = to;
    } else if (from < index && to >= index) {
      newIndex = index - 1;
    } else if (from > index && to <= index) {
      newIndex = index + 1;
    }
    assert(identical(newTracks[newIndex], cur));
    // Manual reordering defines a new "original" order when not shuffled.
    return copyWith(
      tracks: List.unmodifiable(newTracks),
      originalOrder: shuffled ? originalOrder : List.unmodifiable(newTracks),
      index: newIndex,
    );
  }

  /// Moves several items together to final index [start], keeping their order
  /// and the same track current.
  PlaybackQueue moveMany(Iterable<int> indices, int start) {
    var q = this;
    for (final (from, to) in groupMoves(tracks.length, indices, start)) {
      q = q.move(from, to);
    }
    return q;
  }

  /// Turns shuffle on/off. The current track never changes; when shuffling,
  /// it moves to the front and everything else is shuffled behind it.
  PlaybackQueue setShuffle(bool enabled, {Random? random}) {
    if (enabled == shuffled) return this;
    if (isEmpty) return copyWith(shuffled: enabled);
    final cur = current!;
    if (enabled) {
      final rest = [...tracks]..removeAt(index);
      rest.shuffle(random);
      return copyWith(
        tracks: List.unmodifiable([cur, ...rest]),
        index: 0,
        shuffled: true,
      );
    }
    final restored = originalOrder.isEmpty ? tracks : originalOrder;
    final newIndex = restored.indexOf(cur);
    return copyWith(
      tracks: List.unmodifiable(restored),
      index: newIndex < 0 ? 0 : newIndex,
      shuffled: false,
    );
  }

  PlaybackQueue setRepeat(QueueRepeatMode mode) => copyWith(repeatMode: mode);

  /// Cycles off → all → one → off (what the repeat button does).
  PlaybackQueue cycleRepeat() => setRepeat(
        QueueRepeatMode.values[(repeatMode.index + 1) % QueueRepeatMode.values.length],
      );
}

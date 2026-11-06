/// Moving several list items as one group. Pure, so playlists and the queue
/// share it and it can be tested without a screen.
library;

/// Where a dragged group lands. [dragged] is the row under the finger, [to] is
/// its final index as `onReorderItem` reports it (a list with only that row
/// taken out). Returns the final index of the group's first item.
int groupDropStart(Set<int> selected, int dragged, int to) {
  // Rows in the list as the drop saw it, minus the dragged one: selected rows
  // before the drop point leave too, so the target moves up by that many.
  var before = 0;
  var seen = 0;
  for (var i = 0; seen < to; i++) {
    if (i == dragged) continue;
    if (selected.contains(i)) before++;
    seen++;
  }
  return to - before;
}

/// Single moves (from, to) that gather [indices] at [start], keeping their order
/// among each other and the order of everything else.
List<(int, int)> groupMoves(int length, Iterable<int> indices, int start) {
  final group = indices.where((i) => i >= 0 && i < length).toSet().toList()..sort();
  if (group.isEmpty) return const [];
  final begin = start.clamp(0, length - group.length);
  final order = List<int>.generate(length, (i) => i);
  final moves = <(int, int)>[];
  void place(int k) {
    final from = order.indexOf(group[k]);
    final target = begin + k;
    if (from == target) return;
    order.insert(target, order.removeAt(from));
    moves.add((from, target));
  }

  // Rows going down are placed last-first and rows going up first-first, so a
  // placed row is never pushed off its spot by a later move.
  for (var k = group.length - 1; k >= 0; k--) {
    if (group[k] < begin + k) place(k);
  }
  for (var k = 0; k < group.length; k++) {
    if (group[k] > begin + k) place(k);
  }
  return moves;
}

/// [items] after [groupMoves].
List<T> applyMoves<T>(List<T> items, List<(int, int)> moves) {
  final out = [...items];
  for (final (from, to) in moves) {
    out.insert(to, out.removeAt(from));
  }
  return out;
}

/// How a playlist is shown. `custom` is the order the user made by dragging; it
/// stays saved whatever sort is picked.
enum PlaylistSort {
  custom,
  title,
  artist,
  album,
  recent,
  longest;

  static PlaylistSort parse(String? name) => values.asNameMap()[name] ?? custom;
}

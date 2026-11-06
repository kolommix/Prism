import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/smooth_scroll.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../l10n/l10n.dart';
import '../../library/presentation/widgets/track_actions.dart';
import '../../library/presentation/widgets/track_tile.dart';
import '../../playlists/presentation/reorder_widgets.dart';
import '../application/player_providers.dart';
import '../domain/playback_queue.dart';
import '../domain/reorder.dart';

/// Reorderable "up next" list: drag to reorder (handle on Windows, hold on a
/// phone), select several and move them together, swipe to remove, tap to jump.
class QueueList extends ConsumerStatefulWidget {
  const QueueList({super.key, this.padding = EdgeInsets.zero, this.shrinkWrap = false});

  final EdgeInsets padding;
  final bool shrinkWrap;

  @override
  ConsumerState<QueueList> createState() => _QueueListState();
}

class _QueueListState extends ConsumerState<QueueList> {
  /// Positions in the queue; a moved group is re-selected where it landed.
  Set<int> _selected = {};
  bool _selecting = false;

  void _toggle(int i) => setState(() {
        if (!_selected.remove(i)) _selected.add(i);
        if (_selected.isEmpty) _selecting = false;
      });

  void _clear() => setState(() {
        _selected = {};
        _selecting = false;
      });

  Future<void> _moveGroup(Set<int> indices, int start, int length) async {
    final player = ref.read(playerControllerProvider);
    final begin = start.clamp(0, length - indices.length);
    await player.moveMany(indices, begin);
    if (mounted && _selecting) {
      setState(() => _selected = {for (var k = 0; k < indices.length; k++) begin + k});
    }
  }

  Future<void> _onDrop(int from, int to, int length) async {
    if (_selected.length > 1 && _selected.contains(from)) {
      await _moveGroup({..._selected}, groupDropStart(_selected, from, to), length);
    } else {
      await ref.read(playerControllerProvider).move(from, to);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(queueProvider).value ?? PlaybackQueue.empty;
    final player = ref.read(playerControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    if (queue.isEmpty) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.queueIsEmpty)),
      );
    }
    final selected = {for (final i in _selected) if (i < queue.length) i};

    Widget list() => SmoothScroll(
          builder: (scroll) => ReorderableListView.builder(
            scrollController: scroll,
            padding: widget.padding,
            shrinkWrap: widget.shrinkWrap,
            buildDefaultDragHandles: false,
            itemCount: queue.length,
            onReorderItem: (from, to) => _onDrop(from, to, queue.length),
            proxyDecorator: (child, index, animation) =>
                reorderProxy(context, child, animation, group: selected.contains(index) ? selected.length : 1),
            itemBuilder: (context, i) {
              final track = queue.tracks[i];
              final isPast = i < queue.index;
              return Dismissible(
                // Index in the key: the same song may be queued twice.
                key: ValueKey('q-${track.id}-$i-${queue.length}'),
                direction: _selecting ? DismissDirection.none : DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  color: scheme.errorContainer,
                  child: Icon(Icons.remove_circle_outline_rounded, color: scheme.onErrorContainer),
                ),
                onDismissed: (_) => player.removeAt(i),
                child: reorderRow(
                  index: i,
                  child: AnimatedOpacity(
                    duration: context.motion.d(PrismMotion.medium),
                    opacity: isPast ? 0.5 : 1,
                    child: TrackTile(
                      track: track,
                      longPressActions: !reorderByLongPress,
                      leading: _selecting ? Checkbox(value: selected.contains(i), onChanged: (_) => _toggle(i)) : null,
                      onTap: _selecting ? () => _toggle(i) : () => player.jumpTo(i),
                      trailing: reorderByLongPress
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                tooltip: l10n.more,
                                icon: const Icon(Icons.more_vert_rounded, size: 20),
                                onPressed: () => showTrackActions(context, ref, track),
                              ),
                              ReorderHandle(index: i),
                            ])
                          : ReorderHandle(index: i),
                    ),
                  ),
                ),
              );
            },
          ),
        );
    if (widget.shrinkWrap) return list();

    return Column(children: [
      if (_selecting && selected.isNotEmpty)
        SelectionBar(
          count: selected.length,
          topLabel: l10n.playNext,
          // "Top" of a queue is right after the song that is playing.
          onTop: () {
            final before = selected.where((i) => i <= queue.index).length;
            _moveGroup(selected, queue.index + 1 - before, queue.length);
          },
          onBottom: () => _moveGroup(selected, queue.length, queue.length),
          onRemove: () async {
            await player.removeMany(selected);
            _clear();
          },
          onClear: _clear,
        )
      else if (!widget.shrinkWrap)
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: l10n.orderSelect,
            visualDensity: VisualDensity.compact,
            icon: Icon(_selecting ? Icons.checklist_rtl_rounded : Icons.checklist_rounded, size: 18),
            onPressed: () => _selecting ? _clear() : setState(() => _selecting = true),
          ),
        ),
      Flexible(child: list()),
    ]);
  }
}

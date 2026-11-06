import 'dart:io';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../core/theme/prism_theme_extensions.dart';
import '../../../l10n/l10n.dart';

/// Lifted look of a row being dragged. With a group, a badge says how many.
Widget reorderProxy(BuildContext context, Widget child, Animation<double> animation, {int group = 1}) {
  final scheme = Theme.of(context).colorScheme;
  return AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final t = Curves.easeOut.transform(animation.value);
      return Transform.scale(
        scale: lerpDouble(1, 1.03, t)!,
        child: Material(
          elevation: lerpDouble(0, 10, t)!,
          color: scheme.surfaceContainerHigh,
          borderRadius: context.shape.medium,
          child: group > 1
              ? Stack(children: [
                  child!,
                  Positioned(
                    right: 56,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: scheme.onSurface, borderRadius: BorderRadius.circular(10)),
                      child: Text('$group', style: TextStyle(color: scheme.surface, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ])
              : child,
        ),
      );
    },
    child: child,
  );
}

/// True where press-and-hold on the row starts a drag.
bool get reorderByLongPress => Platform.isAndroid;

/// Phones: hold the row anywhere. Windows: the handle only.
Widget reorderRow({required int index, required Widget child, bool enabled = true}) =>
    enabled && reorderByLongPress ? ReorderableDelayedDragStartListener(index: index, child: child) : child;

class ReorderHandle extends StatelessWidget {
  const ReorderHandle({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) => ReorderableDragStartListener(
        index: index,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: MouseRegion(cursor: SystemMouseCursors.grab, child: Icon(Icons.drag_indicator_rounded)),
        ),
      );
}

/// Shown while rows are selected: count and what can be done with them.
class SelectionBar extends StatelessWidget {
  const SelectionBar({
    super.key,
    required this.count,
    required this.onTop,
    required this.onBottom,
    required this.onRemove,
    required this.onClear,
    this.topLabel,
  });

  final int count;
  final VoidCallback onTop, onBottom, onRemove, onClear;
  final String? topLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(children: [
          IconButton(tooltip: l10n.close, icon: const Icon(Icons.close_rounded), onPressed: onClear),
          Expanded(child: Text(l10n.orderSelected(count), style: text.labelLarge, maxLines: 1, overflow: TextOverflow.ellipsis)),
          IconButton(tooltip: topLabel ?? l10n.orderMoveTop, icon: const Icon(Icons.vertical_align_top_rounded), onPressed: onTop),
          IconButton(tooltip: l10n.orderMoveBottom, icon: const Icon(Icons.vertical_align_bottom_rounded), onPressed: onBottom),
          IconButton(tooltip: l10n.delete, icon: const Icon(Icons.delete_outline_rounded), onPressed: onRemove),
        ]),
      ),
    );
  }
}

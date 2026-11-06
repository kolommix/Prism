import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/motion/smooth_scroll.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../l10n/l10n.dart';
import '../../player/presentation/widgets/waveform_seek_bar.dart';
import '../application/editor_controller.dart';
import '../domain/edit_decision_list.dart';
import '../domain/timeline.dart';

/// Slider dialog returning the chosen value (null = cancelled).
Future<double?> askValue(BuildContext context, String title, double min, double max, double initial,
    String Function(double) format, {int? divisions}) {
  var value = initial.clamp(min, max).toDouble();
  return showDialog<double>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(format(value), style: Theme.of(context).textTheme.headlineSmall),
          Slider(value: value, min: min, max: max, divisions: divisions, onChanged: (v) => setState(() => value = v)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, value), child: Text(l10n.apply)),
        ],
      ),
    ),
  );
}

/// The segments as blocks in the order they play. Tap selects one; drag moves
/// it (handle on Windows, press and hold on a phone).
class SegmentLane extends StatelessWidget {
  const SegmentLane({
    super.key,
    required this.timeline,
    required this.cursor,
    required this.selection,
    required this.onSelect,
    required this.onMove,
  });

  final Timeline timeline;
  final Duration cursor;
  final (Duration, Duration)? selection;
  final void Function(Duration a, Duration b) onSelect;
  final void Function(int from, int to) onMove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final segments = timeline.segments;
    final starts = timeline.segmentStarts;
    final total = math.max(1, timeline.duration.inMicroseconds);
    final current = timeline.locate(cursor).$1;
    return SizedBox(
      height: 42,
      child: LayoutBuilder(builder: (context, c) {
        return ReorderableListView.builder(
          scrollDirection: Axis.horizontal,
          buildDefaultDragHandles: false,
          itemCount: segments.length,
          onReorderItem: (from, to) {
            if (to != from) onMove(from, to);
          },
          itemBuilder: (context, i) {
            final s = segments[i];
            final width = math.max(68.0, s.outputLength.inMicroseconds / total * (c.maxWidth - 8));
            final sel = selection;
            final on = sel != null && sel.$1 == starts[i] && sel.$2 == starts[i] + s.outputLength;
            final bg = on ? scheme.onSurface.withValues(alpha: 0.18) : (i == current ? scheme.surfaceContainerHighest : scheme.surfaceContainerHigh);
            final content = Material(
              color: bg,
              borderRadius: BorderRadius.circular(context.shape.radius / 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(context.shape.radius / 2),
                onTap: () => onSelect(starts[i], starts[i] + s.outputLength),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(children: [
                    if (segments.length > 1) const Icon(Icons.drag_indicator_rounded, size: 14),
                    if (s.isChanged) Padding(padding: const EdgeInsets.only(left: 2, right: 4), child: _Dot(color: context.look.led)),
                    Expanded(
                      child: Text(
                        s.silent ? '— ${formatDuration(s.outputLength)}' : formatDuration(s.outputLength),
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ]),
                ),
              ),
            );
            return SizedBox(
              key: ValueKey('seg-$i-${s.sourceStart.inMilliseconds}-${s.input}'),
              width: width,
              child: Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Theme.of(context).platform == TargetPlatform.android
                    ? ReorderableDelayedDragStartListener(index: i, child: content)
                    : ReorderableDragStartListener(index: i, child: content),
              ),
            );
          },
        );
      }),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

/// Settings of the selection, or of the segment under the cursor.
class SegmentInspector extends StatelessWidget {
  const SegmentInspector({super.key, required this.state, required this.ctrl});
  final EditorState state;
  final EditorController ctrl;

  @override
  Widget build(BuildContext context) {
    final t = state.timeline!;
    final (start, end) = state.targetRange;
    final a = start.inMilliseconds, b = end.inMilliseconds;
    final (index, _) = t.locate(start);
    final s = t.segments[index];
    final text = Theme.of(context).textTheme;

    String sign(double v) => v > 0 ? '+' : '';
    String db(double v) => l10n.dbValue(sign(v), fmtNum(v, 1));
    String secs(double v) => l10n.secondsValue(fmtNum(v, 1));

    return SmoothListView(padding: const EdgeInsets.all(12), children: [
      Text(
        state.hasSelection
            ? l10n.selection(formatDuration(start), formatDuration(end))
            : l10n.edSegmentN(index + 1, t.segments.length),
        style: text.labelLarge,
      ),
      const SizedBox(height: 8),
      LiveSlider(
        key: ValueKey('speed$index${s.speed}'),
        label: l10n.speed,
        value: s.speed,
        min: minSpeed,
        max: maxSpeed,
        divisions: 75,
        format: (v) => '${fmtNum(v, 2)}x',
        onCommit: (v) => ctrl.apply(s.isRamp ? EditOp.ramp(startMs: a, endMs: b, from: v, to: s.speedEnd!) : EditOp.speed(startMs: a, endMs: b, factor: v)),
      ),
      SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.edRamp),
        value: s.isRamp,
        onChanged: (on) => ctrl.apply(on
            ? EditOp.ramp(startMs: a, endMs: b, from: s.speed, to: s.speed < 1 ? 1 : math.min(2, s.speed * 1.5))
            : EditOp.speed(startMs: a, endMs: b, factor: s.speed)),
      ),
      if (s.isRamp)
        LiveSlider(
          key: ValueKey('ramp$index${s.speedEnd}'),
          label: l10n.edRampTo,
          value: s.speedEnd!,
          min: minSpeed,
          max: maxSpeed,
          divisions: 75,
          format: (v) => '${fmtNum(v, 2)}x',
          onCommit: (v) => ctrl.apply(EditOp.ramp(startMs: a, endMs: b, from: s.speed, to: v)),
        ),
      LiveSlider(
        key: ValueKey('pitch$index${s.pitchSemitones}'),
        label: l10n.pitch,
        value: s.pitchSemitones,
        min: minPitch,
        max: maxPitch,
        divisions: 48,
        format: (v) => l10n.stValue(sign(v), fmtNum(v, 1)),
        onCommit: (v) => ctrl.apply(EditOp.pitch(startMs: a, endMs: b, semitones: v)),
      ),
      LiveSlider(
        key: ValueKey('gain$index${s.gainDb}'),
        label: l10n.edVolume,
        value: s.gainDb,
        min: minGainDb,
        max: maxGainDb,
        divisions: 72,
        format: db,
        onCommit: (v) => ctrl.apply(EditOp.gain(startMs: a, endMs: b, db: v)),
      ),
      SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.edReverse),
        value: s.reverse,
        onChanged: (_) => ctrl.apply(EditOp.reverse(startMs: a, endMs: b)),
      ),
      const Divider(height: 20),
      LiveSlider(
        key: ValueKey('fi$index${s.fadeIn}'),
        label: l10n.fadeIn2,
        value: s.fadeIn.inMilliseconds / 1000,
        min: 0,
        max: 10,
        divisions: 100,
        format: secs,
        onCommit: (v) => ctrl.apply(EditOp.segmentFade(startMs: a, endMs: b, inMs: (v * 1000).round(), outMs: s.fadeOut.inMilliseconds, curve: s.curve.name)),
      ),
      LiveSlider(
        key: ValueKey('fo$index${s.fadeOut}'),
        label: l10n.fadeOut2,
        value: s.fadeOut.inMilliseconds / 1000,
        min: 0,
        max: 10,
        divisions: 100,
        format: secs,
        onCommit: (v) => ctrl.apply(EditOp.segmentFade(startMs: a, endMs: b, inMs: s.fadeIn.inMilliseconds, outMs: (v * 1000).round(), curve: s.curve.name)),
      ),
      if (index < t.segments.length - 1)
        LiveSlider(
          key: ValueKey('xf$index${s.xfadeNext}'),
          label: l10n.edCrossfadeNext,
          value: s.xfadeNext.inMilliseconds / 1000,
          min: 0,
          max: 10,
          divisions: 100,
          format: secs,
          onCommit: (v) => ctrl.apply(EditOp.crossfade(segment: index, ms: (v * 1000).round(), curve: s.curve.name)),
        ),
      Row(children: [
        Expanded(child: Text(l10n.edCurve, style: text.bodyMedium)),
        DropdownButton<FadeCurve>(
          value: s.curve,
          underline: const SizedBox.shrink(),
          items: [for (final c in FadeCurve.values) DropdownMenuItem(value: c, child: Text(fadeCurveLabel(c)))],
          onChanged: (c) {
            if (c == null) return;
            ctrl.apply(EditOp.batch(ops: [
              EditOp.segmentFade(startMs: a, endMs: b, inMs: s.fadeIn.inMilliseconds, outMs: s.fadeOut.inMilliseconds, curve: c.name),
              if (s.xfadeNext > Duration.zero) EditOp.crossfade(segment: index, ms: s.xfadeNext.inMilliseconds, curve: c.name),
            ]));
          },
        ),
      ]),
      const Divider(height: 20),
      Text(l10n.edEq, style: text.labelLarge),
      LiveSlider(
        key: ValueKey('low$index${s.eqLowDb}'),
        label: l10n.low,
        value: s.eqLowDb,
        min: -maxEqDb,
        max: maxEqDb,
        divisions: 48,
        format: db,
        onCommit: (v) => ctrl.apply(EditOp.segmentEq(startMs: a, endMs: b, lowDb: v, midDb: s.eqMidDb, highDb: s.eqHighDb)),
      ),
      LiveSlider(
        key: ValueKey('mid$index${s.eqMidDb}'),
        label: l10n.edMid,
        value: s.eqMidDb,
        min: -maxEqDb,
        max: maxEqDb,
        divisions: 48,
        format: db,
        onCommit: (v) => ctrl.apply(EditOp.segmentEq(startMs: a, endMs: b, lowDb: s.eqLowDb, midDb: v, highDb: s.eqHighDb)),
      ),
      LiveSlider(
        key: ValueKey('high$index${s.eqHighDb}'),
        label: l10n.edHigh,
        value: s.eqHighDb,
        min: -maxEqDb,
        max: maxEqDb,
        divisions: 48,
        format: db,
        onCommit: (v) => ctrl.apply(EditOp.segmentEq(startMs: a, endMs: b, lowDb: s.eqLowDb, midDb: s.eqMidDb, highDb: v)),
      ),
      const Divider(height: 20),
      SwitchListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.edGate),
        subtitle: Text(l10n.edGateHint),
        value: s.gateDb != null,
        onChanged: (on) => ctrl.apply(EditOp.gate(startMs: a, endMs: b, db: on ? -45 : null)),
      ),
      if (s.gateDb != null)
        LiveSlider(
          key: ValueKey('gate$index${s.gateDb}'),
          label: l10n.edGateLevel,
          value: s.gateDb!,
          min: -70,
          max: -20,
          divisions: 50,
          format: db,
          onCommit: (v) => ctrl.apply(EditOp.gate(startMs: a, endMs: b, db: v)),
        ),
    ]);
  }
}

String fadeCurveLabel(FadeCurve c) => switch (c) {
      FadeCurve.linear => l10n.edCurveLinear,
      FadeCurve.smooth => l10n.edCurveSmooth,
      FadeCurve.sCurve => l10n.edCurveS,
      FadeCurve.fast => l10n.edCurveFast,
      FadeCurve.slow => l10n.edCurveSlow,
    };

/// A slider that moves freely and only commits when let go, so one drag is one
/// undo step (and one preview reload).
class LiveSlider extends StatefulWidget {
  const LiveSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.format,
    required this.onCommit,
    this.divisions,
  });

  final String label;
  final double value, min, max;
  final int? divisions;
  final String Function(double) format;
  final ValueChanged<double> onCommit;

  @override
  State<LiveSlider> createState() => _LiveSliderState();
}

class _LiveSliderState extends State<LiveSlider> {
  late double _v = widget.value.clamp(widget.min, widget.max);

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(widget.label, style: text.bodyMedium)),
        Text(widget.format(_v), style: text.labelMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
      SizedBox(
        height: 32,
        child: Slider(
          value: _v,
          min: widget.min,
          max: widget.max,
          divisions: widget.divisions,
          onChanged: (v) => setState(() => _v = v),
          onChangeEnd: widget.onCommit,
        ),
      ),
    ]);
  }
}

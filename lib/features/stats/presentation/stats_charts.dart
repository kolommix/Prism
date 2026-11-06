import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/prism_theme_extensions.dart';

import '../../../l10n/l10n.dart';
/// Reports what is under the mouse so one small tooltip can follow it.
///
/// Every chart here is one series in one hue (the theme's main color): darker
/// means more, values are in the tooltip and the lists around the chart.
class _HoverLayer extends StatefulWidget {
  const _HoverLayer({required this.painter, required this.height, required this.label});

  /// Paints the chart; `hovered` is the mark under the mouse or null.
  final CustomPainter Function(int? hovered) painter;
  final double height;

  /// Mark under [local], and its tooltip text; null = nothing there.
  final (int, String)? Function(Offset local, Size size) label;

  @override
  State<_HoverLayer> createState() => _HoverLayerState();
}

class _HoverLayerState extends State<_HoverLayer> {
  int? _hovered;
  String? _text;
  Offset _at = Offset.zero;

  void _update(Offset local, Size size) {
    final hit = widget.label(local, size);
    setState(() {
      _hovered = hit?.$1;
      _text = hit?.$2;
      _at = local;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, widget.height);
        const tipW = 170.0;
        final left = (_at.dx - tipW / 2).clamp(0.0, math.max(0.0, size.width - tipW)).toDouble();
        final top = _at.dy < 44 ? _at.dy + 16 : _at.dy - 40;
        return MouseRegion(
          onHover: (e) => _update(e.localPosition, size),
          onExit: (_) => setState(() {
            _hovered = null;
            _text = null;
          }),
          child: GestureDetector(
            onTapDown: (d) => _update(d.localPosition, size),
            child: SizedBox.fromSize(
              size: size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: CustomPaint(painter: widget.painter(_hovered))),
                  if (_text != null)
                    Positioned(
                      left: left,
                      top: top,
                      width: tipW,
                      child: IgnorePointer(
                        child: Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: Text(
                                _text!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: scheme.onInverseSurface, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Thin vertical bars on a baseline, rounded at the data end, with a light
/// grid and a few axis labels.
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.values,
    required this.tooltip,
    required this.axisLabel,
    this.height = 170,
    this.unit = 'min',
  });

  final List<double> values;
  final String Function(int i) tooltip;

  /// Label under bar i, or null. Should be sparse.
  final String? Function(int i) axisLabel;
  final double height;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme.labelSmall ?? const TextStyle(fontSize: 11);
    const axis = 20.0, leftAxis = 34.0;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: context.motion.d(const Duration(milliseconds: 700)),
      curve: PrismMotion.curve,
      builder: (context, grow, _) => _HoverLayer(
        height: height,
        label: (p, size) {
          if (values.isEmpty) return null;
          final slot = (size.width - leftAxis) / values.length;
          final i = ((p.dx - leftAxis) / slot).floor();
          if (i < 0 || i >= values.length || p.dy > size.height - axis) return null;
          return (i, tooltip(i));
        },
        painter: (hovered) => _BarPainter(
          values: values,
          grow: grow,
          hovered: hovered,
          ink: scheme.primary,
          grid: scheme.onSurface.withValues(alpha: 0.08),
          label: text.copyWith(color: scheme.onSurfaceVariant, fontSize: 10.5),
          axisLabel: axisLabel,
          axis: axis,
          leftAxis: leftAxis,
          unit: unit,
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.values,
    required this.grow,
    required this.hovered,
    required this.ink,
    required this.grid,
    required this.label,
    required this.axisLabel,
    required this.axis,
    required this.leftAxis,
    required this.unit,
  });

  final List<double> values;
  final double grow, axis, leftAxis;
  final int? hovered;
  final Color ink, grid;
  final TextStyle label;
  final String? Function(int) axisLabel;
  final String unit;

  /// A round number at or above [v]: 1, 2, 5 × 10ⁿ.
  static double _niceTop(double v) {
    if (v <= 0) return 1;
    final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    for (final m in const [1.0, 2.0, 5.0, 10.0]) {
      if (m * mag >= v) return m * mag;
    }
    return 10 * mag;
  }

  void _text(Canvas canvas, String s, Offset at, {TextAlign align = TextAlign.left}) {
    final tp = TextPainter(text: TextSpan(text: s, style: label), textDirection: TextDirection.ltr)..layout();
    final dx = switch (align) {
      TextAlign.right => at.dx - tp.width,
      TextAlign.center => at.dx - tp.width / 2,
      _ => at.dx,
    };
    tp.paint(canvas, Offset(dx, at.dy));
    tp.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final chartH = size.height - axis;
    final top = _niceTop(values.reduce(math.max));
    final line = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final f in const [0.0, 0.5, 1.0]) {
      final y = chartH - chartH * f + 0.5;
      canvas.drawLine(Offset(leftAxis, y), Offset(size.width, y), line);
      final v = top * f;
      _text(canvas, v == v.roundToDouble() ? '${v.round()}' : fmtNum(v, 1), Offset(leftAxis - 8, y - 7), align: TextAlign.right);
    }
    final slot = (size.width - leftAxis) / values.length;
    final barW = math.min(18.0, math.max(2.0, slot - 2));
    final bar = Paint()..color = ink;
    final soft = Paint()..color = ink.withValues(alpha: 0.72);
    for (var i = 0; i < values.length; i++) {
      final x = leftAxis + slot * i + (slot - barW) / 2;
      final v = values[i];
      if (v > 0) {
        final h = math.max(2.0, v / top * chartH * grow);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(x, chartH - h, barW, h),
            topLeft: Radius.circular(math.min(4, barW / 2)),
            topRight: Radius.circular(math.min(4, barW / 2)),
          ),
          hovered == null || hovered == i ? bar : soft,
        );
      }
      final l = axisLabel(i);
      if (l != null) _text(canvas, l, Offset(x + barW / 2, chartH + 5), align: TextAlign.center);
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.values != values || old.grow != grow || old.hovered != hovered || old.ink != ink;
}

/// Grid of cells where a darker cell means more: weekday × hour.
class WeekHourHeatmap extends StatelessWidget {
  const WeekHourHeatmap({super.key, required this.minutes, this.height = 182});

  /// `[day * 24 + hour]`, day 0 = Monday.
  final List<double> minutes;
  final double height;

  static List<String> get days => [for (var i = 1; i <= 7; i++) weekdayShort(i)];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
      color: scheme.onSurfaceVariant,
      fontSize: 10.5,
    );
    const left = 34.0, bottom = 20.0;
    return _HoverLayer(
      height: height,
      label: (p, size) {
        final cw = (size.width - left) / 24, ch = (size.height - bottom) / 7;
        final h = ((p.dx - left) / cw).floor(), d = (p.dy / ch).floor();
        if (h < 0 || h > 23 || d < 0 || d > 6) return null;
        final m = minutes[d * 24 + h].round();
        return (d * 24 + h, '${days[d]} ${h.toString().padLeft(2, '0')}:00 · ${l10n.minutesValue(m)}');
      },
      painter: (hovered) => _HeatPainter(
        minutes: minutes,
        hovered: hovered,
        ink: scheme.primary,
        empty: scheme.onSurface.withValues(alpha: 0.05),
        ring: scheme.onSurface,
        label: style,
        left: left,
        bottom: bottom,
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  _HeatPainter({
    required this.minutes,
    required this.hovered,
    required this.ink,
    required this.empty,
    required this.ring,
    required this.label,
    required this.left,
    required this.bottom,
  });

  final List<double> minutes;
  final int? hovered;
  final Color ink, empty, ring;
  final TextStyle label;
  final double left, bottom;

  void _text(Canvas canvas, String s, Offset at, {bool centre = false}) {
    final tp = TextPainter(text: TextSpan(text: s, style: label), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(centre ? at.dx - tp.width / 2 : at.dx, at.dy));
    tp.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cw = (size.width - left) / 24, ch = (size.height - bottom) / 7;
    final top = math.max(1.0, minutes.reduce(math.max));
    for (var d = 0; d < 7; d++) {
      _text(canvas, WeekHourHeatmap.days[d], Offset(0, d * ch + ch / 2 - 7));
      for (var h = 0; h < 24; h++) {
        final v = minutes[d * 24 + h];
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(left + h * cw + 1, d * ch + 1, cw - 2, ch - 2),
          const Radius.circular(3),
        );
        // Square root: one giant evening doesn't wash out everything else.
        final f = math.sqrt(v / top);
        canvas.drawRRect(rect, Paint()..color = v <= 0 ? empty : ink.withValues(alpha: 0.18 + 0.82 * f));
        if (hovered == d * 24 + h) {
          canvas.drawRRect(
            rect,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = ring,
          );
        }
      }
    }
    for (final h in const [0, 6, 12, 18]) {
      _text(canvas, h.toString().padLeft(2, '0'), Offset(left + h * cw + cw / 2, size.height - bottom + 5), centre: true);
    }
  }

  @override
  bool shouldRepaint(_HeatPainter old) => old.minutes != minutes || old.hovered != hovered || old.ink != ink;
}

/// Days of the last weeks as small squares, one column per week.
class CalendarHeatmap extends StatelessWidget {
  const CalendarHeatmap({super.key, required this.byDay, required this.today, this.weeks = 26, this.height = 136});

  final Map<DateTime, Duration> byDay;
  final DateTime today;
  final int weeks;
  final double height;

  static List<String> get _months => [for (var i = 1; i <= 12; i++) monthShort(i)];

  DateTime _at(int week, int day) {
    // The rightmost column is this week; Monday first.
    final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day - (weeks - 1 - week) * 7 + day);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(
      color: scheme.onSurfaceVariant,
      fontSize: 10.5,
    );
    const bottom = 20.0;
    return _HoverLayer(
      height: height,
      label: (p, size) {
        final cw = size.width / weeks, ch = (size.height - bottom) / 7;
        final w = (p.dx / cw).floor(), d = (p.dy / ch).floor();
        if (w < 0 || w >= weeks || d < 0 || d > 6) return null;
        final date = _at(w, d);
        if (date.isAfter(today)) return null;
        final mins = byDay[date]?.inMinutes ?? 0;
        return (w * 7 + d, '${dateShort(date)} · ${l10n.minutesValue(mins)}');
      },
      painter: (hovered) => _CalendarPainter(
        byDay: byDay,
        today: today,
        weeks: weeks,
        at: _at,
        hovered: hovered,
        ink: scheme.primary,
        empty: scheme.onSurface.withValues(alpha: 0.05),
        ring: scheme.onSurface,
        label: style,
        bottom: bottom,
        months: _months,
      ),
    );
  }
}

class _CalendarPainter extends CustomPainter {
  _CalendarPainter({
    required this.byDay,
    required this.today,
    required this.weeks,
    required this.at,
    required this.hovered,
    required this.ink,
    required this.empty,
    required this.ring,
    required this.label,
    required this.bottom,
    required this.months,
  });

  final Map<DateTime, Duration> byDay;
  final DateTime today;
  final int weeks;
  final DateTime Function(int, int) at;
  final int? hovered;
  final Color ink, empty, ring;
  final TextStyle label;
  final double bottom;
  final List<String> months;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / weeks, ch = (size.height - bottom) / 7;
    final top = byDay.values.fold<int>(1, (m, d) => math.max(m, d.inMinutes));
    var lastMonth = -1;
    for (var w = 0; w < weeks; w++) {
      final first = at(w, 0);
      if (first.month != lastMonth) {
        if (lastMonth != -1 || first.day <= 7) {
          final tp = TextPainter(text: TextSpan(text: months[first.month - 1], style: label), textDirection: TextDirection.ltr)..layout();
          if (w * cw + tp.width <= size.width) tp.paint(canvas, Offset(w * cw + 1, size.height - bottom + 5));
          tp.dispose();
        }
        lastMonth = first.month;
      }
      for (var d = 0; d < 7; d++) {
        final date = at(w, d);
        if (date.isAfter(today)) continue;
        final side = math.min(cw, ch) - 2;
        final rect = RRect.fromRectAndRadius(Rect.fromLTWH(w * cw + 1, d * ch + 1, side, side), const Radius.circular(3));
        final mins = byDay[date]?.inMinutes ?? 0;
        canvas.drawRRect(rect, Paint()..color = mins <= 0 ? empty : ink.withValues(alpha: 0.2 + 0.8 * math.sqrt(mins / top)));
        if (hovered == w * 7 + d) {
          canvas.drawRRect(
            rect,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = ring,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_CalendarPainter old) => old.byDay != byDay || old.hovered != hovered || old.ink != ink;
}

/// Labelled horizontal bars that grow in; the value is on the right as text.
class ShareBars extends StatelessWidget {
  const ShareBars({super.key, required this.rows});

  /// Label, share 0..1 of the widest bar, value text.
  final List<(String, double, String)> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final (i, (label, share, value)) in rows.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: share.clamp(0.0, 1.0)),
                    duration: context.motion.d(Duration(milliseconds: 500 + i * 60)),
                    curve: PrismMotion.curve,
                    builder: (context, f, _) => Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: math.max(0.01, f),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 62,
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/prism_theme_extensions.dart';
import '../domain/eq_math.dart';
import '../domain/eq_settings.dart';
import '../../../l10n/l10n.dart';

const _points = 160;
const _minHz = 20.0, _maxHz = 20000.0;
const _rangeDb = 15.0;

/// Live frequency-response curve of the EQ.
///
/// * The curve is the real biquad response (same math the audio uses).
/// * Changes morph smoothly: every point tweens from the old curve to the new.
/// * Drag anywhere on it to grab the nearest band and move it up/down.
class EqResponseCurve extends StatefulWidget {
  const EqResponseCurve({super.key, required this.settings, this.onBandChanged, this.height = 220});

  final EqSettings settings;
  final void Function(int band, double db)? onBandChanged;
  final double height;

  @override
  State<EqResponseCurve> createState() => _EqResponseCurveState();
}

class _EqResponseCurveState extends State<EqResponseCurve> {
  static final _freqs = logFrequencies(_points, from: _minHz, to: _maxHz);

  /// Band grabbed by the current drag (kept for the whole gesture).
  int? _dragging;

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final onBandChanged = widget.onBandChanged;
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: widget.height,
      child: TweenAnimationBuilder<_Curve>(
        tween: _CurveTween(end: _Curve([for (final f in _freqs) eqResponseDb(settings, f)])),
        duration: context.motion.d(const Duration(milliseconds: 420)),
        curve: Curves.easeOutCubic,
        builder: (context, curve, _) => LayoutBuilder(
          builder: (context, c) {
            int nearestBand(double dx) {
              var best = 0;
              var bestDist = double.infinity;
              for (var i = 0; i < eqBandFrequencies.length; i++) {
                final d = (_xFor(eqBandFrequencies[i], c.maxWidth) - dx).abs();
                if (d < bestDist) {
                  best = i;
                  bestDist = d;
                }
              }
              return best;
            }

            double dbAt(double dy) => ((c.maxHeight / 2 - dy) / (c.maxHeight / 2) * _rangeDb).clamp(-eqMaxGainDb, eqMaxGainDb);

            return GestureDetector(
              onPanStart: onBandChanged == null ? null : (d) => _dragging = nearestBand(d.localPosition.dx),
              onPanUpdate: onBandChanged == null
                  ? null
                  : (d) {
                      _dragging ??= nearestBand(d.localPosition.dx);
                      onBandChanged(_dragging!, (dbAt(d.localPosition.dy) * 2).round() / 2);
                    },
              onPanEnd: (_) => _dragging = null,
              child: CustomPaint(
                size: Size(c.maxWidth, c.maxHeight),
                painter: _CurvePainter(
                  points: curve.values,
                  bandDbs: [for (final f in eqBandFrequencies) eqResponseDb(settings, f)],
                  enabled: settings.enabled,
                  line: scheme.primary,
                  accent: scheme.tertiary,
                  grid: scheme.onSurface.withValues(alpha: 0.12),
                  label: scheme.onSurfaceVariant,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

double _xFor(double hz, double width) =>
    math.log(hz / _minHz) / math.log(_maxHz / _minHz) * width;

class _Curve {
  const _Curve(this.values);
  final List<double> values;
}

class _CurveTween extends Tween<_Curve> {
  _CurveTween({required _Curve end}) : super(begin: end, end: end);

  @override
  _Curve lerp(double t) {
    final a = begin!.values, b = end!.values;
    return _Curve([for (var i = 0; i < b.length; i++) a[i] + (b[i] - a[i]) * t]);
  }
}

class _CurvePainter extends CustomPainter {
  _CurvePainter({
    required this.points,
    required this.bandDbs,
    required this.enabled,
    required this.line,
    required this.accent,
    required this.grid,
    required this.label,
  });

  final List<double> points;
  final List<double> bandDbs;
  final bool enabled;
  final Color line, accent, grid, label;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    double y(double db) => mid - db.clamp(-_rangeDb, _rangeDb) / _rangeDb * mid;

    // Grid: dB lines and band frequency ticks.
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final db in const [-12.0, -6.0, 0.0, 6.0, 12.0]) {
      canvas.drawLine(Offset(0, y(db)), Offset(size.width, y(db)), gridPaint..strokeWidth = db == 0 ? 1.5 : 1);
    }
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (final f in eqBandFrequencies) {
      final x = _xFor(f, size.width);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint..strokeWidth = 0.5);
      tp.text = TextSpan(
        text: f >= 1000 ? '${fmtNum((f / 1000), f >= 10000 ? 0 : 0)}k' : f.round().toString(),
        style: TextStyle(fontSize: 9, color: label),
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - tp.height));
    }
    for (final db in const [-12, 12]) {
      tp.text = TextSpan(text: l10n.dbValue(db > 0 ? '+' : '', db), style: TextStyle(fontSize: 9, color: label));
      tp.layout();
      tp.paint(canvas, Offset(4, y(db.toDouble()) - tp.height - 1));
    }

    // Curve path.
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * size.width;
      i == 0 ? path.moveTo(x, y(points[i])) : path.lineTo(x, y(points[i]));
    }
    final colors = enabled ? [line, accent] : [label.withValues(alpha: 0.5), label.withValues(alpha: 0.5)];
    // Fill between the curve and the 0 dB line.
    final fill = Path.from(path)
      ..lineTo(size.width, mid)
      ..lineTo(0, mid)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(size.width, 0),
          [colors[0].withValues(alpha: 0.28), colors[1].withValues(alpha: 0.28)],
        ),
    );
    // Soft glow + crisp line.
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(Offset.zero, Offset(size.width, 0), colors);
    canvas.drawPath(
      path,
      stroke
        ..strokeWidth = 8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawPath(
      path,
      stroke
        ..strokeWidth = 2.5
        ..maskFilter = null,
    );

    // Band handles.
    for (var i = 0; i < eqBandFrequencies.length; i++) {
      final c = Offset(_xFor(eqBandFrequencies[i], size.width), y(bandDbs[i]));
      canvas.drawCircle(c, 6, Paint()..color = enabled ? line : label);
      canvas.drawCircle(c, 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.points != points || old.enabled != enabled || old.line != line || old.accent != accent;
}

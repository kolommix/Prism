import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/prism_theme_extensions.dart';
import '../../visualizer/domain/spectrum.dart';
import '../domain/eq_math.dart';
import '../domain/eq_settings.dart';
import '../../../l10n/l10n.dart';

const _points = 180;
const _minHz = 20.0, _maxHz = 20000.0;
const _rangeDb = 15.0;

/// Space under the plot for the frequency and region labels.
const _footer = 34.0;

/// "1k", "62", "16k".
String eqFreqLabel(double f) => f >= 1000 ? '${fmtNum(f / 1000, f % 1000 == 0 ? 0 : 1)}k' : f.round().toString();

/// "1 kHz", "62 Hz".
String eqFreqLong(double f) => f >= 1000 ? l10n.khzValue(fmtNum(f / 1000, f % 1000 == 0 ? 0 : 1)) : l10n.hzValue(f.round().toString());

/// "+2.5 dB".
String eqDbLabel(double db) => l10n.dbValue(db > 0.04 ? '+' : '', fmtNum(db.abs() < 0.05 ? 0 : db, 1));

/// The EQ as one picture you can play with.
///
/// * The curve is the real biquad response (same math the audio uses) and
///   glides to every change.
/// * Each band has a handle: drag it, turn the mouse wheel over it (half a dB
///   a notch), double-click it for 0 dB. Hovering shows its frequency and gain.
/// * Behind it, softly, the spectrum of the song that plays (from the cached
///   analysis, so it costs nothing extra), to see where the music is.
class EqResponseCurve extends StatefulWidget {
  const EqResponseCurve({
    super.key,
    required this.settings,
    this.onBandChanged,
    this.height = 260,
    this.spectrum,
    this.position,
  });

  final EqSettings settings;
  final void Function(int band, double db)? onBandChanged;
  final double height;

  /// The playing song's spectrum and where in it we are (both optional).
  final BandSource? spectrum;
  final ValueListenable<Duration>? position;

  @override
  State<EqResponseCurve> createState() => _EqResponseCurveState();
}

class _EqResponseCurveState extends State<EqResponseCurve> {
  static final _freqs = logFrequencies(_points, from: _minHz, to: _maxHz);

  /// Band under the mouse, and the one grabbed by a drag (kept for the gesture).
  int? _hover;
  int? _dragging;

  int? get _active => _dragging ?? _hover;

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final onBandChanged = widget.onBandChanged;
    final scheme = Theme.of(context).colorScheme;
    final look = context.look;
    return SizedBox(
      height: widget.height,
      child: LayoutBuilder(
        builder: (context, c) {
          final plot = Size(c.maxWidth, c.maxHeight - _footer);

          int? bandAt(Offset p, {double reach = 28}) {
            int? best;
            var bestDist = reach;
            for (var i = 0; i < eqBandFrequencies.length; i++) {
              final d = (_xFor(eqBandFrequencies[i], plot.width) - p.dx).abs();
              if (d < bestDist) {
                best = i;
                bestDist = d;
              }
            }
            return best;
          }

          int nearest(Offset p) => bandAt(p, reach: double.infinity)!;
          double dbAt(double dy) => ((plot.height / 2 - dy) / (plot.height / 2) * _rangeDb).clamp(-eqMaxGainDb, eqMaxGainDb);
          void set(int band, double db) => onBandChanged?.call(band, (db * 2).round() / 2);

          return Listener(
            onPointerSignal: (e) {
              if (e is! PointerScrollEvent || onBandChanged == null) return;
              final band = bandAt(e.localPosition);
              if (band == null) return;
              // Takes the wheel only over a band, so the page still scrolls elsewhere.
              GestureBinding.instance.pointerSignalResolver.register(e, (_) {
                set(band, settings.gainsDb[band] + (e.scrollDelta.dy < 0 ? 0.5 : -0.5));
              });
            },
            child: MouseRegion(
              cursor: _active != null ? SystemMouseCursors.resizeUpDown : MouseCursor.defer,
              onHover: (e) {
                final b = bandAt(e.localPosition);
                if (b != _hover) setState(() => _hover = b);
              },
              onExit: (_) => setState(() => _hover = null),
              child: GestureDetector(
                onDoubleTapDown: (d) {
                  final b = bandAt(d.localPosition);
                  if (b != null) set(b, 0);
                },
                onVerticalDragStart: onBandChanged == null
                    ? null
                    : (d) => setState(() => _dragging = nearest(d.localPosition)),
                onVerticalDragUpdate: onBandChanged == null
                    ? null
                    : (d) {
                        _dragging ??= nearest(d.localPosition);
                        set(_dragging!, dbAt(d.localPosition.dy));
                      },
                onVerticalDragEnd: (_) => setState(() => _dragging = null),
                onVerticalDragCancel: () => setState(() => _dragging = null),
                child: Stack(
                  children: [
                    if (widget.spectrum != null && widget.position != null)
                      Positioned.fill(
                        bottom: _footer,
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _SpectrumPainter(
                              source: widget.spectrum!,
                              position: widget.position!,
                              color: scheme.onSurface.withValues(alpha: settings.enabled ? 0.10 : 0.06),
                            ),
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: TweenAnimationBuilder<_Curve>(
                        tween: _CurveTween(end: _Curve([for (final f in _freqs) eqResponseDb(settings, f)], settings.gainsDb)),
                        // While a finger or the mouse holds a point the curve
                        // follows it at once; a glide there trailed behind.
                        duration: _dragging != null ? Duration.zero : context.motion.d(const Duration(milliseconds: 320)),
                        curve: PrismMotion.curve,
                        builder: (context, curve, _) => CustomPaint(
                          painter: _CurvePainter(
                            points: curve.values,
                            gains: curve.gains,
                            target: settings.gainsDb,
                            active: _active,
                            enabled: settings.enabled,
                            line: look.monochrome ? scheme.onSurface : scheme.primary,
                            grid: scheme.onSurface.withValues(alpha: 0.08),
                            zero: scheme.onSurface.withValues(alpha: 0.22),
                            label: scheme.onSurfaceVariant,
                            bubble: scheme.surfaceContainerHighest,
                            onBubble: scheme.onSurface,
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
      ),
    );
  }
}

double _xFor(double hz, double width) => math.log(hz / _minHz) / math.log(_maxHz / _minHz) * width;

/// The response line and the band points, gliding together (points that
/// jumped ahead of their line looked broken).
class _Curve {
  const _Curve(this.values, this.gains);
  final List<double> values;
  final List<double> gains;
}

class _CurveTween extends Tween<_Curve> {
  _CurveTween({required _Curve end}) : super(begin: end, end: end);

  @override
  _Curve lerp(double t) {
    final a = begin!.values, b = end!.values;
    final ga = begin!.gains, gb = end!.gains;
    return _Curve(
      [for (var i = 0; i < b.length; i++) a[i] + (b[i] - a[i]) * t],
      [for (var i = 0; i < gb.length; i++) (i < ga.length ? ga[i] : gb[i]) + (gb[i] - (i < ga.length ? ga[i] : gb[i])) * t],
    );
  }
}

class _CurvePainter extends CustomPainter {
  _CurvePainter({
    required this.points,
    required this.gains,
    required this.target,
    required this.active,
    required this.enabled,
    required this.line,
    required this.grid,
    required this.zero,
    required this.label,
    required this.bubble,
    required this.onBubble,
  });

  final List<double> points;
  final List<double> gains;

  /// Where the points are going: the readout shows this, not a value mid-glide.
  final List<double> target;
  final int? active;
  final bool enabled;
  final Color line, grid, zero, label, bubble, onBubble;

  @override
  void paint(Canvas canvas, Size full) {
    final size = Size(full.width, full.height - _footer);
    final mid = size.height / 2;
    double y(double db) => mid - db.clamp(-_rangeDb, _rangeDb) / _rangeDb * mid;
    final ink = enabled ? line : label.withValues(alpha: 0.6);
    final tp = TextPainter(textDirection: TextDirection.ltr);
    void text(String s, Offset at, {double size = 10, Color? color, bool center = false, FontWeight? weight}) {
      tp.text = TextSpan(text: s, style: TextStyle(fontSize: size, color: color ?? label, fontWeight: weight));
      tp.layout();
      tp.paint(canvas, center ? at - Offset(tp.width / 2, 0) : at);
    }

    // Grid: dB lines, the 0 dB line stronger.
    final gridPaint = Paint()..strokeWidth = 1;
    for (final db in const [-12.0, -6.0, 6.0, 12.0]) {
      canvas.drawLine(Offset(0, y(db)), Offset(size.width, y(db)), gridPaint..color = grid);
      text(eqDbLabel(db), Offset(4, y(db) - 13), size: 9);
    }
    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), gridPaint..color = zero);

    // Regions of the sound under the plot: bass, mids, treble and in between.
    for (final r in EqRegion.values) {
      final x0 = _xFor(r.from, size.width), x1 = _xFor(r.to, size.width);
      if (r != EqRegion.subBass) {
        canvas.drawLine(Offset(x0, 0), Offset(x0, size.height), gridPaint..color = grid);
      }
      tp.text = TextSpan(text: eqRegionLabel(r), style: TextStyle(fontSize: 10, color: label.withValues(alpha: 0.8)));
      tp.layout(maxWidth: math.max(0, x1 - x0 - 4));
      tp.paint(canvas, Offset((x0 + x1) / 2 - tp.width / 2, size.height + 18));
    }
    // Band frequencies.
    for (var i = 0; i < eqBandFrequencies.length; i++) {
      final x = _xFor(eqBandFrequencies[i], size.width);
      text(eqFreqLabel(eqBandFrequencies[i]), Offset(x, size.height + 3),
          size: 10, center: true, color: i == active ? onBubble : label, weight: i == active ? FontWeight.w600 : null);
    }

    // Curve, with a soft fill towards 0 dB in the same color.
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i / (points.length - 1) * size.width;
      i == 0 ? path.moveTo(x, y(points[i])) : path.lineTo(x, y(points[i]));
    }
    final fill = Path.from(path)
      ..lineTo(size.width, mid)
      ..lineTo(0, mid)
      ..close();
    canvas.drawPath(fill, Paint()..color = ink.withValues(alpha: 0.14));
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = ink,
    );

    // Band handles: a ring on each band's own gain, a guide for the active one.
    for (var i = 0; i < eqBandFrequencies.length; i++) {
      final x = _xFor(eqBandFrequencies[i], size.width);
      final c = Offset(x, y(gains[i]));
      final on = i == active;
      if (on) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), Paint()..color = ink.withValues(alpha: 0.25));
      }
      canvas.drawCircle(c, on ? 9 : 7, Paint()..color = ink);
      canvas.drawCircle(c, on ? 5 : 3.5, Paint()..color = bubble);
    }

    // Readout of the active band.
    final a = active;
    if (a != null) {
      final x = _xFor(eqBandFrequencies[a], size.width);
      final s = '${eqFreqLong(eqBandFrequencies[a])}  ${eqDbLabel(target[a])}';
      tp.text = TextSpan(text: s, style: TextStyle(fontSize: 12, color: onBubble, fontWeight: FontWeight.w600));
      tp.layout();
      final w = tp.width + 16, h = tp.height + 8;
      final cy = y(gains[a]);
      final top = cy - 20 - h < 0 ? cy + 18 : cy - 20 - h;
      final left = (x - w / 2).clamp(0.0, size.width - w);
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w, h), const Radius.circular(8));
      canvas.drawRRect(r, Paint()..color = bubble);
      tp.paint(canvas, Offset(left + 8, top + 4));
    }
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.points != points || old.active != active || old.enabled != enabled || old.line != line || old.gains != gains;
}

/// The playing song's spectrum, as quiet bars behind the curve. Repaints with
/// the position (only while music plays; the page's ticker stops otherwise).
class _SpectrumPainter extends CustomPainter {
  _SpectrumPainter({required this.source, required this.position, required this.color}) : super(repaint: position);

  final BandSource source;
  final ValueListenable<Duration> position;
  final Color color;
  late final Float32List _levels = Float32List(source.bands);
  late final Float32List _shown = Float32List(source.bands);

  /// Band edges of the analysis (40 Hz to 16 kHz, log spaced; see analyzePcm16).
  static double _edge(int b, int bands) => 40 * math.pow(16000 / 40, b / bands).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    source.sample(position.value, _levels);
    final n = source.bands;
    final paint = Paint()..color = color;
    for (var b = 0; b < n; b++) {
      // A little smoothing so bars don't flicker.
      _shown[b] = _shown[b] * 0.55 + _levels[b] * 0.45;
      final x0 = _xFor(_edge(b, n), size.width), x1 = _xFor(_edge(b + 1, n), size.width);
      final h = _shown[b].clamp(0.0, 1.0) * size.height * 0.85;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(x0 + 0.5, size.height - h, x1 - 0.5, size.height), const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SpectrumPainter old) => old.source != source || old.color != color;
}

String eqRegionLabel(EqRegion r) => switch (r) {
      EqRegion.subBass => l10n.eqRegionSubBass,
      EqRegion.bass => l10n.eqRegionBass,
      EqRegion.lowMids => l10n.eqRegionLowMids,
      EqRegion.mids => l10n.eqRegionMids,
      EqRegion.presence => l10n.eqRegionPresence,
      EqRegion.brilliance => l10n.eqRegionBrilliance,
    };

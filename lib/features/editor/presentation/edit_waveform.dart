import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/prism_theme_extensions.dart';
import '../../../l10n/l10n.dart';
import '../../audio_fx/domain/eq_math.dart';
import '../domain/audio_analysis.dart';
import '../domain/timeline.dart';

/// Visible part of the edited timeline.
@immutable
class WaveView {
  const WaveView({required this.start, required this.length});
  final Duration start;
  final Duration length;
  Duration get end => start + length;

  /// Keeps the window inside [0, total] with at least 50 ms visible.
  WaveView clampTo(Duration total) {
    final minLen = math.min(50000, total.inMicroseconds);
    final len = Duration(microseconds: length.inMicroseconds.clamp(minLen, math.max(1, total.inMicroseconds)));
    final maxStart = total - len;
    final s = start < Duration.zero ? Duration.zero : (start > maxStart ? maxStart : start);
    return WaveView(start: s, length: len);
  }

  @override
  bool operator ==(Object other) => other is WaveView && other.start == start && other.length == length;
  @override
  int get hashCode => Object.hash(start, length);
}

/// Zoomable waveform of the **edited** result.
///
/// * One finger / mouse drag: select a range; grab an edge of the selection to
///   move just that edge. Tap: move the cursor. Double-tap: select the segment.
/// * Two fingers: pinch to zoom, move to pan. Mouse wheel: pan,
///   Ctrl + wheel: zoom around the pointer.
/// * Segments with changed settings are tinted and labelled; the drawn
///   amplitude includes per-segment gain and fades.
///
/// The view glides to where it was asked to go (by real time), and the moving
/// playhead has its own layer, so playing never repaints the waveform.
class EditWaveform extends StatefulWidget {
  const EditWaveform({
    super.key,
    required this.timeline,
    required this.pyramid,
    required this.others,
    required this.view,
    required this.onViewChanged,
    required this.selection,
    required this.onSelection,
    required this.onSelectionEnd,
    required this.cursor,
    required this.onCursor,
    required this.snapPoints,
    required this.position,
    required this.playing,
    this.beats = const [],
  });

  final Timeline timeline;
  final PeakPyramid pyramid;
  final Map<String, PeakPyramid> others;
  final WaveView view;
  final ValueChanged<WaveView> onViewChanged;
  final (Duration, Duration)? selection;
  final void Function(Duration? a, Duration? b) onSelection;
  final VoidCallback onSelectionEnd;
  final Duration cursor;
  final ValueChanged<Duration> onCursor;
  final List<Duration> Function() snapPoints;

  /// Playhead right now (called every frame while [playing]).
  final Duration Function() position;
  final bool playing;

  /// Beat marks to draw, in output time.
  final List<Duration> beats;

  @override
  State<EditWaveform> createState() => _EditWaveformState();
}

class _EditWaveformState extends State<EditWaveform> with SingleTickerProviderStateMixin {
  Duration? _dragStart;
  WaveView? _scaleStartView;
  double _scaleStartFocus = 0;
  List<Duration> _snap = const [];
  late Ticker _ticker;
  Duration _lastTick = Duration.zero;
  final _playhead = ValueNotifier<Duration>(Duration.zero);

  // The view on screen glides towards widget.view.
  late double _shownStart = widget.view.start.inMicroseconds.toDouble();
  late double _shownLength = widget.view.length.inMicroseconds.toDouble();
  final _shown = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    _syncTicker();
  }

  @override
  void didUpdateWidget(EditWaveform old) {
    super.didUpdateWidget(old);
    _syncTicker();
  }

  bool get _gliding =>
      (_shownStart - widget.view.start.inMicroseconds).abs() > 500 ||
      (_shownLength - widget.view.length.inMicroseconds).abs() > 500;

  void _syncTicker() {
    final want = widget.playing || _gliding;
    if (want && !_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    } else if (!want && _ticker.isActive) {
      _ticker.stop();
    }
    if (!widget.playing) _playhead.value = widget.cursor;
  }

  void _tick(Duration elapsed) {
    final dt = _lastTick == Duration.zero ? 0.0 : (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (widget.playing) _playhead.value = widget.position();
    if (_gliding) {
      final k = 1 - math.exp(-dt * 22);
      _shownStart += (widget.view.start.inMicroseconds - _shownStart) * k;
      _shownLength += (widget.view.length.inMicroseconds - _shownLength) * k;
      if (!_gliding) {
        _shownStart = widget.view.start.inMicroseconds.toDouble();
        _shownLength = widget.view.length.inMicroseconds.toDouble();
      }
      _shown.value++;
    } else if (!widget.playing) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _playhead.dispose();
    _shown.dispose();
    super.dispose();
  }

  Duration _timeAt(double x, double width) {
    final v = widget.view;
    final t = v.start + Duration(microseconds: (x / width * v.length.inMicroseconds).round());
    final total = widget.timeline.duration;
    return t < Duration.zero ? Duration.zero : (t > total ? total : t);
  }

  double _xOf(Duration t, double width) =>
      (t - widget.view.start).inMicroseconds / math.max(1, widget.view.length.inMicroseconds) * width;

  Duration _snapped(double x, double width) {
    final t = _timeAt(x, width);
    final perPixel = widget.view.length.inMicroseconds / math.max(1, width);
    final best = nearestSnap(_snap, t, Duration(microseconds: (perPixel * 8).round()));
    return best ?? t;
  }

  void _zoom(double factor, double focusX, double width) {
    final v = widget.view;
    final focusT = _timeAt(focusX, width);
    final newLen = Duration(microseconds: (v.length.inMicroseconds / factor).round());
    final newStart = focusT - Duration(microseconds: (focusX / width * newLen.inMicroseconds).round());
    widget.onViewChanged(WaveView(start: newStart, length: newLen).clampTo(widget.timeline.duration));
  }

  void _pan(double dx, double width) {
    final v = widget.view;
    final shift = Duration(microseconds: (-dx / width * v.length.inMicroseconds).round());
    widget.onViewChanged(WaveView(start: v.start + shift, length: v.length).clampTo(widget.timeline.duration));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Listener(
        onPointerSignal: (e) {
          if (e is! PointerScrollEvent) return;
          if (HardwareKeyboard.instance.isControlPressed) {
            _zoom(e.scrollDelta.dy < 0 ? 1.25 : 0.8, e.localPosition.dx, w);
          } else {
            _pan(-(e.scrollDelta.dy + e.scrollDelta.dx), w);
          }
        },
        child: GestureDetector(
          onTapUp: (d) {
            widget.onSelection(null, null);
            widget.onCursor(_timeAt(d.localPosition.dx, w));
          },
          onDoubleTapDown: (d) {
            final t = _timeAt(d.localPosition.dx, w);
            final tl = widget.timeline;
            final (i, _) = tl.locate(t);
            final start = tl.segmentStarts[i];
            widget.onSelection(start, start + tl.segments[i].outputLength);
          },
          onDoubleTap: () {},
          onScaleStart: (d) {
            if (d.pointerCount >= 2) {
              _scaleStartView = widget.view;
              _scaleStartFocus = d.localFocalPoint.dx;
              return;
            }
            _snap = widget.snapPoints();
            final sel = widget.selection;
            final x = d.localFocalPoint.dx;
            if (sel != null) {
              // Grab an edge: the other one stays as the anchor.
              if ((x - _xOf(sel.$1, w)).abs() < 14) {
                _dragStart = sel.$2;
                return;
              }
              if ((x - _xOf(sel.$2, w)).abs() < 14) {
                _dragStart = sel.$1;
                return;
              }
            }
            _dragStart = _snapped(x, w);
            widget.onSelection(_dragStart, _dragStart);
          },
          onScaleUpdate: (d) {
            final start = _scaleStartView;
            if (d.pointerCount >= 2 && start != null) {
              final len = Duration(microseconds: (start.length.inMicroseconds / d.scale).round());
              final focusT = start.start + Duration(microseconds: (_scaleStartFocus / w * start.length.inMicroseconds).round());
              final s = focusT - Duration(microseconds: (d.localFocalPoint.dx / w * len.inMicroseconds).round());
              widget.onViewChanged(WaveView(start: s, length: len).clampTo(widget.timeline.duration));
              // Pinching follows the fingers exactly, with no glide.
              _shownStart = s.inMicroseconds.toDouble();
              _shownLength = len.inMicroseconds.toDouble();
            } else if (_dragStart != null) {
              widget.onSelection(_dragStart, _snapped(d.localFocalPoint.dx, w));
            }
          },
          onScaleEnd: (_) {
            final selecting = _dragStart != null;
            _scaleStartView = null;
            _dragStart = null;
            if (selecting) widget.onSelectionEnd();
          },
          child: Stack(fit: StackFit.expand, children: [
            RepaintBoundary(
              child: CustomPaint(
                isComplex: true,
                painter: _WavePainter(
                  repaint: _shown,
                  timeline: widget.timeline,
                  pyramid: widget.pyramid,
                  others: widget.others,
                  start: () => _shownStart,
                  length: () => _shownLength,
                  selection: widget.selection,
                  cursor: widget.cursor,
                  beats: widget.beats,
                  wave: scheme.onSurface,
                  edited: context.look.led,
                  faint: scheme.onSurface.withValues(alpha: 0.14),
                  label: scheme.onSurfaceVariant,
                  selectionColor: scheme.onSurface.withValues(alpha: 0.12),
                ),
              ),
            ),
            RepaintBoundary(
              child: CustomPaint(
                painter: _PlayheadPainter(
                  position: _playhead,
                  shown: _shown,
                  start: () => _shownStart,
                  length: () => _shownLength,
                  visible: widget.playing,
                  color: context.look.led,
                ),
              ),
            ),
          ]),
        ),
      );
    });
  }
}

class _PlayheadPainter extends CustomPainter {
  _PlayheadPainter({
    required this.position,
    required Listenable shown,
    required this.start,
    required this.length,
    required this.visible,
    required this.color,
  }) : super(repaint: Listenable.merge([position, shown]));

  final ValueNotifier<Duration> position;
  final double Function() start, length;
  final bool visible;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible) return;
    final x = (position.value.inMicroseconds - start()) / math.max(1, length()) * size.width;
    if (x < 0 || x > size.width) return;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), Paint()
      ..color = color
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_PlayheadPainter old) => old.visible != visible || old.color != color;
}

/// Tick spacing that gives readable labels for a view length.
Duration _rulerStep(Duration length, double width) {
  const steps = [100, 250, 500, 1000, 2000, 5000, 10000, 15000, 30000, 60000, 120000, 300000, 600000];
  final msPerPixel = length.inMilliseconds / math.max(1, width);
  for (final s in steps) {
    if (s / msPerPixel >= 80) return Duration(milliseconds: s);
  }
  return const Duration(minutes: 30);
}

String _clock(Duration d, {required bool fine}) {
  final m = d.inMinutes;
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (!fine) return '$m:$s';
  final t = (d.inMilliseconds.remainder(1000) ~/ 100);
  return '$m:$s.$t';
}

class _WavePainter extends CustomPainter {
  _WavePainter({
    required Listenable repaint,
    required this.timeline,
    required this.pyramid,
    required this.others,
    required this.start,
    required this.length,
    required this.selection,
    required this.cursor,
    required this.beats,
    required this.wave,
    required this.edited,
    required this.faint,
    required this.label,
    required this.selectionColor,
  }) : super(repaint: repaint);

  final Timeline timeline;
  final PeakPyramid pyramid;
  final Map<String, PeakPyramid> others;
  final double Function() start, length;
  final (Duration, Duration)? selection;
  final Duration cursor;
  final List<Duration> beats;
  final Color wave, edited, faint, label, selectionColor;

  static const _rulerHeight = 16.0;

  @override
  void paint(Canvas canvas, Size size) {
    final viewStart = start(), viewLen = math.max(1.0, length());
    double xOf(int us) => (us - viewStart) / viewLen * size.width;
    final top = _rulerHeight;
    final mid = top + (size.height - top) / 2;
    final halfH = (size.height - top) / 2 - 4;
    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), Paint()..color = faint);

    // Ruler.
    final tp = TextPainter(textDirection: TextDirection.ltr);
    final step = _rulerStep(Duration(microseconds: viewLen.round()), size.width);
    final fine = step < const Duration(seconds: 1);
    var tick = (viewStart / step.inMicroseconds).floor() * step.inMicroseconds;
    while (tick < viewStart + viewLen) {
      final x = xOf(tick);
      canvas.drawLine(Offset(x, top - 4), Offset(x, top), Paint()..color = faint);
      tp.text = TextSpan(text: _clock(Duration(microseconds: tick), fine: fine), style: TextStyle(fontSize: 10, color: label));
      tp.layout();
      tp.paint(canvas, Offset(x + 3, 0));
      tick += step.inMicroseconds;
    }

    final starts = timeline.segmentStarts;
    final total = timeline.duration.inMicroseconds;

    // Segment backgrounds + labels.
    for (var i = 0; i < timeline.segments.length; i++) {
      final s = timeline.segments[i];
      final x0 = xOf(starts[i].inMicroseconds), x1 = xOf(starts[i].inMicroseconds + s.outputLength.inMicroseconds);
      if (x1 < 0 || x0 > size.width) continue;
      if (s.isChanged) {
        canvas.drawRect(Rect.fromLTRB(x0, top, x1, size.height), Paint()..color = edited.withValues(alpha: 0.06));
        final parts = [
          if (s.isRamp) '${fmtNum(s.speed, 2)}→${fmtNum(s.speedEnd!, 2)}x' else if (s.speed != 1) '${fmtNum(s.speed, 2)}x',
          if (s.pitchSemitones != 0) l10n.stValue(s.pitchSemitones > 0 ? '+' : '', fmtNum(s.pitchSemitones, 1)),
          if (s.gainDb != 0) l10n.dbValue(s.gainDb > 0 ? '+' : '', fmtNum(s.gainDb, 1)),
          if (s.reverse) '◂◂',
          if (s.hasEq) 'EQ',
          if (s.gateDb != null) 'gate',
        ];
        if (parts.isNotEmpty) {
          tp.text = TextSpan(text: parts.join(' · '), style: TextStyle(fontSize: 10, color: edited, fontWeight: FontWeight.w600));
          tp.layout(maxWidth: math.max(0, x1 - x0 - 6));
          tp.paint(canvas, Offset(math.max(x0, 0) + 4, top + 2));
        }
      }
      if (i > 0) canvas.drawLine(Offset(x0, top), Offset(x0, size.height), Paint()..color = label.withValues(alpha: 0.5));
    }

    // Waveform: one line per two pixels, batched per colour.
    final columns = (size.width / 2).ceil();
    final plain = Float32List(columns * 4);
    final tinted = Float32List(columns * 4);
    var nPlain = 0, nTinted = 0;
    final usPerColumn = viewLen / size.width * 2;
    final plan = timeline.toPlan();
    final totalD = timeline.duration;
    var seg = 0;
    for (var c = 0; c < columns; c++) {
      final x = c * 2.0;
      final us = viewStart + c * usPerColumn;
      if (us < 0) continue;
      if (us > total) break;
      while (seg + 1 < starts.length && us >= starts[seg + 1].inMicroseconds) {
        seg++;
      }
      final s = timeline.segments[seg];
      final inOut = Duration(microseconds: (us - starts[seg].inMicroseconds).round());
      final a = s.sourceAt(inOut);
      final b = s.sourceAt(inOut + Duration(microseconds: usPerColumn.round()));
      final from = (a < b ? a : b).inMicroseconds / 1e6, to = (a < b ? b : a).inMicroseconds / 1e6;
      final p = s.silent ? null : (s.input == null ? pyramid : others[s.input]);
      var amp = p == null ? 0.0 : p.peak(from, to);
      amp *= dbToLinear(s.gainDb + timeline.masterGainDb);
      amp *= plan.fadeFactor(Duration(microseconds: us.round()), totalD);
      amp *= _segmentFade(s, inOut);
      final h = math.max(0.6, amp.clamp(0.0, 1.0) * halfH);
      final list = s.isChanged ? tinted : plain;
      final n = (s.isChanged ? nTinted : nPlain) * 4;
      list[n] = x;
      list[n + 1] = mid - h;
      list[n + 2] = x;
      list[n + 3] = mid + h;
      if (s.isChanged) {
        nTinted++;
      } else {
        nPlain++;
      }
    }
    final linePaint = Paint()..strokeWidth = 1.4;
    if (nPlain > 0) {
      canvas.drawRawPoints(ui.PointMode.lines, Float32List.sublistView(plain, 0, nPlain * 4), linePaint..color = wave.withValues(alpha: 0.85));
    }
    if (nTinted > 0) {
      canvas.drawRawPoints(ui.PointMode.lines, Float32List.sublistView(tinted, 0, nTinted * 4), linePaint..color = edited);
    }

    // Beat marks, when they aren't a blur.
    if (beats.length > 1 && viewLen / 1e6 < 60) {
      final p = Paint()..color = label.withValues(alpha: 0.5);
      for (final b in beats) {
        final x = xOf(b.inMicroseconds);
        if (x >= 0 && x <= size.width) canvas.drawLine(Offset(x, size.height - 6), Offset(x, size.height), p);
      }
    }

    // Selection.
    final sel = selection;
    if (sel != null) {
      final a = xOf(sel.$1.inMicroseconds), b = xOf(sel.$2.inMicroseconds);
      canvas.drawRect(Rect.fromLTRB(math.min(a, b), top, math.max(a, b), size.height), Paint()..color = selectionColor);
      final edge = Paint()
        ..color = wave
        ..strokeWidth = 2;
      canvas.drawLine(Offset(a, top), Offset(a, size.height), edge);
      canvas.drawLine(Offset(b, top), Offset(b, size.height), edge);
    }

    // Cursor.
    final cx = xOf(cursor.inMicroseconds);
    canvas.drawLine(Offset(cx, top), Offset(cx, size.height), Paint()
      ..color = wave.withValues(alpha: 0.6)
      ..strokeWidth = 1.5);
  }

  double _segmentFade(Segment s, Duration inOut) {
    var f = 1.0;
    if (s.fadeIn > Duration.zero && inOut < s.fadeIn) f = inOut.inMicroseconds / s.fadeIn.inMicroseconds;
    final left = s.outputLength - inOut;
    if (s.fadeOut > Duration.zero && left < s.fadeOut) f = math.min(f, left.inMicroseconds / s.fadeOut.inMicroseconds);
    return f.clamp(0.0, 1.0);
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.timeline != timeline ||
      old.selection != selection ||
      old.cursor != cursor ||
      !identical(old.pyramid, pyramid) ||
      old.others.length != others.length ||
      old.beats.length != beats.length ||
      old.wave != wave;
}

/// Overview of the whole edit with the visible window; tap or drag to move it.
class WaveOverview extends StatelessWidget {
  const WaveOverview({
    super.key,
    required this.timeline,
    required this.pyramid,
    required this.others,
    required this.view,
    required this.onViewChanged,
  });

  final Timeline timeline;
  final PeakPyramid pyramid;
  final Map<String, PeakPyramid> others;
  final WaveView view;
  final ValueChanged<WaveView> onViewChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = timeline.duration.inMicroseconds;
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      double x(Duration d) => total == 0 ? 0 : d.inMicroseconds / total * w;
      void moveTo(double dx) {
        final center = Duration(microseconds: (dx / w * total).round());
        onViewChanged(WaveView(start: center - view.length ~/ 2, length: view.length).clampTo(timeline.duration));
      }

      return GestureDetector(
        onTapDown: (d) => moveTo(d.localPosition.dx),
        onHorizontalDragUpdate: (d) => moveTo(d.localPosition.dx),
        child: SizedBox(
          height: 36,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.shape.radius / 2),
            child: Stack(fit: StackFit.expand, children: [
              ColoredBox(color: scheme.surfaceContainerHigh),
              RepaintBoundary(
                child: CustomPaint(
                  isComplex: true,
                  painter: _OverviewPainter(timeline: timeline, pyramid: pyramid, others: others, color: scheme.onSurface.withValues(alpha: 0.5)),
                ),
              ),
              Positioned(
                left: x(view.start),
                width: math.max(6, x(view.end) - x(view.start)),
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.onSurface, width: 1.5),
                    color: scheme.onSurface.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    });
  }
}

class _OverviewPainter extends CustomPainter {
  _OverviewPainter({required this.timeline, required this.pyramid, required this.others, required this.color});

  final Timeline timeline;
  final PeakPyramid pyramid;
  final Map<String, PeakPyramid> others;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final total = timeline.duration.inMicroseconds;
    if (total <= 0) return;
    final columns = (size.width / 2).ceil();
    final pts = Float32List(columns * 4);
    final mid = size.height / 2;
    final starts = timeline.segmentStarts;
    final perColumn = total / columns;
    var seg = 0;
    for (var c = 0; c < columns; c++) {
      final us = c * perColumn;
      while (seg + 1 < starts.length && us >= starts[seg + 1].inMicroseconds) {
        seg++;
      }
      final s = timeline.segments[seg];
      final inOut = Duration(microseconds: (us - starts[seg].inMicroseconds).round());
      final a = s.sourceAt(inOut), b = s.sourceAt(inOut + Duration(microseconds: perColumn.round()));
      final p = s.silent ? null : (s.input == null ? pyramid : others[s.input]);
      final amp = p == null ? 0.0 : p.peak((a < b ? a : b).inMicroseconds / 1e6, (a < b ? b : a).inMicroseconds / 1e6);
      final h = math.max(0.5, amp * (mid - 2));
      final x = c * 2.0;
      pts[c * 4] = x;
      pts[c * 4 + 1] = mid - h;
      pts[c * 4 + 2] = x;
      pts[c * 4 + 3] = mid + h;
    }
    canvas.drawRawPoints(ui.PointMode.lines, pts, Paint()
      ..color = color
      ..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(_OverviewPainter old) =>
      old.timeline != timeline || !identical(old.pyramid, pyramid) || old.others.length != others.length || old.color != color;
}

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/seek_bar_style.dart';

String seekTimeLabel(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}

/// Everything a seek bar painter reads. The listenables drive repaints.
class SeekPaintData {
  const SeekPaintData({
    required this.progress,
    required this.pulse,
    required this.hover,
    required this.hoverT,
    required this.playT,
    required this.peaks,
    required this.levels,
    required this.live,
    required this.duration,
    required this.ink,
    required this.dim,
    required this.led,
    required this.bubble,
    required this.bubbleText,
    this.look = const SeekBarLook(),
  });

  final SeekBarLook look;

  final ValueListenable<double> progress;

  /// Seconds of animation time while playing.
  final ValueListenable<double> pulse;

  /// Pointer position 0..1 over the bar.
  final ValueListenable<double?> hover;

  /// 0..1 how far the hover look is in.
  final Animation<double> hoverT;

  /// 0..1 paused..playing, eased.
  final Animation<double> playT;
  final List<double> peaks;

  /// Live spectrum bands 0..1, empty when the song has no spectrum.
  final Float32List levels;

  /// The bars move with the music (the setting, in every style).
  final bool live;
  final Duration duration;
  final Color ink, dim, led, bubble;
  final TextStyle bubbleText;

  Listenable get all => Listenable.merge([progress, pulse, hover, hoverT, playT]);
}

/// The painter for a style.
CustomPainter seekPainterFor(SeekBarStyle style, SeekPaintData data) => switch (style) {
      SeekBarStyle.waveform => WavePainter(data),
      SeekBarStyle.ribbon => RibbonPainter(data),
      SeekBarStyle.led => LedPainter(data),
      SeekBarStyle.tuner => TunerPainter(data),
      SeekBarStyle.live => LivePainter(data),
    };

abstract class _SeekPainter extends CustomPainter {
  _SeekPainter(this.d) : super(repaint: d.all);

  final SeekPaintData d;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0) return;
    paintBar(canvas, size);
    _paintHover(canvas, size);
  }

  void paintBar(Canvas canvas, Size size);

  /// 0..1 how much the music moves things now: nothing while paused.
  double get liveMix => d.live ? d.playT.value * math.min(1.0, d.look.react) : 0;

  /// What the music does at [f] (0..1 across the bar): bass in the middle,
  /// fading to the treble at both ends. Songs without a spectrum (streamed,
  /// still analysing) wobble gently over their [peak] instead.
  double musicAt(double f, int i, double peak) {
    final bands = d.levels;
    if (bands.isNotEmpty) {
      final at = (f - 0.5).abs() * 2 * (bands.length - 1);
      final lo = at.floor(), hi = math.min(lo + 1, bands.length - 1);
      return math.pow(bands[lo] + (bands[hi] - bands[lo]) * (at - lo), 1.6).toDouble() * math.max(1.0, d.look.react);
    }
    return peak * (0.55 + 0.45 * math.sin(d.pulse.value * 3 + i * 0.7)) * math.max(1.0, d.look.react);
  }

  /// Thin marker + time bubble above the bar, the same in every style.
  void _paintHover(Canvas canvas, Size size) {
    final ht = Curves.easeOutCubic.transform(d.hoverT.value);
    final fraction = d.hover.value;
    if (fraction == null || ht <= 0.01) return;
    final hx = fraction * size.width;
    canvas.drawLine(
      Offset(hx, 0),
      Offset(hx, size.height),
      Paint()
        ..color = d.ink.withValues(alpha: 0.6 * ht)
        ..strokeWidth = 1.5,
    );
    if (d.duration <= Duration.zero) return;
    final tp = TextPainter(
      text: TextSpan(
        text: seekTimeLabel(d.duration * fraction),
        style: d.bubbleText.copyWith(color: d.bubbleText.color?.withValues(alpha: ht)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = tp.width + 14, h = tp.height + 6;
    final left = (hx - w / 2).clamp(0.0, math.max(0.0, size.width - w)).toDouble();
    final box = Rect.fromLTWH(left, -h - 6 - 4 * (1 - ht), w, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, Radius.circular(h / 2)),
      Paint()..color = d.bubble.withValues(alpha: 0.95 * ht),
    );
    tp.paint(canvas, Offset(box.left + 7, box.top + 3));
    tp.dispose();
  }

  @override
  bool shouldRepaint(covariant _SeekPainter old) =>
      old.runtimeType != runtimeType ||
      old.d.peaks != d.peaks ||
      old.d.look != d.look ||
      old.d.duration != d.duration ||
      old.d.live != d.live ||
      old.d.ink != d.ink ||
      old.d.dim != d.dim ||
      old.d.led != d.led ||
      old.d.bubble != d.bubble;
}

/// The original: a bright "comet" trail behind the playhead, bars that swell
/// around it, and on hover taller bars and a preview of the jump.
class WavePainter extends _SeekPainter {
  WavePainter(super.d);

  @override
  void paintBar(Canvas canvas, Size size) {
    final peaks = d.peaks;
    if (peaks.isEmpty) return;
    final n = peaks.length;
    final slot = size.width / n;
    final barW = math.max(1.5, math.min(slot - 1, math.max(2.0, slot * 0.55) * d.look.thickness));
    final playX = d.progress.value * size.width;
    final t = d.pulse.value;
    final ht = Curves.easeOutCubic.transform(d.hoverT.value);
    final hx = d.hover.value == null ? null : d.hover.value! * size.width;
    final mid = size.height / 2;
    // Bars use 80 % of the height at rest, all of it while hovered.
    final scaleH = size.height * (0.8 + 0.2 * ht);

    // Played part: one color, a tone shift from dim at the start to full at
    // the playhead (a trail, not a hue gradient).
    final played = Paint()
      ..shader = LinearGradient(colors: [d.ink.withValues(alpha: 0.4), d.ink])
          .createShader(Rect.fromLTWH(0, 0, math.max(1, playX), size.height));
    final idle = Paint()..color = d.dim;
    final preview = Paint()..color = d.ink.withValues(alpha: 0.35 + 0.15 * ht);
    final mix = liveMix;

    for (var i = 0; i < n; i++) {
      final x = i * slot + slot / 2;
      // A crest that travels with the playhead.
      final dist = ((x - playX) / (size.width * 0.06)).abs();
      final crest = dist < 1 ? (1 - dist) * (1 - dist) * (0.28 + 0.08 * math.sin(t * 6 + i)) : 0.0;
      final shape = mix == 0 ? peaks[i] : peaks[i] * (1 - 0.55 * mix) + musicAt(i / math.max(1, n - 1), i, peaks[i]) * 0.75 * mix;
      final h = (shape + crest).clamp(0.1, 1.0) * scaleH;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, mid), width: barW, height: h),
        Radius.circular(barW / 2),
      );
      final Paint paint;
      if (x <= playX) {
        paint = played;
      } else if (hx != null && x <= hx) {
        paint = preview; // where a click would jump to
      } else {
        paint = idle;
      }
      canvas.drawRRect(rect, paint);
    }

    if (!d.look.head) return;
    // Playhead: a solid pill, no glow.
    final head = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(playX.clamp(1.5, size.width - 1.5), mid), width: 3, height: size.height + 4),
      const Radius.circular(2),
    );
    canvas.drawRRect(head, Paint()..color = d.ink);
  }
}

/// A line that waves behind the playhead and lies flat ahead of it. The wave
/// settles into a straight line on pause and grows while hovered.
class RibbonPainter extends _SeekPainter {
  RibbonPainter(super.d);

  @override
  void paintBar(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final playX = d.progress.value * size.width;
    final ht = Curves.easeOutCubic.transform(d.hoverT.value);
    final live = d.playT.value;
    final t = d.pulse.value;
    final amp = size.height * (0.16 + 0.1 * ht) * live;
    final length = math.max(18.0, size.height * 0.9) / d.look.density;
    final k = 2 * math.pi / length;

    final mix = liveMix;
    final path = Path()..moveTo(0, mid);
    for (var x = 2.0; x < playX; x += 2) {
      // Grows out of the start of the bar and lands on the playhead.
      final ease = math.min(1.0, x / 24) * math.min(1.0, (playX - x) / 10 + 0.15);
      final swing = mix == 0 ? 1.0 : 1 + mix * (musicAt(x / size.width, x ~/ 2, 0.6) * 2.6 - 0.45);
      path.lineTo(x, mid + math.sin(x * k - t * 5) * amp * ease * swing);
    }
    path.lineTo(playX, mid);
    canvas.drawPath(
      path,
      Paint()
        ..color = d.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * d.look.thickness
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final rest = Paint()
      ..color = d.dim
      ..strokeWidth = 3 * d.look.thickness
      ..strokeCap = StrokeCap.round;
    if (playX + 6 < size.width) canvas.drawLine(Offset(playX + 6, mid), Offset(size.width - 2, mid), rest);
    final hx = d.hover.value == null ? null : d.hover.value! * size.width;
    if (hx != null && hx > playX + 6) {
      canvas.drawLine(Offset(playX + 6, mid), Offset(hx, mid), rest..color = d.ink.withValues(alpha: 0.35 + 0.15 * ht));
    }

    if (!d.look.head) return;
    final headH = size.height * (0.62 + 0.2 * ht);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(playX.clamp(2.0, size.width - 2), mid), width: 4, height: headH),
        const Radius.circular(2),
      ),
      Paint()..color = d.ink,
    );
  }
}

/// Stacks of small blocks like the meter on a hi-fi amplifier: the song's
/// shape in lit blocks, an amber column at the playhead.
class LedPainter extends _SeekPainter {
  LedPainter(super.d);

  @override
  void paintBar(Canvas canvas, Size size) {
    final peaks = d.peaks;
    if (peaks.isEmpty) return;
    final blockH = 3.0 * d.look.thickness;
    const gapV = 2.0;
    final rows = math.max(3, ((size.height + gapV) / (blockH + gapV)).floor());
    final top = size.height - rows * (blockH + gapV) + gapV;
    final slot = math.max(5.0, size.width / peaks.length);
    final cols = (size.width / slot).floor();
    final blockW = slot - 2;
    final playX = d.progress.value * size.width;
    final ht = Curves.easeOutCubic.transform(d.hoverT.value);
    final hx = d.hover.value == null ? null : d.hover.value! * size.width;

    final mix = liveMix;
    final lit = Path(), lit2 = Path(), idle = Path(), jump = Path(), head = Path();
    for (var c = 0; c < cols; c++) {
      final x = c * slot + 1;
      final isHead = d.look.head && playX >= x - 1 && playX < x + slot - 1;
      final peak = peaks[c * peaks.length ~/ cols];
      final shown = mix == 0 ? peak : peak * (1 - 0.6 * mix) + musicAt(c / math.max(1, cols - 1), c, peak) * 0.85 * mix;
      final level = isHead ? rows : math.max(1, (shown * rows).ceil().clamp(1, rows));
      for (var r = 0; r < level; r++) {
        final y = top + (rows - 1 - r) * (blockH + gapV);
        final rect = Rect.fromLTWH(x, y, blockW, blockH);
        if (isHead) {
          head.addRect(rect);
        } else if (x < playX) {
          // The tallest blocks of the played part read a little brighter.
          (r >= level - 1 ? lit : lit2).addRect(rect);
        } else if (hx != null && x < hx) {
          jump.addRect(rect);
        } else {
          idle.addRect(rect);
        }
      }
    }
    canvas.drawPath(idle, Paint()..color = d.dim);
    canvas.drawPath(jump, Paint()..color = d.ink.withValues(alpha: 0.35 + 0.15 * ht));
    canvas.drawPath(lit2, Paint()..color = d.ink.withValues(alpha: 0.7));
    canvas.drawPath(lit, Paint()..color = d.ink);
    canvas.drawPath(head, Paint()..color = d.led);
  }
}

/// A radio dial: fine ticks, taller every 5th and 10th, an amber needle, and
/// the scale swells and spreads around the needle like a lens.
class TunerPainter extends _SeekPainter {
  TunerPainter(super.d);

  @override
  void paintBar(Canvas canvas, Size size) {
    final mid = size.height / 2;
    final playX = d.progress.value * size.width;
    final ht = Curves.easeOutCubic.transform(d.hoverT.value);
    final hx = d.hover.value == null ? null : d.hover.value! * size.width;
    final slot = 6.0 / d.look.density;
    final tick = 1.5 * d.look.thickness;
    final count = (size.width / slot).floor();
    final lens = 54 + 26 * ht;

    final played = Paint()
      ..color = d.ink
      ..strokeWidth = tick
      ..strokeCap = StrokeCap.round;
    final idle = Paint()
      ..color = d.dim
      ..strokeWidth = tick
      ..strokeCap = StrokeCap.round;
    final jump = Paint()
      ..color = d.ink.withValues(alpha: 0.35 + 0.15 * ht)
      ..strokeWidth = tick
      ..strokeCap = StrokeCap.round;

    final mix = liveMix;
    for (var i = 0; i <= count; i++) {
      final raw = i * slot + 1;
      final toNeedle = raw - playX;
      final near = (1 - toNeedle.abs() / lens).clamp(0.0, 1.0);
      final swell = near * near;
      // Ticks are pushed apart near the needle.
      final x = (raw + toNeedle.sign * swell * 7).clamp(0.0, size.width);
      final base = i % 10 == 0 ? 0.92 : (i % 5 == 0 ? 0.62 : 0.34);
      final music = mix == 0 ? 0.0 : musicAt(i / math.max(1, count), i, base) * mix;
      final h = size.height * (base + (1 - base) * math.max(swell, music)).clamp(0.0, 1.0);
      final paint = raw <= playX ? played : (hx != null && raw <= hx ? jump : idle);
      canvas.drawLine(Offset(x, mid - h / 2), Offset(x, mid + h / 2), paint);
    }

    if (!d.look.head) return;
    // Needle with a small pointer on top.
    final nx = playX.clamp(1.0, size.width - 1);
    canvas.drawLine(
      Offset(nx, -3),
      Offset(nx, size.height + 3),
      Paint()
        ..color = d.led
        ..strokeWidth = 2,
    );
    final cap = Path()
      ..moveTo(nx - 4, -5)
      ..lineTo(nx + 4, -5)
      ..lineTo(nx, 0)
      ..close();
    canvas.drawPath(cap, Paint()..color = d.led);
  }
}

/// The bar is a spectrum analyser spread over its whole width: bars move with
/// the song, the played part is bright, the rest is dim. Songs without a
/// spectrum (streamed, still analysing) wobble gently over the peaks.
class LivePainter extends _SeekPainter {
  LivePainter(super.d);

  @override
  void paintBar(Canvas canvas, Size size) {
    final peaks = d.peaks;
    if (peaks.isEmpty) return;
    final n = peaks.length;
    final slot = size.width / n;
    final barW = math.max(1.5, math.min(slot - 1, math.max(2.0, slot * 0.6) * d.look.thickness));
    final playX = d.progress.value * size.width;
    final ht = Curves.easeOutCubic.transform(d.hoverT.value);
    final hx = d.hover.value == null ? null : d.hover.value! * size.width;
    final mid = size.height / 2;
    final live = d.playT.value * math.min(1.0, d.look.react);

    final played = Paint()..color = d.ink;
    final idle = Paint()..color = d.dim;
    final jump = Paint()..color = d.ink.withValues(alpha: 0.35 + 0.15 * ht);
    for (var i = 0; i < n; i++) {
      final v = musicAt(i / math.max(1, n - 1), i, peaks[i]);
      // Paused: settles into the song's quiet shape.
      final level = peaks[i] * 0.35 * (1 - live) + v * live;
      final h = math.max(3.0, level.clamp(0.0, 1.0) * size.height);
      final x = i * slot + slot / 2;
      final Paint paint = x <= playX ? played : (hx != null && x <= hx ? jump : idle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, mid), width: barW, height: h),
          Radius.circular(barW / 2),
        ),
        paint,
      );
    }
    if (!d.look.head) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(playX.clamp(1.5, size.width - 1.5), mid), width: 3, height: size.height + 4),
        const Radius.circular(2),
      ),
      Paint()..color = d.ink,
    );
  }
}

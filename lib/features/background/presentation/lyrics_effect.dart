import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../lyrics/domain/lrc.dart';
import 'background_effects.dart';

/// One line of words: its letters drawn once into a picture; every letter is a
/// piece of that picture, so letters move on their own at the cost of one draw call.
class _Line {
  _Line(this.image, this.width, this.height, this.dpr, this.src, this.centers, this.starts, this.slot)
      : age = Float32List(src.length)..fillRange(0, src.length, -1);

  final ui.Image image;

  /// Size in logical pixels; [image] is [dpr] times larger.
  final double width, height, dpr;

  /// Per letter: where it is in [image], its middle in the line, and where
  /// it starts in the text (UTF-16, as the lyrics count).
  final List<Rect> src;
  final List<Offset> centers;
  final List<int> starts;

  /// Seconds since each letter was sung; below 0 = not yet.
  final Float32List age;

  /// Place in the stack, gliding: 0 the big middle line, below 0 sung lines
  /// above it, 1 the next line under it.
  double slot;

  void dispose() => image.dispose();
}

/// The song's words as they are sung.
///
/// The line being sung is big in the middle: every letter rises in when it is
/// sung, then dances with its part of the spectrum (left letters with the
/// bass, right ones with the treble) and swells on the beat. Sung lines shrink
/// and float up into the dark, the next line waits faintly below, and the
/// song's name slides by huge and faint at the back. Before the first line,
/// and for songs without lyrics, the name and artist take the stage. Plain
/// (untimed) lyrics are spread over the song. The mouse pushes letters aside,
/// a click scatters them.
class LyricsEffect extends BackgroundEffect {
  LyricsEffect(super.params, super.color, super.accent);

  /// Built lines by number: 0 the song's name, 1.. the lyric lines.
  final _lines = <int, _Line>{};
  SongText? _for;
  bool _fresh = true;
  List<LyricLine> _timed = const [];

  /// Set for timed lyrics (word timing for the karaoke reveal).
  Lyrics? _lyrics;
  _Line? _ghost;
  double _ghostX = 0;
  double _font = 0;
  double _dpr = 1;
  int _current = 0;
  final _batch = SpriteBatch();

  /// The line shown big: 0 the song's name, then the lyric lines from 1.
  int get currentLine => _current;

  @override
  Future<void> prepare() async {}

  @override
  void resize(Size s) {
    size = s;
    _dpr = math.min(2.0, ui.PlatformDispatcher.instance.views.firstOrNull?.devicePixelRatio ?? 1);
    final font = (math.min(s.height * 0.085, s.width * 0.065) * params.size).clamp(8.0, 120.0);
    if (font != _font) {
      _font = font;
      _drop();
      _fresh = true;
    }
  }

  void _drop() {
    for (final l in _lines.values) {
      l.dispose();
    }
    _lines.clear();
    _ghost?.dispose();
    _ghost = null;
  }

  void _load(SongText? s) {
    _drop();
    _for = s;
    _fresh = true;
    _lyrics = null;
    _timed = const [];
    final l = s?.lyrics;
    if (s == null || l == null) return;
    if (l.synced) {
      _lyrics = l;
      _timed = l.lines;
    } else if ((l.plain ?? '').trim().isNotEmpty && s.duration > const Duration(seconds: 20)) {
      // No timing: spread over the song, leaving the start and end free.
      final rows = [
        for (final r in l.plain!.split('\n'))
          if (r.trim().isNotEmpty) r.trim(),
      ];
      final ms = s.duration.inMilliseconds;
      _timed = [
        for (var i = 0; i < rows.length; i++) LyricLine(Duration(milliseconds: (ms * (0.08 + 0.84 * i / rows.length)).round()), rows[i]),
      ];
    }
  }

  int _indexAt(Duration t) {
    var lo = 0, hi = _timed.length - 1, found = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (_timed[mid].time <= t) {
        found = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return found;
  }

  /// How much of lyric line [i] is sung, 0..1 of its characters.
  double _sung(int i, Duration t) {
    final l = _lyrics;
    if (l != null) return l.sungAt(i, t);
    final line = _timed[i];
    final next = i + 1 < _timed.length ? _timed[i + 1].time : line.time + const Duration(seconds: 6);
    final byLength = line.time + Duration(milliseconds: math.max(1500, line.text.length * 200));
    final end = next < byLength ? next : byLength;
    final len = (end - line.time).inMicroseconds;
    return len <= 0 ? 1 : ((t - line.time).inMicroseconds / len).clamp(0.0, 1.0);
  }

  /// Scripts whose letters join or stack (Arabic, Indic and the like): cut
  /// out of the whole drawn line, because a letter drawn alone looks different.
  static final _joined = RegExp(r'[\u0590-\u08FF\u0900-\u0DFF\u0E00-\u0EFF\u1000-\u109F\u1780-\u17FF\uFB1D-\uFDFF\uFE70-\uFEFF]');

  /// [whole]: one picture of the line as laid out (the sliding name), with
  /// room above and below so tall marks aren't cut. Otherwise every letter is
  /// drawn alone into its own padded cell: a letter's ink reaches outside its
  /// box (the mark on Й and Ё, tails of щ ц р у, f and j), so cutting boxes out
  /// of the drawn line clipped those and left pieces of the neighbours behind.
  _Line? _make(String text,
      {String sub = '', required double font, required double maxWidth, double? dpr, int maxLines = 3, double slot = 0, bool whole = false}) {
    if (text.trim().isEmpty && sub.trim().isEmpty) return null;
    final family = _for?.fontFamily;
    final d = dpr ?? _dpr;
    final full = sub.isEmpty ? text : '$text\n$sub';
    final main = ui.TextStyle(color: const Color(0xFFFFFFFF), fontSize: font, fontWeight: FontWeight.w600, height: 1.12, fontFamily: family);
    final small = ui.TextStyle(color: const Color(0xB3FFFFFF), fontSize: font * 0.42, fontWeight: FontWeight.w500, height: 1.7, fontFamily: family);
    ui.Paragraph build(double width) {
      final b = ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center, maxLines: maxLines + (sub.isEmpty ? 0 : 1), ellipsis: '…'))
        ..pushStyle(main)
        ..addText(text);
      if (sub.isNotEmpty) {
        b
          ..pushStyle(small)
          ..addText('\n$sub');
      }
      return b.build()..layout(ui.ParagraphConstraints(width: width));
    }

    var para = build(maxWidth);
    // As narrow as the text: smaller picture, and the middle is the middle.
    final tight = math.min(maxWidth, para.longestLine.ceilToDouble() + 2);
    if (tight < maxWidth) {
      para.dispose();
      para = build(tight);
    }
    final w = para.width, h = para.height;
    // Where every letter is in the line.
    final boxes = <Rect>[], chars = <String>[], starts = <int>[];
    var i = 0;
    for (final ch in full.characters) {
      final end = i + ch.length;
      if (ch.trim().isNotEmpty) {
        final found = para.getBoxesForRange(i, end);
        if (found.isNotEmpty) {
          boxes.add(found.first.toRect());
          chars.add(ch);
          starts.add(i);
        }
      }
      i = end;
    }
    if (boxes.isEmpty) {
      para.dispose();
      return null;
    }
    final centers = [for (final r in boxes) r.center];
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec)..scale(d);

    if (whole || _joined.hasMatch(full)) {
      final pad = whole ? (font * 0.3).ceilToDouble() : 0.0;
      canvas.drawParagraph(para, Offset(0, pad));
      para.dispose();
      final pic = rec.endRecording();
      final img = pic.toImageSync((w * d).ceil().clamp(1, 8192), ((h + pad * 2) * d).ceil().clamp(1, 8192));
      pic.dispose();
      final src = [for (final r in boxes) Rect.fromLTRB(r.left * d - 0.5, (r.top + pad) * d, r.right * d + 0.5, (r.bottom + pad) * d)];
      return _Line(img, w, h + pad * 2, d, src, [for (final c in centers) c.translate(0, pad)], starts, slot);
    }
    para.dispose();

    // One cell per different letter, in rows.
    const rowWidth = 2000.0;
    final cells = <String, Rect>{};
    final src = <Rect>[];
    var x = 0.0, y = 0.0, rowH = 0.0, atlasW = 1.0;
    for (var g = 0; g < boxes.length; g++) {
      final isSub = starts[g] > text.length;
      final key = isSub ? '\n${chars[g]}' : chars[g];
      var cell = cells[key];
      if (cell == null) {
        final size = isSub ? font * 0.42 : font;
        final pad = (size * 0.32).ceilToDouble();
        final cw = boxes[g].width.ceilToDouble() + pad * 2, chh = boxes[g].height.ceilToDouble() + pad * 2;
        if (x > 0 && x + cw > rowWidth) {
          x = 0;
          y += rowH;
          rowH = 0;
        }
        cell = Rect.fromLTWH(x, y, cw, chh);
        cells[key] = cell;
        x += cw;
        rowH = math.max(rowH, chh);
        atlasW = math.max(atlasW, x);
        final one = (ui.ParagraphBuilder(ui.ParagraphStyle(maxLines: 1))
              ..pushStyle(isSub ? small : main)
              ..addText(chars[g]))
            .build()
          ..layout(const ui.ParagraphConstraints(width: double.infinity));
        // The letter sits where its box is: in the middle of the cell.
        canvas
          ..save()
          ..clipRect(cell)
          ..drawParagraph(one, Offset(cell.left + pad + (boxes[g].width.ceilToDouble() - boxes[g].width) / 2, cell.top + pad + (boxes[g].height.ceilToDouble() - boxes[g].height) / 2))
          ..restore();
        one.dispose();
      }
      src.add(Rect.fromLTRB(cell.left * d, cell.top * d, cell.right * d, cell.bottom * d));
    }
    final pic = rec.endRecording();
    final img = pic.toImageSync((atlasW * d).ceil().clamp(1, 8192), ((y + rowH) * d).ceil().clamp(1, 8192));
    pic.dispose();
    return _Line(img, w, h, d, src, centers, starts, slot);
  }

  _Line? _build(int key, double slot) {
    final s = _for!;
    final width = size.width * 0.84;
    if (key == 0) {
      final line = _make(s.title.isEmpty ? 'Prism' : s.title, sub: s.artist, font: _font * 1.15, maxWidth: width, maxLines: 2, slot: slot);
      // The name comes in letter by letter.
      if (line != null) {
        for (var g = 0; g < line.age.length; g++) {
          line.age[g] = -0.05 - g * 0.035;
        }
      }
      return line;
    }
    return _make(_timed[key - 1].text, font: _font, maxWidth: width, slot: slot);
  }

  void _buildGhost() {
    final s = _for!;
    final text = s.artist.isEmpty ? '${s.title}     ' : '${s.title}  ·  ${s.artist}     ';
    var font = math.min(size.height * 0.3, 260.0);
    var g = _make(text, font: font, maxWidth: 1e6, dpr: 1, maxLines: 1, whole: true);
    if (g != null && g.width > 6000) {
      font *= 6000 / g.width;
      g.dispose();
      g = _make(text, font: font, maxWidth: 1e6, dpr: 1, maxLines: 1, whole: true);
    }
    _ghost = g;
  }

  @override
  void step(double dt) {
    super.step(dt);
    if (song != _for) _load(song);
    if (_for == null || size.isEmpty) return;
    if (_ghost == null) _buildGhost();
    _ghostX += dt * params.speed * (16 + bass * 40);

    final pos = songPosition;
    final li = _indexAt(pos);
    final cur = li + 1;
    final jumped = _fresh || (cur - _current).abs() > 2;
    _current = cur;

    // Keep the lines around the current one, a sung one more to fade out.
    _lines.removeWhere((key, line) {
      final gone = key < cur - 5 || key > cur + 1;
      if (gone) line.dispose();
      return gone;
    });
    for (var key = cur - 4; key <= cur + 1; key++) {
      if (key < 0 || key > _timed.length || _lines.containsKey(key)) continue;
      // A new next line rises from below; after a jump all sit in place.
      final slot = (key - cur) + (!jumped && key > cur ? 0.8 : 0.0);
      final line = _build(key, slot.toDouble());
      if (line != null) _lines[key] = line;
    }
    _fresh = false;

    final glide = 1 - math.exp(-dt * 5);
    final sungChars = li >= 0 ? _sung(li, pos) * _timed[li].text.length : 0.0;
    for (final MapEntry(:key, value: line) in _lines.entries) {
      final target = (key - cur).toDouble();
      line.slot = jumped ? target : line.slot + (target - line.slot) * glide;
      final age = line.age;
      if (key == 0) {
        for (var g = 0; g < age.length; g++) {
          age[g] += dt;
        }
      } else if (key < cur) {
        for (var g = 0; g < age.length; g++) {
          age[g] = age[g] < 0 ? (jumped ? 5 : 0) : age[g] + dt;
        }
      } else if (key == cur) {
        for (var g = 0; g < age.length; g++) {
          age[g] = line.starts[g] < sungChars ? (age[g] < 0 ? 0 : age[g] + dt) : -1;
        }
      } else {
        age.fillRange(0, age.length, -1);
      }
    }
  }

  static double _scaleOf(int k) => k == 0 ? 1 : (k > 0 ? 0.5 : 0.6 * math.pow(0.78, -k - 1).toDouble());
  static double _alphaOf(int k) => switch (k) {
        0 => 1,
        1 => 0.32,
        -1 => 0.42,
        -2 => 0.26,
        -3 => 0.18,
        -4 => 0.08,
        _ => 0,
      };

  @override
  void paint(Canvas canvas) {
    if (_for == null || size.isEmpty) return;
    final w = size.width, h = size.height;
    final bright = params.brightness;

    // The song's name, huge and faint, sliding by at the back, low where nothing else is.
    final g = _ghost;
    if (g != null) {
      final paint = Paint()
        ..filterQuality = FilterQuality.low
        ..colorFilter = ColorFilter.mode(color.withValues(alpha: (0.06 + bass * 0.04) * bright), BlendMode.modulate);
      final srcRect = Rect.fromLTWH(0, 0, g.image.width.toDouble(), g.image.height.toDouble());
      final y = h * 0.86 - g.height / 2;
      for (var x = -(_ghostX % g.width); x < w; x += g.width) {
        canvas.drawImageRect(g.image, srcRect, Rect.fromLTWH(x, y, g.width, g.height), paint);
      }
    }

    // Where each place in the stack is: lines stacked by their real heights.
    final gap = _font * 0.35;
    double heightAt(int k) => (_lines[_current + k]?.height ?? _font * 1.12) * _scaleOf(k);
    final ys = Float64List(9); // places -5..3
    double yOf(int k) => ys[k + 5];
    ys[5] = h * 0.56;
    for (var k = -1; k >= -5; k--) {
      ys[k + 5] = yOf(k + 1) - heightAt(k + 1) / 2 - gap * _scaleOf(k) - heightAt(k) / 2;
    }
    for (var k = 1; k <= 3; k++) {
      ys[k + 5] = yOf(k - 1) + heightAt(k - 1) / 2 + gap + heightAt(k) / 2;
    }

    final p = pointer;
    final mouse = params.mouse;
    for (final MapEntry(:key, value: line) in _lines.entries) {
      final s = line.slot.clamp(-5.0, 3.0);
      final f = math.min(2, s.floor()), t = s - f;
      final y = yOf(f) + (yOf(f + 1) - yOf(f)) * t;
      final sc = _scaleOf(f) + (_scaleOf(f + 1) - _scaleOf(f)) * t;
      final alpha = (_alphaOf(f) + (_alphaOf(f + 1) - _alphaOf(f)) * t) * bright;
      if (alpha < 0.005) continue;
      final dance = math.max(0.0, 1 - s.abs() * 2);
      final sway = s < 0 ? math.sin(time * 0.35 + key * 1.7) * _font * 0.5 * math.min(1.0, -s) : 0.0;
      final n = line.src.length;
      for (var j = 0; j < n; j++) {
        final c = line.centers[j];
        var x = w / 2 + sway + (c.dx - line.width / 2) * sc;
        var yy = y + (c.dy - line.height / 2) * sc;
        var a = alpha;
        var hot = 0.0;
        var gs = sc;
        final age = line.age[j];
        if (age < 0) {
          // The name: not in yet. A lyric line: waiting to be sung, faint.
          if (key == 0) continue;
          if (s < 0.5) a *= 0.22;
        } else {
          final rise = math.min(1.0, age / 0.28);
          final e = 1 - math.pow(1 - rise, 3).toDouble();
          yy += (1 - e) * _font * 0.45 * sc;
          a *= 0.2 + 0.8 * e;
          hot = math.max(0.0, 1 - age / 0.9);
          if (dance > 0) {
            final band = levelAt(n == 1 ? 0 : j / (n - 1));
            yy -= (band * _font * 0.32 + math.sin(time * 1.6 + j * 0.45) * _font * 0.035) * dance;
            gs *= 1 + (bass * 0.07 + band * 0.05) * dance;
            hot += bass * 0.3 * dance;
          }
        }
        if (p != null && mouse > 0) {
          final dx = x - p.dx, dy = yy - p.dy;
          final d2 = dx * dx + dy * dy;
          const r = 160.0;
          if (d2 < r * r && d2 > 0.01) {
            final d = math.sqrt(d2);
            final k = (1 - d / r) * (1 - d / r) * mouse;
            x += dx / d * k * 22;
            yy += dy / d * k * 22;
            hot += k * 0.6;
          }
        }
        for (final wv in waves) {
          final dx = x - wv.at.dx, dy = yy - wv.at.dy;
          final d = math.sqrt(dx * dx + dy * dy);
          final off = (d - wv.radius).abs();
          if (off < 80 && d > 0.01) {
            final k = (1 - off / 80) * wv.power;
            x += dx / d * k * 26;
            yy += dy / d * k * 26;
            hot += k * 0.5;
          }
        }
        if (a < 0.01) continue;
        final r = line.src[j];
        _batch.add(gs / line.dpr, x, yy, 0, r.left, r.top, r.right, r.bottom, mixArgb(color, accent, hot, a.clamp(0.0, 1.0)));
      }
      _batch.flush(canvas, line.image);
    }
  }

  @override
  void dispose() {
    _drop();
    super.dispose();
  }
}

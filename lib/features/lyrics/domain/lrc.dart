import 'dart:math' as math;

/// One word of a line with its own time (enhanced LRC).
class LyricWord {
  const LyricWord(this.time, this.text);
  final Duration time;

  /// Includes its trailing space, so the words join back into the line.
  final String text;

  @override
  bool operator ==(Object other) => other is LyricWord && other.time == time && other.text == text;
  @override
  int get hashCode => Object.hash(time, text);
}

/// One timed lyric line.
class LyricLine {
  const LyricLine(this.time, this.text, {this.words = const []});
  final Duration time;
  final String text;

  /// Word timing when the file has it; empty otherwise.
  final List<LyricWord> words;

  @override
  bool operator ==(Object other) => other is LyricLine && other.time == time && other.text == text;
  @override
  int get hashCode => Object.hash(time, text);
  @override
  String toString() => '[${time.inMilliseconds}] $text';
}

/// Lyrics for a track: synced lines and/or plain text.
class Lyrics {
  const Lyrics({this.lines = const [], this.plain, required this.source});

  /// Sorted by time; empty when only plain text is known.
  final List<LyricLine> lines;
  final String? plain;

  /// Where they came from: `lrc-file`, `embedded`, `lrclib`.
  final String source;

  bool get synced => lines.isNotEmpty;
  bool get isEmpty => lines.isEmpty && (plain == null || plain!.trim().isEmpty);

  /// Some line has word timing.
  bool get hasWordTiming => lines.any((l) => l.words.isNotEmpty);

  /// Index of the line being sung at [t] (−1 before the first line).
  int indexAt(Duration t) {
    var lo = 0, hi = lines.length - 1, found = -1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      if (lines[mid].time <= t) {
        found = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return found;
  }

  /// 0..1 progress through line [i] at [t] (for the karaoke wipe). The last
  /// line uses [lastLineLength].
  double progressAt(int i, Duration t, {Duration lastLineLength = const Duration(seconds: 4)}) {
    if (i < 0 || i >= lines.length) return 0;
    final start = lines[i].time;
    final end = i + 1 < lines.length ? lines[i + 1].time : start + lastLineLength;
    final len = (end - start).inMicroseconds;
    if (len <= 0) return 1;
    return ((t - start).inMicroseconds / len).clamp(0.0, 1.0);
  }

  /// When line [i] is probably over. A long instrumental gap before the next
  /// line must not make the wipe crawl, so it's limited by the line's length.
  Duration _sungEnd(int i) {
    final line = lines[i];
    final byLength = Duration(milliseconds: math.max(2000, line.text.length * 220));
    final capped = line.time + byLength;
    if (i + 1 >= lines.length) return capped;
    final next = lines[i + 1].time;
    return next < capped ? next : capped;
  }

  /// The last word has no next tag: until the next line, at most 1.5 s.
  Duration _lastWordEnd(int i, LyricWord word) {
    final capped = word.time + const Duration(milliseconds: 1500);
    if (i + 1 >= lines.length) return capped;
    final next = lines[i + 1].time;
    return next < capped ? next : capped;
  }

  /// How much of line [i]'s text is sung at [t], 0..1 of its characters. Uses
  /// word timing when there is some, otherwise an even pace over the line.
  double sungAt(int i, Duration t) {
    if (i < 0 || i >= lines.length) return 0;
    final line = lines[i];
    final total = line.text.length;
    if (total == 0) return 1;
    if (t <= line.time) return 0;
    if (line.words.isEmpty) {
      final end = _sungEnd(i);
      final len = (end - line.time).inMicroseconds;
      return len <= 0 ? 1 : ((t - line.time).inMicroseconds / len).clamp(0.0, 1.0);
    }
    var done = 0;
    for (var w = 0; w < line.words.length; w++) {
      final word = line.words[w];
      final wordEnd = w + 1 < line.words.length ? line.words[w + 1].time : _lastWordEnd(i, word);
      if (t < word.time) return done / total;
      if (t < wordEnd) {
        final len = (wordEnd - word.time).inMicroseconds;
        final inside = len <= 0 ? 1.0 : (t - word.time).inMicroseconds / len;
        return ((done + word.text.length * inside) / total).clamp(0.0, 1.0);
      }
      done += word.text.length;
    }
    return 1;
  }
}

final _timeTag = RegExp(r'\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]');
final _wordTag = RegExp(r'<(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?>');
final _offsetTag = RegExp(r'^\[offset:\s*([+-]?\d+)\]', caseSensitive: false);

Duration _time(String min, String sec, String? frac) {
  final ms = frac == null ? 0 : (frac.length == 3 ? int.parse(frac) : int.parse(frac.padRight(2, '0')) * 10);
  return Duration(minutes: int.parse(min), seconds: int.parse(sec), milliseconds: ms);
}

/// Words of an enhanced line. [stamp] is the line's time in the file, [shift]
/// moves everything (several line stamps, file offset).
List<LyricWord> _parseWords(String rest, Duration stamp, Duration shift) {
  final tags = _wordTag.allMatches(rest).toList();
  if (tags.isEmpty) return const [];
  final out = <LyricWord>[];
  final first = _time(tags.first[1]!, tags.first[2]!, tags.first[3]);
  // Words before the first tag start with the line.
  final lead = rest.substring(0, tags.first.start);
  if (lead.trim().isNotEmpty) out.add(LyricWord(stamp + shift, lead));
  // A repeated line has only one set of tags: they count from its first time.
  final base = first >= stamp ? stamp : first;
  for (var i = 0; i < tags.length; i++) {
    final t = _time(tags[i][1]!, tags[i][2]!, tags[i][3]);
    final end = i + 1 < tags.length ? tags[i + 1].start : rest.length;
    final text = rest.substring(tags[i].end, end);
    if (text.isEmpty) continue;
    out.add(LyricWord(t - base + stamp + shift, text));
  }
  return out;
}

/// Parses LRC text. Supports several timestamps per line
/// (`[00:12.00][01:02.00]chorus`), `[offset:+250]`, hundredths or
/// milliseconds, and enhanced word tags (`<00:12.30>`). Returns an empty list
/// when the text has no timestamps (= plain lyrics).
List<LyricLine> parseLrc(String text) {
  var offsetMs = 0;
  final out = <LyricLine>[];
  for (final raw in text.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    final off = _offsetTag.firstMatch(line);
    if (off != null) {
      offsetMs = int.parse(off.group(1)!);
      continue;
    }
    final stamps = <Duration>[];
    var rest = line;
    while (true) {
      final m = _timeTag.matchAsPrefix(rest);
      if (m == null) break;
      stamps.add(_time(m.group(1)!, m.group(2)!, m.group(3)));
      rest = rest.substring(m.end);
    }
    if (stamps.isEmpty) continue; // metadata tags like [ar:...] or plain text
    final words = rest.replaceAll(_wordTag, '').trim();
    for (final s in stamps) {
      // A positive offset means lyrics appear earlier.
      final shift = -Duration(milliseconds: offsetMs);
      final t = s + shift;
      final timed = _parseWords(rest, s, shift);
      out.add(LyricLine(t < Duration.zero ? Duration.zero : t, words, words: timed));
    }
  }
  return cleanLines(out);
}

/// Repairs what bad LRC files do: lines out of order, the same line twice, two
/// lines on one timestamp (which would flash past: they become one line), and
/// words timed outside their line.
List<LyricLine> cleanLines(List<LyricLine> lines) {
  final sorted = [...lines]..sort((a, b) => a.time.compareTo(b.time));
  final out = <LyricLine>[];
  for (final l in sorted) {
    if (out.isNotEmpty && out.last.time == l.time) {
      if (l.text == out.last.text || l.text.isEmpty) continue;
      out[out.length - 1] = out.last.text.isEmpty ? l : LyricLine(l.time, '${out.last.text}\n${l.text}');
      continue;
    }
    out.add(l);
  }
  // Word times must stay in order and inside their own line.
  return [
    for (var i = 0; i < out.length; i++)
      if (out[i].words.isEmpty)
        out[i]
      else
        LyricLine(out[i].time, out[i].text, words: _clampWords(out[i], i + 1 < out.length ? out[i + 1].time : null)),
  ];
}

List<LyricWord> _clampWords(LyricLine line, Duration? next) {
  var last = line.time;
  return [
    for (final w in line.words)
      () {
        var t = w.time < last ? last : w.time;
        if (next != null && t > next) t = next;
        last = t;
        return LyricWord(t, w.text);
      }(),
  ];
}

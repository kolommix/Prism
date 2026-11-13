import 'dart:math' as math;

import 'external_track.dart';
import 'matching.dart';

/// Picture file types a photo import takes.
const photoExtensions = ['png', 'jpg', 'jpeg', 'webp', 'bmp', 'heic', 'heif', 'gif'];

bool isPhotoFile(String path) {
  final dot = path.lastIndexOf('.');
  if (dot < 0) return false;
  return photoExtensions.contains(path.substring(dot + 1).toLowerCase());
}

/// One word the text reader found, in picture pixels.
class OcrWord {
  const OcrWord(this.text, this.x, this.y, this.w, this.h);
  final String text;
  final double x, y, w, h;
  double get right => x + w;
  double get bottom => y + h;
}

/// A run of words on one row (one line of the reader, or a column of it).
class OcrLine {
  OcrLine(this.words)
      : x = words.map((w) => w.x).reduce(math.min),
        y = words.map((w) => w.y).reduce(math.min),
        right = words.map((w) => w.right).reduce(math.max),
        bottom = words.map((w) => w.bottom).reduce(math.max);
  final List<OcrWord> words;
  final double x, y, right, bottom;
  double get h => bottom - y;
  double get centerX => (x + right) / 2;
  double get centerY => (y + bottom) / 2;
  String get text => words.map((w) => w.text).join(' ');
}

/// What the reader saw in one picture.
class OcrPage {
  const OcrPage(this.width, this.height, this.lines);
  final double width, height;
  final List<OcrLine> lines;
}

// ------------------------------------------------------------ reader answer

final _latin = RegExp(r'[A-Za-zÀ-ɏ]');
final _otherLetter = RegExp(r'[Ѐ-ԯͰ-Ͽ]'); // Cyrillic, Greek
// Cyrillic letters that look like Latin ones: the Russian reader writes
// English words with them ("Ме" for "Me").
final _lookalikes = RegExp(r"^[АВЕКМНОРСТУХІЈЅаеорсухіјѕ0-9\s\-'’.,!?&()]+$");
// Signs a reader puts inside a word for a thin letter ("Chi[dish").
final _junk = RegExp(r'[\[\]{}|]');
const _nonLatinLanguages = {'ru', 'uk', 'be', 'bg', 'sr', 'mk', 'kk', 'ky', 'tg', 'mn', 'el'};

/// Turns the native answer (`prism/ocr` "read") into one page. Windows reads
/// the picture once per installed language: the Russian reader is the base,
/// and on rows that are mostly English its look-alike letters are swapped for
/// what the English reader saw in the same place.
OcrPage ocrPageFromNative(Map<Object?, Object?> raw) {
  final engines = <(String, List<OcrLine>)>[
    for (final e in (raw['engines'] as List? ?? const []).whereType<Map>())
      (
        '${e['lang'] ?? ''}',
        [
          for (final l in (e['lines'] as List? ?? const []).whereType<List>())
            if (_words(l) case final words when words.isNotEmpty) OcrLine(words),
        ],
      ),
  ];
  final width = (raw['width'] as num?)?.toDouble() ?? 0;
  final height = (raw['height'] as num?)?.toDouble() ?? 0;
  if (engines.isEmpty) return OcrPage(width, height, const []);
  bool nonLatin(String lang) => _nonLatinLanguages.contains(lang.split(RegExp('[-_+]')).first.toLowerCase());
  final base = engines.where((e) => nonLatin(e.$1)).firstOrNull;
  final helper = engines.where((e) => !nonLatin(e.$1)).firstOrNull;
  if (base == null || helper == null) return OcrPage(width, height, (base ?? engines.first).$2);
  return OcrPage(width, height, mergeReadings(base.$2, helper.$2));
}

List<OcrWord> _words(List<Object?> raw) => [
      for (final w in raw.whereType<Map>())
        if ('${w['text'] ?? ''}'.trim().isNotEmpty)
          OcrWord(
            '${w['text']}'.trim(),
            (w['x'] as num?)?.toDouble() ?? 0,
            (w['y'] as num?)?.toDouble() ?? 0,
            (w['w'] as num?)?.toDouble() ?? 0,
            (w['h'] as num?)?.toDouble() ?? 0,
          ),
    ];

bool _isLatinWord(String s) => _latin.hasMatch(s) && !_otherLetter.hasMatch(s);

/// [base] read by a Cyrillic reader, [helper] by a Latin one, same picture.
List<OcrLine> mergeReadings(List<OcrLine> base, List<OcrLine> helper) {
  final helperWords = [for (final l in helper) ...l.words];
  OcrWord? sameSpot(OcrWord w) {
    OcrWord? best;
    var bestOverlap = 0.3;
    for (final h in helperWords) {
      final ix = math.min(w.right, h.right) - math.max(w.x, h.x);
      final iy = math.min(w.bottom, h.bottom) - math.max(w.y, h.y);
      if (ix <= 0 || iy <= 0) continue;
      final union = w.w * w.h + h.w * h.h - ix * iy;
      final overlap = union <= 0 ? 0.0 : ix * iy / union;
      if (overlap > bestOverlap) {
        bestOverlap = overlap;
        best = h;
      }
    }
    return best;
  }

  OcrLine? sameRow(OcrLine line) {
    for (final h in helper) {
      final ix = math.min(line.right, h.right) - math.max(line.x, h.x);
      final iy = math.min(line.bottom, h.bottom) - math.max(line.y, h.y);
      if (ix <= 0 || iy <= 0) continue;
      final a = (line.right - line.x) * line.h, b = (h.right - h.x) * h.h;
      if (ix * iy / (a + b - ix * iy) < 0.6) continue;
      final clean = h.words.every((w) => !_junk.hasMatch(w.text) && !_otherLetter.hasMatch(w.text));
      return clean ? h : null;
    }
    return null;
  }

  return [
    for (final line in base)
      () {
        final latin = line.words.where((w) => _isLatinWord(w.text)).length;
        final other = line.words.where((w) => _otherLetter.hasMatch(w.text)).length;
        if (other == 0) {
          // A Latin row: the Latin reader's own reading of it is better (the
          // Russian one drops "I" and lowers capitals), when it is clean.
          final same = sameRow(line);
          if (same != null) return same;
          if (!line.words.any((w) => _junk.hasMatch(w.text))) return line;
          OcrWord clean(OcrWord w) {
            if (!_junk.hasMatch(w.text)) return w;
            final h = sameSpot(w);
            return h != null && !_junk.hasMatch(h.text) && _isLatinWord(h.text) ? OcrWord(h.text, w.x, w.y, w.w, w.h) : w;
          }

          return OcrLine([for (final w in line.words) clean(w)]);
        }
        final allLookalike = line.words.every((w) => !_otherLetter.hasMatch(w.text) || _lookalikes.hasMatch(w.text));
        final englishRow = (latin > 0 && latin >= other) || (latin == 0 && allLookalike);
        if (!englishRow) return line;
        OcrWord swap(OcrWord w) {
          if (!_otherLetter.hasMatch(w.text)) return w;
          final h = sameSpot(w);
          return h != null && _isLatinWord(h.text) ? OcrWord(h.text, w.x, w.y, w.w, w.h) : w;
        }

        return OcrLine([for (final w in line.words) swap(w)]);
      }(),
  ];
}

// ----------------------------------------------------------------- songs

final _duration = RegExp(r'^\(?(\d{1,2}):(\d{2})(?::(\d{2}))?\)?$');
final _letter = RegExp(r'\p{L}', unicode: true);
final _digit = RegExp(r'\d');
final _counts = RegExp(
  r'\d+\s*(songs?|tracks?|треков|трека|трек|песен|песни|песня|composiciones|titres|min|mins|мин|hr|hrs|h|ч|likes?|saves?|'
  r'followers?|listeners?|plays?|views?|подписчик\w*|слушател\w*|прослушиван\w*|просмотр\w*|лайк\w*)\b',
  unicode: true,
  caseSensitive: false,
);
// Buttons and headings of music apps: never a song name on their own.
const _uiWords = {
  'play', 'pause', 'shuffle', 'shuffle play', 'download', 'downloaded', 'downloading', 'follow', 'following', 'share',
  'search', 'home', 'library', 'your library', 'liked songs', 'add', 'add songs', 'edit', 'sort', 'filter', 'more',
  'playlist', 'public playlist', 'album', 'single', 'ep', 'songs', 'tracks', 'artist', 'artists', 'see all',
  'show all', 'now playing', 'playing from', 'playing from playlist', 'queue', 'up next', 'next in queue', 'lyrics',
  'radio', 'explicit', 'e', 'premium', 'recommended', 'popular', 'title', 'date added', 'duration', 'cancel', 'done',
  'save', 'saved', 'mix', 'made for you', 'recently played', 'discography', 'about', 'videos', 'video', 'listen',
  'слушать', 'перемешать', 'скачать', 'скачано', 'скачивание', 'поиск', 'главная', 'библиотека', 'медиатека',
  'моя музыка', 'коллекция', 'мне нравится', 'любимое', 'треки', 'трек', 'плейлист', 'альбом', 'сингл', 'исполнитель',
  'исполнители', 'показать все', 'ещё', 'еще', 'сейчас играет', 'очередь', 'далее', 'текст', 'радио', 'подписаться',
  'поделиться', 'добавить', 'изменить', 'сортировка', 'название', 'дата добавления', 'длительность', 'отмена', 'готово',
  'сохранить', 'моя волна', 'популярное', 'популярные треки', 'рекомендации', 'для вас', 'недавно прослушанные',
  'дискография', 'видео', 'музыка', 'music', 'песни', 'songs and videos',
};

int _durationMs(String s) {
  final m = _duration.firstMatch(s.trim());
  if (m == null) return 0;
  final a = int.parse(m[1]!), b = int.parse(m[2]!);
  if (b >= 60) return 0;
  final c = m[3] == null ? null : int.parse(m[3]!);
  return c == null ? (a * 60 + b) * 1000 : ((a * 60 + b) * 60 + c) * 1000;
}

String _cleanTitle(String s) => s
    .replaceFirst(RegExp(r'^\s*(?:#?\d{1,3}[.)]?\s+)(?=\p{L})', unicode: true), '')
    .replaceAll(RegExp(r'^[\s•·|›>»*\-–—.:]+'), '')
    .replaceAll(RegExp(r'[\s•·|‹<«*.:…⋮]+$'), '')
    .replaceAll(RegExp(r'\s{2,}'), ' ')
    // Tesseract reads a lone "I" as "|" ("Do | Wanna Know?").
    .replaceAllMapped(RegExp(r'(?<=[A-Za-z,] )\|(?= [A-Za-z])'), (_) => 'I')
    .trim();

bool _isNoise(String raw) {
  final s = _cleanTitle(raw);
  final letters = _letter.allMatches(s).length;
  if (letters < 2) return true;
  final digits = _digit.allMatches(s).length;
  if (digits > letters && letters < 4) return true;
  if (_counts.hasMatch(s)) return true;
  final key = s.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N} ]', unicode: true), '').trim();
  return _uiWords.contains(key);
}

/// Splits a reader line where words are far apart: columns (title, album,
/// date, length on one row of a desktop app) become separate pieces.
List<OcrLine> _pieces(OcrLine line) {
  final words = [...line.words]..sort((a, b) => a.x.compareTo(b.x));
  final heights = [for (final w in words) w.h]..sort();
  final h = heights[heights.length ~/ 2];
  final out = <OcrLine>[];
  var run = <OcrWord>[words.first];
  for (final w in words.skip(1)) {
    if (w.x - run.last.right > math.max(2.2 * h, 12)) {
      out.add(OcrLine(run));
      run = [w];
    } else {
      run.add(w);
    }
  }
  out.add(OcrLine(run));
  return out;
}

/// "Artist • Album • 3:45", "E • Artist", "Artist · Album" → artist + length.
(String, int) _artistPart(String s) {
  var duration = 0;
  final parts = <String>[];
  for (final p in s.split(RegExp(r'\s*[•·|]\s*'))) {
    final t = p.trim();
    if (t.isEmpty) continue;
    final d = _durationMs(t);
    if (d > 0) {
      duration = d;
      continue;
    }
    if (RegExp(r'^(E|\[E\]|Explicit|🅴)$', caseSensitive: false).hasMatch(t)) continue;
    if (_counts.hasMatch(t)) continue;
    parts.add(t);
  }
  var artist = parts.isEmpty ? '' : parts.first;
  artist = artist.replaceFirst(RegExp(r'^(?:E|🅴)\s+(?=\p{Lu})', unicode: true), '');
  return (_cleanTitle(artist), duration);
}

class _Song {
  _Song(this.title, this.artist, this.top, this.bottom, this.left, {this.durationMs = 0});
  final String title, artist;
  final double top, bottom, left;
  int durationMs;
}

/// Song names in a screenshot or photo of a playlist, top to bottom.
///
/// Music apps show a song as its name with the artist in a smaller line just
/// under it, both starting at the same place; a list of those is the songs.
/// Headings, buttons, counts and the status bar are left out. Without such
/// pairs, "Artist - Song" lines count, and failing that every line is a name.
List<ExternalTrack> songsFromPhoto(OcrPage page) {
  final width = page.width > 0 ? page.width : 1000.0;
  final pieces = <OcrLine>[];
  final durations = <OcrLine>[];
  for (final line in page.lines) {
    for (final p in _pieces(line)) {
      if (_durationMs(p.text) > 0) {
        durations.add(p);
      } else if (!_isNoise(p.text)) {
        pieces.add(p);
      }
    }
  }
  pieces.sort((a, b) => a.y.compareTo(b.y));

  // Title over artist, lined up on the left (lists) or centered (the playing
  // screen), close together, artist not bigger.
  final used = <OcrLine>{};
  final pairs = <_Song>[];
  for (final a in pieces) {
    if (used.contains(a)) continue;
    final tol = math.max(width * 0.03, a.h);
    for (final b in pieces) {
      if (identical(a, b) || used.contains(b)) continue;
      if (b.y < a.y + a.h * 0.5) continue;
      if (b.y - a.bottom > a.h * 1.1) break;
      final aligned = (a.x - b.x).abs() <= tol || (a.centerX - b.centerX).abs() <= tol;
      if (!aligned || b.h > a.h * 1.25) continue;
      final (artist, d) = _artistPart(b.text);
      final title = _cleanTitle(a.text);
      if (title.isEmpty || artist.isEmpty) continue;
      used
        ..add(a)
        ..add(b);
      pairs.add(_Song(title, artist, a.y, b.bottom, a.x, durationMs: d));
      break;
    }
  }

  List<_Song> songs;
  if (pairs.length >= 2) {
    // Keep the column most songs start in (drops a header that looked like one).
    final tol = width * 0.03;
    var best = <_Song>[];
    for (final p in pairs) {
      final same = [for (final q in pairs) if ((q.left - p.left).abs() <= tol) q];
      if (same.length > best.length) best = same;
    }
    songs = best.length >= 3 ? best : pairs;
  } else {
    final dashed = <_Song>[];
    for (final p in pieces) {
      if (used.contains(p)) continue;
      final m = RegExp(r'^(.+?)\s+[-–—]\s+(.+)$').firstMatch(_cleanTitle(p.text));
      if (m == null) continue;
      final artist = _cleanTitle(m[1]!), title = _cleanTitle(m[2]!);
      if (artist.isEmpty || title.isEmpty) continue;
      dashed.add(_Song(title, artist, p.y, p.bottom, p.x));
    }
    songs = [...pairs, ...dashed];
    if (songs.isEmpty) {
      songs = [
        for (final p in pieces)
          if (_cleanTitle(p.text).length >= 3) _Song(_cleanTitle(p.text), '', p.y, p.bottom, p.x),
      ];
    }
  }

  // A length on the same row belongs to that song.
  for (final d in durations) {
    final cy = d.centerY;
    for (final s in songs) {
      final pad = (s.bottom - s.top) * 0.3;
      if (cy >= s.top - pad && cy <= s.bottom + pad && d.x > s.left && s.durationMs == 0) {
        s.durationMs = _durationMs(d.text);
        break;
      }
    }
  }

  songs.sort((a, b) => a.top.compareTo(b.top));
  return dedupeSongs([
    for (final s in songs.take(500))
      ExternalTrack(
        service: OnlineService.file,
        title: s.title,
        artists: s.artist.isEmpty ? const [] : splitArtists(s.artist),
        durationMs: s.durationMs,
      ),
  ]);
}

/// Several screenshots of one long list overlap: each song once, first place kept.
List<ExternalTrack> dedupeSongs(Iterable<ExternalTrack> songs) {
  final seen = <String>{};
  return [
    for (final s in songs)
      if (seen.add('${s.title.toLowerCase()}|${s.artist.toLowerCase()}')) s,
  ];
}

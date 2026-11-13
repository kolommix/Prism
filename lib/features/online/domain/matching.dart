import 'dart:math' as math;

import '../../library/data/search_text.dart';
import '../../library/domain/track.dart';
import 'external_track.dart';
import '../../../l10n/l10n.dart';

/// How sure the matcher is that a candidate is the wanted song.
enum MatchConfidence {
  high,
  medium,
  low,
  none;

  String get label => switch (this) {
        MatchConfidence.high => l10n.high,
        MatchConfidence.medium => l10n.medium,
        MatchConfidence.low => l10n.lowCheckIt,
        MatchConfidence.none => l10n.noMatch,
      };
  static MatchConfidence of(double score) => score >= 0.85
      ? high
      : score >= 0.7
      ? medium
      : score >= MatchScorer.acceptThreshold
      ? low
      : none;
}

/// Score of one candidate, with the parts so the UI can explain it.
class MatchScore {
  const MatchScore({required this.value, required this.title, required this.artist, required this.duration, this.note});

  static const zero = MatchScore(value: 0, title: 0, artist: 0, duration: 0);

  /// 0..1, see [MatchScorer.score].
  final double value;
  final double title;
  final double artist;
  final double duration;

  /// Why it was pushed down (e.g. "karaoke version"), for the review list.
  final String? note;

  MatchConfidence get confidence => MatchConfidence.of(value);

  @override
  String toString() =>
      'MatchScore(${value.toStringAsFixed(2)} t=${title.toStringAsFixed(2)} a=${artist.toStringAsFixed(2)} '
      'd=${duration.toStringAsFixed(2)}${note == null ? '' : ' $note'})';
}

/// Words in brackets / after a dash that never change which song it is.
final _noise = RegExp(
  r'^(?:official(?: music| lyric| hd| 4k)?(?: video| audio| visuali[sz]er| mv)?|official|music video|video(?: oficial)?|'
  r'audio(?: only| oficial)?|lyrics?(?: video)?|with lyrics|letra|visuali[sz]er|hd|hq|4k|uhd|mv|m/v|explicit|clean|'
  r'(?:\d{4} )?(?:digital )?remaster(?:ed)?(?: \d{4})?(?: version)?|remaster(?:ed)? version|'
  r'radio edit|single version|album version|original mix|mono|stereo|color coded(?: lyrics)?|'
  r'prod\.? .*|from .*|taken from .*|bonus track|deluxe(?: edition| version)?|'
  r'(?:feat|ft|featuring|with)\.? .*)$',
);

/// Words that mean a *different recording* of the song.
const _variantWords = {
  'live': 'live version',
  'remix': 'remix',
  'acoustic': 'acoustic version',
  'instrumental': 'instrumental',
  'karaoke': 'karaoke',
  'cover': 'cover',
  'sped up': 'sped up',
  'speed up': 'sped up',
  'slowed': 'slowed',
  'nightcore': 'nightcore',
  'reverb': 'reverb edit',
  '8d': '8D audio',
  'bass boosted': 'bass boosted',
  'daycore': 'daycore',
  'demo': 'demo',
  'extended': 'extended mix',
  'piano version': 'piano version',
  'orchestral': 'orchestral version',
  'mashup': 'mashup',
};

/// Fan-made versions: a much stronger penalty when the wanted song isn't one.
const _fanVariants = {
  'karaoke',
  'cover',
  'sped up',
  'slowed',
  'nightcore',
  'reverb edit',
  '8D audio',
  'bass boosted',
  'daycore',
  'mashup',
};

/// Words of videos that are not a song at all (a film, a talk, a review).
/// The documentary called "Трудный возраст" is not Дора's song of that name.
const _notMusicWords = [
  'documentary', 'full movie', 'movie', 'film', 'trailer', 'teaser', 'interview', 'reaction', 'react', 'review',
  'podcast', 'news', 'lecture', 'episode', 'gameplay', 'walkthrough', 'lets play', 'tutorial', 'how to', 'vlog',
  'livestream', 'stream', 'documental', 'audiobook', 'sermon', 'talk show', 'explained', 'analysis', 'unboxing',
  'документальный', 'документалка', 'фильм', 'кино о', 'трейлер', 'интервью', 'реакция', 'обзор', 'подкаст',
  'новости', 'лекция', 'серия', 'выпуск', 'прохождение', 'урок', 'влог', 'стрим', 'сериал', 'мультфильм',
  'аудиокнига', 'проповедь', 'ток шоу', 'разбор', 'репортаж', 'передача', 'эфир',
];

/// The "not music" words in [raw] (normalized), for [MatchScorer].
Set<String> notMusicWordsIn(String raw) {
  final s = ' ${normalizeForSearch(raw)} ';
  return {
    for (final w in _notMusicWords)
      if (s.contains(' ${normalizeForSearch(w)} ')) w,
  };
}

final _brackets = RegExp(r'\s*[\(\[\{【]([^\)\]\}】]*)[\)\]\}】]');
final _dashTail = RegExp(r'\s+[-–—]\s+([^-–—]+)$');
final _featOutside = RegExp(r'\s+(?:feat|ft|featuring)\.?\s+.*$', caseSensitive: false);
final _titleDash = RegExp(r'\s+[-–—|]\s+');
final _channelNoise = RegExp(r'\s*(?:-\s*topic|vevo|official)\s*$', caseSensitive: false);

/// Removes "(Official Video)", "- Remastered 2011", "feat. X" and similar.
String cleanTitle(String raw) => normalizeForSearch(cleanTitleText(raw));

/// [cleanTitle] with the letters as they are (for searching catalogues, which
/// match "Трудный" but not "трудныи").
String cleanTitleText(String raw) {
  var s = raw.replaceAllMapped(_brackets, (m) => _noise.hasMatch(normalizeLoose(m[1]!)) ? '' : ' ${m[1]} ');
  // Strip noisy "- …" tails repeatedly ("Song - 2011 Remaster - Mono").
  while (true) {
    final m = _dashTail.firstMatch(s);
    if (m == null || !_noise.hasMatch(normalizeLoose(m[1]!))) break;
    s = s.substring(0, m.start);
  }
  s = s.replaceFirst(_featOutside, '');
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Lower-case + accents stripped, punctuation kept (for the noise regex).
String normalizeLoose(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

Set<String> variantsOf(String raw) {
  final s = ' ${normalizeForSearch(raw)} ';
  return {
    for (final e in _variantWords.entries)
      if (s.contains(' ${e.key} ')) e.value,
  };
}

List<String> _tokens(String normalized) => normalized.split(' ').where((t) => t.isNotEmpty).toList();

String _compact(String s) => normalizeForSearch(s).replaceAll(' ', '');

/// Splits "A, B & C feat. D" into artists.
List<String> splitArtists(String raw) => raw
    .split(RegExp(r'\s*(?:,|;|/|&| x | and | feat\.? | ft\.? | featuring | with )\s*', caseSensitive: false))
    .map((a) => a.trim())
    .where((a) => a.isNotEmpty)
    .toList();

/// Levenshtein similarity 0..1 on short strings (capped at 64 chars).
double stringSimilarity(String a, String b) {
  if (a == b) return 1;
  if (a.isEmpty || b.isEmpty) return 0;
  final x = a.length > 64 ? a.substring(0, 64) : a;
  final y = b.length > 64 ? b.substring(0, 64) : b;
  var prev = List<int>.generate(y.length + 1, (i) => i);
  for (var i = 1; i <= x.length; i++) {
    final cur = List<int>.filled(y.length + 1, 0)..[0] = i;
    for (var j = 1; j <= y.length; j++) {
      final cost = x.codeUnitAt(i - 1) == y.codeUnitAt(j - 1) ? 0 : 1;
      cur[j] = math.min(math.min(cur[j - 1] + 1, prev[j] + 1), prev[j - 1] + cost);
    }
    prev = cur;
  }
  return 1 - prev[y.length] / math.max(x.length, y.length);
}

bool _tokenEq(String a, String b) => a == b || (a.length >= 4 && b.length >= 4 && stringSimilarity(a, b) >= 0.8);

/// How many of [want] appear in [have] (fuzzy per token).
int _matched(List<String> want, List<String> have) {
  final pool = [...have];
  var n = 0;
  for (final w in want) {
    final i = pool.indexWhere((h) => _tokenEq(w, h));
    if (i >= 0) {
      n++;
      pool.removeAt(i);
    }
  }
  return n;
}

/// Title similarity: token overlap, "all wanted words are there", or plain
/// edit distance (handles typos and scripts without spaces).
double titleSimilarity(String wanted, String candidate) {
  final w = _tokens(wanted), c = _tokens(candidate);
  if (w.isEmpty || c.isEmpty) return 0;
  final m = _matched(w, c);
  final dice = 2 * m / (w.length + c.length);
  final coverage = m / w.length;
  // Candidate has every wanted word plus a few extras ("Song Title HD Remake").
  final contained = coverage == 1 && c.length - m <= 3 ? 0.92 - 0.04 * (c.length - m) : 0.0;
  final edit = stringSimilarity(wanted.replaceAll(' ', ''), candidate.replaceAll(' ', ''));
  return [dice, contained, edit].reduce(math.max);
}

double durationSimilarity(int wantedMs, int candidateMs) {
  if (wantedMs <= 0 || candidateMs <= 0) return 0.6;
  final diff = (wantedMs - candidateMs).abs();
  if (diff <= 2000) return 1;
  if (diff <= 5000) return 0.9;
  if (diff <= 10000) return 0.7;
  if (diff <= 20000) return 0.45;
  if (diff <= 40000) return 0.2;
  return 0;
}

/// Scores how likely [candidate] is the song [wanted] describes.
///
/// * Title 50 %, artist 30 %, length 20 %.
/// * Online candidates ("Artist - Title (Official Video)", channel as artist)
///   are split at the dash, and noise words are dropped first.
/// * A different recording (live, remix, karaoke, sped up…) on only one side
///   is pushed down; fan versions (karaoke, nightcore…) strongly.
/// * The right artist can't rescue a wrong title, and the right title by a
///   different artist (a cover) stays below "medium".
abstract final class MatchScorer {
  /// Below this the candidate is not used (the song stays unmatched).
  static const acceptThreshold = 0.5;

  static MatchScore score(ExternalTrack wanted, Track candidate) {
    final wantTitle = cleanTitle(wanted.title);
    if (wantTitle.isEmpty) return MatchScore.zero;
    final wantArtists = wanted.artists.isNotEmpty ? wanted.artists : const <String>[];
    final online = candidate.sourceId != 'local';

    // Candidate title and "who" text.
    var candTitleRaw = candidate.title;
    var candWho = candidate.artist.isNotEmpty ? candidate.artist : candidate.albumArtist;
    if (online) {
      final parts = candidate.title.split(_titleDash);
      if (parts.length >= 2) {
        // "Artist - Title" (YouTube) – keep the channel as a second artist source.
        candWho = '${parts.first} $candWho';
        candTitleRaw = parts.sublist(1).join(' - ');
      }
      candWho = candWho.replaceAll(_channelNoise, '');
    }
    var candTitle = cleanTitle(candTitleRaw);
    if (online) {
      // Drop artist words that leaked into the video title ("Song by Artist").
      final artistTokens = {for (final a in wantArtists) ..._tokens(normalizeForSearch(a))};
      final wantTokens = _tokens(wantTitle).toSet();
      final kept = _tokens(candTitle).where((t) => wantTokens.contains(t) || !artistTokens.contains(t)).join(' ');
      if (kept.isNotEmpty) candTitle = kept;
    }
    final title = math.max(
      titleSimilarity(wantTitle, candTitle),
      titleSimilarity(wantTitle, cleanTitle(candidate.title)),
    );

    // Artist: primary artist fully inside the candidate's artist/channel text
    // (compact compare also handles "TaylorSwiftVEVO"); else token coverage.
    double artist;
    if (wantArtists.isEmpty) {
      artist = 0.5;
    } else if (normalizeForSearch(candWho).isEmpty && !online) {
      artist = 0.4;
    } else {
      final whoCompact = _compact('$candWho ${online ? candidate.title : ''}');
      final whoTokens = _tokens(normalizeForSearch('$candWho ${online ? candidate.title : ''}'));
      artist = 0;
      for (var i = 0; i < wantArtists.length; i++) {
        final a = wantArtists[i];
        final ac = _compact(a);
        final at = _tokens(normalizeForSearch(a));
        double s;
        if (ac.isNotEmpty && whoCompact.contains(ac)) {
          s = 1;
        } else if (at.isEmpty) {
          s = 0;
        } else {
          final cov = _matched(at, whoTokens) / at.length;
          s = math.max(cov, stringSimilarity(ac, _compact(candWho)));
        }
        // Only the main artist can give full marks.
        artist = math.max(artist, i == 0 ? s : s * 0.85);
      }
    }

    final duration = durationSimilarity(wanted.durationMs, candidate.durationMs);
    var value = 0.5 * title + 0.3 * artist + 0.2 * duration;

    // Different recording on one side only.
    String? note;
    final wv = variantsOf(wanted.title), cv = variantsOf(candidate.title);
    for (final v in cv.difference(wv)) {
      value *= _fanVariants.contains(v) ? 0.35 : 0.6;
      note ??= v;
    }
    for (final v in wv.difference(cv)) {
      value *= 0.6;
      note ??= l10n.notThe(v);
    }

    // Not a song: a film, an interview, a review… with the song's name.
    if (online) {
      final notMusic = notMusicWordsIn(candidate.title).difference(notMusicWordsIn(wanted.title));
      if (notMusic.isNotEmpty) {
        value *= 0.3;
        note ??= l10n.matchNotMusic;
      }
      // Far longer than any song (and than the wanted one): a film or a mix.
      final longest = math.max(wanted.durationMs, 12 * 60 * 1000);
      if (candidate.durationMs > longest + 3 * 60 * 1000) {
        value *= 0.3;
        note ??= l10n.matchTooLong;
      }
    }

    value = math.min(value, title + 0.2);
    if (artist < 0.3) {
      // Someone else's upload with the same name. Only a matching length
      // makes it worth a "check it"; otherwise it is not taken.
      value = math.min(value, online && duration < 0.7 ? acceptThreshold - 0.01 : 0.62);
    }
    if (online && candidate.artist.toLowerCase().endsWith(' - topic')) value += 0.03;
    return MatchScore(
      value: value.clamp(0, 1).toDouble(),
      title: title,
      artist: artist,
      duration: duration,
      note: note,
    );
  }

  /// Best candidate (ties go to the earlier one, so callers order by preference).
  static ({Track track, MatchScore score})? best(ExternalTrack wanted, Iterable<Track> candidates) {
    ({Track track, MatchScore score})? top;
    for (final c in candidates) {
      final s = score(wanted, c);
      if (top == null || s.value > top.score.value + 1e-9) top = (track: c, score: s);
    }
    return top;
  }

  /// Search text for services: "main artist title" without noise words.
  static String queryFor(ExternalTrack t) {
    final a = t.artists.isEmpty ? '' : t.artists.first;
    return '$a ${cleanTitle(t.title)}'.trim();
  }
}

/// Key used to spot the same song twice in one import.
String duplicateKey(ExternalTrack t) =>
    '${cleanTitle(t.title)}|${t.artists.isEmpty ? '' : normalizeForSearch(t.artists.first)}';

/// Indexes of tracks that repeat an earlier one (same cleaned title + main
/// artist, length within 3 s or unknown). Returns `index -> first index`.
Map<int, int> findImportDuplicates(List<ExternalTrack> tracks) {
  final firstByKey = <String, List<int>>{};
  final dupes = <int, int>{};
  for (var i = 0; i < tracks.length; i++) {
    final key = duplicateKey(tracks[i]);
    if (key.startsWith('|')) continue;
    final earlier = firstByKey[key] ??= [];
    final same = earlier.where((j) {
      final a = tracks[i].durationMs, b = tracks[j].durationMs;
      return a == 0 || b == 0 || (a - b).abs() <= 3000;
    }).firstOrNull;
    if (same != null) {
      dupes[i] = same;
    } else {
      earlier.add(i);
    }
  }
  return dupes;
}

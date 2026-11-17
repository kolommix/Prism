/// Finding a song by a line of its words.
///
/// Text is compared "loosely": lower case, `ё` as `е`, LRC time tags and
/// punctuation dropped, spaces collapsed. So "Is this the real life?" finds
/// "[00:12.30]Is this the real life —".
library;

final _timeTag = RegExp(r'\[[^\]]*\]');
final _notWord = RegExp(r'[^\p{L}\p{N}]+', unicode: true);

/// [s] as the search compares it.
String loosen(String s) =>
    s.replaceAll(_timeTag, ' ').toLowerCase().replaceAll('ё', 'е').replaceAll(_notWord, ' ').trim();

/// Whether [query] is long enough to be a line rather than a name: at least
/// two words and 8 letters (shorter ones would hit half the library).
bool looksLikeLine(String query) {
  final q = loosen(query);
  return q.length >= 8 && q.contains(' ');
}

/// One song's words, ready to search.
class LyricsIndexEntry {
  LyricsIndexEntry(this.trackId, String text) : lines = _lines(text) {
    joined = lines.map((l) => l.$2).join(' ');
  }

  final int trackId;

  /// (original line, loosened line), empty lines left out.
  final List<(String, String)> lines;
  late final String joined;

  static List<(String, String)> _lines(String text) => [
        for (final raw in text.split('\n'))
          if (loosen(raw) case final l when l.isNotEmpty) (raw.replaceAll(_timeTag, '').trim(), l),
      ];

  /// The line [q] (already loosened) is on, or null if the song lacks it. A
  /// phrase running over two lines matches too and shows its first line.
  String? find(String q) {
    for (final (raw, l) in lines) {
      if (l.contains(q)) return raw;
    }
    final at = joined.indexOf(q);
    if (at < 0) return null;
    var pos = 0;
    for (final (raw, l) in lines) {
      if (at < pos + l.length + 1) return raw;
      pos += l.length + 1;
    }
    return lines.last.$1;
  }
}

/// Songs whose words have [query], as (track id, the matching line), at most
/// [limit]. Songs where it starts a line come first (likely the chorus).
List<(int, String)> searchLyrics(List<LyricsIndexEntry> index, String query, {int limit = 30}) {
  final q = loosen(query);
  if (q.isEmpty) return const [];
  final hits = <(int, String, bool)>[];
  for (final e in index) {
    final line = e.find(q);
    if (line != null) hits.add((e.trackId, line, loosen(line).startsWith(q)));
  }
  hits.sort((a, b) => (b.$3 ? 1 : 0) - (a.$3 ? 1 : 0));
  return [for (final h in hits.take(limit)) (h.$1, h.$2)];
}

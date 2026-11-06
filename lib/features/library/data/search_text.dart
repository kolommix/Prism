/// Helpers that normalise text for the `search_text` column and queries.
///
/// Both sides go through [normalizeForSearch], so "Beyoncé" matches "beyonce"
/// and "AC/DC" matches "ac dc".
library;

const _accents = {
  'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a', 'ā': 'a',
  'ç': 'c', 'č': 'c', 'ć': 'c',
  'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ě': 'e',
  'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i',
  'ñ': 'n', 'ń': 'n', 'ň': 'n',
  'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o', 'ō': 'o',
  'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ů': 'u',
  'ý': 'y', 'ÿ': 'y',
  'ž': 'z', 'ź': 'z', 'ż': 'z',
  'š': 's', 'ś': 's', 'ß': 'ss',
  'ř': 'r', 'ł': 'l', 'đ': 'd', 'ď': 'd', 'ť': 't',
  'ё': 'е', 'й': 'и',
};

final _separators = RegExp(r'''[\s\-_/\\.,;:!?'"()\[\]{}&+]+''');

/// Lower-cases, strips common accents and collapses punctuation to spaces.
String normalizeForSearch(String input) {
  final lower = input.toLowerCase();
  final buf = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    buf.write(_accents[ch] ?? ch);
  }
  return buf.toString().replaceAll(_separators, ' ').trim();
}

/// Builds the value stored in `tracks.search_text`.
String buildSearchText({
  required String title,
  String artist = '',
  String album = '',
  String albumArtist = '',
}) =>
    normalizeForSearch('$title $artist $album $albumArtist');

/// Splits a user query into normalised tokens (empty tokens removed).
List<String> searchTokens(String query) =>
    normalizeForSearch(query).split(' ').where((t) => t.isNotEmpty).toList();

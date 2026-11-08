import '../data/search_text.dart';

/// Separators between artists in one tag: "Rat Boy, IBDY", "A & B",
/// "A x B", "A feat. B", "A ft B", "A / B", "A; B".
final artistSeparators = RegExp(
  r'\s*(?:,|&|/|;|\s[xX×]\s|\s(?:feat|ft|featuring)\.?\s)\s*',
  caseSensitive: false,
);

/// The single names in an artist tag, as written ("Rat Boy", "IBDY").
List<String> artistNames(String artist) => [
      for (final n in ' $artist '.split(artistSeparators))
        if (n.trim().isNotEmpty) n.trim(),
    ];

/// True when [name] is one of the artists of [artist] (case and accents ignored).
bool hasArtist(String artist, String name) {
  final want = normalizeForSearch(name);
  if (want.isEmpty) return false;
  return normalizeForSearch(artist) == want || artistNames(artist).any((n) => normalizeForSearch(n) == want);
}

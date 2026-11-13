import '../../library/data/search_text.dart';
import '../../library/domain/track.dart';
import 'external_track.dart';
import 'matching.dart';

/// A song as people name it (for lyrics and cover searches), not as the file or
/// the video says it. "Artist - Song (Official Video)" by "ArtistVEVO" becomes
/// Song by Artist; a file without tags called "03. Artist - Song" too; an
/// empty artist stays empty (never "Unknown artist").
ExternalTrack songAsNamed(Track t) {
  var title = t.title.trim();
  var artist = (t.artist.isNotEmpty ? t.artist : t.albumArtist).trim();
  final online = t.sourceId != 'local';
  artist = artist.replaceAll(RegExp(r'\s*(?:-\s*topic|vevo|official)\s*$', caseSensitive: false), '').trim();
  if (!online && artist.isEmpty) title = title.replaceFirst(RegExp(r'^\d{1,3}[\s.\-_)]+(?=\D)'), '');
  final dash = RegExp(r'\s+[-–—]\s+').firstMatch(title);
  if (dash != null && (online || artist.isEmpty)) {
    final left = title.substring(0, dash.start).trim();
    final right = title.substring(dash.end).trim();
    final leftClean = cleanTitle(left);
    // "Song - Remastered 2011" keeps its name: only a real name on the left counts.
    final noiseTail = cleanTitle(title) == leftClean;
    if (left.isNotEmpty && right.isNotEmpty && leftClean.isNotEmpty && !noiseTail) {
      final channel = artist;
      artist = left;
      title = right;
      if (channel.isNotEmpty && normalizeForSearch(channel) != normalizeForSearch(left)) {
        return ExternalTrack(
          service: OnlineService.file,
          title: title,
          artists: [...splitArtists(artist), channel],
          durationMs: t.durationMs,
        );
      }
    }
  }
  return ExternalTrack(
    service: OnlineService.file,
    title: title,
    artists: splitArtists(artist),
    album: online ? '' : t.album,
    durationMs: t.durationMs,
  );
}

/// True when [songAsNamed] took the artist from the title, not from tags.
bool artistFromTitle(Track t, ExternalTrack named) {
  final tagged = (t.artist.isNotEmpty ? t.artist : t.albumArtist).trim();
  return named.artists.isNotEmpty && (tagged.isEmpty || t.sourceId != 'local') && named.title != t.title.trim();
}

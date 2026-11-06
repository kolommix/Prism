import 'package:prism/features/library/domain/track.dart';

/// Builds a simple track for tests: `t(1)` → id 1, title "Song 1".
Track t(int id, {String? title, String artist = 'Artist', String album = 'Album'}) =>
    Track(id: id, uri: '/music/$id.mp3', title: title ?? 'Song $id', artist: artist, album: album, durationMs: 180000);

/// Ids of a track list, for compact expectations.
List<int> ids(Iterable<Track> tracks) => [for (final x in tracks) x.id];

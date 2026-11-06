import '../../features/library/domain/track.dart';

/// Capabilities a source can advertise so the UI can show/hide features.
enum TrackSourceCapability {
  /// Tracks can be listed/browsed (local library, a streaming catalog).
  browse,

  /// Free-text search is supported.
  search,

  /// Tracks need network access to play.
  requiresNetwork,

  /// Tracks can be edited (future audio editor).
  editable,
}

/// Something that owns tracks and knows how to play them.
///
/// This is the main plug-in point for future features:
/// * `LocalTrackSource` (today) – files on disk, indexed in SQLite.
/// * A streaming integration (later) – implements [search] against an API and
///   returns an `https://` (or signed) URI from [resolvePlaybackUri].
///
/// The player never touches files or HTTP directly; it always asks the
/// [TrackSourceRegistry] to resolve a [Track] first.
abstract class TrackSource {
  /// Stable id stored in `Track.sourceId`, e.g. `local`.
  String get id;

  /// Human readable name for settings/UI.
  String get displayName;

  Set<TrackSourceCapability> get capabilities;

  /// Returns a URI the audio engine can open (`file://`, `https://`, …).
  Future<Uri> resolvePlaybackUri(Track track);

  /// Optional HTTP headers needed for playback (auth for streaming).
  Future<Map<String, String>> playbackHeaders(Track track) async => const {};

  /// Searches this source. Local search is served by the library repository,
  /// so the local source may simply delegate there.
  Future<List<Track>> search(String query, {int limit = 50});
}

/// Looks up the right [TrackSource] for a track.
class TrackSourceRegistry {
  TrackSourceRegistry(Iterable<TrackSource> sources)
      : _sources = {for (final s in sources) s.id: s};

  final Map<String, TrackSource> _sources;

  Iterable<TrackSource> get all => _sources.values;

  TrackSource sourceFor(Track track) {
    final source = _sources[track.sourceId];
    if (source == null) {
      throw StateError('No TrackSource registered for "${track.sourceId}"');
    }
    return source;
  }

  /// Registers a new source at runtime (e.g. after a user logs in).
  void register(TrackSource source) => _sources[source.id] = source;
}

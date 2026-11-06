import '../../../core/sources/track_source.dart';
import '../domain/track.dart';
import 'library_repository.dart';
import '../../../l10n/l10n.dart';

/// [TrackSource] for files on this device.
class LocalTrackSource extends TrackSource {
  LocalTrackSource(this._repo);

  static const sourceId = 'local';
  final LibraryRepository _repo;

  @override
  String get id => sourceId;

  @override
  String get displayName => l10n.thisDevice;

  @override
  Set<TrackSourceCapability> get capabilities =>
      const {TrackSourceCapability.browse, TrackSourceCapability.search, TrackSourceCapability.editable};

  @override
  Future<Uri> resolvePlaybackUri(Track track) async => Uri.file(track.uri);

  @override
  Future<List<Track>> search(String query, {int limit = 50}) => _repo.search(query, limit: limit);
}

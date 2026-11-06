import '../../library/domain/track.dart';
import '../domain/external_track.dart';
import '../domain/link_parser.dart';
import '../domain/online_error.dart';
import '../../../l10n/l10n.dart';

/// What a module can do; the UI only shows what's there.
enum ModuleFeature {
  /// Has an account login (OAuth).
  login,

  /// Lists the user's playlists after login.
  myPlaylists,

  /// Liked songs / likes / favourites.
  likes,

  /// Saved albums.
  savedAlbums,

  /// Opens pasted links (playlist / album / track).
  links,

  /// Catalog search that returns playable tracks.
  search,

  /// Audio can be played in Prism.
  stream,
}

class AccountInfo {
  const AccountInfo({required this.name, this.detail});
  final String name;
  final String? detail;
}

/// One online service, isolated in its own folder under `services/`.
///
/// A module is created only when its feature flag is on; anything it throws
/// is an [OnlineException] and is caught by `OnlineServices`, so a broken
/// module (missing key, API change, outage) only greys out its own UI.
/// Every method has a default that says "not supported".
abstract class MusicServiceModule {
  OnlineService get service;
  Set<ModuleFeature> get features;

  /// Short status line when the module can't work yet (missing key…).
  String? get setupHint => null;

  OnlineException unsupported(String what) =>
      OnlineException(OnlineErrorKind.unsupported, service: service, message: l10n.canNot(service.label, what));

  // ---- account
  Future<AccountInfo?> account() async => null;
  Future<AccountInfo> connect() => throw unsupported(l10n.logIn);
  Future<void> disconnect() async {}

  // ---- library import (metadata only)
  Future<List<RemotePlaylistInfo>> myPlaylists() => throw unsupported(l10n.listYourPlaylists);
  Future<List<RemotePlaylistInfo>> savedAlbums() => throw unsupported(l10n.listSavedAlbums);
  Future<ImportedList> likedSongs() => throw unsupported(l10n.readLikedSongs);

  /// Fetches a playlist or album picked from [myPlaylists] / [savedAlbums].
  Future<ImportedList> fetchList(RemotePlaylistInfo info, {bool album = false}) => throw unsupported(l10n.openPlaylists);

  bool canOpen(ParsedLink link) => link.service == service;
  Future<ImportedList> openLink(ParsedLink link) => throw unsupported(l10n.openLinks);

  // ---- catalog (playable)
  /// Source id of the tracks this module plays (`youtube`, `soundcloud`).
  String? get playableSourceId => null;

  /// Returns remote [Track]s with `id == 0` (not saved yet); they are saved by
  /// `RemoteTrackStore` when played / added / matched.
  Future<List<Track>> search(String query, {int limit = 20}) => throw unsupported('search');

  /// Resolves a playable URL for a track of [playableSourceId].
  Future<Uri> streamUri(Track track) => throw unsupported(l10n.playAudio);
  Future<Map<String, String>> streamHeaders(Track track) async => const {};

  /// Downloads the audio for the offline cache (returns file extension).
  Future<String> download(Track track, String targetPathWithoutExt) => throw unsupported(l10n.saveSongsOffline);

  void dispose() {}
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:path/path.dart' as p;

import '../../../core/db/app_database.dart';
import '../domain/library_models.dart';
import '../domain/tag_reader.dart';
import 'library_repository.dart';
import 'search_text.dart';

/// File extensions the scanner picks up (lower-case, with dot).
const supportedAudioExtensions = {'.mp3', '.flac', '.m4a', '.ogg', '.wav'};

bool isSupportedAudioFile(String path) =>
    supportedAudioExtensions.contains(p.extension(path).toLowerCase());

/// Walks library folders, reads tags of new/changed files and syncs the DB.
///
/// The scan is incremental: a file whose size and modification time did not
/// change since the last scan is skipped, so re-scanning a big library is
/// mostly just a directory walk.
class LibraryScanner {
  LibraryScanner({
    required LibraryRepository repository,
    required TagReader tagReader,
    required this._artworkDir,
    this.batchSize = 200,
  })  : _repo = repository,
        _tags = tagReader;

  final LibraryRepository _repo;
  final TagReader _tags;
  final Directory _artworkDir;

  /// Rows are written in batches of this size (one transaction each), so the
  /// UI updates gradually during long scans.
  final int batchSize;

  /// Scans every folder in the library. Emits progress and completes with a
  /// [ScanFinished] event.
  Stream<ScanProgress> scanAll() async* {
    yield* scanFolders(await _repo.folders());
  }

  Stream<ScanProgress> scanFolders(List<String> roots) async* {
    final sw = Stopwatch()..start();
    final known = await _repo.fileFingerprints();
    final removedByUser = await _repo.removedUris();

    // 1) Discover files ------------------------------------------------------
    final found = <String, FileStat>{};
    for (final root in roots) {
      final dir = Directory(root);
      if (!await dir.exists()) continue;
      await for (final entity in dir.list(recursive: true, followLinks: false).handleError((_) {})) {
        if (entity is! File || !isSupportedAudioFile(entity.path) || removedByUser.contains(entity.path)) continue;
        found[entity.path] = await entity.stat();
        if (found.length % 200 == 0) yield ScanProgress.discovering(found: found.length);
      }
    }
    yield ScanProgress.discovering(found: found.length);

    // 2) Read tags for new/changed files ---------------------------------
    final toRead = <String>[];
    for (final entry in found.entries) {
      final prev = known[entry.key];
      final fp = (entry.value.size, entry.value.modified.millisecondsSinceEpoch);
      if (prev == null || prev != fp) toRead.add(entry.key);
    }

    var added = 0, updated = 0, done = 0;
    final pending = <TracksCompanion>[];
    if (!await _artworkDir.exists()) await _artworkDir.create(recursive: true);

    for (var i = 0; i < toRead.length; i += batchSize) {
      final chunk = toRead.sublist(i, i + batchSize > toRead.length ? toRead.length : i + batchSize);
      final tagList = await _tags.readMany(chunk);
      for (var j = 0; j < chunk.length; j++) {
        final path = chunk[j];
        pending.add(await _buildRow(path, found[path]!, tagList[j]));
        if (known.containsKey(path)) {
          updated++;
        } else {
          added++;
        }
      }
      done += chunk.length;
      await _repo.upsertTracks(List.of(pending));
      pending.clear();
      yield ScanProgress.reading(done: done, total: toRead.length, currentFile: p.basename(chunk.last));
    }

    // 3) Remove tracks whose files vanished (only inside scanned roots) -----
    final rootPrefixes = roots.map((r) => r.endsWith(p.separator) ? r : '$r${p.separator}').toList();
    final gone = known.keys.where(
      (uri) => !found.containsKey(uri) && rootPrefixes.any(uri.startsWith),
    );
    final removed = await _repo.deleteByUris(gone);

    yield ScanProgress.finished(added: added, updated: updated, removed: removed, took: sw.elapsed);
  }

  Future<TracksCompanion> _buildRow(String path, FileStat stat, AudioTags tags) async {
    final title = _clean(tags.title) ?? p.basenameWithoutExtension(path);
    final artist = _clean(tags.artist) ?? '';
    final album = _clean(tags.album) ?? '';
    final albumArtist = _clean(tags.albumArtist) ?? '';
    final artwork = await _saveCover(tags, album: album, artist: albumArtist.isEmpty ? artist : albumArtist, path: path);

    return TracksCompanion.insert(
      uri: path,
      folder: p.dirname(path),
      title: title,
      artist: Value(artist),
      album: Value(album),
      albumArtist: Value(albumArtist),
      genre: Value(_clean(tags.genre) ?? ''),
      year: Value(tags.year),
      trackNumber: Value(tags.trackNumber),
      discNumber: Value(tags.discNumber),
      durationMs: Value(tags.duration?.inMilliseconds ?? 0),
      artworkPath: Value(artwork),
      fileSize: Value(stat.size),
      modifiedMs: Value(stat.modified.millisecondsSinceEpoch),
      searchText: Value(buildSearchText(title: title, artist: artist, album: album, albumArtist: albumArtist)),
      rgTrackGain: Value(tags.rgTrackGain),
      rgTrackPeak: Value(tags.rgTrackPeak),
      rgAlbumGain: Value(tags.rgAlbumGain),
      rgAlbumPeak: Value(tags.rgAlbumPeak),
      // The file changed: what it says now counts, and it may be looked up again.
      infoCheckedMs: const Value(null),
      infoOriginal: const Value(null),
    );
  }

  /// Writes the cover once per album (or per file for loose singles) into the
  /// artwork cache, named by a hash so duplicates share one file.
  Future<String?> _saveCover(AudioTags tags, {required String album, required String artist, required String path}) async {
    final bytes = tags.coverBytes;
    if (bytes == null || bytes.isEmpty) return null;
    final key = album.isNotEmpty ? 'album:$artist|$album' : 'file:$path';
    final name = md5.convert(utf8.encode(key)).toString();
    final ext = _looksLikePng(bytes) ? '.png' : '.jpg';
    final file = File(p.join(_artworkDir.path, '$name$ext'));
    try {
      if (!await file.exists()) await file.writeAsBytes(bytes, flush: false);
      return file.path;
    } on FileSystemException {
      return null;
    }
  }

  static bool _looksLikePng(List<int> b) => b.length > 4 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47;

  static String? _clean(String? s) {
    if (s == null) return null;
    final t = s.replaceAll('\u0000', '').trim();
    return t.isEmpty ? null : t;
  }
}

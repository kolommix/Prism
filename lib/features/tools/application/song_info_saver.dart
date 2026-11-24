import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/diagnostics/error_log.dart';
import '../../../core/ffmpeg/dash_fix.dart';
import '../../../core/providers.dart';
import '../../audio_fx/application/loudness_controller.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/track.dart';
import '../data/tag_writer.dart';
import 'tools_providers.dart';

/// The song's info with [e] applied: every field, not only the changed ones.
///
/// Imported songs (and many downloaded files) have nothing written in the
/// file; the names live in Prism's library. Writing only the changed title
/// and then reading the file back lost the artist, album and cover, and the
/// background info search then put an old name back after the next start
/// (what friends saw). With everything written, the file says what Prism shows.
TagEdit fullTagEdit(Track t, TagEdit e) => TagEdit(
      title: e.title ?? t.title,
      artist: e.artist ?? t.artist,
      album: e.album ?? t.album,
      genre: e.genre ?? (t.genre.isEmpty ? null : t.genre),
      year: e.year ?? t.year,
      trackNumber: e.trackNumber ?? t.trackNumber,
      cover: e.cover,
      removeCover: e.removeCover,
    );

/// Saves what the user changed about a song (tag editor, Fix song info).
///
/// * Files that can hold tags (MP3, M4A, FLAC, WAV) get all of the song's
///   info, with a backup first; the library reads the file again.
/// * Other formats (Opus, WebM, OGG) keep the change in Prism's library only.
/// * Either way it counts as the user's choice: the background search for
///   missing info leaves the song alone from now on.
class SongInfoSaver {
  SongInfoSaver(this._ref);
  final Ref _ref;

  /// Returns true when the file itself was written.
  Future<bool> save(Track track, TagEdit edit) async {
    final repo = _ref.read(libraryRepositoryProvider);
    final full = fullTagEdit(track, edit);
    final local = track.sourceId == 'local';
    var wroteFile = false;
    if (local && TagWriter.canWrite(track.uri)) {
      // Songs saved straight from YouTube by older versions: a DASH MP4 the
      // tag library can't write into. Made a plain m4a first (same audio).
      await fixDashM4a(File(track.uri), _ref.read(ffmpegRunnerProvider));
      final writer = await _ref.read(tagWriterProvider.future);
      try {
        await writer.write(track.uri, full);
      } on TagWriteException catch (e, st) {
        ErrorLog.instance.record(e, st, where: 'tags', message: '${track.title}: ${e.message}');
        rethrow;
      }
      wroteFile = true;
      final art = track.artworkPath;
      if ((edit.cover != null || edit.removeCover) && art != null && _isOwnArtwork(art)) {
        final f = File(art);
        if (await f.exists()) await f.delete();
      }
      await _ref.read(libraryScannerProvider).scanFiles([track.uri]).drain<void>();
      // The file has no picture (imported songs, covers found online): keep
      // the cover Prism showed instead of losing it.
      if (edit.cover == null && !edit.removeCover && art != null) await repo.keepArtworkIfNone(track.id, art);
      if (edit.removeCover) await repo.clearArtwork(track.id);
    } else {
      String? cover;
      if (edit.cover != null) cover = await _saveCover(edit.cover!);
      await repo.saveUserInfo(track, full, coverPath: cover);
    }
    await repo.markInfoChecked(track.id);
    return wroteFile;
  }

  bool _isOwnArtwork(String path) => !path.startsWith('http') && p.isWithin(_ref.read(artworkDirProvider).path, path);

  Future<String?> _saveCover(List<int> bytes) async {
    try {
      final dir = _ref.read(artworkDirProvider);
      if (!await dir.exists()) await dir.create(recursive: true);
      final png = bytes.length > 4 && bytes[0] == 0x89 && bytes[1] == 0x50;
      final file = File(p.join(dir.path, 'user-${md5.convert(bytes)}${png ? '.png' : '.jpg'}'));
      if (!await file.exists()) await file.writeAsBytes(bytes);
      return file.path;
    } on Object catch (e, st) {
      ErrorLog.instance.record(e, st, where: 'tags', message: 'Could not save the cover');
      return null;
    }
  }
}

final songInfoSaverProvider = Provider<SongInfoSaver>(SongInfoSaver.new);

/// Stable text for a list of bytes (tests).
String coverKey(List<int> bytes) => base64Url.encode(md5.convert(bytes).bytes);

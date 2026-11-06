import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:path/path.dart' as p;
import '../../../l10n/l10n.dart';

/// What the user changed in the tag editor (null = leave as is).
class TagEdit {
  const TagEdit({
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.year,
    this.trackNumber,
    this.cover,
    this.removeCover = false,
  });

  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? year;
  final int? trackNumber;

  /// New front cover (JPEG/PNG bytes).
  final Uint8List? cover;
  final bool removeCover;
}

class TagWriteException implements Exception {
  TagWriteException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Writes tags into audio files (this *does* modify the user's file).
///
/// Safety: the original is copied to [backupDir] first (last [keepBackups]
/// kept), the write runs in a background isolate, and the result is read back
/// and verified. Supported: MP3 (ID3v2), M4A/MP4, FLAC, WAV. OGG is read-only
/// in the tag library.
class TagWriter {
  TagWriter(this.backupDir, {this.keepBackups = 30});

  final Directory backupDir;
  final int keepBackups;

  static bool canWrite(String path) => const {'.mp3', '.m4a', '.mp4', '.flac', '.wav'}.contains(p.extension(path).toLowerCase());

  /// Writes [edit] into [path]; returns the backup file path.
  Future<String> write(String path, TagEdit edit) async {
    if (!canWrite(path)) throw TagWriteException(l10n.writingTagsIsNotSupportedFor(p.extension(path)));
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    final backup = p.join(backupDir.path, '${DateTime.now().millisecondsSinceEpoch}_${p.basename(path)}');
    await File(path).copy(backup);
    await _trim();
    try {
      await Isolate.run(() => _write(path, edit));
    } on Object catch (e) {
      // Put the original back if the writer broke the file.
      await File(backup).copy(path);
      throw TagWriteException(l10n.couldNotWriteTags(e));
    }
    final check = await Isolate.run(() => readMetadata(File(path)));
    if (edit.title != null && check.title != edit.title) {
      await File(backup).copy(path);
      throw TagWriteException(l10n.tagsDidNotStickFileRestored);
    }
    return backup;
  }

  static void _write(String path, TagEdit e) {
    updateMetadata(File(path), (m) {
      if (e.title != null) m.setTitle(e.title);
      if (e.artist != null) m.setArtist(e.artist);
      if (e.album != null) m.setAlbum(e.album);
      if (e.genre != null) m.setGenres(e.genre!.isEmpty ? const [] : [e.genre!]);
      if (e.year != null) m.setYear(DateTime(e.year!));
      if (e.trackNumber != null) m.setTrackNumber(e.trackNumber);
      if (e.removeCover) {
        m.setPictures(const []);
      } else if (e.cover != null) {
        final png = e.cover!.length > 4 && e.cover![0] == 0x89 && e.cover![1] == 0x50;
        m.setPictures([Picture(e.cover!, png ? 'image/png' : 'image/jpeg', PictureType.coverFront)]);
      }
    });
  }

  Future<void> _trim() async {
    final files = await backupDir.list().where((f) => f is File).cast<File>().toList();
    if (files.length <= keepBackups) return;
    files.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path))); // timestamp prefix
    for (final f in files.take(files.length - keepBackups)) {
      await f.delete();
    }
  }
}

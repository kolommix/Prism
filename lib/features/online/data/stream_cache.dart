import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../library/domain/track.dart';
import '../services/music_service_module.dart';

/// Offline copies of streamed songs in `<app support>/stream_cache/`.
///
/// One file per track (`<source>_<hash>.<ext>`), oldest-used files are
/// deleted when the cache grows past [limitBytes]. Downloads run one at a
/// time in the background; a failed download just leaves no file.
class StreamCache {
  StreamCache(this.dir, {this.limitBytes = 2 * 1024 * 1024 * 1024});

  final Directory dir;
  int limitBytes;

  final _queue = <(Track, MusicServiceModule)>[];
  final _pending = <String>{};
  bool _working = false;
  final _changes = StreamController<String>.broadcast();

  /// Emits the uri of a track whose cached state changed.
  Stream<String> get changes => _changes.stream;

  String _base(Track t) =>
      p.join(dir.path, '${t.sourceId}_${sha1.convert(utf8.encode(t.uri)).toString().substring(0, 20)}');

  /// The cached file, if there is a complete one.
  Future<File?> fileFor(Track t) async {
    if (!await dir.exists()) return null;
    final base = p.basename(_base(t));
    await for (final e in dir.list()) {
      if (e is File && p.basenameWithoutExtension(e.path) == base && !e.path.endsWith('.part')) {
        // Touch so eviction keeps recently played songs.
        unawaited(e.setLastModified(DateTime.now()).catchError((Object _) {}));
        return e;
      }
    }
    return null;
  }

  bool isDownloading(Track t) => _pending.contains(t.uri);

  /// Queues a download (no-op when cached or already queued).
  void download(Track t, MusicServiceModule module) {
    if (_pending.contains(t.uri)) return;
    _pending.add(t.uri);
    _queue.add((t, module));
    _changes.add(t.uri);
    unawaited(_pump());
  }

  Future<void> _pump() async {
    if (_working) return;
    _working = true;
    try {
      while (_queue.isNotEmpty) {
        final (t, module) = _queue.removeAt(0);
        try {
          if (await fileFor(t) == null) {
            await dir.create(recursive: true);
            await module.download(t, _base(t));
            await _evict();
          }
        } on Object catch (e) {
          debugPrint('Offline copy of "${t.title}" failed: $e');
          // Leftover partial file.
          for (final f in await _files()) {
            if (f.path.endsWith('.part') && p.basename(f.path).startsWith(p.basename(_base(t)))) {
              await f.delete().catchError((Object _) => f);
            }
          }
        } finally {
          _pending.remove(t.uri);
          _changes.add(t.uri);
        }
      }
    } finally {
      _working = false;
    }
  }

  Future<void> remove(Track t) async {
    final f = await fileFor(t);
    await f?.delete();
    _changes.add(t.uri);
  }

  Future<List<File>> _files() async => await dir.exists()
      ? [
          await for (final e in dir.list())
            if (e is File) e,
        ]
      : const [];

  Future<int> sizeBytes() async {
    var total = 0;
    for (final f in await _files()) {
      total += await f.length();
    }
    return total;
  }

  Future<void> clear() async {
    for (final f in await _files()) {
      await f.delete().catchError((Object _) => f);
    }
    _changes.add('');
  }

  /// Deletes least recently used files until the cache fits the limit.
  Future<void> _evict() async {
    final files = [for (final f in await _files()) (f, await f.stat())]
      ..sort((a, b) => a.$2.modified.compareTo(b.$2.modified));
    var total = files.fold<int>(0, (n, e) => n + e.$2.size);
    for (final (f, s) in files) {
      if (total <= limitBytes) break;
      await f.delete().catchError((Object _) => f);
      total -= s.size;
    }
  }
}

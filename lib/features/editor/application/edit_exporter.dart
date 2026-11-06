import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/ffmpeg/ffmpeg_runner.dart';
import '../../../l10n/l10n.dart';
import '../../library/data/library_repository.dart';
import '../../library/data/library_scanner.dart';
import '../../library/domain/track.dart';
import '../domain/audio_analysis.dart';
import '../domain/edit_decision_list.dart';
import '../domain/export_command.dart';
import '../domain/timeline.dart';

class ExportException implements Exception {
  ExportException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The user pressed Cancel.
class ExportCancelled implements Exception {
  const ExportCancelled();
}

/// Renders edits with FFmpeg: exports, "save as new track", overwrite with
/// backup, preview files and ringtones. Windows runs the bundled `ffmpeg.exe`,
/// Android runs FFmpegKit in-process; both take the same arguments.
class EditExporter {
  EditExporter({required this._ffmpeg, required this._repo, required this._scanner});

  final FfmpegRunner? _ffmpeg;
  final LibraryRepository _repo;
  final LibraryScanner _scanner;

  bool get available => _ffmpeg != null;

  FfmpegRunner get _ff {
    final f = _ffmpeg;
    if (f == null) throw ExportException(l10n.ffmpegIsNotAvailableOnThis);
    return f;
  }

  Future<PitchEngine> _pitchEngine() async =>
      await _ff.hasFilter('rubberband') ? PitchEngine.rubberband : PitchEngine.resample;

  /// Renders [edl] to [output]. [onProgress] gets 0..1. A cancelled or failed
  /// run leaves no file behind.
  Future<void> render(
    EditDecisionList edl,
    String output,
    ExportFormat format, {
    String? title,
    ExportSettings settings = const ExportSettings(),
    List<String> globalFilters = const [],
    void Function(double)? onProgress,
    FfmpegCancel? cancel,
  }) async {
    final timeline = edl.build();
    final total = timeline.duration.inMilliseconds;
    final args = buildExportArgs(
      timeline: timeline,
      input: edl.sourceUri,
      output: output,
      format: format,
      pitchEngine: await _pitchEngine(),
      title: title,
      settings: settings,
      globalFilters: globalFilters,
    );
    final res = await _ff.run(
      args,
      cancel: cancel,
      onProgress: onProgress == null || total <= 0 ? null : (t) => onProgress((t.inMilliseconds / total).clamp(0, 1)),
    );
    if (cancel?.isCancelled ?? false) {
      await _remove(output);
      throw const ExportCancelled();
    }
    if (!res.ok) {
      await _remove(output);
      throw ExportException(l10n.ffmpegFailed(res.exitCode, res.tail));
    }
  }

  Future<void> _remove(String path) async {
    final f = File(path);
    if (await f.exists()) await f.delete();
  }

  /// Folder where "save as new track" puts files: next to the original on
  /// Windows, `Music/Prism edits` on Android (shared storage the scanner sees).
  Future<Directory> _newTrackDir(Track source) async {
    final dir = Platform.isAndroid
        ? Directory('/storage/emulated/0/Music/Prism edits')
        : Directory(p.dirname(source.uri));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Exports the edit next to the library and scans it in. Returns the path.
  Future<String> saveAsNewTrack(
    Track source,
    EditDecisionList edl,
    ExportFormat format, {
    ExportSettings settings = const ExportSettings(),
    List<String> globalFilters = const [],
    void Function(double)? onProgress,
    FfmpegCancel? cancel,
  }) async {
    final dir = await _newTrackDir(source);
    final base = p.basenameWithoutExtension(source.uri);
    var path = p.join(dir.path, '$base (edit).${format.extension}');
    for (var i = 2; await File(path).exists(); i++) {
      path = p.join(dir.path, '$base (edit $i).${format.extension}');
    }
    await render(edl, path, format,
        title: settings.tags.containsKey('title') ? null : l10n.xEdit(source.title),
        settings: settings,
        globalFilters: globalFilters,
        onProgress: onProgress,
        cancel: cancel);
    // Make sure the folder is part of the library, then index the new file.
    final roots = await _repo.folders();
    final inLibrary = roots.any((r) => p.isWithin(r, dir.path) || p.equals(r, dir.path));
    if (!inLibrary) await _repo.addFolder(dir.path);
    await _scanner.scanFolders([dir.path]).drain<void>();
    return path;
  }

  /// Replaces the song's own file with the edit. A copy of the original goes to
  /// [backupDir] first and comes back if anything fails. Returns the backup.
  Future<String> overwriteWithBackup(
    Track source,
    EditDecisionList edl,
    Directory backupDir, {
    ExportSettings settings = const ExportSettings(),
    List<String> globalFilters = const [],
    void Function(double)? onProgress,
    FfmpegCancel? cancel,
  }) async {
    final format = ExportFormat.ofPath(source.uri);
    if (format == null) throw ExportException(l10n.edOverwriteUnsupported(p.extension(source.uri)));
    final ext = p.extension(source.uri);
    final temp = p.join(p.dirname(source.uri), '${p.basenameWithoutExtension(source.uri)}.prism-edit$ext');
    await render(edl, temp, format, settings: settings, globalFilters: globalFilters, onProgress: onProgress, cancel: cancel);
    if (!await backupDir.exists()) await backupDir.create(recursive: true);
    final backup = p.join(backupDir.path, '${DateTime.now().millisecondsSinceEpoch}_${p.basename(source.uri)}');
    await File(source.uri).copy(backup);
    try {
      await File(temp).copy(source.uri);
    } on Object catch (e) {
      await File(backup).copy(source.uri);
      throw ExportException(l10n.edOverwriteFailed(e));
    } finally {
      await _remove(temp);
    }
    await _scanner.scanFolders([p.dirname(source.uri)]).drain<void>();
    return backup;
  }

  /// Renders to a temp file and returns its bytes (for the "Export to file…"
  /// save dialog, which writes the bytes itself on every platform).
  Future<(String, Uint8List)> renderToBytes(
    Track source,
    EditDecisionList edl,
    ExportFormat format, {
    ExportSettings settings = const ExportSettings(),
    List<String> globalFilters = const [],
    void Function(double)? onProgress,
    FfmpegCancel? cancel,
  }) async {
    final tmp = await getTemporaryDirectory();
    final out = p.join(tmp.path, 'prism_export_${DateTime.now().millisecondsSinceEpoch}.${format.extension}');
    try {
      await render(edl, out, format,
          title: settings.tags.containsKey('title') ? null : l10n.xEdit(source.title),
          settings: settings,
          globalFilters: globalFilters,
          onProgress: onProgress,
          cancel: cancel);
      final name = '${p.basenameWithoutExtension(source.uri)} (edit).${format.extension}';
      return (name, await File(out).readAsBytes());
    } finally {
      await _remove(out);
    }
  }

  /// A plain WAV of the edit, for previews and live presets the player can't
  /// do on the fly. Returns [path] (an existing file is reused).
  Future<String> renderWav(EditDecisionList edl, String path, {void Function(double)? onProgress, FfmpegCancel? cancel}) async {
    if (await File(path).exists()) return path;
    await File(path).parent.create(recursive: true);
    final temp = '$path.part.wav';
    await render(edl, temp, ExportFormat.wav,
        settings: const ExportSettings(keepMetadata: false, removeCover: true), onProgress: onProgress, cancel: cancel);
    await File(temp).rename(path);
    return path;
  }

  /// Exact position of the zero crossing nearest to [source] in [path].
  Future<Duration> nearestZero(String path, Duration source) async {
    const before = Duration(milliseconds: 15);
    const rate = 48000;
    final tmp = await getTemporaryDirectory();
    final raw = p.join(tmp.path, 'prism_zero_${DateTime.now().microsecondsSinceEpoch}.raw');
    final start = source < before ? Duration.zero : source - before;
    try {
      final res = await _ff.run(buildSnippetArgs(input: path, start: start, length: const Duration(milliseconds: 30), output: raw));
      if (!res.ok) return source;
      final bytes = await File(raw).readAsBytes();
      final samples = Int16List.sublistView(bytes, 0, bytes.length ~/ 2);
      final center = ((source - start).inMicroseconds * rate / 1e6).round();
      final i = nearestZeroCrossing(samples, center);
      return start + Duration(microseconds: (i * 1e6 / rate).round());
    } on Object {
      return source;
    } finally {
      await _remove(raw);
    }
  }
}

/// Convenience: an EDL's timeline duration for display.
Duration editedDuration(EditDecisionList edl) => Timeline.fromOps(edl.sourceDuration, edl.ops).duration;

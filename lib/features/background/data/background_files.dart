import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../../core/ffmpeg/ffmpeg_runner.dart';
import '../../../l10n/l10n.dart';
import '../domain/background_config.dart';

class BackgroundFileException implements Exception {
  BackgroundFileException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// FFmpeg arguments that turn a video into the looped frames of the background.
List<String> videoFrameArgs(String input, String outputDir, {int seconds = 30, int fps = 12, int width = 720}) => [
      '-y',
      '-i', input,
      '-an',
      '-t', '$seconds',
      '-vf', 'fps=$fps,scale=$width:-2',
      '-q:v', '6',
      p.join(outputDir, '%05d.jpg'),
    ];

/// Copies of the pictures and frames the user chose, so a background doesn't
/// break when the original file moves.
class BackgroundFiles {
  BackgroundFiles(this.supportDir, this._ffmpeg);

  final Directory supportDir;
  final FfmpegRunner? _ffmpeg;

  Directory get _images => Directory(p.join(supportDir.path, 'bg_images'));
  Directory get _videos => Directory(p.join(supportDir.path, 'bg_video'));

  /// Keeps a copy of a chosen picture; returns the copy's path.
  Future<String> addImage(String path) async {
    final bytes = await File(path).readAsBytes();
    return _writeImage(bytes, p.extension(path));
  }

  Future<String> _writeImage(List<int> bytes, String ext) async {
    await _images.create(recursive: true);
    final out = File(p.join(_images.path, '${md5.convert(bytes)}$ext'));
    if (!await out.exists()) await out.writeAsBytes(bytes);
    return out.path;
  }

  /// Extracts up to 30 s of frames from a video; returns their folder.
  Future<String> addVideo(String path) async {
    final ff = _ffmpeg;
    if (ff == null) throw BackgroundFileException(l10n.ffmpegIsNotAvailableOnThis);
    final st = await File(path).stat();
    final key = md5.convert(utf8.encode('$path|${st.size}|${st.modified.millisecondsSinceEpoch}'));
    final dir = Directory(p.join(_videos.path, '$key'));
    if (await dir.exists() && (await dir.list().length) > 0) return dir.path;
    await dir.create(recursive: true);
    final res = await ff.run(videoFrameArgs(path, dir.path));
    final frames = await dir.list().length;
    if (!res.ok || frames == 0) {
      await dir.delete(recursive: true);
      throw BackgroundFileException(l10n.bgVideoFailed);
    }
    return dir.path;
  }

  /// What a theme file carries: the settings, a picture inside the file (it has
  /// to work on another device), and never a local path. A video is too big to
  /// travel, so a theme that uses one falls back to the cover.
  Future<Map<String, dynamic>> toThemeJson(BackgroundConfig cfg, {int maxImageBytes = 6 * 1024 * 1024}) async {
    final clean = cfg.copyWith(imagePath: '', videoDir: '');
    final json = clean.toJson();
    if (cfg.current == BackgroundStyle.video) {
      json['style'] = BackgroundStyle.cover.name;
    } else if (cfg.current == BackgroundStyle.image) {
      final f = File(cfg.imagePath);
      if (await f.exists() && await f.length() <= maxImageBytes) {
        json['imageData'] = base64Encode(await f.readAsBytes());
        json['imageExt'] = p.extension(cfg.imagePath);
      } else {
        json['style'] = BackgroundStyle.cover.name;
      }
    }
    return json;
  }

  /// Reads a theme's background back. Null when it can't be understood (a theme
  /// should still apply if its background is broken).
  Future<BackgroundConfig?> fromThemeJson(Map<String, dynamic> json) async {
    try {
      final data = json['imageData'];
      final body = {...json}
        ..remove('imageData')
        ..remove('imageExt');
      var cfg = BackgroundConfig.fromJson(body);
      if (data is String) {
        final ext = p.extension('x${json['imageExt'] ?? '.jpg'}');
        final safe = RegExp(r'^\.[A-Za-z0-9]{1,5}$').hasMatch(ext) ? ext : '.jpg';
        cfg = cfg.copyWith(imagePath: await _writeImage(base64Decode(data), safe));
      }
      return cfg;
    } on Object {
      return null;
    }
  }
}

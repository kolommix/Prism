import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../../core/ffmpeg/ffmpeg_runner.dart';
import '../../library/domain/track.dart';
import '../domain/spectrum.dart';

/// Decodes a song with FFmpeg (22.05 kHz mono), analyses it in a background
/// isolate and caches the result on disk (~250 KB per song, oldest deleted
/// above [maxCacheFiles]).
class SpectrumService {
  SpectrumService({required this._ffmpeg, required Directory cacheDir, this.maxCacheFiles = 300}) : _dir = cacheDir;

  final FfmpegRunner? _ffmpeg;
  final Directory _dir;
  final int maxCacheFiles;
  static const _rate = 22050;

  bool get available => _ffmpeg != null;

  Future<Spectrum?> spectrumFor(Track t) async {
    final ff = _ffmpeg;
    if (ff == null || t.sourceId != 'local') return null;
    final file = File(t.uri);
    if (!await file.exists()) return null;
    final stat = await file.stat();
    final key = md5.convert(utf8.encode('${t.uri}|${stat.size}|${stat.modified.millisecondsSinceEpoch}')).toString();
    if (!await _dir.exists()) await _dir.create(recursive: true);
    final cached = File(p.join(_dir.path, '$key.spc'));
    if (await cached.exists()) {
      final s = Spectrum.decode(await cached.readAsBytes());
      if (s != null) return s;
    }
    final raw = p.join(_dir.path, '$key.raw');
    try {
      final res = await ff.run(['-y', '-i', t.uri, '-vn', '-ac', '1', '-ar', '$_rate', '-f', 's16le', '-acodec', 'pcm_s16le', raw]);
      if (!res.ok) return null;
      final pcm = await File(raw).readAsBytes();
      final spectrum = await Isolate.run(() => analyzePcm16(pcm, sampleRate: _rate));
      await cached.writeAsBytes(spectrum.encode());
      await _trim();
      return spectrum;
    } finally {
      final r = File(raw);
      if (await r.exists()) await r.delete();
    }
  }

  Future<void> _trim() async {
    final files = await _dir.list().where((e) => e is File && e.path.endsWith('.spc')).cast<File>().toList();
    if (files.length <= maxCacheFiles) return;
    final withTime = [for (final f in files) (f, (await f.stat()).modified)]..sort((a, b) => a.$2.compareTo(b.$2));
    for (final (f, _) in withTime.take(files.length - maxCacheFiles)) {
      await f.delete();
    }
  }

  /// For tests: analyse an in-memory PCM buffer the same way.
  static Spectrum analyze(Uint8List pcm) => analyzePcm16(pcm, sampleRate: _rate);
}

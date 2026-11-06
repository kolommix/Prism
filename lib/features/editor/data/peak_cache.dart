import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../../core/ffmpeg/ffmpeg_runner.dart';
import '../domain/audio_analysis.dart';

/// Waveform data plus what the editor derives from it.
class AudioAnalysis {
  const AudioAnalysis({required this.pyramid, required this.beats, required this.silences});
  final PeakPyramid pyramid;

  /// Source time, sorted.
  final List<Duration> beats;
  final List<(Duration, Duration)> silences;
}

/// Decodes a song once and keeps its waveform in `<dir>/<hash>.peaks`, so
/// opening the editor again is instant. The key has the file's size and date:
/// a changed file is decoded again.
class PeakCache {
  PeakCache(this.dir, this._ffmpeg, {this.keepFiles = 300});

  final Directory dir;
  final FfmpegRunner? _ffmpeg;
  final int keepFiles;

  static const _rate = 16000;
  static const _pps = 200;
  static const _magic = 0x31505250; // "PRP1"

  Future<File> _fileFor(String path) async {
    final st = await File(path).stat();
    final key = md5.convert('$path|${st.size}|${st.modified.millisecondsSinceEpoch}'.codeUnits);
    return File(p.join(dir.path, '$key.peaks'));
  }

  Future<AudioAnalysis?> load(String path) async {
    final ffmpeg = _ffmpeg;
    final file = await _fileFor(path);
    Uint8List? base;
    if (await file.exists()) base = _read(await file.readAsBytes());
    if (base == null) {
      if (ffmpeg == null) return null;
      base = await _decode(ffmpeg, path);
      await dir.create(recursive: true);
      await file.writeAsBytes(_write(base));
      await _trim();
    }
    final data = base;
    return Isolate.run(() {
      final beats = detectBeats(data, _pps);
      final silences = detectSilences(data, _pps);
      return AudioAnalysis(pyramid: PeakPyramid(_pps, data), beats: beats, silences: silences);
    });
  }

  Future<Uint8List> _decode(FfmpegRunner ffmpeg, String path) async {
    final raw = p.join(Directory.systemTemp.path, 'prism_peaks_${path.hashCode}_${DateTime.now().microsecondsSinceEpoch}.raw');
    try {
      final res = await ffmpeg.run(['-y', '-i', path, '-vn', '-ac', '1', '-ar', '$_rate', '-f', 's16le', '-acodec', 'pcm_s16le', raw]);
      if (!res.ok) throw FileSystemException(res.tail, path);
      return await Isolate.run(() async => peaksFromPcmBytes(await File(raw).readAsBytes(), _rate ~/ _pps));
    } finally {
      final f = File(raw);
      if (await f.exists()) await f.delete();
    }
  }

  static Uint8List? _read(Uint8List bytes) {
    if (bytes.length < 8) return null;
    final h = ByteData.sublistView(bytes);
    if (h.getUint32(0, Endian.little) != _magic) return null;
    final len = h.getUint32(4, Endian.little);
    if (bytes.length < 8 + len) return null;
    return Uint8List.sublistView(bytes, 8, 8 + len);
  }

  static Uint8List _write(Uint8List base) {
    final out = Uint8List(8 + base.length);
    ByteData.sublistView(out)
      ..setUint32(0, _magic, Endian.little)
      ..setUint32(4, base.length, Endian.little);
    out.setRange(8, out.length, base);
    return out;
  }

  Future<void> _trim() async {
    final files = await dir.list().where((f) => f is File).cast<File>().toList();
    if (files.length <= keepFiles) return;
    final dated = [for (final f in files) (f, (await f.stat()).modified)]..sort((a, b) => a.$2.compareTo(b.$2));
    for (final (f, _) in dated.take(files.length - keepFiles)) {
      await f.delete();
    }
  }
}

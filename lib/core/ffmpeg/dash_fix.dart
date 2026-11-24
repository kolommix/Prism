import 'dart:io';

import 'ffmpeg_runner.dart';

/// YouTube's AAC audio comes as a "DASH" MP4 (fragments, brand `dash`).
/// Players read it, but the tag library can't write into it ("tags did not
/// stick"), and some tools see no length. FFmpeg copies the same audio into a
/// plain .m4a in a moment, without re-encoding (yt-dlp does the same).
///
/// Returns true when the file was rewritten. A file that isn't a DASH MP4, or
/// no FFmpeg, leaves everything as it was.
Future<bool> fixDashM4a(File file, FfmpegRunner? ffmpeg) async {
  if (ffmpeg == null || !await isDashMp4(file)) return false;
  final tmp = File('${file.path}.fix.m4a');
  try {
    final r = await ffmpeg.run([
      '-y', '-v', 'error', '-i', file.path, '-map', '0:a:0', '-c', 'copy', '-movflags', '+faststart', '-f', 'mp4', tmp.path,
    ]);
    if (!r.ok || !await tmp.exists() || await tmp.length() < 1024) {
      if (await tmp.exists()) await tmp.delete();
      return false;
    }
    await tmp.rename(file.path);
    return true;
  } on Object {
    try {
      if (await tmp.exists()) await tmp.delete();
    } on Object {
      // Left for the next cleanup.
    }
    return false;
  }
}

/// True for an MP4 whose `ftyp` box names `dash` as its brand.
Future<bool> isDashMp4(File file) async {
  try {
    final raf = await file.open();
    try {
      final head = await raf.read(32);
      if (head.length < 12) return false;
      final type = String.fromCharCodes(head.sublist(4, 8));
      final brand = String.fromCharCodes(head.sublist(8, 12));
      return type == 'ftyp' && brand == 'dash';
    } finally {
      await raf.close();
    }
  } on Object {
    return false;
  }
}

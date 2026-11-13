import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../domain/photo_songs.dart';

/// Reads the text in a picture on this device: Windows' own text recognition,
/// Tesseract on Android (English + Russian). Nothing is sent anywhere.
class PhotoReader {
  const PhotoReader();

  static const _channel = MethodChannel('prism/ocr');

  static bool get supported => Platform.isWindows || Platform.isAndroid;

  /// Throws [PhotoReadException] when the picture can't be read.
  Future<OcrPage> read(String path) async {
    if (!supported) throw const PhotoReadException();
    try {
      final raw = await _channel.invokeMethod<Map<Object?, Object?>>('read', {'path': p.normalize(p.absolute(path))});
      if (raw == null) throw const PhotoReadException();
      return ocrPageFromNative(raw);
    } on PlatformException catch (e) {
      throw PhotoReadException(e.message);
    } on MissingPluginException {
      throw const PhotoReadException();
    }
  }
}

class PhotoReadException implements Exception {
  const PhotoReadException([this.detail]);
  final String? detail;
  @override
  String toString() => 'PhotoReadException($detail)';
}

// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:prism/features/online/data/photo_reader.dart';
import 'package:prism/features/online/domain/photo_songs.dart';

const _songs = [
  ('Bohemian Rhapsody', 'Queen', '5:55'),
  ('Кукла колдуна', 'Король и Шут', '3:24'),
  ('Blinding Lights', 'The Weeknd', '3:20'),
  ('Группа крови', 'Кино', '4:46'),
  ('Smells Like Teen Spirit', 'Nirvana', '5:01'),
  ('Позови меня с собой', 'Алла Пугачёва', '4:57'),
  ('Do I Wanna Know?', 'Arctic Monkeys', '4:32'),
  ('Трудный возраст', 'Дора', '2:38'),
  ("Don't Stop Me Now", 'Queen', '3:29'),
  ('Shape of You', 'Ed Sheeran', '3:53'),
];

/// A phone playlist screenshot, dark theme, drawn on the device with its own
/// fonts (status bar, title, buttons, then the songs).
Future<String> _drawScreenshot() async {
  const w = 1080.0, h = 1500.0;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec)..drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF121212));
  void text(String s, double x, double y, double size, Color color, {FontWeight weight = FontWeight.w400}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, color: color, fontWeight: weight)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(x, y));
  }

  const white = Color(0xFFFFFFFF), grey = Color(0xFF9A9A9A);
  text('12:45', 40, 20, 24, white);
  text('87%', 960, 20, 24, white);
  text('Road trip mix', 60, 120, 52, white, weight: FontWeight.w600);
  text('kolommix · 42 songs, 2 h 31 min', 60, 200, 24, grey);
  text('Shuffle', 60, 270, 30, white, weight: FontWeight.w600);
  var y = 360.0;
  for (final (title, artist, len) in _songs) {
    c.drawRect(Rect.fromLTWH(60, y, 96, 96), Paint()..color = const Color(0xFF555555));
    text(title, 180, y + 6, 30, white, weight: FontWeight.w600);
    text(artist, 180, y + 52, 24, grey);
    text(len, 940, y + 30, 24, grey);
    y += 116;
  }
  final image = await rec.endRecording().toImage(w.toInt(), h.toInt());
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(p.join(Directory.systemTemp.path, 'prism_photo_test.png'));
  await file.writeAsBytes(png!.buffer.asUint8List());
  return file.path;
}

/// Photo import on the real device: draws a playlist screenshot, reads it
/// with the platform's text reader (Tesseract on Android, Windows' own on
/// Windows) and finds the songs.
///
/// `flutter test integration_test/photo_import_test.dart -d DEVICE`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a playlist screenshot becomes its songs', (tester) async {
    final found = await tester.runAsync(() async {
      final path = await _drawScreenshot();
      final watch = Stopwatch()..start();
      final page = await const PhotoReader().read(path);
      print('read in ${watch.elapsedMilliseconds} ms, ${page.lines.length} lines');
      for (final l in page.lines) {
        print('  ${l.x.round()},${l.y.round()} | ${l.text}');
      }
      return songsFromPhoto(page);
    });
    final names = [for (final s in found!) '${s.artist} - ${s.title}'];
    print('songs: $names');
    final wanted = [for (final (t, a, _) in _songs) '$a - $t'];
    final right = wanted.where(names.contains).length;
    print('$right of ${wanted.length} exactly right');
    expect(names.length, inInclusiveRange(9, 11), reason: 'no headers or buttons as songs');
    expect(right, greaterThanOrEqualTo(8));
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/online/domain/import_intake.dart';
import 'package:prism/features/online/domain/photo_songs.dart';

/// The fixtures are the real answer of Windows' text recognition (English +
/// Russian readers, same shape as `prism/ocr`) for drawn playlist screenshots.
OcrPage _fixture(String name) =>
    ocrPageFromNative(jsonDecode(File('test/fixtures/photo/$name.json').readAsStringSync()) as Map<String, dynamic>);

List<String> _names(OcrPage page) => [for (final s in songsFromPhoto(page)) '${s.artist} - ${s.title}'];

void main() {
  const phone = [
    'Queen - Bohemian Rhapsody',
    'Король и Шут - Кукла колдуна',
    'The Weeknd - Blinding Lights',
    'Кино - Группа крови',
    'Nirvana - Smells Like Teen Spirit',
    'Алла Пугачёва - Позови меня с собой',
    'Arctic Monkeys - Do I Wanna Know?',
    'Би-2, Юлия Чичерина - Мой рок-н-ролл',
    "Queen - Don't Stop Me Now",
    'Ed Sheeran - Shape of You',
  ];

  test('phone playlist, dark: every song, no header or buttons, English words fixed', () {
    final page = _fixture('phone_dark');
    expect(_names(page), phone);
    final songs = songsFromPhoto(page);
    expect(songs.first.durationMs, (5 * 60 + 55) * 1000);
    expect(songs.last.durationMs, (3 * 60 + 53) * 1000);
  });

  test('phone playlist, light', () {
    final names = _names(_fixture('phone_light'));
    expect(names.length, phone.length);
    expect(names, containsAll(phone.where((n) => !n.contains('Wanna'))));
  });

  test('desktop table: title column only, album and date columns left out', () {
    final page = _fixture('desktop_table');
    expect(_names(page), [
      'Дора - Трудный возраст',
      'MGMT - Kids',
      'Сплин - Мало огня',
      'Childish Gambino - Redbone',
      'MGMT - Electric Feel',
      'Кино - Спокойная ночь',
      'Arctic Monkeys - Do I Wanna Know?',
    ]);
    expect(songsFromPhoto(page)[1].durationMs, (5 * 60 + 2) * 1000);
  });

  test('a list of "Artist - Song" lines (notes, a message)', () {
    OcrLine line(String text, double y) {
      var x = 20.0;
      return OcrLine([
        for (final w in text.split(' '))
          () {
            final word = OcrWord(w, x, y, w.length * 12.0, 24);
            x += w.length * 12.0 + 8;
            return word;
          }(),
      ]);
    }

    final page = OcrPage(800, 600, [
      line('My songs', 20),
      line('1. Дора - Трудный возраст', 80),
      line('2. MGMT - Kids', 160),
      line('3. Queen – Bohemian Rhapsody', 240),
    ]);
    expect(_names(page), ['Дора - Трудный возраст', 'MGMT - Kids', 'Queen - Bohemian Rhapsody']);
  });

  test('look-alike Russian letters on English rows are swapped for the English reading', () {
    final base = [
      OcrLine([const OcrWord('Shape', 0, 0, 60, 20), const OcrWord('of', 70, 0, 20, 20), const OcrWord('Уои', 100, 0, 40, 20)]),
      OcrLine([const OcrWord('Кино', 0, 40, 50, 20)]),
    ];
    final helper = [
      OcrLine([const OcrWord('Shape', 0, 0, 60, 20), const OcrWord('of', 70, 0, 20, 20), const OcrWord('You', 100, 0, 41, 20)]),
      OcrLine([const OcrWord('KMHO', 0, 40, 50, 20)]),
    ];
    final merged = mergeReadings(base, helper);
    expect(merged[0].text, 'Shape of You');
    expect(merged[1].text, 'Кино');
  });

  test('a lone "|" between English words is the letter I', () {
    final page = OcrPage(800, 400, [
      OcrLine([const OcrWord('Do', 20, 20, 30, 24), const OcrWord('|', 58, 20, 6, 24), const OcrWord('Wanna', 72, 20, 70, 24), const OcrWord('Know?', 150, 20, 70, 24)]),
      OcrLine([const OcrWord('Arctic', 20, 50, 60, 18), const OcrWord('Monkeys', 88, 50, 80, 18)]),
      OcrLine([const OcrWord('Kids', 20, 100, 50, 24)]),
      OcrLine([const OcrWord('MGMT', 20, 130, 60, 18)]),
    ]);
    expect(_names(page), ['Arctic Monkeys - Do I Wanna Know?', 'MGMT - Kids']);
  });

  test('pictures are recognized as photo imports', () {
    expect(isPhotoFile(r'C:\Users\me\Pictures\Screenshot 2026-11-13.PNG'), isTrue);
    expect(isPhotoFile('list.csv'), isFalse);
    expect(classifyImportText(r'C:\shots\playlist.jpg'), isA<PhotosInput>());
  });

  test('overlapping screenshots: each song once', () {
    final page = _fixture('phone_dark');
    final twice = dedupeSongs([...songsFromPhoto(page), ...songsFromPhoto(page)]);
    expect(twice.length, phone.length);
  });
}

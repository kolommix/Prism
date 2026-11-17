import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/lyrics/domain/lyrics_search.dart';

void main() {
  final index = [
    LyricsIndexEntry(1, '[00:01.00]Is this the real life?\n[00:05.00]Is this just fantasy?'),
    LyricsIndexEntry(2, 'Я всё ещё жду\nпереломай мои кости, ну же'),
    LyricsIndexEntry(3, 'Something else entirely'),
  ];

  test('finds a line, ignoring case, punctuation and time tags', () {
    expect(searchLyrics(index, 'is THIS the real life'), [(1, 'Is this the real life?')]);
  });

  test('a phrase across two lines shows the first one', () {
    expect(searchLyrics(index, 'real life is this just'), [(1, 'Is this the real life?')]);
  });

  test('ё and е are the same', () {
    expect(searchLyrics(index, 'я все еще жду'), [(2, 'Я всё ещё жду')]);
  });

  test('a name is not a line', () {
    expect(looksLikeLine('Queen'), isFalse);
    expect(looksLikeLine('переломай мои'), isTrue);
  });
}

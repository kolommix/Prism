import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/l10n/l10n.dart';

void main() {
  tearDown(() => setAppLocale(const Locale('en')));

  test('both languages have the same keys and placeholders', () {
    Map<String, dynamic> load(String f) => jsonDecode(File('lib/l10n/$f').readAsStringSync()) as Map<String, dynamic>;
    final en = load('app_en.arb');
    final ru = load('app_ru.arb');
    final keys = en.keys.where((k) => !k.startsWith('@')).toSet();
    expect(ru.keys.where((k) => !k.startsWith('@')).toSet(), keys);
    final placeholder = RegExp(r'(?<![a-z=])\{(\w+)\}');
    for (final k in keys) {
      final a = placeholder.allMatches(en[k] as String).map((m) => m[1]).toSet();
      final b = placeholder.allMatches(ru[k] as String).map((m) => m[1]).toSet();
      expect(b, a, reason: k);
    }
  });

  test('Russian plurals use one / few / many', () {
    setAppLocale(const Locale('ru'));
    expect(l10n.nSongs(1), '1 песня');
    expect(l10n.nSongs(2), '2 песни');
    expect(l10n.nSongs(5), '5 песен');
    expect(l10n.nSongs(11), '11 песен');
    expect(l10n.nSongs(21), '21 песня');
    expect(l10n.nSongs(24), '24 песни');
    expect(l10n.nDays(3), '3 дня');
    expect(l10n.nTimes(5), '5 раз');
  });

  test('English plurals', () {
    expect(l10n.nSongs(1), '1 song');
    expect(l10n.nSongs(2), '2 songs');
  });

  test('dates and numbers follow the language', () async {
    await initAppLocaleData();
    setAppLocale(const Locale('ru'));
    expect(fmtNum(12.5, 1), '12,5');
    expect(monthShort(1), 'янв');
    expect(weekdayShort(1), 'пн');
    setAppLocale(const Locale('en'));
    expect(fmtNum(12.5, 1), '12.5');
    expect(monthShort(1), 'Jan');
    expect(weekdayShort(1), 'Mon');
  });

  test('saved choice wins, unknown system language falls back to English', () {
    expect(resolveAppLocale('ru', const Locale('en')), const Locale('ru'));
    expect(resolveAppLocale('', const Locale('ru')), const Locale('ru'));
    expect(resolveAppLocale('', const Locale('de')), const Locale('en'));
  });

  test('unknown artist is recognized in any language', () {
    expect(isUnknownArtist('Unknown artist'), isTrue);
    expect(isUnknownArtist('Неизвестный исполнитель'), isTrue);
    expect(isUnknownArtist('Radiohead'), isFalse);
  });
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/hotkeys/domain/hotkeys.dart';
import 'package:prism/features/lyrics/application/lyrics_window.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/lyrics/domain/lrc.dart';

void main() {
  group('hotkeys', () {
    test('every action has its own standard key, with modifiers', () {
      expect(defaultHotkeys.keys.toSet(), HotkeyAction.values.toSet());
      expect(defaultHotkeys.values.toSet().length, defaultHotkeys.length, reason: 'no two actions share a key');
      expect(defaultHotkeys.values.every((c) => c.valid), isTrue);
    });

    test('saved and read back', () {
      const c = HotkeyCombo(0x27, ctrl: true, alt: true, shift: true);
      expect(HotkeyCombo.decode(c.encode()), c);
      expect(c.mods, 7);
      expect(HotkeyCombo.decode('junk'), isNull);
      expect(HotkeyCombo.decode(''), isNull);
    });

    test('a key alone is refused, an F key alone is fine', () {
      expect(const HotkeyCombo(0x41).valid, isFalse);
      expect(const HotkeyCombo(0x7B).valid, isTrue);
    });

    test('keys by their place: Russian layout gives the same codes', () {
      expect(vkForPhysicalKey(PhysicalKeyboardKey.keyL), 0x4C);
      expect(vkForPhysicalKey(PhysicalKeyboardKey.digit0), 0x30);
      expect(vkForPhysicalKey(PhysicalKeyboardKey.f5), 0x74);
      expect(vkForPhysicalKey(PhysicalKeyboardKey.arrowRight), 0x27);
      expect(vkForPhysicalKey(PhysicalKeyboardKey.controlLeft), isNull);
      expect(const HotkeyCombo(0x27, ctrl: true, alt: true).label, 'Ctrl + Alt + →');
    });
  });

  group('floating lyrics lines', () {
    const track = Track(id: 1, uri: 'x', title: 'Кукла колдуна', artist: 'Король и Шут');
    final lyrics = Lyrics(
      lines: [
        const LyricLine(Duration(seconds: 10), 'Тёмный, мрачный коридор'),
        const LyricLine(Duration(seconds: 14), ''),
        const LyricLine(Duration(seconds: 18), 'Я на цыпочках, как вор'),
      ],
      source: 'lrclib',
    );

    test('before the singing: the name, then the first line', () {
      expect(lyricsWindowLines(track, lyrics, Duration.zero), ('Кукла колдуна', 'Тёмный, мрачный коридор'));
    });

    test('the line being sung and the next; a pause is a note', () {
      expect(lyricsWindowLines(track, lyrics, const Duration(seconds: 11)), ('Тёмный, мрачный коридор', '♪'));
      expect(lyricsWindowLines(track, lyrics, const Duration(seconds: 15)), ('♪', 'Я на цыпочках, как вор'));
      expect(lyricsWindowLines(track, lyrics, const Duration(seconds: 30)), ('Я на цыпочках, как вор', ''));
    });

    test('no timed lyrics: name and artist; nothing playing: empty', () {
      expect(lyricsWindowLines(track, null, Duration.zero), ('Кукла колдуна', 'Король и Шут'));
      expect(lyricsWindowLines(null, lyrics, Duration.zero), ('', ''));
    });
  });
}

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/background/domain/background_config.dart';
import 'package:prism/features/background/presentation/background_effects.dart';
import 'package:prism/features/background/presentation/lyrics_effect.dart';
import 'package:prism/features/lyrics/domain/lrc.dart';

LyricsEffect _effect(SongText song) {
  final e = BackgroundEffect.create(BackgroundStyle.lyrics, BackgroundConfig.defaultsFor(BackgroundStyle.lyrics), Colors.white, Colors.amber) as LyricsEffect;
  e.resize(const Size(800, 500));
  e.song = song;
  return e;
}

void _paint(BackgroundEffect e) {
  final rec = ui.PictureRecorder();
  e.paint(Canvas(rec));
  rec.endRecording().dispose();
}

void main() {
  final synced = Lyrics(
    lines: const [
      LyricLine(Duration(seconds: 10), 'First line here'),
      LyricLine(Duration(seconds: 14), 'Второй ряд'),
      LyricLine(Duration(seconds: 18), ''),
      LyricLine(Duration(seconds: 22), 'Last one'),
    ],
    source: 'test',
  );

  test('the line being sung is the big one; before it, the song name', () {
    final e = _effect(SongText(title: 'Song', artist: 'Band', lyrics: synced, duration: const Duration(minutes: 1)));
    for (final (sec, want) in [(2, 0), (11, 1), (15, 2), (19, 3), (30, 4), (12, 1)]) {
      e.songPosition = Duration(seconds: sec);
      for (var i = 0; i < 30; i++) {
        e.step(1 / 60);
      }
      expect(e.currentLine, want, reason: 'at $sec s');
      _paint(e);
    }
    e.bass = 0.8;
    e.levels.fillRange(0, 32, 0.7);
    e.pointer = const Offset(400, 280);
    e.burst(const Offset(300, 250), 1);
    e.step(1 / 60);
    _paint(e);
    e.dispose();
  });

  test('plain lyrics are spread over the song', () {
    final plain = Lyrics(plain: 'one\n\ntwo\nthree\nfour', source: 'test');
    final e = _effect(SongText(title: 'Song', lyrics: plain, duration: const Duration(seconds: 100)));
    e.songPosition = const Duration(seconds: 1);
    e.step(1 / 60);
    expect(e.currentLine, 0, reason: 'the name first');
    e.songPosition = const Duration(seconds: 50);
    e.step(1 / 60);
    expect(e.currentLine, 3, reason: 'half way: the third of four lines');
    e.songPosition = const Duration(seconds: 99);
    e.step(1 / 60);
    expect(e.currentLine, 4);
    _paint(e);
    e.dispose();
  });

  test('no lyrics: only the name, and a new song starts over', () {
    final e = _effect(const SongText(title: 'Instrumental', artist: 'Band'));
    e.songPosition = const Duration(seconds: 40);
    e.step(1 / 60);
    expect(e.currentLine, 0);
    _paint(e);
    e.song = SongText(title: 'Next', lyrics: synced);
    e.songPosition = const Duration(seconds: 15);
    e.step(1 / 60);
    expect(e.currentLine, 2);
    _paint(e);
    e.song = null;
    e.step(1 / 60);
    _paint(e);
    e.dispose();
  });
}

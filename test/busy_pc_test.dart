import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/motion/busy_pc.dart';
import 'package:prism/core/theme/album_palette.dart';

void main() {
  const budget = 8333; // 120 Hz

  List<({int atUs, int spanUs})> frames(int count, {required int fromUs, required int lateEvery, int gapUs = budget}) => [
        for (var i = 0; i < count; i++)
          (atUs: fromUs + i * gapUs, spanUs: lateEvery > 0 && i % lateEvery == 0 ? 3 * budget : budget ~/ 2),
      ];

  group('busy PC', () {
    test('a smooth app is not busy', () {
      final m = BusyMeter();
      expect(m.add(frames(200, fromUs: 0, lateEvery: 0), budgetUs: budget), isFalse);
      expect(m.busy, isFalse);
    });

    test('a few late frames (opening a page) are not "busy"', () {
      final m = BusyMeter();
      m.add(frames(200, fromUs: 0, lateEvery: 20), budgetUs: budget);
      expect(m.busy, isFalse);
    });

    test('many late frames turn it on, a calm stretch turns it off again', () {
      final m = BusyMeter();
      expect(m.add(frames(60, fromUs: 0, lateEvery: 2), budgetUs: budget), isTrue);
      expect(m.busy, isTrue);
      // 4 s calm is not enough...
      var t = 60 * budget;
      m.add(frames(480, fromUs: t, lateEvery: 0), budgetUs: budget);
      expect(m.busy, isTrue);
      // ...10 s is.
      t += 480 * budget;
      m.add(frames(1200, fromUs: t, lateEvery: 0), budgetUs: budget);
      expect(m.busy, isFalse);
    });

    test('too few frames to judge: no change', () {
      final m = BusyMeter();
      expect(m.add(frames(10, fromUs: 0, lateEvery: 1), budgetUs: budget), isFalse);
    });

    test('nothing drawn for a while ends busy mode', () {
      final m = BusyMeter()..add(frames(60, fromUs: 0, lateEvery: 1), budgetUs: budget);
      expect(m.idle(), isTrue);
      expect(m.busy, isFalse);
    });
  });

  test('Windows priority goes above normal and back', () {
    expect(ProcessPriority.apply(high: true), isTrue);
    expect(ProcessPriority.current(), ProcessPriority.aboveNormal);
    expect(ProcessPriority.apply(high: false), isTrue);
    expect(ProcessPriority.current(), ProcessPriority.normal);
  }, testOn: 'windows');

  test('cover colors are counted in a background isolate', () async {
    // Half red, half blue, 64 x 64.
    final px = Uint8List(64 * 64 * 4);
    for (var i = 0; i < 64 * 64; i++) {
      final red = i % 64 < 32;
      px[i * 4] = red ? 220 : 20;
      px[i * 4 + 1] = 30;
      px[i * 4 + 2] = red ? 30 : 220;
      px[i * 4 + 3] = 255;
    }
    final colors = await Isolate.run(() => AlbumPaletteExtractor.countColors(px, 64, 64));
    expect(colors, hasLength(4));
    final seed = colors![0];
    final r = (seed >> 16) & 0xFF, b = seed & 0xFF;
    expect(r > 150 || b > 150, isTrue, reason: 'a strong cover color, not grey');
  }, skip: Platform.isWindows ? null : 'Windows only here');
}

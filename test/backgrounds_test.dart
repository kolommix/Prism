import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prism/core/theme/theme_config.dart';
import 'package:prism/features/background/data/background_files.dart';
import 'package:prism/features/background/domain/background_config.dart';
import 'package:prism/features/background/presentation/background_effects.dart';

void main() {
  group('config', () {
    test('every style has its own settings, saved separately', () {
      var c = const BackgroundConfig();
      for (final s in BackgroundStyle.values) {
        if (s == BackgroundStyle.cover) continue;
        c = c.withParams(s, BackgroundConfig.defaultsFor(s).copyWith(speed: 2));
      }
      for (final s in BackgroundStyle.values) {
        if (s == BackgroundStyle.cover) continue;
        expect(c.paramsFor(s).speed, 2, reason: s.name);
      }
      final other = c.withParams(BackgroundStyle.aurora, const BgParams(speed: 0.5));
      expect(other.paramsFor(BackgroundStyle.aurora).speed, 0.5);
      expect(other.paramsFor(BackgroundStyle.snow).speed, 2);
    });

    test('JSON round trip, also the per-style map', () {
      final c = const BackgroundConfig(style: 'aurora', dim: 0.3, parallax: true, batterySaver: true, gradientPreset: 'ember')
          .withParams(BackgroundStyle.mesh, const BgParams(speed: 1.5));
      final back = BackgroundConfig.fromJson(jsonDecode(jsonEncode(c.toJson())) as Map<String, dynamic>);
      expect(back, c);
      expect(back.current, BackgroundStyle.aurora);
    });

    test('settings saved before this version still load', () {
      final old = BackgroundConfig.fromJson(const {'style': 'matrix', 'strength': 0.5});
      expect(old.current, BackgroundStyle.matrix);
      expect(old.dim, 0);
      expect(old.parallax, isFalse);
      expect(BackgroundStyle.parse('gone'), BackgroundStyle.cover);
    });

    test('presets are all there, an unknown one falls back', () {
      expect(gradientPresets.length, greaterThanOrEqualTo(6));
      expect(GradientPreset.parse('nope'), gradientPresets.first);
      for (final g in gradientPresets) {
        expect(g.colors.length, greaterThanOrEqualTo(2), reason: g.id);
      }
    });

    test('the battery saver caps the frame rate', () {
      expect(const BackgroundConfig(batterySaver: true).effectiveFrameRate, 20);
      expect(const BackgroundConfig(batterySaver: true, frameRate: 60).effectiveFrameRate, 20);
      expect(const BackgroundConfig(frameRate: 60).effectiveFrameRate, 60);
      expect(const BackgroundConfig().effectiveFrameRate, 0);
    });
  });

  group('every style paints', () {
    for (final style in BackgroundStyle.values) {
      if (style == BackgroundStyle.cover) continue;
      test(style.name, () async {
        final params = BackgroundConfig.defaultsFor(style);
        final e = BackgroundEffect.create(style, params, Colors.white, Colors.amber, config: const BackgroundConfig());
        await e.prepare();
        e.resize(const Size(400, 300));
        for (var i = 0; i < 5; i++) {
          e.step(1 / 60);
        }
        e.bass = 0.8;
        e.pointer = const Offset(100, 100);
        e.step(1 / 60);
        final rec = ui.PictureRecorder();
        e.paint(Canvas(rec));
        rec.endRecording().dispose();
        e.dispose();
      });
    }

    test('the same motion at any frame rate (starfield)', () {
      double run(int fps) {
        final e = BackgroundEffect.create(BackgroundStyle.starfield, const BgParams(), Colors.white, Colors.white, config: const BackgroundConfig());
        e.resize(const Size(400, 300));
        for (var i = 0; i < fps; i++) {
          e.step(1 / fps);
        }
        return e.time;
      }

      expect(run(30), closeTo(run(120), 1e-6));
    });

    test('low detail draws fewer', () {
      final a = BackgroundEffect.create(BackgroundStyle.snow, const BgParams(), Colors.white, Colors.white, config: const BackgroundConfig());
      final b = BackgroundEffect.create(BackgroundStyle.snow, const BgParams(), Colors.white, Colors.white, config: const BackgroundConfig(batterySaver: true));
      expect(b.lowDetail, isTrue);
      expect(a.lowDetail, isFalse);
    });
  });

  group('files', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('prism_bg_'));
    tearDown(() => dir.delete(recursive: true));

    test('video frames command', () {
      final a = videoFrameArgs('in.mp4', 'out');
      expect(a, containsAllInOrder(['-i', 'in.mp4', '-an', '-t', '30']));
      expect(a, contains('fps=12,scale=720:-2'));
      expect(a.last, p.join('out', '%05d.jpg'));
    });

    test('a theme file carries a picture inside, no path', () async {
      final img = File(p.join(dir.path, 'pic.png'))..writeAsBytesSync(Uint8List.fromList([1, 2, 3]));
      final files = BackgroundFiles(dir, null);
      final copy = await files.addImage(img.path);
      final json = await files.toThemeJson(BackgroundConfig(style: 'image', imagePath: copy));
      expect(jsonEncode(json), isNot(contains(dir.path.replaceAll(r'\', r'\\'))));
      expect(json['imageData'], isNotNull);
      final other = BackgroundFiles(Directory(p.join(dir.path, 'other'))..createSync(), null);
      final back = (await other.fromThemeJson(json))!;
      expect(back.current, BackgroundStyle.image);
      expect(File(back.imagePath).readAsBytesSync(), [1, 2, 3]);
      expect(p.isWithin(p.join(dir.path, 'other'), back.imagePath), isTrue);
    });

    test('a video can not travel in a theme: it becomes the cover', () async {
      final json = await BackgroundFiles(dir, null).toThemeJson(const BackgroundConfig(style: 'video', videoDir: 'x'));
      expect(json['style'], 'cover');
      expect(json['videoDir'], '');
    });

    test('a theme with a broken background still gives no crash', () async {
      expect(await BackgroundFiles(dir, null).fromThemeJson(const {'frameRate': 'no'}), isNull);
      expect(await BackgroundFiles(dir, null).fromThemeJson(const {'imageData': '!!!'}), isNull);
    });
  });

  test('a theme file with a background survives export and import', () {
    final theme = const ThemeConfig().copyWith(name: 'T', background: {'style': 'aurora', 'dim': 0.2});
    final back = ThemeConfig.fromShareableJson(theme.toShareableJson());
    expect(back.background?['style'], 'aurora');
  });

  test('themes from before still import, without a background', () {
    final back = ThemeConfig.fromShareableJson(jsonEncode({'format': 'prism-theme', 'version': 1, 'theme': {'name': 'Old'}}));
    expect(back.name, 'Old');
    expect(back.background, isNull);
  });
}

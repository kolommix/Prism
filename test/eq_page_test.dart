import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/theme/theme_builder.dart';
import 'package:prism/core/theme/theme_config.dart';
import 'package:prism/features/audio_fx/application/eq_controller.dart';
import 'package:prism/features/audio_fx/domain/eq_math.dart';
import 'package:prism/features/audio_fx/domain/eq_settings.dart';
import 'package:prism/features/audio_fx/presentation/equalizer_page.dart';
import 'package:prism/features/player/application/player_providers.dart';
import 'package:prism/features/settings/application/settings_controller.dart';
import 'package:prism/features/settings/domain/app_settings.dart';
import 'package:prism/l10n/l10n.dart';

void main() {
  group('simple tone controls', () {
    test('a flat EQ reads 0 / 0 / 0', () {
      final t = eqToneLevels(List.filled(10, 0));
      for (final v in t.values) {
        expect(v, closeTo(0, 1e-9));
      }
    });

    test('moving Bass lifts the low bands, leaves the highs, and reads back', () {
      final g = eqWithTone(List.filled(10, 0), EqTone.bass, 6);
      expect(g[0], closeTo(6, 0.01));
      expect(g[9], 0);
      expect(eqToneLevels(g)[EqTone.bass], closeTo(6, 0.01));
      expect(eqToneLevels(g)[EqTone.treble], closeTo(0, 0.01));
    });

    test('a shape made in the detailed view stays when a tone moves', () {
      final shaped = <double>[0, 0, 0, 0, 0, 3, 0, 0, 0, 0];
      final g = eqWithTone(shaped, EqTone.treble, eqToneLevels(shaped)[EqTone.treble]! + 2);
      expect(g[5] - shaped[5], closeTo(0.2, 0.01), reason: 'only the small treble weight at 1 kHz');
      expect(g[9], closeTo(2, 0.01));
    });

    test('auto volume keeps the loudest point at 0 dB', () {
      const eq = EqSettings(enabled: true, gainsDb: [6, 6, 0, 0, 0, 0, 0, 0, 0, 0]);
      final pre = eqAutoPreampDb(eq);
      expect(pre, lessThan(-5));
      expect(eqPeakBoostDb(eq) + pre, lessThanOrEqualTo(0.01));
      expect(eqAutoPreampDb(const EqSettings(enabled: true)), 0);
    });
  });

  for (final detailed in [false, true]) {
    for (final ru in [false, true]) {
      testWidgets('page fits at phone width (${ru ? 'Russian' : 'English'}, ${detailed ? 'detailed' : 'simple'})', (tester) async {
        if (ru) {
          setAppLocale(const Locale('ru'));
          addTearDown(() => setAppLocale(const Locale('en')));
        }
        tester.view.physicalSize = const Size(360, 1800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(ProviderScope(
          overrides: [
            initialSettingsProvider.overrideWithValue(AppSettings(eqDetailed: detailed)),
            currentTrackProvider.overrideWithValue(null),
            engineStateProvider.overrideWith((ref) => const Stream.empty()),
            tuningProvider.overrideWith((ref) => const Stream.empty()),
            initialEqProvider.overrideWithValue(const EqState(
              settings: EqSettings(enabled: true, gainsDb: [9, 8, 4, 0, -2, 0, 2, 4, 6, 9], presetName: 'Custom'),
              customPresets: [EqPreset(name: 'Mine', gainsDb: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1])],
            )),
          ],
          child: MaterialApp(
            theme: buildPrismTheme(prismTheme, platformBrightness: Brightness.dark, reduceMotion: false),
            home: const EqualizerPage(),
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(l10n.eqFixVolume), findsOneWidget, reason: 'this curve goes over 0 dB');
        if (detailed) {
          expect(find.text('16k'), findsWidgets);
        } else {
          expect(find.text(l10n.eqToneMids), findsWidgets);
        }
        expect(find.text('Mine'), findsOneWidget);
      });
    }
  }
}

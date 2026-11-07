import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/theme/theme_builder.dart';
import 'package:prism/core/theme/theme_config.dart';
import 'package:prism/features/player/domain/seek_bar_style.dart';
import 'package:prism/features/player/presentation/widgets/waveform_seek_bar.dart';
import 'package:prism/features/settings/domain/app_settings.dart';

void main() {
  test('settings saved before these options load with the old look', () {
    final old = AppSettings.fromJson(const {'seekBarStyle': 'led'});
    expect(old.seekBarLook, const SeekBarLook());
    expect(old.seekBarLook.isDefault, isTrue);
  });

  test('options survive saving', () {
    const s = AppSettings(seekBarColor: 0xFFFF0000, seekBarSize: 1.4, seekBarDim: 0.3, seekBarHead: false, seekBarTimes: false);
    final back = AppSettings.fromJson(s.toJson());
    expect(back.seekBarLook, s.seekBarLook);
    expect(back.seekBarLook.isDefault, isFalse);
  });

  testWidgets('every style paints at the far ends of every option', (tester) async {
    const looks = [
      SeekBarLook(),
      SeekBarLook(color: 0xFF00FF00, size: 1.6, density: 2, thickness: 2, dim: 0.6, react: 2, head: false, times: false),
      SeekBarLook(size: 0.6, density: 0.5, thickness: 0.5, dim: 0.05, react: 0),
    ];
    for (final look in looks) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildPrismTheme(const ThemeConfig(), platformBrightness: Brightness.dark, reduceMotion: true),
            home: Scaffold(
              body: Column(
                children: [
                  for (final s in SeekBarStyle.values)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: SeekBarStylePreview(style: s, look: look, live: true),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull, reason: '$look');
    }
    await tester.pumpWidget(const SizedBox());
  });
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:prism/features/settings/application/settings_controller.dart';
import 'package:prism/features/settings/data/settings_store.dart';
import 'package:prism/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/main.dart' as app;

/// Frame-timing benchmark of the real app (real library, no audio played).
///
/// flutter drive --profile -d windows --driver=test_driver/perf_driver.dart --target=integration_test/perf_test.dart
///
/// Scenarios: idle (animated background + glass), scrolling the songs list,
/// switching tabs, opening the full player. Results: build/perf/*.json.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Future<void> wait(WidgetTester tester, int ms) async {
    final end = DateTime.now().add(Duration(milliseconds: ms));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('frame timings', (tester) async {
    app.main();
    await wait(tester, 6000); // startup + library load

    await binding.watchPerformance(() => wait(tester, 4000), reportKey: 'idle');

    final list = find.byType(Scrollable).first;
    await binding.watchPerformance(() async {
      for (var i = 0; i < 4; i++) {
        await tester.fling(list, const Offset(0, -600), 2500);
        await wait(tester, 700);
        await tester.fling(list, const Offset(0, 600), 2500);
        await wait(tester, 700);
      }
    }, reportKey: 'scroll_fling');

    await binding.watchPerformance(() async {
      // Mouse-wheel style scrolling (what a Windows user does).
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(tester.getCenter(list)));
      for (var i = 0; i < 30; i++) {
        await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
        await wait(tester, 50);
      }
      for (var i = 0; i < 30; i++) {
        await tester.sendEventToBinding(pointer.scroll(const Offset(0, -120)));
        await wait(tester, 50);
      }
      await wait(tester, 500);
    }, reportKey: 'scroll_wheel');

    await binding.watchPerformance(() async {
      // In the app's language, whichever that is on this machine.
      for (final tab in [l10n.search, l10n.playlists2, l10n.settings, l10n.xLibrary, l10n.search, l10n.xLibrary]) {
        await tester.tap(find.text(tab).first);
        await wait(tester, 600);
      }
    }, reportKey: 'tab_switch');

    // The animated backgrounds, with the mouse moving over them.
    final live = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final before = live.read(settingsProvider).background;
    // This runs on the real settings: put them back even if something fails.
    final store = SettingsStore(SharedPreferencesAsync());
    final settingsBefore = live.read(settingsProvider);
    addTearDown(() => store.save(settingsBefore));
    for (final style in ['matrix', 'constellation', 'ripple', 'mesh', 'aurora', 'blobs', 'starfield', 'rain', 'snow', 'asciiSmoke', 'asciiDonut', 'ridges', 'galaxy', 'lyrics']) {
      live.read(settingsProvider.notifier).update((s) => s.copyWith(background: s.background.copyWith(style: style)));
      await wait(tester, 800);
      await binding.watchPerformance(() async {
        final mouse = TestPointer(2, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(mouse.hover(const Offset(300, 300)));
        for (var i = 0; i < 40; i++) {
          await tester.sendEventToBinding(mouse.hover(Offset(300.0 + i * 12, 300.0 + i * 4)));
          await wait(tester, 100);
        }
      }, reportKey: 'live_$style');
    }
    live.read(settingsProvider.notifier).update((s) => s.copyWith(background: before));
    await wait(tester, 300);

    // Whole-app re-tint, like a track change with album-art colors.
    final container = ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));
    final settings = container.read(settingsProvider.notifier);
    final original = container.read(settingsProvider).theme;
    await binding.watchPerformance(() async {
      settings.setTheme(original.copyWith(primaryColor: 0xFFFF6E40, dynamicColor: false));
      await wait(tester, 1200);
      settings.setTheme(original.copyWith(primaryColor: 0xFF00BFA5, dynamicColor: false));
      await wait(tester, 1200);
    }, reportKey: 'theme_change');
    settings.setTheme(original); // leave the user's theme as it was
    await wait(tester, 1000);
  });
}

// ignore_for_file: invalid_use_of_protected_member, avoid_print
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:prism/core/motion/smooth_scroll.dart';
import 'package:prism/core/router/app_router.dart';
import 'package:prism/features/library/application/library_providers.dart';
import 'package:prism/features/settings/application/settings_controller.dart';
import 'package:prism/features/settings/data/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:prism/features/settings/presentation/settings_page.dart';
import 'package:prism/features/together/presentation/together_sheet.dart';
import 'package:prism/main.dart' as app;
import 'package:window_manager/window_manager.dart';

/// Pictures of the real app with the real library, at several window sizes,
/// without touching the mouse or the screen. For checking layout:
///
/// flutter test integration_test/ui_shots_test.dart -d windows --dart-define=SHOTS=some/folder
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;
  const out = String.fromEnvironment('SHOTS', defaultValue: 'build/shots');
  // --dart-define=LOCALE=ru takes the pictures in that language.
  const locale = String.fromEnvironment('LOCALE');

  testWidgets('shots', (tester) async {
    Future<void> wait(int ms) async {
      final end = DateTime.now().add(Duration(milliseconds: ms));
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }

    Future<void> shot(String name) async {
      await wait(900);
      final view = tester.binding.renderViews.first;
      final layer = view.layer! as OffsetLayer;
      final image = await tester.runAsync(() async {
        final img = await layer.toImage(Offset.zero & view.size, pixelRatio: 1);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        await File('$out/$name.png').writeAsBytes(png!.buffer.asUint8List());
        return img;
      });
      print('shot $name ${image?.width}x${image?.height}');
    }

    await Directory(out).create(recursive: true);
    app.main();
    await wait(6000);

    BuildContext ctx() => tester.element(find.byType(Scaffold).first);
    ProviderContainer c() => ProviderScope.containerOf(ctx());
    final router = GoRouter.of(ctx());
    void go(String route) => router.go(route);

    Future<void> size(double w, double h) async {
      await tester.runAsync(() => windowManager.setSize(Size(w, h)));
      await wait(500);
    }

    final before = c().read(settingsProvider).background;
    final beforeLocale = c().read(settingsProvider).localeCode;
    // This runs on the real settings: put them back even if a shot fails.
    final store = SettingsStore(SharedPreferencesAsync());
    final settingsBefore = c().read(settingsProvider);
    addTearDown(() => store.save(settingsBefore));
    if (locale.isNotEmpty) {
      c().read(settingsProvider.notifier).update((s) => s.copyWith(localeCode: locale));
      await wait(500);
    }

    Future<void> pages(String tag) async {
      go(Routes.library);
      await shot('$tag-library');
      go(Routes.stats);
      await shot('$tag-stats');
      go(Routes.playlists);
      await shot('$tag-playlists');
      go(Routes.settings);
      await wait(200);
      for (final s in [SettingsSection.library, SettingsSection.appearance, SettingsSection.windows, SettingsSection.together, SettingsSection.privacy]) {
        c().read(selectedSettingsSectionProvider.notifier).select(s);
        await shot('$tag-settings-${s.name}');
      }
      go(Routes.library);
      await wait(200);
      if (c().read(settingsProvider).theme.name.isNotEmpty) {
        unawaited(showTogetherSheet(ctx()));
        await shot('$tag-together');
        Navigator.of(ctx(), rootNavigator: true).pop();
        await wait(300);
      }
    }

    await size(1400, 860);
    await pages('a');
    router.push(Routes.player);
    await shot('a-player');
    router.pop();
    await wait(700);
    router.push(Routes.immersive);
    await shot('a-immersive');
    router.pop();
    await wait(700);
    go(Routes.background);
    await shot('a-background-page');
    // Editor on the first song, and the other settings pages.
    final firstSong = c().read(tracksProvider).value?.firstOrNull;
    if (firstSong != null) {
      router.push(Routes.editor(firstSong.id));
      await wait(4000);
      await shot('a-editor');
      await size(720, 800);
      await shot('d-editor');
      await size(1400, 860);
      router.pop();
      await wait(600);
    }
    for (final (name, route) in [
      ('theme', Routes.themeEditor),
      ('eq', Routes.equalizer),
      ('online', Routes.onlineServices),
      ('import', Routes.importPlaylists),
      ('import-review', Routes.importReview),
      ('duplicates', Routes.duplicates),
      ('metadata', firstSong == null ? Routes.duplicates : Routes.metadata([firstSong.id])),
    ]) {
      go(route);
      await shot('a-page-$name');
    }

    // The seek bar at the far end of its options: it must still fit everywhere.
    final lookBefore = c().read(settingsProvider);
    c().read(settingsProvider.notifier).update(
          (x) => x.copyWith(seekBarColor: 0xFF40C4FF, seekBarSize: 1.6, seekBarDensity: 2, seekBarThickness: 2, seekBarDim: 0.5, seekBarReact: 2),
        );
    go(Routes.library);
    await shot('look-big');
    router.push(Routes.immersive);
    await shot('look-big-immersive');
    router.pop();
    await wait(700);
    c().read(settingsProvider.notifier).update((x) => x.copyWith(seekBarSize: 0.6, seekBarDensity: 0.5, seekBarThickness: 0.5, seekBarHead: false, seekBarTimes: false));
    await shot('look-small');
    c().read(settingsProvider.notifier).update((x) => x.copyWith(seekBarSize: 1, seekBarDensity: 1, seekBarThickness: 1, seekBarHead: true));
    go(Routes.settings);
    await wait(200);
    c().read(selectedSettingsSectionProvider.notifier).select(SettingsSection.appearance);
    await wait(500);
    final list = tester.state<ScrollableState>(
      find.descendant(of: find.byType(SmoothListView).last, matching: find.byType(Scrollable)).first,
    );
    for (var i = 0; i < 3; i++) {
      list.position.jumpTo(list.position.maxScrollExtent);
      await wait(200);
    }
    await shot('look-settings');
    list.position.jumpTo(list.position.pixels - 620);
    await shot('look-settings-top');
    c().read(settingsProvider.notifier).update((_) => lookBefore);
    await wait(200);

    // The animated backgrounds behind the real pages.
    for (final style in ['matrix', 'constellation', 'ripple', 'mesh', 'aurora', 'blobs', 'gradient', 'starfield', 'rain', 'snow', 'asciiSmoke', 'asciiDonut', 'ridges', 'galaxy', 'lyrics']) {
      c().read(settingsProvider.notifier).update((s) => s.copyWith(background: s.background.copyWith(style: style)));
      go(Routes.library);
      await wait(1800);
      await shot('bg-$style');
    }
    c().read(settingsProvider.notifier).update((s) => s.copyWith(background: before));

    await size(1020, 720);
    await pages('b');
    await size(720, 800);
    go(Routes.library);
    await shot('d-library');
    go(Routes.stats);
    await shot('d-stats');
    go(Routes.settings);
    await shot('d-settings');
    go(Routes.library);
    await wait(300);
    await size(1800, 1000);
    go(Routes.library);
    await shot('c-library');
    go(Routes.stats);
    await shot('c-stats');
    go(Routes.library);
    await size(1400, 860);
    await wait(300);
    c().read(settingsProvider.notifier).update((s) => s.copyWith(localeCode: beforeLocale));
    await wait(300);
  });
}

void unawaited(Future<void> f) {}

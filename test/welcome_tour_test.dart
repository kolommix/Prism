import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/providers.dart';
import 'package:prism/core/theme/theme_builder.dart';
import 'package:prism/core/theme/theme_config.dart';
import 'package:prism/features/onboarding/presentation/welcome_tour.dart';
import 'package:prism/l10n/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late SharedPreferencesAsync prefs;
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    prefs = SharedPreferencesAsync();
  });

  Future<void> start(WidgetTester tester, {Size size = const Size(1000, 800)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: buildPrismTheme(const ThemeConfig(), platformBrightness: Brightness.dark, reduceMotion: false),
        home: Consumer(
          builder: (context, ref, _) => Scaffold(
            body: TextButton(onPressed: () => WelcomeTour.maybeShow(context, ref), child: const Text('go')),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  testWidgets('first start: the tour walks through its pages and closes', (tester) async {
    await start(tester);
    expect(find.text(l10n.tourWelcomeTitle), findsOneWidget);
    for (final title in [l10n.tourMusicTitle, l10n.tourPlayerTitle, l10n.tourPlaylistsTitle, l10n.tourYoursTitle]) {
      await tester.tap(find.text(l10n.tourNext));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }
    expect(find.text(l10n.tourMusicTitle), findsNothing);
    await tester.tap(find.text(l10n.tourDone));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tourYoursTitle), findsNothing);
    expect(await prefs.getBool(WelcomeTour.seenKey), isTrue);

    // Only once.
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tourWelcomeTitle), findsNothing);
  });

  testWidgets('skip closes it; people who used Prism before never see it', (tester) async {
    await start(tester);
    await tester.tap(find.text(l10n.tourSkip));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tourWelcomeTitle), findsNothing);

    await WelcomeTour.reset(prefs);
    await prefs.setString('playback.last', '{}');
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.tourWelcomeTitle), findsNothing);
  });

  testWidgets('Russian on a narrow phone: every page fits', (tester) async {
    setAppLocale(const Locale('ru'));
    addTearDown(() => setAppLocale(const Locale('en')));
    await start(tester, size: const Size(340, 640));
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text(l10n.tourNext));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.text(l10n.tourDone), findsOneWidget);
  });
}

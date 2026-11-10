import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/theme/theme_builder.dart';
import 'package:prism/core/theme/theme_config.dart';
import 'package:prism/features/settings/application/settings_controller.dart';
import 'package:prism/features/settings/domain/app_settings.dart';
import 'package:prism/features/together/application/together_controller.dart';
import 'package:prism/features/together/domain/together_protocol.dart';
import 'package:prism/features/together/presentation/together_sheet.dart';
import 'package:prism/features/update/update_check.dart';
import 'package:prism/features/update/update_installer.dart';
import 'package:prism/l10n/l10n.dart';

import 'extras_widgets_test.dart' show nowPlaying, song;

class _Fixed extends TogetherController {
  _Fixed(this._s);
  final TogetherState _s;
  @override
  TogetherState build() => _s;
}

void main() {
  Future<void> open(WidgetTester tester, TogetherState s, {Size size = const Size(340, 700)}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        togetherProvider.overrideWith(() => _Fixed(s)),
        initialSettingsProvider.overrideWithValue(const AppSettings(togetherName: 'Ivan')),
        ...nowPlaying(song).cast(),
      ],
      child: MaterialApp(
        theme: buildPrismTheme(prismTheme, platformBrightness: Brightness.dark, reduceMotion: false),
        home: const Scaffold(body: SingleChildScrollView(child: TogetherSheet())),
      ),
    ));
    // A spinner turns forever ("finding the song"): settle by time.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  const people = [
    SessionPerson('Max', PersonStatus.listening),
    SessionPerson('Александра', PersonStatus.missing),
    SessionPerson('Lena', PersonStatus.finding),
  ];

  for (final ru in [false, true]) {
    final lang = ru ? 'Russian' : 'English';

    testWidgets('$lang, phone width: the host sees code, invite, people and the control switch', (tester) async {
      if (ru) {
        setAppLocale(const Locale('ru'));
        addTearDown(() => setAppLocale(const Locale('en')));
      }
      await open(tester, const TogetherState(
        role: TogetherRole.host,
        code: 'K7QXA',
        connected: true,
        overInternet: true,
        people: ['Max', 'Александра', 'Lena'],
        who: people,
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('K7QXA'), findsOneWidget);
      expect(find.text(l10n.togetherCopyInvite), findsOneWidget);
      expect(find.text(l10n.togetherFriendsControl), findsOneWidget);
      expect(find.textContaining(l10n.togetherStatusMissing), findsOneWidget);
    });

    testWidgets('$lang, phone width: a guest sees the host, the people and who controls', (tester) async {
      if (ru) {
        setAppLocale(const Locale('ru'));
        addTearDown(() => setAppLocale(const Locale('en')));
      }
      await open(tester, TogetherState(
        role: TogetherRole.guest,
        code: 'K7QXA',
        connected: true,
        hostName: 'Ivan',
        status: l10n.followingTheHost,
        people: const ['Max', 'Александра'],
        who: people.take(2).toList(),
      ));
      expect(tester.takeException(), isNull);
      expect(find.text(l10n.xWith('Ivan')), findsOneWidget);
      expect(find.text(l10n.togetherYouCanControl), findsOneWidget);
    });

    testWidgets('$lang, phone width: the start page has the name, start and join', (tester) async {
      if (ru) {
        setAppLocale(const Locale('ru'));
        addTearDown(() => setAppLocale(const Locale('en')));
      }
      await open(tester, const TogetherState());
      expect(tester.takeException(), isNull);
      expect(find.text(l10n.startASession), findsOneWidget);
      expect(find.text(l10n.togetherJoinTitle), findsOneWidget);
      expect(find.text(l10n.yourNameInASession), findsOneWidget);
    });

    testWidgets('$lang, phone width: the update dialog fits', (tester) async {
      if (ru) {
        setAppLocale(const Locale('ru'));
        addTearDown(() => setAppLocale(const Locale('en')));
      }
      tester.view.physicalSize = const Size(340, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: buildPrismTheme(prismTheme, platformBrightness: Brightness.dark, reduceMotion: false),
        home: const Scaffold(
          body: UpdateDialog(
            windows: true,
            release: ReleaseInfo(
              version: '1.3.0',
              url: 'https://github.com/kolommix/Prism/releases/latest',
              notes: '- One\n- Two',
              assets: [
                ReleaseAsset(
                  name: 'Prism-Setup-1.3.0.exe',
                  url: 'https://github.com/kolommix/Prism/releases/download/v1.3.0/Prism-Setup-1.3.0.exe',
                  size: 1,
                ),
              ],
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text(l10n.updateNow), findsOneWidget);
      expect(find.text(l10n.updateWindowsHint), findsOneWidget);
    });
  }
}

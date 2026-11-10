import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/theme_builder.dart';
import 'features/audio_fx/application/loudness_controller.dart';
import 'features/background/application/background_input.dart';
import 'features/library/application/auto_tagger.dart';
import 'features/stats/application/stats_providers.dart';
import 'features/desktop/application/android_widget_sync.dart';
import 'features/desktop/application/desktop_extras.dart';
import 'features/desktop/presentation/mini_overlay.dart';
import 'features/desktop/presentation/window_caption.dart';
import 'features/player/application/player_providers.dart';
import 'features/player/engine/playback_engine.dart';
import 'features/online/domain/online_error.dart';
import 'features/player/platform/windows_desktop_integration.dart';
import 'features/settings/application/settings_controller.dart';
import 'l10n/l10n.dart';

import 'features/online/application/import_flow.dart';
import 'features/online/application/import_repair.dart';
import 'features/online/application/online_providers.dart';
import 'features/online/domain/import_intake.dart';
import 'features/playlists/application/share_inbox.dart';
import 'core/providers.dart';
import 'core/app_version.dart';
import 'core/motion/busy_pc.dart';
import 'features/library/application/library_providers.dart';
import 'features/together/presentation/together_sheet.dart';
import 'features/together/application/together_controller.dart';
import 'features/update/update_check.dart';
import 'features/update/update_installer.dart';
import 'features/onboarding/presentation/welcome_tour.dart';
/// Windows integration instance (null on Android / in tests).
final windowsIntegrationProvider = Provider<WindowsDesktopIntegration?>((ref) => null);

/// Root widget: builds the theme from settings + current cover colors and
/// hosts the router. Theme changes animate (MaterialApp lerps ThemeData).
class PrismApp extends ConsumerStatefulWidget {
  const PrismApp({super.key, this.startArgs = const []});

  /// Command line: may hold a shared playlist.
  final List<String> startArgs;

  @override
  ConsumerState<PrismApp> createState() => _PrismAppState();
}

class _PrismAppState extends ConsumerState<PrismApp> with WidgetsBindingObserver {
  late final GoRouter _router = buildRouter();
  late Brightness _platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
  late bool _osReduceMotion = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;

  final _messenger = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<EngineEvent>? _playerEvents;
  String? _lastError;
  DateTime _lastErrorAt = DateTime(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DeepLinks(_onImportRequest, onMusic: _onMusicDropped).start(widget.startArgs);
      _showTourOnce();
      _quietUpdateCheck();
      unawaited(_sayUpdated());
      // Imports that were still going when the app closed.
      if (ref.read(onlineHubProvider).flags.importDownload) unawaited(ref.read(importFlowProvider).resumeAll());
      // Songs older versions saved broken (silent or cut off) are found and
      // saved again; a little later, so the start stays quick.
      Timer(const Duration(seconds: 20), () {
        if (mounted) unawaited(ref.read(importRepairProvider).run());
      });
    });
    // A streamed song that can't play (offline, removed video, service off)
    // is skipped by the player; say why, once, instead of failing silently.
    _playerEvents = ref.read(playerControllerProvider).events.listen((e) {
      if (e != EngineEvent.failed) return;
      final err = ref.read(playerControllerProvider).lastError;
      if (err is! OnlineException) return;
      final now = DateTime.now();
      if (err.message == _lastError && now.difference(_lastErrorAt) < const Duration(seconds: 8)) return;
      _lastError = err.message;
      _lastErrorAt = now;
      _messenger.currentState?.showSnackBar(SnackBar(content: Text(err.message), duration: const Duration(seconds: 5)));
    });
  }

  /// First start: the welcome tour, over the app (the router's navigator).
  Future<void> _showTourOnce() async {
    final nav = _router.routerDelegate.navigatorKey.currentContext;
    if (nav == null) return;
    await WelcomeTour.maybeShow(nav, ref);
  }

  Future<void> _quietUpdateCheck() async {
    if (!ref.read(settingsProvider).autoCheckUpdates) return;
    final latest = await quietUpdateCheck(ref.read(prefsProvider));
    if (latest == null || !mounted) return;
    _messenger.currentState?.showSnackBar(SnackBar(
      content: Text(l10n.updateAvailable(latest.version)),
      duration: const Duration(seconds: 10),
      action: SnackBarAction(
        label: l10n.updateNow,
        onPressed: () {
          final c = _router.routerDelegate.navigatorKey.currentContext;
          if (c != null) unawaited(showUpdateDialog(c, latest));
        },
      ),
    ));
  }

  /// After an update: says so once, so friends know it worked.
  Future<void> _sayUpdated() async {
    const key = 'update.lastRunVersion';
    final prefs = ref.read(prefsProvider);
    final last = await prefs.getString(key);
    await prefs.setString(key, appVersion);
    if (last == null || !isNewerVersion(appVersion, last) || !mounted) return;
    _messenger.currentState?.showSnackBar(SnackBar(content: Text(l10n.updatedTo(appVersion))));
  }

  /// Songs or folders dragged onto the window: into the library at once, then
  /// one message with how many and a Play button.
  Future<void> _onMusicDropped(List<String> files, List<String> folders) async {
    final scan = ref.read(scanControllerProvider.notifier);
    _messenger.currentState?.showSnackBar(SnackBar(content: Text(l10n.dropAdding), duration: const Duration(seconds: 2)));
    try {
      for (final folder in folders) {
        await scan.addFolder(folder);
      }
      await scan.addFiles(files);
    } on Object catch (e) {
      _messenger.currentState?.showSnackBar(SnackBar(content: Text(l10n.error(e))));
      return;
    }
    if (!mounted) return;
    final wanted = files.toSet();
    final prefixes = [for (final d in folders) d.endsWith(Platform.pathSeparator) ? d : '$d${Platform.pathSeparator}'];
    final library = await ref.read(libraryRepositoryProvider).watchTracks().first;
    final songs = [
      for (final t in library)
        if (wanted.contains(t.uri) || prefixes.any(t.uri.startsWith)) t,
    ]..sort((a, b) => a.uri.compareTo(b.uri));
    if (!mounted) return;
    _messenger.currentState?.hideCurrentSnackBar();
    _messenger.currentState?.showSnackBar(SnackBar(
      content: Text(songs.isEmpty ? l10n.dropNothingNew : l10n.dropAdded(songs.length)),
      duration: const Duration(seconds: 6),
      action: songs.isEmpty
          ? null
          : SnackBarAction(label: l10n.play, onPressed: () => ref.read(playerControllerProvider).playTracks(songs)),
    ));
  }

  /// A link or file from outside (share sheet, drag and drop, `liner://`): to the
  /// import screen, which takes it from the inbox and shows any problem.
  void _onImportRequest(ImportRequest request) {
    if (!mounted) return;
    ref.read(importInboxProvider.notifier).put(request);
    _router.go(Routes.importPlaylists);
  }

  @override
  void dispose() {
    _playerEvents?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _router.dispose();
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_offerInviteFromClipboard());
  }

  /// Codes already asked about (or this session's own), so nothing nags.
  final _askedInvites = <String>{};

  /// Prism comes to the front with a friend's invite in the clipboard (the
  /// "Copy invite" message): one click joins. Windows only: on Android every
  /// clipboard read shows a system notice.
  Future<void> _offerInviteFromClipboard() async {
    if (!Platform.isWindows) return;
    final together = ref.read(togetherProvider);
    if (together.role != TogetherRole.none || together.busy) return;
    final String? text;
    try {
      text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    } on Object {
      return;
    }
    final code = findInviteCode(text);
    if (code == null || !_askedInvites.add(code) || !mounted) return;
    _messenger.currentState?.showSnackBar(SnackBar(
      content: Text(l10n.togetherJoinFromClipboard(code)),
      duration: const Duration(seconds: 12),
      action: SnackBarAction(
        label: l10n.join,
        onPressed: () async {
          await ref.read(togetherProvider.notifier).join(code);
          final c = _router.routerDelegate.navigatorKey.currentContext;
          if (c != null && c.mounted) unawaited(showTogetherSheet(c));
        },
      ),
    ));
  }

  @override
  void didChangePlatformBrightness() =>
      setState(() => _platformBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness);

  @override
  void didChangeAccessibilityFeatures() => setState(
        () => _osReduceMotion = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations,
      );

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final seed = ref.watch(currentPaletteProvider).value?.seed;
    ref.listen(settingsProvider.select((s) => s.closeToTray), (_, v) {
      ref.read(windowsIntegrationProvider)?.closeToTray = v;
    });
    ref.listen(settingsProvider.select((s) => s.highPriority), (_, v) => ProcessPriority.apply(high: v));
    // Listen together tells things once ("Max changed the music").
    ref.listen(togetherProvider.select((s) => (s.noticeId, s.notice)), (before, now) {
      if (now.$2 == null || before?.$1 == now.$1) return;
      _messenger.currentState?.showSnackBar(SnackBar(content: Text(now.$2!), duration: const Duration(seconds: 3)));
    });
    // The own session's code is never offered back.
    ref.listen(togetherProvider.select((s) => s.code), (_, code) {
      if (code != null) _askedInvites.add(code);
    });
    // A busy PC: colors snap instead of gliding (see BusyMeter).
    final busy = ref.watch(busyPcProvider);
    // Keeps normalisation mode + automatic loudness analysis running.
    ref.listen(loudnessControllerProvider, (_, _) {});
    // Finds missing covers and artists in the background (if on).
    ref.listen(autoTaggerProvider, (_, _) {});
    // Records listens for smart playlists and stats (never changes value).
    ref.watch(playRecorderProvider);
    // Android home-screen widget + Discord presence (no-ops elsewhere).
    ref.watch(androidWidgetSyncProvider);
    ref.watch(discordPresenceProvider);
    final mini = ref.watch(miniModeProvider);

    // The language is a global (see l10n.dart): switching it rebuilds everything.
    final locale = resolveAppLocale(settings.localeCode);
    if (setAppLocale(locale)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => rebuildAllWidgets());
    }

    final reduceMotion = settings.reduceMotion || _osReduceMotion;
    final theme = buildPrismTheme(
      settings.theme,
      platformBrightness: _platformBrightness,
      reduceMotion: reduceMotion,
      dynamicSeed: seed,
      panelOpacity: settings.background.isLive ? settings.background.panelOpacity.clamp(0.15, 1.0) : null,
      frostedPanels: settings.background.isLive && settings.background.frosted && !settings.background.batterySaver,
    );
    final input = ref.read(backgroundInputProvider);

    return MaterialApp.router(
      title: 'Prism',
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      scaffoldMessengerKey: _messenger,
      debugShowCheckedModeBanner: false,
      theme: theme,
      // Every frame of a theme animation rebuilds the whole app (~4 ms each,
      // measured), so keep it short; the background's own 1.2 s colour glide
      // carries the smooth feel on track changes.
      themeAnimationDuration: reduceMotion || busy
          ? Duration.zero
          : Duration(milliseconds: (450 * settings.theme.animationSpeed).round()),
      themeAnimationCurve: Curves.easeOutCubic,
      routerConfig: _router,
      // Windows mini mode: the full app stays mounted (offstage) under the overlay.
      builder: (context, child) => mini
          ? Stack(children: [Offstage(child: child), const MiniOverlay()])
          : MouseRegion(
              opaque: false,
              onExit: (_) => input.pointer = null,
              // Sees every pointer in the app without taking any of them.
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerHover: (e) => input.pointer = e.position,
                onPointerMove: (e) => input.pointer = e.position,
                onPointerDown: (e) {
                  input.pointer = e.position;
                  input.burst(e.position, strength: 0.5);
                },
                child: BackdropGroup(
                  child: WindowCaption(
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [child ?? const SizedBox.shrink(), const DropOverlay()],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/motion/frame_probe.dart';
import 'core/db/app_database.dart';
import 'core/providers.dart';
import 'core/sources/track_source.dart';
import 'core/ffmpeg/ffmpeg_runner.dart';
import 'features/audio_fx/application/eq_controller.dart';
import 'features/audio_fx/application/loudness_controller.dart';
import 'features/editor/data/edit_repository.dart';
import 'features/player/application/playback_plan_service.dart';
import 'features/audio_fx/platform/android_audio_effects.dart';
import 'features/audio_fx/platform/audio_effects_backend.dart';
import 'features/audio_fx/platform/mpv_audio_effects.dart';
import 'features/library/data/library_repository.dart';
import 'features/library/data/local_track_source.dart';
import 'features/player/application/playback_state_store.dart';
import 'features/player/application/player_controller.dart';
import 'features/player/application/player_providers.dart';
import 'features/player/engine/just_audio_deck_engine.dart';
import 'features/player/platform/prism_audio_handler.dart';
import 'features/player/platform/windows_desktop_integration.dart';
import 'features/settings/application/settings_controller.dart';
import 'features/online/application/online_hub.dart';
import 'features/online/application/online_providers.dart';
import 'features/online/data/oauth.dart';
import 'features/online/data/online_config.dart';
import 'features/online/data/online_http.dart';
import 'features/online/data/stream_cache.dart';
import 'features/settings/data/settings_store.dart';
import 'l10n/l10n.dart';

import 'features/background/data/background_files.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'core/app_version.dart';
/// Command line of this run; `liner://` links and `.liner` files arrive here.
List<String> startArgs = const [];

/// Startup order matters:
/// 1. platform audio backends (media_kit on Windows),
/// 2. database + settings (so the first frame has the right theme),
/// 3. player + restore last session,
/// 4. OS integrations (Android media service / Windows SMTC + tray),
/// 5. runApp with everything injected into Riverpod.
Future<void> main([List<String> args = const []]) async {
  startArgs = args;
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    // just_audio on Windows is backed by libmpv through media_kit. Prism owns
    // mpv's `af` chain (EQ + rubberband pitch), so media_kit's own pitch mode
    // (which overwrites `af`) is off; gapless needs playlist prefetch.
    JustAudioMediaKit.pitch = false;
    JustAudioMediaKit.prefetchPlaylist = true;
    JustAudioMediaKit.title = 'Prism';
    JustAudioMediaKit.ensureInitialized(windows: true, android: false);
    // Prism resolves streams itself; mpv must not try to spawn youtube-dl.
    unawaited(JustAudioMediaKit.setGlobalProperty('ytdl', 'no'));
    await windowManager.ensureInitialized();
    // The runner shows the window on Flutter's first frame (flutter_window.cpp);
    // showing it here as well would flash an empty window first.
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(title: 'Prism', minimumSize: Size(420, 640), center: true),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => windowManager.focus());
  }

  final db = AppDatabase();
  final supportDir = await getApplicationSupportDirectory();
  final artworkDir = Directory(p.join(supportDir.path, 'artwork'));
  final prefs = SharedPreferencesAsync();
  final settings = await SettingsStore(prefs).load();
  await initAppLocaleData();
  try {
    appVersion = (await PackageInfo.fromPlatform()).version;
  } on Object {
    // Keeps the built-in number.
  }
  setAppLocale(resolveAppLocale(settings.localeCode));

  final eq = await EqStore(prefs).load();

  final libraryRepo = LibraryRepository(db);
  // Online services: each module is isolated; nothing here may stop the app.
  final online = OnlineHub(
    configLoader: OnlineConfigLoader(supportDir),
    prefs: prefs,
    tokens: SecureTokenStore(),
    http: OnlineHttp(),
    launch: (url) => launchUrl(url, mode: LaunchMode.externalApplication),
    cache: StreamCache(Directory(p.join(supportDir.path, 'stream_cache'))),
  );
  try {
    await online.init();
  } on Object catch (e) {
    debugPrint(l10n.onlineServicesUnavailable(e));
  }
  final sources = TrackSourceRegistry([LocalTrackSource(libraryRepo), ...online.trackSources()]);
  final AudioEffectsBackend effects = Platform.isWindows
      ? MpvAudioEffects()
      : (Platform.isAndroid ? AndroidAudioEffects() : NoAudioEffects());
  final ffmpeg = FfmpegRunner.forPlatform();
  final planService = PlaybackPlanService(freshTrack: libraryRepo.trackById, normalization: settings.normalization);
  EditRepository.renderDir = p.join(supportDir.path, 'edit_renders');
  final edits = EditRepository(db);
  planService.liveEditPlan = edits.livePlanFor;
  final player = PlayerController(
    engine: JustAudioDeckEngine(sources: sources, effects: effects, planFor: planService.planFor),
    store: PrefsPlaybackStateStore(prefs),
  );
  await player.setCrossfade(settings.crossfade);
  await effects.setEq(eq.settings);
  await player.setPreampDb(eq.settings.enabled ? eq.settings.preampDb : 0);
  try {
    await player.restore(libraryRepo.tracksByIds);
  } on Object catch (e) {
    debugPrint('Could not restore last session: $e');
  }

  WindowsDesktopIntegration? windows;
  if (Platform.isAndroid) {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await PrismAudioHandler.init(player);
  } else if (Platform.isWindows) {
    windows = WindowsDesktopIntegration(player)..closeToTray = settings.closeToTray;
    await windows.init();
  }

  FrameProbe.startIfAsked();
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        prefsProvider.overrideWithValue(prefs),
        artworkDirProvider.overrideWithValue(artworkDir),
        trackSourcesProvider.overrideWithValue(sources),
        playerControllerProvider.overrideWithValue(player),
        initialSettingsProvider.overrideWithValue(settings),
        windowsIntegrationProvider.overrideWithValue(windows),
        audioEffectsProvider.overrideWithValue(effects),
        initialEqProvider.overrideWithValue(eq),
        ffmpegRunnerProvider.overrideWithValue(ffmpeg),
        backgroundFilesProvider.overrideWithValue(BackgroundFiles(supportDir, ffmpeg)),
        playbackPlanServiceProvider.overrideWithValue(planService),
        editRepositoryProvider.overrideWithValue(edits),
        onlineHubProvider.overrideWithValue(online),
      ],
      child: PrismApp(startArgs: args),
    ),
  );
}

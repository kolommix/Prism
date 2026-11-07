# Prism - status (2026-11-07)

## Latest: privacy + easier import, version 1.2.0 (2026-11-07), not released yet
- **Location report solved**: `permission_handler_windows` created a Windows `Geolocator` and subscribed to it in its constructor, at every launch, in every version so far. Nothing read or sent the result. Prism now links only `permission_handler_android`. Android never had a location permission. Friends keep seeing it until a new release is out.
- Also: computer name no longer used as the default listen-together name, `RECEIVE_BOOT_COMPLETED` removed, Settings → Privacy, `docs/PRIVACY.md`, CI check (`tool/privacy_check.dart`, `.github/workflows/privacy.yml`, never run on GitHub yet).
- **Full screen**: own code in `flutter_window.cpp` (`prism/window`), because window_manager keeps the title bar on a maximized window. `integration_test/fullscreen_test.dart` measures it.
- **Remove from Prism**: track menu, file stays, undo, rescans skip it (schema v8 `removed_tracks`), Settings → Library → Removed songs.
- **Import**: one screen, details in `docs/PROGRESS.md` block 15. `ImportFlow`, `import_intake.dart`, `public_readers.dart`, `import_review_page.dart`, `drop_bridge.cpp`, Android SEND filters (launchMode is now singleTask).
- **Limits**: SoundCloud links need a key or a file, Spotify about 100 songs without a login, Yandex only where it answers. Without YouTube turned on, matching only searches the library; the job and Review pages offer to turn it on, with its terms.
- **NOT verified**: drag and drop by hand, Android share target and immersive mode on a device, re-sync against a real changed playlist, the GitHub workflow.

## Before that: the big feature round, version 1.1.0 (2026-11-07)
Checklist with a status per block: `docs/PROGRESS.md`. Short version:
- **Languages**: everything through ARB, English + Russian, 1050 keys, system language or manual switch, plurals, dates, numbers, tray menu.
- **Editor rebuilt**: waveform pyramid cached on disk, minimap, snap (zero crossing, beats, silence), delete vs ripple delete,
  duplicate, loop, reorder by drag, merge songs, ramps, reverse, per-part EQ + gate + fades + crossfades with curves, quick tools,
  ringtone, export mp3 CBR/VBR, m4a, wav, flac with tags and cover, cancel, overwrite with backup, session saved per track.
- **Lyrics**: `PlayheadEstimator` (never backwards), spring scroll, word timing, per-song offset, bad-file repair.
- **Visualizer**: beats, ribbon, particles, shader glow, sensitivity, low power, Android live FFT.
- **New**: song info fixer, Yandex import, playlist sharing, multi-select reorder + per-playlist sort, story mode + picture export,
  many backgrounds, GitHub release workflow, update check, READMEs, GPL-3.0 license.
- **Real bugs found on the way**: lyric jitter cause; `ensureVisible` did nothing for lines not built yet; FFmpeg's default `agate` ratio
  barely gates; a test broker's socket error made one test flaky (also hardened `mqtt_lite`); a search finishing after its page closed; `ui_shots` and `perf_test` could leave real settings changed when they failed (they now always restore); `1 songs`.
- **Verified**: analyzer clean. 395 unit/widget tests, and all real-audio FFmpeg tests of the editor (every new feature rendered and measured). In Russian, no mouse: 43 pictures of the real app at 4 window sizes, 0 layout errors, shaders work on Windows. Android APK compiles (not run). Perf on this PC, 0 missed frames at 120 fps, raster avg ms: idle 2.29, fling 2.36, wheel 2.34, tabs 2.42, Matrix 2.29, Constellation 2.86, Ripple 2.31, Mesh 2.32, Aurora 2.29, Blobs 2.30, Starfield 2.99, Rain 3.17, Snow 2.29, Grain 2.29 (shaders run on the GPU, which raster time doesn't fully show). Live: MusicBrainz + iTunes + a real cover through the fixer (MusicBrainz sometimes refuses back-to-back runs; the fixer then shows iTunes only)
- **NOT verified**: Android on a real device (compiled only; ringtone, touch, live FFT, FFmpegKit filters, video background, deep links).
  Yandex live (API answers HTTP 451 from this PC). The GitHub workflow has never run (no repo yet). Hands-on clicking through the new editor; how smooth lyrics feel by eye;
  `liner://` opening from outside.

## Latest: smooth + live + auto info (2026-11-06)
- **Real cause of "feels like 30 fps"**: Flutter on Windows starts frames from a timer on the 15.6 ms system tick, so the
  app ran at 64 fps on the user's 119 Hz screen, out of step with it. `windows/runner/frame_pump.cpp`: a thread waits for
  each refresh (DwmFlush) and nudges the task runner. Measured with `FrameProbe`: 64 → 120 fps. `timeBeginPeriod` did
  not help. Depends on the window class `FlutterTaskRunnerWindow`; if a Flutter upgrade renames it, it silently falls
  back to 64 fps: re-run the probe after upgrades.
- Everything per-frame now goes by time, not frames (visualizer, cover pulse, backgrounds, seek bars), or it would run
  twice as fast at 120 fps. Wheel scrolling is one continuous glide instead of a restarted animation per notch.
- **Backgrounds**: driven by the screen instead of a 30 fps timer; Matrix fades continuously and symbols are made at the
  size shown; lines fade instead of popping. Behind the UI: frosted panels (real blur), slightly out of focus, darker at
  the edges, softer reactions. New settings: Strength, Out of focus, Frosted panels, Frames per second.
- **Seek bars**: every style moves with the music, the thin mini-player bar too. Settings → Appearance switch (default on).
- **Missing info** (Settings → Library, default on): finds covers, artists, albums, year, genre via Apple/Deezer, one song
  per ~3 s. Fills only what's missing, never touches files, keeps what was there (undo button). Schema v5.
- **Cramped UI**: taller player bar with more space, more room for the song name on narrow windows, side-panel cover
  scales with the window so the queue fits, roomier settings rows and stats. Hover/click effects inside panels were
  hidden (painted under the panel): fixed.
- New tool: `integration_test/ui_shots_test.dart` takes pictures of the real app at several sizes without touching the
  mouse.
- **Verified**: 235 tests, shots of every main page at 4 window sizes, 0 layout errors. Perf at 120 fps: Cover idle raster
  2.39 ms; with mouse moving and frosted panels Matrix 2.21, Constellation 2.95, Ripple 2.25, 0 missed frames.
  Auto-find ran on the real library: DELTARUNE and Undertale songs got covers, artists and albums.
- **NOT verified**: how smooth it feels on the user's screen (numbers only), Android (frame pump is Windows only; the
  new backgrounds and live bars weren't run there), CPU use on a weak PC at high refresh rates.

## Before that: look + together + stats (2026-11-05/06)
- **Seek bar**: 4 new styles (Ribbon, LED blocks, Tuner, Live spectrum) + Waveform. Settings → Appearance (working
  samples) or right-click the bar.
- **Logo**: old mark back (gradient `blur_on`, bold name, from the 2026-10-31 code). Tilts to the mouse, click = spin +
  rings + background shockwave, right-click = next background.
- **Cover click** fills the app window, Windows stays as it is. The bar's full-screen button still goes real full screen.
- **Backgrounds** (Settings → Appearance → Background, "Try it"): Matrix, Constellation, Ripple. Mouse, clicks, bass.
  Own settings per style: colors or theme colors, brightness, speed, density, size, trail/link/wave, mouse, music,
  symbols (katakana, binary, hex, letters, notes, own text), shape; solid panels, cover underneath, fps, stop on pause.
  Default stays Cover.
- **Listen together**: no setup any more. 5-letter code works from anywhere through a free public MQTT broker (own small
  client, scrambled with the code; can be turned off), same Wi-Fi sessions show up in a list, copied code is filled in,
  names of who is there, entry in the sidebar, missing song → YouTube/SoundCloud if on, big queues only send a window.
- **Discord**: album art + link via iTunes/Deezer, clean titles from file names, buttons, party while together,
  seeks update the bar, connects when Discord starts, status line in Settings.
- **Stats**: own nav tab. Overview, Top, History, Library, Wrapped; Week/Month/Year/All time, comparison with the period
  before, new songs, current streak, sessions, records, per day/month chart, weekday × hour and 6-month heatmaps, day
  parts, decades, completion, top albums, library numbers.
- Bugs found on the way: Settings rows painted hover/ripple under their box (invisible); `_applyAudio` didn't catch
  Riverpod 3's wrapped error.
- **Verified then**: 229 unit/widget tests. Live: `flutter test --tags network test/platform/together_session_test.dart`
  passes a real host + guest session over HiveMQ/EMQX and over direct LAN relay (join, follow next song, leave, host ends,
  wrong code), fake audio. test.mosquitto.org and eclipseprojects refused or failed, so only two brokers. HiveMQ stopped answering at times after many connects from this PC (6 s timeouts), EMQX never did, so EMQX is first and the code names the broker: host and guest can't end up on different ones (that was a real "No session" bug). Host and guests also reconnect by themselves if a connection drops (tested against a local MQTT broker that kicks everyone). In the
  installed app (screenshots): all backgrounds + mouse reaction, 5 bar styles while playing, in-app cover view, stats,
  together sheet, settings. Real Discord pipe answers ("Invalid Client ID" for a made-up id). Perf, mouse moving:
  Matrix build 0.27 / raster 2.00 ms, Constellation 0.11 / 2.47, Ripple 0.49 / 1.96, Cover idle 0.06 / 2.17, 0 missed.
- **Discord app** "Prism" (id 1568018022571180102, the user's) is built in as `prismDiscordClientId`. Real Discord
  accepted the whole status (cover, link, button, party); it answers with name=Prism. A plain "Playing Prism" card with a ? icon (seen 2026-11-06) did not come from Prism: the switch was off then. App icon to upload: docs/prism-discord-icon.png. The app code connects to real Discord when the status is on (test without UI clicks). The status stays off by default:
  Settings → Windows. Songs without tags: a cover only if the file name holds the result's title + artist and the
  length fits (all 5 of the user's DELTARUNE file names found; a fan version is refused).
- **NOT verified**: two real PCs in a session, UDP beacon between PCs (blocked by some firewalls, code still works),
  how the status looks on a profile (Discord accepted it, nobody looked), Android (including backgrounds + broker), Live
  spectrum on a very long song.

## Before that: unslop pass, settings, import, visualizers (2026-11-04)
- **Look** (all themes): quiet hi-fi direction. No hue gradients or colored glows (logo, covers, seek bar,
  stats cards, buttons), flat `PrismMark` logo, headings 600 max, one curve `PrismMotion.curve` (no
  overshoot springs / elastic), selected = surface step + hairline. Signature: amber `LedDot`
  (`context.look.led`, theme primary in color themes) on selected nav/settings rows, active tools, the
  playing-bars, ready import links. `PrismBackground` = grey cover backdrop in every theme (gradient
  background removed); backdrop marked `isComplex` so the GPU caches it.
- **Settings**: categories (Library, Playback, Appearance, Online & import, Listen together, Windows,
  Backup, About) - two panes on wide windows, pages on phones; `SettingsGroup`/`SettingsTile` rows.
  Visualizer style picker moved to Appearance.
- **Import**: one box - paste a link (clipboard link is pre-filled), live "Spotify playlist" detection,
  Import, or Choose file; which services work is shown with LED dots; off service → snackbar "Set up".
  Playlists page has an "Import playlists" row.
- **Visualizers** (`visualizer_painter.dart`): Bars (amber falling peak caps), Mirror, Radial, Wave +
  new VU meters (low/high needles with ballistics), Waterfall (3 s heat map), LED matrix.
- **Bugs**: Windows release kept a stale icon font from 2026-11-02 (new icons blank) - fixed by clearing
  `.dart_tool/flutter_build`; relay `close()` crashed with concurrent modification (flaky test);
  "1 songs"; visualizer said "needs FFmpeg" for streamed songs.
- Checked in the installed app (Midnight theme): library, playlists, settings, import. Perf: raster avg
  idle 2.77 / fling 3.09 / wheel 2.94 / tab 2.99 ms, 0 missed. Tests 192. Not checked live: the new
  visualizers while playing (widget test paints all 7), phone layout of settings.

## Before that: player bar + full-screen lyrics (2026-11-02, evening)
- **Seek bar** (player bar + full player): elapsed | waveform | total, denser bars (~1 per 6 px), bright
  "comet" trail, glowing playhead, crest around it, hover = taller bars + jump preview + time bubble.
- **Player bar right side**: only favorite, full screen, More, volume (+ slim slider, mouse wheel). More
  menu = sleep timer, speed & pitch, A-B loop, EQ, listen together, mini player, each with its state; a dot
  on the button while one is on. Volume lives in `playerVolumeProvider` (slider no longer resets to 100 %).
- **Full-screen view** (`/immersive`, `ImmersivePlayerPage`): click the side-panel cover (Hero) or the
  bar's full-screen button. Big synced lyrics left, pulsing cover + seek bar + controls right. Windows
  goes full screen; F11 toggles, Esc closes and restores, Space plays/pauses.
- Checked in the installed app (screenshots): bar, menu button, full screen opens + Esc restores the
  window. Perf: 0 missed frames, raster avg idle 3.05 / fling 3.05 / wheel 3.13 / tab 2.97 ms (a blurred
  playhead glow cost ~0.5 ms/frame; replaced with layered fills). Tests: 191.

## Before that: black & white UI rework (2026-11-02, later)
- **Default theme "Mono"** (`monochrome: true`, AMOLED): greys only, inverted selected states, covers
  stay in color; "Paper" = light version. Theme editor: "Black & white" switch hides the color pickers.
  Users still on a built-in color preset are moved to Mono once (font kept); own themes stay colored.
- **Visuals**: grey blurred cover behind the app (`AmbientBackdrop`, cross-fades per song), cover in the
  full player pulses with the bass + glowing halo (`BeatPulse`, from the cached spectrum), cover / lyrics
  / visualizer cross-fade, sidebar selection pill glides, album/artist cards lift on hover with a play
  button, bolder headings.
- **Faster**: no palette extraction or whole-app theme re-tint on song change (mono), no 20 fps background
  timer (mono), player-bar/mini seek bars repaint once per pixel of progress instead of 60x/s, time
  labels once per second, playing-bars repaint without rebuilds.
- **Bugs fixed**: seek bar jumped back after a tap/drag; list intro animation replayed when scrolling
  back up; full player could pop the page under it too; lyrics/visualizer used a disposed position after
  a stage switch; tag editor setState after close; import "Open" snackbar used a dead context.
- Tests: 188 unit/widget (new: mono theme + settings upgrade, beat pulse, backdrop + hover play).
- Perf (profile, Medal + Steam running): 0 missed frames; raster avg idle 3.12 / fling 3.43 / wheel 3.50 /
  tab 3.41 ms (before 2.90 / 3.60 / 3.59 / 2.88); idle renders 84 frames instead of 102. Theme-change test
  only changes primaryColor, which Mono ignores (measures little now).

## Earlier today: online services + playlist import (2026-11-02)
- `features/online/`: one module per service behind flags (Settings → Online services), built in
  `OnlineHub` try/catch; all errors = `OnlineException` (offline / rate limit / auth / not configured…).
- **Spotify**: PKCE login, playlists / liked songs / saved albums as text (Feb-2026 `/items` + fallback).
  Never audio. Dev Mode = 5 users, only own/collab playlists → hint to use Exportify CSV.
- **YouTube / YT Music**: Data API (key) or youtube_explode extractor (flag, personal use): search,
  playlist links, Google login for own playlists/likes, **playback**, offline copies (LRU cache).
  Own `WebPlaylistReader` (library can't parse the 2026 `lockupViewModel` layout) and `StreamProxy`
  (googlevideo 403s open-ended ranges → loopback proxy with 1 MB bounded ranges).
- **SoundCloud**: official API (search, likes, playlists, stream where `access == playable`).
- **Deezer** public API + **Apple Music** page reading (off by default) for links.
- **Import**: file (CSV Exportify/TuneMyMusic/generic, JSON incl. Spotify data export, M3U/M3U8), links,
  accounts → preview (names, duplicates, "imported before") → background matching (local first, then
  YouTube, SoundCloud; confidence + Fix) → resumable (schema v4 `import_jobs/items`) → playlist.
- Unified search page (library + each enabled service, per-section errors). Remote tracks live in
  `tracks` (source_id ≠ local), hidden from library views, work in playlists/favorites/queue.
- Engine: resolve errors → `failed` + `lastError` (snackbar), unresolvable *next* retried at track end.
- README "Online services" (setup + ToS table), in-app terms notes, `online_config.example.json`.
- Tests: 182 unit (57 new: matching, parsers, pipeline, HTTP retries, OAuth, proxy, DB, 4 screens) +
  network-tagged live tests.

## Verified (2026-11-02, Windows)
- Live: YouTube search → stream → real JustAudioDeckEngine/libmpv → audible WAV; removed video skipped
  with reason. Deezer playlist/album, Apple Music album + playlist (with artists), YouTube 163-song
  playlist all imported. Deezer→YouTube: first 5 songs all "high" before YouTube's bot check hit.
- Installed build starts; real DB migrated to v4.

## NOT verified (needs keys / approval from the user)
- Spotify, SoundCloud, Google (YouTube Data API + login): no keys → never run live; mocked only.
- Clicking through the new screens in the installed app (only widget tests). Android not run.
- YouTube bot check after many searches from one IP: import pauses (handled), but full 50-song live
  match not completed today.

## Earlier: extras + release 1.0.0 (2026-11-01)
- **Synced lyrics**: .lrc next to the song → embedded tag → LRCLIB (setting), cached in DB; karaoke wipe,
  auto-follow, tap to seek. Full player stage switch Cover / Lyrics / Visualizer; side panel Up next / Lyrics.
- **Visualizer**: Bars / Mirror / Radial / Wave in theme colors, from a cached FFmpeg+FFT spectrum.
- **Listen together**: host starts a session (LAN code `K7QX-C0A80105`, or a public relay +
  4-letter code via `dart run tool/relay.dart`); guests follow queue/position/play/speed from their own library.
- **Smart playlists** (Most played, Recently added, Forgotten gems + own rules) and **Wrapped stats** cards.
- **Android home widget**, Windows **mini player** (always on top), **Discord status** (needs an Application ID).
- **Tag editor** (with backup), **duplicate finder**, **backup/restore** (settings, EQ, themes, playlists,
  favorites, smart playlists, edits; works across devices).
- **Release**: `tool\build_release.ps1` → `dist\Prism-Setup-1.0.0.exe` (78.5 MB, Inno Setup, per user),
  `Prism-1.0.0.apk` (154.5 MB), `-arm64-v8a` (47.3 MB), `-armeabi-v7a` (61.6 MB), signed "CN=kolommix, O=Prism".
  Keystore + passwords: `%USERPROFILE%\.prism-signing\` (BACK IT UP - without it friends can't update over the APK).
- README rewritten for friends (install steps, SmartScreen, which APK, listen together, Discord, screenshots).
- DB schema v3 (plays, smart_playlists, lyrics_cache). Analyzer clean, 125 unit tests + 13 audio tests pass.

### Verified then (Windows)
- Installer: silent install → "Prism version 1.0.0" in Apps, app starts from the installed folder.
- Screens open: Playlists (stats tile + smart playlists), Stats ("No listens yet" - history starts now),
  Lyrics tab. Widget tests drive Wrapped cards, karaoke line, all 4 visualizer styles, together sheet.
- Relay: two real WebSocket clients through `ListenTogetherRelay` (host/guest/second host refused);
  `dart run tool/relay.dart` starts and accepts connections.
- Discord IPC: handshake + SET_ACTIVITY against a fake named pipe (PowerShell server).
- Tag writer: real MP3 edited, read back, backup kept. Spectrum: real FFmpeg decode → bands.
- Perf re-run after extras: idle 2.76 / fling 3.59 / wheel 3.48 / tab 2.86 ms raster avg (first run was
  ~1.5 ms higher everywhere while Medal/Discord/Steam were using the GPU).

### Not verified then
- **Android on a device** (user skipped): widget, effects, FFmpegKit export, visualizer decode, lyrics.
- Discord with the real Discord app; listen together between two real devices; Windows firewall prompt.
- LRCLIB live: the API returned HTTP 502 during the whole session (site up, API down) → tested with a mock.

## Limitations
- Visualizer is precomputed from the file (no mic/loopback permission): it ignores EQ/speed effects on
  the sound, first play of a song needs a few seconds of analysis.
- Listen together needs the same songs on every device (title + artist + length), or an online service for missing
  ones. Public brokers are free test services: no guarantee, may go away (then: own relay, `cloudBrokers`).
- Local covers can't go on Discord (only images from a web address): covers come from Apple/Deezer search.
- Installer isn't code-signed → SmartScreen "More info → Run anyway". APKs are big (FFmpeg); use arm64.
- Tag writing: no OGG.
- YouTube extractor is unofficial (YouTube ToS): may break any time; searches spaced 1.5 s; bot check → pause.
- Streamed songs: no loudness analysis, visualizer, editor or tag editor (file-only features). Android Equalizer bands are device-specific (often 5).
- Windows live pitch = asetrate+atempo (mpv realtime rubberband was too quiet); exports use rubberband.
- Windows app ≈ 262 MB unpacked (full libmpv + ffmpeg.exe).

## Before that
**Foundation (2026-10-31)**: library, gapless/crossfade engine, queue, sleep timer, resume, Android
notification, Windows SMTC + tray, theme engine, animations, responsive layout.
**Audio features (2026-11-01)**: 10-band EQ (Windows FFmpeg biquads / Android audiofx), speed, pitch,
A-B loop, loudness normalization, non-destructive editor + FFmpeg export. EQ measured = model within
0.01 dB; pitch/speed/edit exports measured (see docs/ARCHITECTURE.md → Testing).
**Smoothness (2026-11-01)**: raster avg 7.3 → 2.5 ms idle, 9.2 → 3.0 ms scrolling, 0 missed frames
(blur only where needed, 20 fps background, no idle tickers, smooth wheel scrolling).

## Next
1. Fill online_config.json (Spotify client id, optional YouTube key, SoundCloud app) and test logins + imports live.
2. Android device test (widget, EQ, export, visualizer, lyrics, online playback through the proxy).
3. Retry LRCLIB live once the API is back.
4. Release 1.1.0 with toolbuild_release.ps1 once the above is checked.

## Gotchas
- New Material icon shows blank in the release build → stale icon-font subset: delete
  `.dart_toollutter_build` and `buildlutter_assets`, rebuild
- google_fonts pinned to 8.x (9.x types clash with Flutter material)
- android/build.gradle.kts maps plugins' compileSdk 37 -> platform android-37.0; app compileSdk 37.0
- windows/CMakeLists.txt defines _SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS (permission_handler_windows)
- Windows build needs Developer Mode ON (plugin symlinks); installer needs Inno Setup 6
- Vendored + patched: third_party/just_audio_media_kit, third_party/ffmpeg_kit_flutter_new_audio (see its README)
- Binaries in windows/third_party (libmpv, ffmpeg) from zhongfly/mpv-winbuild 2026-10-30
- dart:io WebSocket `done` only completes if the socket is listened to (tests hang otherwise)
- Toolchain: Flutter at C:\dev\flutter, JDK 17 (Microsoft), Android SDK in %LOCALAPPDATA%\Android\Sdk
- Old handoffs: _archive/

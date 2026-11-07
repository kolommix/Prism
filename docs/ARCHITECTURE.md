# Prism – Architecture

Cross-platform music player (Android + Windows), Flutter + Dart.

## Layers

Every feature folder uses the same layout. Dependencies only point *down*:

```
presentation/   widgets & pages (Riverpod ConsumerWidgets)
      │
application/    Riverpod providers, controllers (state + use-cases)
      │
domain/         pure Dart models & rules (freezed), no Flutter, no IO
      │
data/           repositories, scanners, IO (drift/SQLite, files)
```

```
lib/
  main.dart                 bootstrap: init backends, DB, player, OS integrations
  app.dart                  MaterialApp.router + theme from settings/cover colors
  core/
    db/                     drift schema (tables, migrations)
    router/                 go_router (StatefulShellRoute + full-screen player)
    theme/                  ThemeConfig (freezed), theme builder, ThemeExtensions,
                            album palette extraction
    motion/                 page transitions, SpringButton
    widgets/                GlassPanel, AmbientBackdrop, Artwork, LedDot
    sources/track_source.dart   ← main plug-in point (see below)
    providers.dart          app-wide singletons (overridden in bootstrap)
  features/
    library/                scan folders, tags, search, albums/artists/folders, favorites
    playlists/              playlists CRUD + ordering
    player/
      domain/playback_queue.dart    pure queue rules (shuffle/repeat/move…)
      engine/                       PlaybackEngine interface + just_audio impl
      application/                  PlayerController, sleep timer, persistence
      platform/                     Android audio_service, Windows SMTC + tray
      presentation/                 mini player, player bar, full player, queue
    settings/               AppSettings, theme editor, settings page
    shell/                  responsive scaffold (bottom nav ↔ sidebar)
    audio_fx/ editor/       equalizer, non-destructive editor (below)
    stats/                  play history, smart playlists, Wrapped cards
    lyrics/                 LRC parser, lyrics sources, karaoke view
    visualizer/             spectrum analysis + painters
    tools/                  tag writer, duplicates, backup/restore
    together/               listen-together relay, protocol, controller
    online/                 Spotify, YouTube, SoundCloud, Deezer, Apple Music, imports (below)
    desktop/                Windows mini player + Discord (status, album art), Android widget sync
    background/             animated backgrounds: config, effects, PrismBackground, settings page
windows/runner/
  smtc_bridge.cpp           media keys + Windows media overlay (C++/WinRT)
  tray_bridge.cpp           notification-area icon + menu (Win32)
tool/
  relay.dart                standalone listen-together relay (dart run)
  build_release.ps1         installer + APKs into dist/
installer/prism.iss         Inno Setup script
```

## State management

* **Riverpod 3** (`flutter_riverpod`), hand-written providers (no generator).
* Things that need async setup (DB, player, settings) are created in
  `main.dart` and injected with `overrideWithValue` – every provider is then
  synchronous and trivially replaceable in tests.
* Lists come from drift `watch()` streams → `StreamProvider`, so the UI updates
  live while a scan is running.

## Library

* `LibraryScanner` walks folders, keeps only `.mp3 .flac .m4a .ogg .wav`,
  and is **incremental**: file size + mtime are stored, unchanged files are
  skipped. Tag parsing runs in a background isolate (`Isolate.run` per batch).
* `TagReader` interface; current impl = `audio_metadata_reader` (pure Dart,
  no native code). Covers are written once per album into
  `<app support>/artwork/<md5>.jpg`.
* SQLite tables: `tracks`, `library_folders`, `favorites`, `playlists`,
  `playlist_entries`, `saved_themes`. Favorites/playlists reference track ids;
  rescans upsert by path so ids (and therefore favorites) are stable.
* Search: pre-normalised `search_text` column (lower-case, accents stripped),
  every query token must match (`LIKE`). Fast enough for tens of thousands of
  songs; upgrade path is an FTS5 virtual table behind the same `search()` API.

## Playback

```
UI / Android notification / Windows SMTC & tray
                    │
             PlayerController  ── owns ──> PlaybackQueue (pure, tested)
                    │  feeds "current + next"
             PlaybackEngine (interface)
                    │
          JustAudioDeckEngine (two just_audio players)
           Android: ExoPlayer      Windows: libmpv via media_kit
```

* **Gapless**: the active player holds a 2-item playlist `[current, next]`;
  the backend pre-buffers `next` and switches without a gap. After the switch
  the engine drops item 0 and the controller appends the new next.
* **Crossfade** (setting 1–12 s): the idle player starts `next` at volume 0
  near the end, volumes ramp in opposite directions, then the players swap.
* Queue edits (play next, reorder, shuffle, remove) never interrupt the song –
  only the pre-buffered "next" is replaced.
* Last queue + position saved (shared_preferences) every 5 s and on pause;
  restored on start without auto-play.
* Sleep timer: fixed minutes or "end of song", with an 8 s fade-out.
* Android: `audio_service` foreground service → notification, lock screen,
  headset/Bluetooth buttons. `MainActivity` extends `AudioServiceActivity`.
* Windows: native C++ bridges (no extra packages, no Rust toolchain):
  `prism/smtc` (media keys + system media overlay with cover) and
  `prism/tray` (tray icon + Play/Pause/Next/Previous/Quit). Closing the window
  hides to tray (setting).

## Theme engine

* `ThemeConfig` (freezed + json) is the single source: colors, brightness
  (system/light/dark/AMOLED), corner radius, font, glass intensity, animation
  speed, dynamic color on/off. Export/import = the same JSON wrapped as
  `{"format":"prism-theme","version":1,"theme":{…}}` (values are clamped on
  import, so hand-edited files can't break the UI).
* `buildPrismTheme()` turns it into `ThemeData` + three `ThemeExtension`s:
  `PrismMotion` (speed, reduce motion), `PrismGlass` (blur/opacity),
  `PrismShape` (radius scale). Widgets read them via `context.motion`,
  `context.glass`, `context.shape` – nothing hard-codes durations or radii.
* **Black & white (default since 2026-11-02, `monochrome: true`)**: `monochromeScheme()`
  (greys only; white on black / black on white), selected states inverted
  (white pill, black text), `PrismLook.monochrome` (`context.look`) for widgets
  that adapt. Covers stay in color. No palette extraction and no theme lerp on
  track changes. Old settings on a built-in color preset are moved to it once
  (`SettingsStore.upgradeTheme`, font kept); own themes and theme files without
  the key stay colored (`ThemeConfig.upgradeJson`).
* Dynamic color (color themes): `AlbumPaletteExtractor` (palette_generator on a 96 px
  thumbnail) → seed color for `ColorScheme.fromSeed` + 3 gradient colors.
  `MaterialApp` lerps between themes, so a song change smoothly re-tints the app.

## Motion

* All durations go through `context.motion.d(...)` (speed multiplier, zero when
  *reduce motion* is on – app setting or the OS accessibility flag).
* Hero: the cover in the mini-player / desktop bar flies into the full player
  (route on the root navigator, custom slide-up transition).
* Backgrounds go through `PrismBackground`: `AmbientBackdrop` by default (cover decoded at 64 px, blurred + greyed
  once into a 48 px image, cached, stretched; cross-fades on track change, no timer; `isComplex` so the raster cache
  keeps it as a texture), or a `LiveBackground` (see Animated backgrounds).
* Design rules (unslop pass 2026-11-04): no hue gradients or colored glows,
  headings weight 600 max, one curve `PrismMotion.curve` (critically damped
  springs, no overshoot), selected = one surface step + hairline, and the one
  accent is the amber `LedDot` (`context.look.led`) on things that are live.
  Settings rows are `SettingsGroup` / `SettingsTile` (settings_widgets.dart).
  Visualizer styles live in `VisualizerPainter` (one ink color, LED peaks).
* Desktop player bar: favorite, full screen, `PlayerMoreButton` (MenuAnchor with the rarer tools and
  their state, dot when one is on), `VolumeSlider` (`playerVolumeProvider`). `ImmersivePlayerPage`
  (root navigator): lyrics left, cover right, Hero `panelArtHeroTag` from the side panel.
  `Routes.immersive` (click on the panel cover) fills the app window and leaves the window as it is;
  `Routes.immersiveWindow` (the bar's button) also makes the Windows window full screen (`WindowsFullScreen`, own code in `flutter_window.cpp`). F11 toggles either way.
* Seek bar: `SeekBarStyle` (Waveform, Ribbon, LED blocks, Tuner, Live spectrum) in `seek_bar_painters.dart`, all
  fed by one `SeekPaintData`. With `liveSeekBar` on (default) every style moves with the song (`musicAt`: spectrum if
  analysed, a gentle wobble if not) and gets a frame per refresh while playing; off, they only update when the playhead
  moves a pixel. Right-click to switch.
* `PrismLogo`: the mark tilts towards the mouse, a click spins it and sends rings + a background shockwave,
  right-click switches the background.
* `BeatPulse` (full player cover): bass from the precomputed spectrum scales the
  cover a little and a blurred halo glows with the level; ticker only while
  playing. Cover / lyrics / visualizer cross-fade. Sidebar selection is one
  pill that glides (`AnimatedPositioned`). Album/artist cards lift on hover and
  show a play button.
* Wheel scrolling: `_WheelGlide`, one activity following a moving target by real time.
* `SpringButton`: real spring simulation (`SpringSimulation`) on release.
* Waveform seek bar: the big one (full player) interpolates every frame with a
  `Ticker`; small ones (player bar, mini player) use a timer paced to one
  physical pixel of progress (a running ticker re-renders the window 60x/s).
  Time labels rebuild once per second. A seek ignores the engine's stale
  position for up to 1.5 s (no jump back). Peaks are pseudo-random per track for now; the
  painter accepts any `List<double>` so real peaks can be plugged in.
* Reorderable queue/playlists with lifted, scaled drag proxy; staggered list
  entrance (only on first appearance, not for items scrolled back into view);
  cross-fading tab switches with state kept per tab.

## Responsive layout

`AppShell` (width-based):
* `< 760 px` – content, glass mini-player, glass bottom `NavigationBar`.
* `≥ 760 px` – sidebar (collapses to icons below 980 px) + content + full-width
  player bar; from `1180 px` a now-playing panel (cover + queue) on the right.

## How future features plug in

### Streaming integrations → `TrackSource` (implemented, see "Online services")
A new source implements `TrackSource` (resolve URI + headers, search) and is
registered in `TrackSourceRegistry`; its tracks carry `sourceId`. The engine
resolves every track through the registry, so queue, gapless, crossfade,
notification and media keys work unchanged. Tokens live in secure storage.

## Online services (implemented)

```
features/online/
  domain/      ExternalTrack (metadata only), MatchScorer, link parser,
               file parsers (CSV/JSON/M3U), OnlineException   ← pure, tested
  data/        OnlineHttp (retries/429/offline), OAuthClient (PKCE, loopback),
               OnlineConfig (local keys file), RemoteTrackStore, StreamCache,
               StreamProxy, ImportRepository (schema v4)
  services/    one folder per service, all `MusicServiceModule`:
               spotify/  youtube/ (YoutubeBackend: DataApi | Explode, +web reader)
               soundcloud/  link_only/ (Deezer, Apple Music)
  application/ OnlineHub (flags, builds modules), MatchService, ImportRunner
  presentation/ settings, import, import job (review + fix), terms notes
```

* **Isolation**: `OnlineHub` builds each module in its own try/catch from
  `online_config.json` + feature flags (prefs `online.flags`); a module that is
  off / not configured / throws only marks itself (`ModuleStatus`). Every
  network error becomes an `OnlineException` with a plain message;
  `isTransient` (offline, 429, 5xx) means "pause and retry later".
* **Playback**: `RemoteTrackSource` (`youtube`, `soundcloud`) is always
  registered; it serves the offline copy if there is one, else asks the
  module. Disabled service → clear error → engine emits `failed` (the engine
  now catches resolve errors, keeps `lastError`, and retries an unresolvable
  *next* track when the current one ends) → controller skips, app shows a snackbar.
* **StreamProxy**: googlevideo answers 403 to open-ended range requests
  (what mpv/ExoPlayer send). YouTube URLs are served through a loopback
  proxy that fetches bounded 1 MB ranges, honours player seeks and
  re-resolves an expired URL once. Android allows cleartext only to 127.0.0.1
  (`res/xml/network_security_config.xml`).
* **Remote tracks in the DB**: `RemoteTrackStore` upserts them into `tracks`
  (`source_id` = service, `uri` = canonical URL, `artwork_path` = https URL),
  so favorites, playlists, history and queue restore work. Library views
  (songs/albums/artists/folders/search) filter `source_id = 'local'`.
* **Matching** (`MatchService` + `MatchScorer`, pure and tested): exact M3U
  path → local library (wins at ≥ medium or within 0.1 of the best online) →
  the linked video itself for YouTube imports → search YouTube, then
  SoundCloud, stop at "high". Score = 50 % title + 30 % artist + 20 % length,
  after dropping noise ("Official Video", "Remastered 2011", "feat. X");
  other recordings (live, remix…) are pushed down, fan versions (karaoke,
  nightcore, sped up…) strongly; a cover by another artist stays < medium.
  Levels: high ≥ 0.85, medium ≥ 0.7, low ≥ 0.5 (kept, flagged), else none.
* **Imports**: `import_jobs` + `import_items` (schema v4). Items are written
  one by one, so `ImportRunner` (2 workers, paced) can pause on a transient
  error and resume later; duplicates inside a list are marked before
  matching. "Create/Update playlist" rewrites the playlist's entries in import
  order (manual fixes included).
* **YouTube extractor** pieces are unofficial and break when YouTube changes:
  `ExplodeBackend` (youtube_explode_dart, searches spaced 1.5 s, bot check →
  rate limit) and `WebPlaylistReader` (own reader for the 2026
  `lockupViewModel` playlist layout the library can't parse yet).
* Spotify Feb-2026 API: `/playlists/{id}/items` with fallback to `/tracks`;
  rows may carry the song under `item` or `track`.

### Yandex Music

`services/yandex/`, flag `yandex` (off by default). There is no official API: endpoints come from the community project
yandex-music-api (`ym.marshal.dev/api/openapi.json`) on `api.music.yandex.net`. Public links need no token; own playlists and
likes use a token the user pastes (`OAuth <token>`, kept in secure storage, checked before saving). Song names only. HTTP 451
(region block) and answers in an unknown shape end in messages that point to the CSV/JSON import. Not run live: from the dev
PC the API answers 451. Tests use the spec's shapes.

## Audio effects (implemented)

```
EqController (Riverpod) ──> AudioEffectsBackend (interface)
                              ├─ MpvAudioEffects      Windows: libmpv `af` = one FFmpeg graph
                              └─ AndroidAudioEffects  Android: AudioFxPlugin.kt per audio session
```
* **Shared model** `audio_fx/domain/eq_settings.dart`: 10 bands (31 Hz–16 kHz,
  Q 1.41), preamp, bass boost, 12 built-in + custom presets (prefs JSON).
  `eq_math.dart` = RBJ biquads, identical to FFmpeg's `equalizer`/`bass`, so the
  drawn curve is the processed sound (verified to 0.01 dB, see Testing).
* **Windows**: `buildMpvAudioFilter()` → `@fx:lavfi=[pitch…,equalizer…,bass…,alimiter]`,
  set on every player through the patched `third_party/just_audio_media_kit`
  (`setGlobalProperty`). Needs the *full* libmpv in `windows/third_party`
  (media-kit's own libmpv has no FFmpeg filters).
* **Android**: `Equalizer` + `BassBoost` + `LoudnessEnhancer` attached to each
  ExoPlayer session; the 10-band curve is sampled at the device's native band
  centres (`mapEqToNativeBands`).
* **Gain path** (preamp, loudness normalisation, edit clip gain, edit fades):
  the engine's player volume; positive gain above 1.0 → mpv volume (Windows,
  linear→cubic mapped in the plugin patch) or LoudnessEnhancer (Android).
* **Speed** = just_audio `setSpeed` (pitch preserved). **Pitch** = effects
  backend (Windows: asetrate+atempo in the graph; Android: `setPitch`).
* **A-B loop**: engine, output time, 50 ms ticker.
* **Loudness normalisation**: ReplayGain tags (MP3 TXXX, Vorbis) or FFmpeg
  `ebur128` measurement (−18 LUFS, peak-limited), `PlaybackPlanService`.

## Playback plans + live edit presets

Every track is played through a `PlaybackPlan` (`player/domain/playback_plan.dart`):
clips (`ClippingAudioSource`, per-clip speed/pitch/gain), fades and a track
gain. Plain tracks are one identity clip. `PlaybackPlanService.planFor()` =
live edit preset (if enabled for the track) + normalisation gain. The engine
keeps the gapless window in *clips* and applies clip params on index changes.

## Audio editor (implemented, non-destructive)

`features/editor`. The audio file is only read; an edit is a list of `EditOp`s saved per track (`track_edits`), with
redo steps, cursor and zoom, after every change, so a session continues where it stopped.

* **`domain/timeline.dart`** replays the ops into a `Timeline` of `Segment`s: source range, speed (optionally a ramp),
  pitch, gain, reverse, silence, a merged file, per-segment fades + curve, crossfade into the next, 3-band EQ, gate. All time
  mapping lives here (`locate`, `sourceToOutput`). Ops use output time, so they mean what the user saw when they were made.
* **`domain/export_command.dart`** turns the same `Timeline` into an FFmpeg filter graph. A ramp is made of steady steps
  (`Segment.steps`, FFmpeg has no gliding tempo filter) and the timeline computes length from those same steps, so the
  file length always matches the screen. Tested against real FFmpeg in `test/platform/editor_v2_export_test.dart`.
* **`data/peak_cache.dart`** decodes once into `peak_cache/<hash>.peaks` (200 values/s); `PeakPyramid` builds coarser levels
  (each 4x) so a whole song and a close-up cost the same to draw. Beats and silences come from this data.
* **Preview**: "B" plays the clip plan when `Timeline.isLiveCompatible` (cuts, speed, pitch, gain, fades), otherwise a WAV
  rendered by FFmpeg with the same graph as the export. "A" plays the file. **Live presets** work the same way: the player
  gets clips, or `PlaybackPlan.renderedFile` (`edit_renders/`) for edits clips can't do. Until that file exists the song
  plays unedited.
* **Quick tools** (`domain/editor_tools.dart`) only look at the waveform and produce normal ops, so they undo like any edit.

**Why FFmpeg**: it is the only option that does all of this on both platforms with the same arguments. Windows runs the
bundled `ffmpeg.exe` (full build, has rubberband; a separate process, so a crash or Cancel can't hurt the app). Android runs
FFmpegKit in-process (`ffmpeg_kit_flutter_new_audio`: lame + AAC + FLAC, no rubberband, so pitch falls back to
`asetrate` + `atempo`). Android has no usable native API for filter graphs or MP3 encoding; writing DSP in Dart would be
slower and worse.

Ringtones: `RingtonePlugin.kt` (MediaStore + `RingtoneManager`, the user allows "modify system settings" once).

## Play history, smart playlists, stats

* `plays` table (schema v3): one row per *listen*. `ListenAccumulator` counts
  real listening time (pauses and seeks don't count, gaps ≥ 5 s ignored); a
  listen = 30 s or half the song. `playRecorderProvider` is watched in `app.dart`.
* `SmartPlaylist` = rules (`SmartRule` union: mostPlayed, recentlyAdded, genre,
  year, notPlayedFor) + sort + limit, stored as JSON in `smart_playlists`.
  `buildSmartQuery()` (pure, tested) turns it into one SQL query with a
  `LEFT JOIN` on play counts; the page watches it via `customSelect(readsFrom:)`.
  Three built-ins have negative ids and are not stored.
* `computeStats()` (pure) → minutes, top tracks/artists/genres, plays per hour, streaks; `WrappedCards` shows them as
  swipeable animated cards.
* `computeDeepStats()` (pure, whole history + period): comparison with the period before, firsts, current streak,
  sessions (30 min of silence ends one), records, weekday × hour, day parts, decades, completion.
  `computeLibraryStats()`: the library itself. `StatsPage` (own nav tab): Overview, Top, History, Library, Wrapped for
  Week / Month / Year / All time. Charts in `stats_charts.dart`: one hue, thin marks, hover tooltip on every mark.

## Lyrics

`LyricsRepository.forTrack()` tries, in order: `lyrics_cache` table →
`<song>.lrc` next to the file → embedded lyrics tag → LRCLIB (`/api/get`, then
`/api/search`; only when *Online lyrics* is on). "Not found" is cached 7 days;
server errors (5xx) are not cached. `parseLrc()` handles offsets, several time
stamps per line and word tags. `LyricsView`: only the current line repaints
(`ShaderMask` wipe driven by `LivePosition`), auto-follow pauses 4 s after the
user scrolls, tap a line to seek.

**Smoothness** (what made it jump and what fixed it): the engine reports the position about 4 times a second with up to
~50 ms of noise, and every report used to overwrite the clock, so the highlight hopped back and forth. `PlayheadEstimator`
now works small errors off by running slightly fast or slow (never backwards) and only takes big differences (seeks) at once;
`LivePosition` shares it, so seek bars and the visualizer gain too. Scrolling was `ensureVisible` on a lazy list, which did
nothing for lines not built yet and restarted its animation on every line; it is now a critically damped spring on a real
column (exact solution, same motion at any frame rate, no overshoot). `KaraokeLine` paints the sung characters from the
text's real boxes, also across wrapped lines, on its own layer; `parseLrc` reads enhanced word tags and `cleanLines` repairs
bad files (order, duplicates, two lines on one stamp, words outside their line). A long gap doesn't make the wipe crawl. Per-
song offset: `lyrics_cache.offset_ms` (schema v6), tune button on the lyrics.

## Visualizer

No microphone / loopback permission: `SpectrumService` decodes the song once
with FFmpeg (22 kHz mono), runs a 2048-point FFT in an isolate → 48 log bands
× 30 fps, cached as a small `.spc` file per song (key = path + size + mtime).
`Visualizer` reads the frame at the live position (bars, mirror, radial, wave;
theme colors). Limitation: it shows the file, not the EQ'd output.

## Tools

* `TagWriter`: `audio_metadata_reader` writer in an isolate, after copying the
  original to `<support>/tag-backups` (last 30 kept); reads the file back and
  restores the copy if the title didn't stick. mp3/m4a/flac/wav (no OGG).
* `findDuplicates()`: normalized title + artist, length within 2 s.
* `BackupService`: one JSON file (`prism-backup` v1) with settings, EQ, themes,
  playlists, favorites, smart playlists and edits. Songs are stored as
  `TrackRef` (path + title + artist + length) and matched again on restore by
  `TrackMatcher`, so a backup works on another device with the same music.

## Song info fixer

`features/metadata`, route `/metadata?ids=`. From a song's menu, an album or a folder. MusicBrainz + iTunes searched together
(a dead service only costs its own results), ranked with the import `MatchScorer`. MusicBrainz goes through `RateLimiter`
(one request per 1.1 s, their rule) with the `Prism/<version> ( url )` user agent; a 503 backs off once. Covers: Cover Art
Archive release, then release group, then iTunes. In a batch, `preferCommonAlbum` nudges songs to the album most of them
agree on. Saving goes through `TagWriter` (backup, verify) and rescans the folder, so the database says what the files say;
formats it can't write (OGG) change the database only. AcoustID needs `fpcalc.exe` beside the app and
`acoustid.apiKey` in the online config: neither FFmpeg build here has Chromaprint.

## Listen together

```
host app ─┬─ RelayLink ──> relay inside the host app <── RelayLink ── guests on the same network (found by UDP beacon)
          └─ CloudLink ──> public MQTT broker        <── CloudLink ── guests anywhere (or your own relay, Settings)
```
* `TogetherLink` hides how people are reached: `RelayLink` (`relay.dart`, `dart:io` WebSockets, rooms by code, in the
  app on port 47800 or `tool/relay.dart`) or `CloudLink` (`mqtt_lite.dart`: own small MQTT 3.1.1 client over TLS;
  brokers in `cloudBrokers`; host publishes on `…/h`, guests on `…/g`; topic = hash of the code). The host takes the
  first broker that answers and picks a code that names it (`randomRoomOn`), guests read it (`brokerOfRoom`).
* Public brokers are free and open, so messages are scrambled with the code (`scramble`: SHA-256 in counter mode). That
  keeps strangers from reading along, it isn't security: nothing in a session is secret. Last will: broker says "ended".
* A dropped connection comes back by itself on the same server (`_keepHostLink`, `_addGuestLink`); a guest gives up
  after a minute without the host.
* `NearbyBeacon` / `NearbyScanner`: UDP broadcast on 47801 every 2 s, the sheet lists sessions on this network.
* Host: `SharedState` on every jump and every 5 s, carrying only `queueVersion`; the queue (a window of 5 back, 40
  ahead) only when it changes or a guest sends `need`. Guests ping with id + name every 8 s: that is how the host knows
  who is there on any link (silent for 28 s = gone). Guests estimate the clock offset with ping/pong, match songs in
  their own library (`TrackMatcher`), try `MatchService` for a missing current song if an online service is on, and seek
  when drift > 700 ms. A guest tries the network first, then the internet; no answer in 4 s = next, then "no session".
  No audio is streamed. Code: 5 letters (`K7QXA`); `ROOM-HEXIP` only when the internet is off.

## Frame rate

Flutter on Windows starts frames from a timer on the system tick (15.6 ms): 64 fps at most on any screen, out of step
with it. `windows/runner/frame_pump.cpp` waits for each display refresh (`DwmFlush`) on its own thread and posts `WM_NULL`
to the engine's `FlutterTaskRunnerWindow`, so a due frame starts right then (64 → 120 fps on a 119 Hz screen). Idle when
the window is hidden. No effect on Android. `FrameProbe` (compiled out without `PRISM_FPS_PROBE`) measures delivery.
So nothing may assume a frame rate: per-frame smoothing uses elapsed time.

## Missing info

`AutoTagger` (`features/library/application`) walks `tracksMissingInfo()` one song at a time (Apple allows ~20 searches a
minute) through `CoverLookup`, saves the cover in the artwork folder and calls `applyAutoTag`. `autoTagChangeFor` (pure)
only fills what is missing. Schema v5: `info_checked_ms` (don't search twice), `info_original` (JSON for undo); a rescan
of a changed file clears both. Services not answering says nothing about a song: it stays on the list.

## Animated backgrounds

`features/background`: `BackgroundConfig` (in `AppSettings`, one `BgParams` per style), `BackgroundEffect` (Matrix,
Constellation, Ripple), `LiveBackground` (runs one), `BackgroundPage`.
* Input: one translucent `Listener` around the app (`app.dart`) writes the pointer to `BackgroundInput` and sends
  clicks as bursts: no rebuilds, no cost when nothing listens.
* Ticker, stepping by real time, capped in Settings if wanted (a timer beats against the screen and judders). Only the
  newest full-window instance runs; it stops on `TickerMode` off, hidden window, mini mode, reduced motion, optionally
  paused music. Bass from the precomputed spectrum, like `BeatPulse`.
* Sits behind the UI: effect drawn into a blurred, dimmed layer (`softness`, `strength`), a radial wash over it, frosted
  panels (`GlassPanel` + `PrismGlass.frosted`, one shared `BackdropGroup`).
* Drawing: one `drawRawAtlas` (Matrix: symbol sheet; Ripple: dot/dash/plus sprites) or `drawRawPoints` batch from
  preallocated lists. Measured at 120 fps (mouse moving, 1384×821, frosted): build 0.2 to 0.7 ms, raster 2.2 to 3 ms, 0 missed.
* Panels get see-through while one runs: `PrismGlass.panelOverride`, set in `buildPrismTheme(panelOpacity:)`.

### More styles (shaders, own files)

`shaders/bg_field.frag` does mesh, aurora, blobs and grain in one draw call (falls back to a plain gradient where shaders
can't load). Starfield, rain and snow are batched points and lines. Gradient and own picture are `isStatic`: no ticker at all
unless parallax is on. Own video: FFmpeg extracts the first 30 s at 12 fps, 720 px wide, into `bg_video/<hash>/`, and
`VideoFramesEffect` decodes only the next JPEG, so no video player plugin and no audio. Only the selected card in the picker
animates. A saved or exported theme carries the background (`ThemeConfig.background`), a picture as base64 inside the file,
never a path; a video falls back to the cover.

## Desktop and widget extras

* **Mini player** (Windows): `MiniModeController` uses `window_manager`
  (380×112, always on top, no title bar, restores old bounds); `app.dart`
  keeps the router offstage and shows `MiniOverlay`.
* **Discord** (Windows): `DiscordIpc` talks to `\\.\pipe\discord-ipc-N` through own `kernel32` FFI bindings in a
  background isolate, retries every 15 s and reports back (`discordStatusProvider`). The application id is built in
  (`prismDiscordClientId`), Settings can override it. Status = clean title, cover + link from `CoverLookup` (iTunes, then Deezer,
  scored with `MatchScorer`, untagged songs with `fileNameMatches`), real timestamps, buttons, party while listening together. If Discord refuses the extras,
  it resends without them (`plainActivity`).
* **Android widget**: `PrismWidgetProvider.kt` (home_widget) shows title,
  artist, cover; its buttons send media-button intents to audio_service.
  `androidWidgetSyncProvider` pushes the current song.

## Releases

`tool/build_release.ps1` → `dist/`: Inno Setup installer (per user, no admin)
and APKs (universal + arm64 + armv7). The release keystore and passwords live
in `%USERPROFILE%\.prism-signing\` (or `PRISM_KEY_PROPERTIES`), never in the
project; without them release builds use the debug key.

## Testing

`flutter test --exclude-tags audio` – pure Dart/drift tests, no device needed:
* `playback_queue_test.dart` – shuffle/repeat/move/remove rules.
* `player_controller_test.dart` – controller ↔ engine contract with a fake engine
  (gapless feed, repeat-one, skip broken files, restore session).
* `library_test.dart` – in-memory SQLite: search, upsert/favorites, aggregates,
  incremental scanner with a fake tag reader, playlists CRUD/ordering/cascade.
* `theme_config_test.dart` – export/import round trip, clamping, bad files.
* `eq_test.dart` – biquad math, presets, mpv filter builder, Android mapping.
* `edit_decision_list_test.dart` – every edit op, output-time semantics,
  clamping, fades, A/B mapping, plan conversion, undo/redo, JSON.
* `export_command_test.dart` – FFmpeg graph/args per format.
* `stats_test.dart` – listen rule, smart playlist SQL on real SQLite, stats.
* `lyrics_test.dart` – LRC parsing, source order, LRCLIB via `MockClient`.
* `visualizer_test.dart` – FFT, band mapping, `.spc` round trip.
* `tools_test.dart` – track matching, duplicates, backup round trip, real MP3 tag write.
* `together_test.dart` – protocol, drift math, real relay over WebSockets.
* `discord_test.dart` – frames + a fake Discord named pipe (PowerShell).
* `online_matching_test.dart` – title cleaning, scoring (YouTube titles, VEVO /
  Topic channels, karaoke/nightcore/live, covers, typos, Cyrillic), import
  duplicates, link parser, CSV/JSON/M3U parsers.
* `online_services_test.dart` – match pipeline with fake services, HTTP
  retries / 429 / offline, OAuth refresh, Spotify/Deezer/YouTube/Apple parsing
  (mocked), YouTube web playlist reader, stream proxy vs a fake googlevideo,
  remote tracks + import jobs on SQLite.
* `extras_widgets_test.dart` – Wrapped cards, karaoke line, visualizer styles, together sheet.

`flutter test --tags audio` – **real audio** on Windows (needs the binaries in
`windows/third_party`). Signals are generated, rendered, then measured with
Goertzel (`test/support/wav.dart`):
* `platform/windows_engine_test.dart` – the real `JustAudioDeckEngine` +
  `MpvAudioEffects` on the full libmpv, output captured with `ao=pcm`: EQ
  matches the model, pitch, speed, live-preset clips + gain.
* `platform/ffmpeg_export_test.dart` – real exports: length, pitch (both
  engines), segment gain, fades, mp3/m4a, ebur128 parsing.
* `platform/mpv_probe_test.dart` – which FFmpeg filters a libmpv build has.

`flutter test --tags network` – **live services** (internet needed):
* `platform/youtube_stream_test.dart` – YouTube search → proxy → real engine →
  audible WAV; removed video → `failed` with a reason.
* `platform/live_matching_test.dart` – public Deezer playlist matched on YouTube.

## Performance

Benchmark: `integration_test/perf_test.dart` (real app + library, profile
mode) records frame build/raster times for idle, fling + wheel scrolling, tab
switching and a theme re-tint:

```
flutter drive --profile -d windows --driver=test_driver/perf_driver.dart --target=integration_test/perf_test.dart
```

Rules that came out of profiling (2026-11-01, raster avg went 7.3 → 2.5 ms idle,
9.2 → 3.0 ms scrolling, 0 missed frames):
* **No `BackdropFilter` by default.** `GlassPanel(backdrop: true)` only where
  real content scrolls under the glass (phone mini-player, nav bar). Blur over
  the soft background gradient is invisible but costs ~5 ms/frame.
* **Background** (`AnimatedGradientBackground`): ~20 fps timer instead of a
  per-frame ticker, paused when hidden, drawn at 1/8 size and upscaled, in its
  own `RepaintBoundary` next to (not around) the content.
* **No idle work**: the engine's 50 ms timer stops when paused and identical
  states are not re-emitted; the seek bar ticker runs only while playing.
* **Theme animation** rebuilds the whole tree each frame (~4 ms) → kept short.
* **Smooth wheel scrolling**: `SmoothScrollController` animates wheel notches;
  use `SmoothCustomScrollView` / `SmoothListView` / `SmoothScroll` for new
  vertical lists.
* Scanner writes 200 rows per batch (every batch re-runs the library queries).

## Code generation

```
dart run build_runner build
```
(freezed, json_serializable, drift). Generated files (`*.g.dart`,
`*.freezed.dart`) live next to their sources – regenerate after changing a
model or table.

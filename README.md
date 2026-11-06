# Prism

**English** · [Русский](README.ru.md)

A music player for Android and Windows, made for me and my friends: your own
music files, a gorgeous theme engine, an equalizer, an editor, synced lyrics and
listening together.

<!-- Screenshots: see "Taking screenshots" below; put files in docs/screenshots/ -->

## Install (for friends)

Downloads are on the [Releases page](https://github.com/kolommix/Prism/releases/latest).

### Windows 10/11
1. Download **`Prism-Setup-<version>.exe`**.
2. Run it. Windows may show "Windows protected your PC" (the installer isn't
   code-signed): click **More info → Run anyway**.
3. No admin rights needed; Prism installs for your user only. Start it from the
   Start menu or the desktop shortcut.
4. In Prism: **Add C:\Users\<you>\Music** (or choose another folder).

Uninstall: Settings → Apps → Prism. Your library and settings stay in
`%APPDATA%\com.kolommix\prism` (delete that folder for a clean slate).

### Android 7+
1. Download **`Prism-<version>-arm64-v8a.apk`** (almost every phone from the
   last ~8 years). Very old phone? Use `armeabi-v7a`. Not sure? Use the big
   `Prism-<version>.apk`, which works everywhere.
2. Open the file. Android asks to **allow installing apps from this source**
   (your browser or file manager): allow it, go back, tap **Install**.
3. Open Prism, allow **Music and audio** access, tap **Add Music folder**.
4. Optional: long-press the home screen → Widgets → **Prism** for the player widget.

Updates: install the new APK over the old one (same signing key, data is kept).

## New in 1.1
- **Russian and English**, following your system or Settings → Appearance → Language
- **New editor**: fast zoomable waveform with a minimap, drag segments to reorder, duplicate, loop, reverse, merge songs, speed 0.25x-4x and gradual ramps, per-part EQ and noise gate, crossfades with curve choice, auto-trim, remove silence, normalize, ringtones, exports to mp3 (CBR or VBR), m4a, wav and flac with tags and cover, overwrite with a backup
- **Smooth lyrics**: no more jumping, word-by-word timing when the file has it, per-song timing slider
- **Visualizer**: beat detection, ribbon, particles and a shader glow, sensitivity, low-power mode; on Android an optional live mode
- **Fix song info**: search MusicBrainz and iTunes, compare side by side, fix a whole album or folder
- **Yandex Music import** (experimental, see the limits below) and **playlist sharing** with a `liner://` code or a `.liner` file
- **Reorder**: select several songs, drag them together, move to top or bottom, sort per playlist with your own order kept
- **Stats**: new vs repeat, Wrapped as a story, save cards as pictures
- **Backgrounds**: mesh gradient, aurora, liquid blobs, starfield, rain, snow, film grain, gradient presets, your own picture or video, parallax, darken, battery saver; saved inside exported themes
- **Check for updates** in Settings → About

## Features
- Library: mp3 / flac / m4a / ogg / wav, tags + covers, instant search, albums,
  artists, folders, favorites, playlists, **smart playlists** (most played,
  recently added, genre, year, not played for…)
- **Listening stats** for a week to all time: time, plays, new songs, streaks, sessions, records, charts per day and
  per weekday × hour, top songs/artists/albums/genres, history, numbers about your library, and "Wrapped" cards
- Gapless playback or crossfade, queue editing, sleep timer, speed + pitch, A-B loop
- 10-band **equalizer** with presets, bass boost, preamp and a live curve
- **Synced lyrics**: `.lrc` files next to your songs, embedded lyrics, or
  lrclib.net, with a karaoke-style highlight. Tap a line to jump there.
- **Visualizer**: Bars, Mirror, Radial, Wave, VU meters, Waterfall and LED matrix (pick in Settings → Appearance)
- **Editor** (non-destructive): trim, cut, split, speed/pitch/volume per part,
  fades, undo/redo, A/B preview, export mp3/m4a/wav or play the edit live
- **Tag editor** (title, artist, album, genre, year, track #, cover; keeps a
  backup of the original), **duplicate finder**, **backup/restore** of settings,
  EQ, themes, playlists, favorites, smart playlists and edits
- **Listen together**: one person starts a session and shares a short code, from anywhere and with nothing to
  set up; friends play the same songs *from their own library* in sync
- **Animated backgrounds** (Settings → Appearance → Background): Matrix, Constellation and Ripple. They react to the
  mouse, clicks and the bass. Colors, speed, density, size, symbols, reactions and how solid the panels are: all yours
- **Seek bar styles**: Waveform, Ribbon, LED blocks, Tuner, Live spectrum, all moving with the music (can be turned off).
  Right-click the bar to switch
- **Finds missing covers, artists and albums** on Apple's and Deezer's public search (Settings → Library, can be turned
  off, can be undone). Only title and artist are sent; your files and your own tags stay as they are
- Themes: **black & white by default** (the cover glows grey behind everything and
  pulses with the bass in the full player), or colors, light/dark/AMOLED, corner radius, font, glass, animation
  speed, colors from the album art; share themes as `.prism-theme.json`
- **Online** (optional, each service on its own switch): import playlists from
  Spotify, YouTube / YouTube Music, SoundCloud, Deezer, Apple Music links, your
  accounts or files (CSV / JSON / M3U); songs are matched to your files first,
  then YouTube / SoundCloud, with a confidence badge and *Fix*. One search box
  for your library + online. YouTube playback and offline copies are *personal use only*
  (see **Online services** below)
- Android: background playback, lock screen, notification, home-screen widget
- Windows: media keys + Windows media overlay, tray icon, always-on-top **mini
  player**, optional **Discord status**

### Listen together
*Listen together* in the sidebar (or More in the player bar):
- **Anywhere**: *Start a session* and send the short code (like `K7QXA`). Your friend types it (a copied code is filled
  in by itself) and presses *Join*.
- **Same Wi-Fi**: friends also see your session in a list and join with one click. On Windows, allow Prism in the
  firewall prompt the first time.
- Everybody plays their own copy (matched by title + artist + length). A song you don't have is looked up on YouTube or
  SoundCloud if you turned those on. Prism doesn't stream audio between devices.
- Over the internet, messages go through a free public MQTT server (HiveMQ or EMQX, no account): song names, length and
  position, scrambled with the code. Don't want that? Settings → Listen together: turn it off (same Wi-Fi only) or run
  your own relay (`dart run tool/relay.dart`, port 47800) and enter `ws://<address>:47800/` there.

### Discord status (Windows)
Settings → Windows → *Discord status*. Shows the song, album art (looked up on Apple's and Deezer's public search:
Discord can't show covers from your PC), real progress, link buttons, and who you listen together with. Connects by
itself when Discord starts. Nothing to set up: Prism's Discord application is built in. Songs without tags only get a
cover when the file name clearly matches.

## Online services (optional)
Settings → **Online services**. Every service has its own switch; if one is
broken or not set up, everything else keeps working.

| What | Needs | Status |
|---|---|---|
| Import from files: CSV (Exportify, TuneMyMusic, any title/artist columns), JSON, M3U/M3U8 | nothing | ✅ |
| Import Deezer playlist/album links | nothing | ✅ |
| Import Apple Music playlist/album links | switch on (reads the public web page) | ✅ best effort, *personal use* |
| YouTube / YouTube Music: search, playlist links, **playback**, offline copies | switch on **YouTube extractor** | ✅ *personal use* |
| YouTube search/playlists via the official API | `youtube.apiKey` | needs your key |
| Your YouTube playlists + liked videos | Google OAuth client | needs your key |
| Spotify: your playlists, liked songs, saved albums (text only) | `spotify.clientId` | needs your key |
| SoundCloud: search, likes, playlists, playback | `soundcloud.clientId` (+ secret) | needs your key |

Prism **never plays Spotify, Deezer or Apple Music audio**. Imported songs are
matched: your own files first, then YouTube / SoundCloud (title + artist +
length). Each match shows a confidence (High / Medium / Low – check it) and
has a **Fix** button. Matching runs in the background, saves progress per song,
pauses when you go offline or a service limits you, and continues with
*Resume*. Duplicates inside one list are skipped (you can turn that off in
the preview).

### API keys
Keys live in a local file, never in the app or this repo. Settings → Online
services → **Create file** makes it (path shown there; template:
[`online_config.example.json`](online_config.example.json)), fill it in, tap **Reload**.
`online_config.json` is gitignored. Logins (tokens) are stored in the system
keychain (Windows Credential Manager / Android Keystore).

- **Spotify**: <https://developer.spotify.com/dashboard> → Create app → Web API,
  redirect URI `http://127.0.0.1:43821/callback` → copy the **Client ID**
  (no secret needed, Prism uses PKCE). Development Mode apps work for **at most
  5 people**: add your friends' Spotify e-mails under *User Management*. Spotify
  only lets such apps read playlists the user **owns or collaborates on** –
  for other playlists use Exportify / TuneMyMusic and import the CSV.
- **YouTube Data API** (optional, the extractor works without it):
  <https://console.cloud.google.com> → new project → enable *YouTube Data API v3*
  → Credentials → API key → `youtube.apiKey`. Free quota ≈ 100 searches/day.
  For your own playlists/likes: OAuth consent screen (External, Testing, add
  yourself as test user) → Credentials → OAuth client ID → *Desktop app* →
  `youtube.oauthClientId` + `youtube.oauthClientSecret`.
- **SoundCloud**: <https://soundcloud.com/you/apps> → register an app (SoundCloud
  may need to approve it), redirect URI `http://127.0.0.1:43822/callback` →
  `soundcloud.clientId` + `soundcloud.clientSecret`.

### Terms of service – what is allowed
| Service | What Prism does | Rules |
|---|---|---|
| Spotify | Web API, reads your library as text | Allowed for non-commercial apps; Development Mode = 5 users. No audio is ever taken from Spotify. **Personal use only.** |
| YouTube Data API | search, playlists, your likes (official) | Allowed with your key and quota. No audio in this API. |
| YouTube extractor | playback, keyless search, offline copies (youtube_explode_dart) | **Against YouTube's Terms** (no playback outside their player, no downloads). Off by default. **Personal use only** – don't share saved files; may break any time. |
| SoundCloud | official API: search, likes, playlists, streaming | Only tracks the uploader made streamable; credited and linked to SoundCloud; no offline copies. |
| Deezer | public API, playlist/album text | Non-commercial use. |
| Apple Music | reads the public playlist/album web page | No free API exists; scraping is a grey area. Off by default, best effort. **Personal use only.** |

The same notes are in the app (Settings → Online services → *What each service allows*).

### When something goes wrong
- *"YouTube asks to slow down"*: too many searches from your connection. Wait
  (minutes to an hour), then *Resume* the import. Prism already spaces searches out.
- *Offline*: local songs and offline copies still play; online search shows
  "offline" per service; imports pause and resume later.
- A streamed song that can't play (removed video, service switched off) is
  skipped with a short message.

## Honest limits
- **Yandex Music has no official API.** Prism uses the private one, so it can stop working any time, and it only answers from some countries (it answers `451` elsewhere). It was **never tested live**: the machine it was built on is blocked. If it fails, export to CSV or JSON and import the file.
- **Spotify** gives song names only; a small app works for 5 people. **YouTube** playback uses an unofficial extractor against their terms: off by default, for yourself, may break. **SoundCloud** and Google need your own keys. **Apple Music** reads web pages and can break.
- **Listen together** plays each person's own files; song names pass through a free public server unless you turn that off.
- **The Windows visualizer** analyses the file, so it doesn't hear EQ or speed, and doesn't work for streamed songs. **Android's live visualizer** asks for the microphone permission because Android requires that for reading audio; nothing is recorded.
- **Video backgrounds** are a silent 12 fps loop of the first 30 seconds.
- **The installer isn't code-signed**, so Windows warns about it. The app is about 260 MB on Windows because of the bundled audio tools.
- **Android** gets far less testing than Windows; see `STATUS.md`.

## Taking screenshots
- Windows: **Win + Shift + S** (snip) or **Alt + PrtScn** for the Prism window.
  The mini player (player bar → ⧉) makes a nice small shot.
- Android: **Power + Volume down**.
- Nice shots: full player with *Lyrics* and *Visualizer*, the Equalizer, the
  Stats cards, the Editor with a few edits, two themes (light + AMOLED).
- Save them as `docs/screenshots/<name>.png` and add them at the top of this
  README: `![Player](docs/screenshots/player.png)`.

## Publishing a version
See [docs/RELEASING.md](docs/RELEASING.md).

## License
GPL-3.0, see [LICENSE](LICENSE). Bundled tools keep their own licenses: [third_party/README.md](third_party/README.md).

## Build from source
The Windows build needs `libmpv-2.dll` and `ffmpeg.exe`: `powershell -File tool\fetch_windows_deps.ps1`.

```
dart run build_runner build
flutter run -d windows
powershell -ExecutionPolicy Bypass -File tool\build_release.ps1   # installer + APKs into dist\
```
Windows needs Visual Studio with "Desktop development with C++", Developer Mode
on (symlinks) and, for the installer, Inno Setup (`winget install JRSoftware.InnoSetup`).
Release APKs are signed with the key in `%USERPROFILE%\.prism-signing\`
(never in this folder); without it they get the debug key.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how everything fits together.

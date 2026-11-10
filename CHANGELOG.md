# Changelog

Every Prism version, newest first. The section of a version is also its GitHub release notes
(`.github/workflows/release.yml` reads it), so add one before tagging.

## 1.3.0 (2026-11-11)

### Updating is one click now
- **Windows: "Update now"** downloads the new version from Prism's GitHub, checks it, installs it over the old one and
  opens Prism again. Nothing to uninstall. (This once, install 1.3.0 by hand: older versions only open the page.)
- Running a newer installer over Prism is always an update: it skips the questions and keeps everything.
- Android: "Download update" gets the right APK for your phone.

### Imports
- **No more empty songs.** Some saved songs showed their full length but played a few seconds or nothing (YouTube
  stopped sending them part way). Every saved song is now checked, broken ones are thrown away and saved again from
  another upload. Broken songs from older versions are found and fixed by themselves after the update.
- **No more "you seem to be offline" while the internet works.** Prism now goes through the Windows proxy like your
  browser (VPN apps), retries a slow answer before pausing, and says when YouTube itself can't be reached on your
  network. Paused downloads carry on by themselves.

### Listen together, reworked
- Friends can play, pause, skip, seek and add songs for everyone (the host can turn that off).
- Everyone plays the very same YouTube upload for a song someone doesn't have.
- "Copy invite" message, and Prism offers to join when it finds a copied invite.
- You see who is listening, who is finding the song and who doesn't have it.

### Equalizer, reworked
- Its own place in the sidebar.
- One big curve with the song's spectrum behind it: drag points, scroll, double-click for 0 dB.
- Simple view (Bass, Mids, Treble) or Detailed view (10 bands, exact values), hold to compare, presets with pictures,
  one click to stop distortion.

### More
- **Drag songs or folders onto Prism** and they are in your library right away.
- **Prism colors** are the default look (black & white is still in the theme list).
- **New icon**: Prism's own blue prism.
- **Smoother on a busy PC**: Prism asks Windows for a little more processor time (Settings, Windows) and lightens its
  animations while the PC is overloaded.
- Plain-text copies of every info file for reading in Notepad.

## 1.2.5 (2026-11-10)

### Smoother
- **No more freezes when the next song starts.** Prism started its helper tools (FFmpeg, yt-dlp) in a way that made
  the whole app wait about half a second each time; they now start in the background.
- The "Up next" list follows the song that is playing.

### Imports
- **Work with an antivirus on.** Prism now ships the unpacked yt-dlp (the one-file version unpacks itself into Temp
  on every run, which antivirus programs often block) and checks secure connections with Windows' own certificates.
  If an antivirus still blocks it, Prism says so and names the folder to allow.

### Player
- **Volume is remembered** between starts. The sleep timer no longer puts it back to 100 %.

### Windows
- New installer: dark, in English and Russian, explains what is installed and where your data lives, and asks before
  deleting your library when you uninstall.
- Prism has its own icon everywhere (it still had Flutter's), sharp in the tray at any display scaling.
- The title bar no longer flashes white.

### New here
- A short tour on the first start: adding music, the player, playlists and imports. Settings, Welcome tour shows it again.

### Android
- Samsung phones with Exynos chips: Prism uses another graphics mode there, which should stop the crash in Backgrounds.

### Security and privacy
- Listen together no longer sends your songs' file paths (they contain your Windows user name) to the room.
- The local stream server only answers Prism itself; listen together ignores malformed messages.

## 1.2.4 (2026-11-09)

- **Sharper covers**: each cover is drawn at the size it is shown (the big player cover was stuck at 600 px),
  and online covers come in the largest size the service has (YouTube, Deezer, SoundCloud, Apple Music).
- **Duplicates, the easy way**: the Library shows how many duplicate songs you have; one tap opens them. Prism
  marks the best copy of each (lossless, then quality, then cover and tags), you can pick another, and one
  button cleans up: playlists, likes and listens move to the copy you keep, and the extra files can go to the
  Recycle Bin. It also finds copies named like "Artist - Song (Official Video)" without tags.
- **Artists are links**: tap a name under the song ("Rat Boy, IBDY" is two links) to see every song in your
  library with that artist, also songs they share with others.

## 1.2.3 (2026-11-09)

### Imports
- Imported songs really download again on Windows. YouTube now gives apps like Prism only the first part of most
  music videos, so Prism saves through yt-dlp (shipped with Prism, and it updates itself from its official page,
  checked against the official checksum). Songs that got stuck before are saved by themselves.
- Faster matching (two songs at a time), and no "Check" step: every found song is saved; a wrong one can still be fixed.
- When one upload is blocked, another upload of the same song is tried. Blocked songs no longer stop the rest.
- Cut-off downloads are cleaned up instead of staying as empty files.
- Android: saving still uses the old way, which YouTube mostly blocks.

### Windows
- Only one Prism at a time: starting it again brings the open window forward, also from the tray.
- The title bar is part of the app now (one surface, own minimize / maximize / close).
- New tray popup: cover, song, artist, previous / play / next, Show Prism, Quit.
- Quitting takes about a tenth of a second instead of several seconds.

### Player
- Visualizer reworked: three styles (Bars, Wave, Ring), and every bar now moves with the music.
- New volume control: rising bars, click / drag / wheel / arrow keys, shows the percent on hover.

### Android
- The media notification works again in release builds (its icon was stripped from the app, so Android
  refused it: no lock-screen controls, and some phones close such apps).
- Prism's own app icon and start screen instead of Flutter's logo.
- The background screen talks about touch and taps on phones, not the mouse.

### Fixes
- "Try it" on the background screen: Close no longer sits under the window buttons.
- Style chips with an icon no longer draw a checkmark on top of it (visualizer, own EQ presets).
- Quitting while songs are saving stops yt-dlp too, and cut-off yt-dlp files are never taken for a saved song.

## 1.2.1 (2026-11-07)
- Imports can save the songs they find as real files in your library (asked once, off by default).
- Discord shows a still bar when paused.
- Seek bar options: color, height, bars, thickness, brightness, reaction, playhead, times.
- Listen together: now-playing row, find missing songs on YouTube in one tap.

## 1.2.0 (2026-11-07)
- Privacy: removed a Windows plugin that started the system location watcher at every launch (nothing was ever
  read or sent). Settings → Privacy, `docs/PRIVACY.md`, and a check in every build.
- One Import screen: paste a link or drop a file, songs arrive while matching runs, re-import syncs.
- Real full screen on Windows.
- Remove a song from Prism without deleting the file (with undo).

## 1.1.2 (2026-11-07)
- Release build fix (Android SDK on the build server).

## 1.1.1 (2026-11-07)
- Release build fix (checks run on Windows).

## 1.1.0 (2026-11-07)
- First public release: English and Russian, rebuilt editor, lyrics timing, visualizer, song info fixer, Yandex
  import, playlist sharing, drag-and-drop order, statistics with story mode, backgrounds, update check.

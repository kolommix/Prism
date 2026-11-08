# Changelog

Every Prism version, newest first. The section of a version is also its GitHub release notes
(`.github/workflows/release.yml` reads it), so add one before tagging.

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

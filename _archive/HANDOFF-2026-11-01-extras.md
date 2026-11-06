# Prism handoff – "extras" task (2026-11-01, in progress)

User asked (pasted list): 1 synced lyrics (LRCLIB + .lrc, karaoke), 2 visualizer (styles), 3 listen together
(session code, minimal relay), 4 smart playlists + Wrapped stats, 5 Android widget + Windows mini overlay +
Discord RPC, 6 tag editor + duplicate finder + backup/restore, 7 signed APK + Windows installer (Inno/MSIX) +
README for friends. Analyze clean, test both platforms (user said: SKIP Android device test).

## Done (analyze clean, tests pass)
- DB schema v3: plays, smart_playlists (row class SmartPlaylistRow), lyrics_cache (LyricsRow).
- features/stats: ListenAccumulator (30 s / half rule), play recorder provider (watched in app.dart),
  smart playlists (rules → SQL, built-ins + editor dialog), Wrapped StatsPage (/playlists/stats). test/stats_test.dart
- features/lyrics: LRC parser, LyricsRepository (cache → .lrc → embedded → LRCLIB), karaoke LyricsView,
  setting onlineLyrics. LRCLIB API returned 502 at build time (outage) → tested with MockClient. test/lyrics_test.dart
- features/visualizer: FFmpeg decode + FFT in isolate, cached spectrum synced to position (no mic permission),
  4 styles, stage switch Cover/Lyrics/Visualizer in full player, Up next/Lyrics tab in side panel. test/visualizer_test.dart
- features/tools: TagWriter (backup copy + verify; OGG read-only), duplicates, BackupService (portable TrackRef
  matching), Settings → Tools section, song menu "Edit tags…", /settings/duplicates. test/tools_test.dart

## TODO
5. Listen together  6. Windows mini overlay + Discord RPC (needs user's Discord app id) + Android widget
7. Signed APK (keystore OUTSIDE GreatMemory: %USERPROFILE%\.prism-signing) + Inno Setup installer + README
8. full analyze/tests, perf benchmark re-run, docs (ARCHITECTURE/STATUS/CLAUDE.md), archive this handoff.

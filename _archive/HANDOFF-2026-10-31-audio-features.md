# Prism handoff – audio features (2026-10-31)

Task from user: (1) 10-band EQ + presets/custom presets, preamp, bass boost, live curve,
Android native effects via platform channel, Windows DSP in pipeline, one shared model/UI;
(2) non-destructive audio editor (EDL ops: trim, cut, split, segment speed w/ pitch kept,
pitch shift, fades, per-segment volume, undo/redo, A/B preview, export mp3/m4a/wav via FFmpeg,
save as new track, "apply edit as live preset"); (3) player speed + pitch, ReplayGain/loudness
normalization, A-B loop; (4) easy launcher (exe/installer). Tests for EDL logic. Verify EQ and
editor change sound on BOTH platforms; list limitations honestly.

## State: code half-way, NOT compiled since last changes
Last green point: `flutter analyze` clean + 61 tests pass, right after the EQ UI step.
After that I edited (not yet codegen'd / analyzed / built):
- `core/db/app_database.dart` -> schema v2 (loudness columns + `TrackEdits` table, migration)
- `library/domain/track.dart` (6 new loudness fields), `tag_reader.dart`, `audio_metadata_tag_reader.dart`
  (ReplayGain from ID3 TXXX + Vorbis), `library_scanner.dart`, `library_repository.dart` (saveLoudness etc.)
- `settings/domain/app_settings.dart` (+ normalization, autoAnalyzeLoudness)
- new: `core/ffmpeg/ffmpeg_runner.dart`, `audio_fx/domain/loudness.dart`,
  `audio_fx/application/loudness_analyzer.dart`, `player/application/playback_plan_service.dart`
- engine `reloadCurrent()` now swaps gain in place when clips unchanged
**First thing next session:** `dart run build_runner build`, `flutter analyze`, `flutter test --exclude-tags audio`, fix.

## Key findings (verified, don't redo)
- media-kit's libmpv (both `media_kit_libs_windows_audio` and `_video`) has NO usable FFmpeg
  filters (`anull` missing, equalizer fails to configure). Proven by `test/platform/mpv_probe_test.dart`.
- Fix (user approved): full libmpv + ffmpeg.exe from github.com/zhongfly/mpv-winbuild
  (linked on mpv.io) in `windows/third_party/{libmpv,ffmpeg}`, installed by `windows/CMakeLists.txt`.
  `media_kit_libs_windows_*` removed from pubspec. Probe with full DLL: EQ +12/-12 dB measured exactly,
  `volume`, `bass`, mpv `rubberband=pitch-scale` (1 kHz -> 1.25 kHz) all work.
  ffmpeg.exe has equalizer, bass, rubberband, atempo, asetrate, loudnorm, ebur128, afade, atrim, concat,
  libmp3lame, aac, pcm_s16le.
- Audio verification harness: `test/support/wav.dart` (tones, WAV read/write, Goertzel `toneDb`).
  mpv renders to WAV with `ao=pcm` + `ao-pcm-file`; EOF = log line "AO signaled EOF" (media_kit keep-open).
  Run: `flutter test --tags audio test/platform/mpv_probe_test.dart`.
- just_audio_media_kit vendored + patched in `third_party/` (global mpv props / af-command).
  `JustAudioMediaKit.pitch=false` (its pitch mode overwrites `af`), `prefetchPlaylist=true` (gapless was OFF before!).
- Android FFmpeg: `ffmpeg_kit_flutter_new_audio` 2.5.7 (sk3llo fork, maintained; arthenica original discontinued),
  vendored Android-only in `third_party/` (its Windows plugin downloads a 2nd ffmpeg). No rubberband ->
  Android pitch in exports via asetrate+aresample+atempo.
- Clipping sources: position relative to clip start on both backends (good for live presets).

## Done
- Shared EQ: `audio_fx/domain/eq_settings.dart` (10 bands 31..16k, Q 1.41, 12 presets), `eq_math.dart`
  (RBJ biquads = FFmpeg equalizer/bass), `audio_fx/application/eq_controller.dart` (prefs persistence, custom presets),
  UI `presentation/equalizer_page.dart` + animated draggable `eq_response_curve.dart`, route `/settings/equalizer`.
- Backends: `platform/audio_effects_backend.dart` (interface), `mpv_audio_effects.dart` (af builder, pure+tested),
  `android_audio_effects.dart` + `android/.../AudioFxPlugin.kt` (Equalizer/BassBoost/LoudnessEnhancer per session,
  debug-only `measure` via Visualizer FFT; RECORD_AUDIO only in `src/debug` manifest), MainActivity registers it.
- Engine rewrite `player/engine/just_audio_deck_engine.dart`: PlaybackPlan per track (clips via ClippingAudioSource,
  per-clip speed/pitch/gain, fades, trackGain), speed, pitch, preamp, A-B loop, effects attach.
  `player/domain/playback_plan.dart` (pure). Controller: setSpeed/setPitchSemitones/cycleAbLoop/clearAbLoop/setPreampDb/reloadCurrent,
  `PlaybackTuning` stream.
- Tests: `test/eq_test.dart` (14).

## TODO (in order)
1. Compile fix (above). Wire `PlaybackPlanService` + `FfmpegRunner` + `LoudnessAnalyzer` in `main.dart`
   (engine `planFor:`), providers, settings UI (normalization mode, "Analyze loudness" with progress).
2. Player UI: speed + pitch sheet, A-B loop button (full player + desktop bar), EQ button in full player.
3. Editor domain `features/editor/domain/`: EDL = list of ops (Trim, Cut, Split, SetSpeed(range), SetPitch(range),
   SetGain(range), FadeIn, FadeOut) in OUTPUT time, pure `apply(ops) -> timeline segments -> PlaybackPlan`,
   history with cursor (undo/redo), JSON; tests (required by user).
4. FFmpeg export command builder (pure, tested): per segment `atrim,asetpts,atempo(chain),rubberband|asetrate trick,volume`
   -> `concat` -> `afade` in/out -> mp3 (libmp3lame -q:a 2) / m4a (aac 256k) / wav. Save as new track (scan folder),
   store EDL in `track_edits`, "live preset" flag -> PlaybackPlanService.
5. Editor screen: waveform peaks via ffmpeg (`-ac 1 -ar 4000 -f s16le`), zoom/scroll, selection, ops toolbar,
   undo/redo, A/B preview (own AudioPlayer, plan-based), export dialog with progress.
6. Verification: Windows audio tests through MpvAudioEffects af string + ffmpeg export (measure tones/duration/pitch).
   Android: no device/emulator yet -> ask user to plug phone (USB debugging) or install emulator; integration test
   using `measure`.
7. Launcher: `tool/install_windows.ps1` (copy Release to %LOCALAPPDATA%\Programs\Prism + Start menu/desktop shortcuts).
   Desktop shortcut already made by hand (points at build\windows\x64\runner\Release\prism.exe).
8. Docs: ARCHITECTURE.md (audio fx, editor, binaries), STATUS.md, third_party/README.md says
   `windows/runner/CMakeLists.txt` -> correct to `windows/CMakeLists.txt`.

## Limitations found so far (tell user)
- Android Equalizer usually 5 bands (device-specific) -> 10-band curve sampled at native centres; BassBoost curve device-specific.
- Windows: changing EQ rebuilds mpv filter chain (debounced 80 ms; tiny click possible).
- Per-clip pitch in live presets is global (applies to both decks during a crossfade overlap).
- M4A ReplayGain tags not readable by the parser -> loudness measured with FFmpeg instead.
- Windows app grows ~220 MB (full libmpv 117 MB + ffmpeg.exe 105 MB).

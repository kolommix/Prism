# Vendored packages

## just_audio_media_kit (2.1.0, MIT)
Copied from pub.dev and patched (search for "Prism patch"):
- `JustAudioMediaKit.setGlobalProperty(key, value)` – sets an mpv property on
  every player (and on players created later). Used for the `af` filter chain
  (EQ, bass shelf, limiter, pitch) and `volume-max`.
- `MediaKitPlayer.setVolume` maps just_audio's linear volume to mpv's cubic
  volume scale (without it 0.5 = −18 dB instead of −6 dB; measured).
- `JustAudioMediaKit.commandAll([...])` – mpv command on every player
  (currently unused; kept for live `af-command`s).

Reason: just_audio keeps the media_kit `Player` private, and the EQ has to reach
the libmpv filter chain. Used via `dependency_overrides` in `pubspec.yaml`.

## windows/third_party (binaries, not in this folder)
- `libmpv/libmpv-2.dll` – full libmpv (FFmpeg with all filters + rubberband)
  from https://github.com/zhongfly/mpv-winbuild (release 2026-10-30-8e5a96fc45,
  linked from https://mpv.io/installation). Replaces media-kit's slim libmpv,
  which has no FFmpeg audio filters.
- `ffmpeg/ffmpeg.exe` – same release (`ffmpeg-x86_64-git-17a4a474f`), used by
  the editor export, waveform peaks and loudness analysis.
Both are copied next to `prism.exe` by `windows/CMakeLists.txt` (install step).

## ffmpeg_kit_flutter_new_audio (2.5.7, LGPL-3.0)
Maintained fork (sk3llo) of the retired arthenica ffmpeg-kit. Copied with its
pubspec reduced to the Android platform; Android binaries come from Maven
Central (com.antonkarpenko:ffmpeg-kit-audio). Used for export, waveform
peaks and loudness analysis on Android. The audio variant has lame/AAC but no
rubberband (GPL), so Android exports pitch-shift with asetrate+atempo.


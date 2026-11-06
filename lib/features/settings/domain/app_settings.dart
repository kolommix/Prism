import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/theme/theme_config.dart';
import '../../audio_fx/domain/loudness.dart';
import '../../background/domain/background_config.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

/// All user preferences (persisted as one JSON blob).
@freezed
abstract class AppSettings with _$AppSettings {
  const AppSettings._();

  const factory AppSettings({
    @Default(ThemeConfig()) ThemeConfig theme,

    /// Asks GitHub for a newer version when the app starts, at most once a day.
    @Default(true) bool autoCheckUpdates,

    /// App language: '' = same as the system, 'en', 'ru'.
    @Default('') String localeCode,

    /// Turns most animations off (also honoured: the OS accessibility flag).
    @Default(false) bool reduceMotion,

    /// 0 = gapless, otherwise crossfade length in seconds.
    @Default(0) int crossfadeSeconds,

    /// Windows: closing the window keeps playing in the tray.
    @Default(true) bool closeToTray,

    /// Loudness normalisation (ReplayGain tags or Prism's own measurement).
    @Default(NormalizationMode.off) NormalizationMode normalization,

    /// Measure loudness in the background for tracks without ReplayGain tags.
    @Default(true) bool autoAnalyzeLoudness,

    /// Look up lyrics on lrclib.net (sends title/artist/album/duration only).
    @Default(true) bool onlineLyrics,

    /// Find missing covers, artists and albums online (sends title and artist
    /// to Apple's and Deezer's public search). Files are never changed.
    @Default(true) bool autoFindInfo,

    /// Visualizer style in the full player.
    @Default('bars') String visualizerStyle,

    /// How strongly the visualizer reacts, 0.5..2.
    @Default(1.0) double visualizerSensitivity,

    /// 30 fps and fewer details.
    @Default(false) bool visualizerLowPower,

    /// Android: real-time FFT of what is playing (needs the microphone
    /// permission). Off = analysis of the file, which needs no permission.
    @Default(false) bool visualizerLive,

    /// A `SeekBarStyle` name.
    @Default('waveform') String seekBarStyle,

    /// Every seek bar style moves with the music (analyses each song once).
    @Default(true) bool liveSeekBar,

    /// Cover or animated background, all of its settings.
    @Default(BackgroundConfig()) BackgroundConfig background,

    /// Listen together through your own relay: `ws://` / `wss://` URL
    /// (`dart run tool/relay.dart`). Empty = the free public server.
    @Default('') String relayUrl,

    /// Sessions also work over the internet (song names pass through a free
    /// public message server, scrambled with the session code). Off = same
    /// Wi-Fi only, nothing leaves the network.
    @Default(true) bool togetherInternet,

    /// Name friends see in a session; empty = the computer's name.
    @Default('') String togetherName,

    /// Windows: show "Listening to …" on Discord.
    @Default(false) bool discordPresence,

    /// Overrides the app id built into Prism; empty = the built-in one.
    @Default('') String discordClientId,

    /// Look up album art and links for the status (sends title + artist to
    /// Apple's and Deezer's public search).
    @Default(true) bool discordCovers,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);

  Duration get crossfade => Duration(seconds: crossfadeSeconds);
}

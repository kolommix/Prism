import '../../../l10n/l10n.dart';

/// Looks of the seek bar in the player bar and the full players.
enum SeekBarStyle {
  waveform,
  ribbon,
  led,
  tuner,
  live;

  String get label => switch (this) {
        SeekBarStyle.waveform => l10n.waveform,
        SeekBarStyle.ribbon => l10n.ribbon,
        SeekBarStyle.led => l10n.ledBlocks,
        SeekBarStyle.tuner => l10n.tuner,
        SeekBarStyle.live => l10n.liveSpectrum,
      };

  String get description => switch (this) {
        SeekBarStyle.waveform => l10n.barsWithABrightTrailBehind,
        SeekBarStyle.ribbon => l10n.aLineThatWavesWhileThe,
        SeekBarStyle.led => l10n.aHiFiMeterMadeOf,
        SeekBarStyle.tuner => l10n.aRadioDialWithANeedle,
        SeekBarStyle.live => l10n.theWholeBarIsASpectrum,
      };
  /// Needs frames while playing, not only when the playhead moves a pixel.
  bool get animated => this == ribbon || this == live;

  static SeekBarStyle parse(String? name) =>
      values.firstWhere((s) => s.name == name, orElse: () => waveform);
}

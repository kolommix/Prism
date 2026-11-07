import '../../../l10n/l10n.dart';

/// What the user changed about the seek bar, the same for every style.
class SeekBarLook {
  const SeekBarLook({
    this.color,
    this.size = 1,
    this.density = 1,
    this.thickness = 1,
    this.dim = 0.18,
    this.react = 1,
    this.head = true,
    this.times = true,
  });

  /// ARGB, null = the theme's color.
  final int? color;
  final double size, density, thickness, dim, react;
  final bool head, times;

  /// Everything still as it comes.
  bool get isDefault => this == const SeekBarLook();

  @override
  bool operator ==(Object other) =>
      other is SeekBarLook &&
      other.color == color &&
      other.size == size &&
      other.density == density &&
      other.thickness == thickness &&
      other.dim == dim &&
      other.react == react &&
      other.head == head &&
      other.times == times;

  @override
  int get hashCode => Object.hash(color, size, density, thickness, dim, react, head, times);
}

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

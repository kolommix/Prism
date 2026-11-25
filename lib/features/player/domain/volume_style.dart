import '../../../l10n/l10n.dart';

/// How the volume control in the player bar looks.
enum VolumeStyle {
  /// A thin line with a round knob: the level is easy to see and grab.
  line,

  /// A thick rounded bar that fills up.
  pill,

  /// The staircase of thin bars (the first look).
  bars;

  String get label => switch (this) {
        VolumeStyle.line => l10n.volumeStyleLine,
        VolumeStyle.pill => l10n.volumeStylePill,
        VolumeStyle.bars => l10n.volumeStyleBars,
      };

  static VolumeStyle parse(String s) => values.asNameMap()[s] ?? line;
}

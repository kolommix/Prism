import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../l10n/l10n.dart';
part 'background_config.freezed.dart';
part 'background_config.g.dart';

/// Which background runs behind the app.
enum BackgroundStyle {
  cover,
  mesh,
  aurora,
  blobs,
  gradient,
  starfield,
  rain,
  snow,
  grain,
  matrix,
  constellation,
  ripple,
  image,
  video;

  String get label => switch (this) {
        BackgroundStyle.cover => l10n.cover,
        BackgroundStyle.mesh => l10n.bgMesh,
        BackgroundStyle.aurora => l10n.bgAurora,
        BackgroundStyle.blobs => l10n.bgBlobs,
        BackgroundStyle.gradient => l10n.bgGradient,
        BackgroundStyle.starfield => l10n.bgStarfield,
        BackgroundStyle.rain => l10n.bgRain,
        BackgroundStyle.snow => l10n.bgSnow,
        BackgroundStyle.grain => l10n.bgGrain,
        BackgroundStyle.matrix => l10n.matrix,
        BackgroundStyle.constellation => l10n.constellation,
        BackgroundStyle.ripple => l10n.ripple,
        BackgroundStyle.image => l10n.bgImage,
        BackgroundStyle.video => l10n.bgVideo,
      };

  String get description => switch (this) {
        BackgroundStyle.cover => l10n.theCurrentCoverBlurredAndGrey,
        BackgroundStyle.mesh => l10n.bgMeshDesc,
        BackgroundStyle.aurora => l10n.bgAuroraDesc,
        BackgroundStyle.blobs => l10n.bgBlobsDesc,
        BackgroundStyle.gradient => l10n.bgGradientDesc,
        BackgroundStyle.starfield => l10n.bgStarfieldDesc,
        BackgroundStyle.rain => l10n.bgRainDesc,
        BackgroundStyle.snow => l10n.bgSnowDesc,
        BackgroundStyle.grain => l10n.bgGrainDesc,
        BackgroundStyle.matrix => l10n.fallingSymbolsTheyLightUpAnd,
        BackgroundStyle.constellation => l10n.driftingStarsJoinedByLinesThe,
        BackgroundStyle.ripple => l10n.aGridOfDotsLikeA,
        BackgroundStyle.image => l10n.bgImageDesc,
        BackgroundStyle.video => l10n.bgVideoDesc,
      };

  /// Uses the symbol, line or dot settings (the original three).
  bool get hasDetailSettings => this == matrix || this == constellation || this == ripple;

  static BackgroundStyle parse(String? name) =>
      values.firstWhere((s) => s.name == name, orElse: () => cover);
}

/// A still gradient: original colors, made for this app.
class GradientPreset {
  const GradientPreset(this.id, this.colors);
  final String id;
  final List<int> colors;

  String get label => switch (id) {
        'dusk' => l10n.bgPresetDusk,
        'ocean' => l10n.bgPresetOcean,
        'forest' => l10n.bgPresetForest,
        'ember' => l10n.bgPresetEmber,
        'ice' => l10n.bgPresetIce,
        'graphite' => l10n.bgPresetGraphite,
        'rose' => l10n.bgPresetRose,
        _ => l10n.bgPresetNight,
      };

  static GradientPreset parse(String? id) => gradientPresets.firstWhere((g) => g.id == id, orElse: () => gradientPresets.first);
}

const gradientPresets = [
  GradientPreset('dusk', [0xFF1B1533, 0xFF4A2A5E, 0xFFB5566B]),
  GradientPreset('ocean', [0xFF06202E, 0xFF0D4A5E, 0xFF2A8C8F]),
  GradientPreset('forest', [0xFF0B1A12, 0xFF17402C, 0xFF4F7A4A]),
  GradientPreset('ember', [0xFF1C0D0A, 0xFF5A1E12, 0xFFC4602B]),
  GradientPreset('ice', [0xFF10202E, 0xFF35566E, 0xFF9CC3D5]),
  GradientPreset('graphite', [0xFF0E0E10, 0xFF26262B, 0xFF4A4A52]),
  GradientPreset('rose', [0xFF22101C, 0xFF662A49, 0xFFD9819A]),
  GradientPreset('night', [0xFF05060F, 0xFF10163A, 0xFF2B2F77]),
];

/// Symbols for the Matrix rain.
enum MatrixGlyphs {
  katakana,
  binary,
  hex,
  latin,
  notes,
  custom;

  String get label => switch (this) {
        MatrixGlyphs.katakana => l10n.katakana,
        MatrixGlyphs.binary => l10n.x0And1,
        MatrixGlyphs.hex => l10n.hex,
        MatrixGlyphs.latin => l10n.letters,
        MatrixGlyphs.notes => l10n.musicNotes,
        MatrixGlyphs.custom => l10n.myOwnText,
      };
  static MatrixGlyphs parse(String? name) =>
      values.firstWhere((s) => s.name == name, orElse: () => katakana);
}

/// How the Ripple grid draws its points.
enum RippleShape {
  dots,
  dashes,
  plus;

  String get label => switch (this) {
        RippleShape.dots => l10n.dots,
        RippleShape.dashes => l10n.dashes,
        RippleShape.plus => l10n.plusSigns,
      };
  static RippleShape parse(String? name) => values.firstWhere((s) => s.name == name, orElse: () => dots);
}

/// Settings of one animated background. Every style keeps its own set.
@freezed
abstract class BgParams with _$BgParams {
  const BgParams._();

  const factory BgParams({
    /// Use the theme's colors instead of [color] and [accent].
    @Default(true) bool followTheme,
    @Default(0xFF35E07A) int color,

    /// Heads of the rain, links to the mouse, wave crests.
    @Default(0xFFD9FFE6) int accent,

    /// 0.1..1
    @Default(0.7) double brightness,

    /// 0.2..3
    @Default(1.0) double speed,

    /// 0.3..2: how much is on screen.
    @Default(1.0) double density,

    /// 0.5..2: symbol / dot size.
    @Default(1.0) double size,

    /// 0.2..2: trail length (Matrix), link length (Constellation), wave width (Ripple).
    @Default(1.0) double reach,

    /// 0..2: reaction to the mouse.
    @Default(1.0) double mouse,

    /// 0..2: reaction to the bass (analyses each song once when above 0).
    @Default(0.8) double music,

    /// Matrix: a [MatrixGlyphs] name.
    @Default('katakana') String glyphs,

    /// Matrix: the symbols for [MatrixGlyphs.custom].
    @Default('PRISM') String customGlyphs,

    /// Ripple: a [RippleShape] name.
    @Default('dots') String shape,
  }) = _BgParams;

  factory BgParams.fromJson(Map<String, dynamic> json) => _$BgParamsFromJson(json);

  /// Hand-edited or restored files can't break the painters.
  BgParams sanitized() => copyWith(
        brightness: brightness.clamp(0.1, 1.0),
        speed: speed.clamp(0.2, 3.0),
        density: density.clamp(0.3, 2.0),
        size: size.clamp(0.5, 2.0),
        reach: reach.clamp(0.2, 2.0),
        mouse: mouse.clamp(0.0, 2.0),
        music: music.clamp(0.0, 2.0),
      );
}

const matrixDefaults = BgParams(followTheme: false, brightness: 0.75);
const constellationDefaults = BgParams();
const rippleDefaults = BgParams();

/// The whole background choice, stored inside AppSettings.
@freezed
abstract class BackgroundConfig with _$BackgroundConfig {
  const BackgroundConfig._();

  const factory BackgroundConfig({
    /// A [BackgroundStyle] name.
    @Default('cover') String style,
    @Default(matrixDefaults) BgParams matrix,
    @Default(constellationDefaults) BgParams constellation,
    @Default(rippleDefaults) BgParams ripple,

    /// 0.15..1: how solid the panels are while an animated background runs.
    @Default(0.4) double panelOpacity,

    /// The blurred cover stays visible under the animation.
    @Default(false) bool showCover,

    /// Frames per second, 0 = as fast as the screen (the smoothest).
    @Default(0) int frameRate,

    /// Panels blur what is behind them, like frosted glass.
    @Default(true) bool frosted,

    /// 0..1 how out of focus the animation is, so it stays in the background.
    @Default(0.2) double softness,

    /// 0.2..1 how strongly the animation shows at all.
    @Default(1.0) double strength,

    /// Stop the animation while the music is paused (saves power).
    @Default(false) bool onlyWhilePlaying,

    /// Settings of the styles without a field of their own, by style name.
    @Default(<String, BgParams>{}) Map<String, BgParams> extra,

    /// A [GradientPreset] id.
    @Default('dusk') String gradientPreset,

    /// Our copy of the user's picture, and the folder of their video's frames.
    @Default('') String imagePath,
    @Default('') String videoDir,

    /// 0..0.9 black over the background, so text stays readable.
    @Default(0.0) double dim,

    /// The background shifts a little with the mouse.
    @Default(false) bool parallax,

    /// 20 fps, fewer details, no blur, no frosted panels.
    @Default(false) bool batterySaver,
  }) = _BackgroundConfig;

  factory BackgroundConfig.fromJson(Map<String, dynamic> json) => _$BackgroundConfigFromJson(json);

  BackgroundStyle get current => BackgroundStyle.parse(style);

  bool get isLive => current != BackgroundStyle.cover;

  BgParams paramsFor(BackgroundStyle s) => switch (s) {
        BackgroundStyle.matrix => matrix,
        BackgroundStyle.constellation => constellation,
        BackgroundStyle.ripple => ripple,
        BackgroundStyle.cover => const BgParams(),
        _ => extra[s.name] ?? defaultsFor(s),
      };

  BackgroundConfig withParams(BackgroundStyle s, BgParams p) => switch (s) {
        BackgroundStyle.matrix => copyWith(matrix: p),
        BackgroundStyle.constellation => copyWith(constellation: p),
        BackgroundStyle.ripple => copyWith(ripple: p),
        BackgroundStyle.cover => this,
        _ => copyWith(extra: {...extra, s.name: p}),
      };

  /// Frames per second that apply, 0 = as fast as the screen.
  int get effectiveFrameRate => batterySaver ? 20 : frameRate;

  static BgParams defaultsFor(BackgroundStyle s) => switch (s) {
        BackgroundStyle.matrix => matrixDefaults,
        BackgroundStyle.constellation => constellationDefaults,
        BackgroundStyle.ripple => rippleDefaults,
        _ => const BgParams(),
      };
}

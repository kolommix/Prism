import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/widgets/artwork.dart';
import '../../audio_fx/application/loudness_controller.dart';
import '../../library/domain/track.dart';
import '../../player/application/player_providers.dart';
import '../../player/presentation/widgets/live_position.dart';
import '../../settings/application/settings_controller.dart';
import '../../../core/motion/busy_pc.dart';
import '../data/live_fft.dart';
import '../data/spectrum_service.dart';
import '../domain/spectrum.dart';
import 'visualizer_painter.dart';
import '../../../l10n/l10n.dart';


final spectrumServiceProvider = FutureProvider<SpectrumService>((ref) async {
  final cache = await getApplicationCacheDirectory();
  return SpectrumService(ffmpeg: ref.watch(ffmpegRunnerProvider), cacheDir: Directory(p.join(cache.path, 'spectrum')));
});

final spectrumProvider = FutureProvider.family<Spectrum?, Track>((ref, t) async {
  final service = await ref.watch(spectrumServiceProvider.future);
  return service.spectrumFor(t);
});

/// The visualizer, synced to playback: the cover turns slowly in the middle
/// like a record and swells on the beat, the spectrum fans out around it
/// (see [VisualizerPainter]). Frames are only made while playing; the low
/// power mode (or a busy PC) moves it at most 30 times a second.
class Visualizer extends ConsumerStatefulWidget {
  const Visualizer({super.key});

  @override
  ConsumerState<Visualizer> createState() => _VisualizerState();
}

class _VisualizerState extends ConsumerState<Visualizer> with SingleTickerProviderStateMixin {
  late final LivePosition _pos = LivePosition(this)..addListener(_onPos);
  final _viz = VizAnalyser();
  final _sinceStep = Stopwatch()..start();
  LiveFft? _live;
  bool _liveFailed = false;

  // What the next step reads (set by build).
  BandSource? _source;
  double _sensitivity = 1;
  bool _lowPower = false;
  bool _still = false;

  void _onPos() {
    final source = _source;
    if (source == null) return;
    if (_lowPower && _sinceStep.elapsedMilliseconds < 32) return;
    _sinceStep.reset();
    _viz.update(source, _pos.value, sensitivity: _sensitivity, still: _still);
  }

  @override
  void dispose() {
    _pos.dispose();
    _viz.dispose();
    _live?.stop();
    super.dispose();
  }

  /// Starts or stops Android's live FFT to match the setting.
  void _syncLive(bool want) {
    if (!LiveFft.supported || _liveFailed) return;
    if (want && _live == null) {
      final live = LiveFft();
      _live = live;
      live.start().then((ok) {
        if (!mounted) return;
        if (!ok) _liveFailed = true;
        setState(() {});
      });
    } else if (!want && _live != null) {
      _live?.stop();
      _live = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(currentTrackProvider);
    final state = ref.watch(engineStateProvider).value;
    final speed = ref.watch(tuningProvider.select((t) => t.value?.speed ?? 1));
    final spectrum = track == null ? null : ref.watch(spectrumProvider(track));
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant);
    final picked = ref.watch(settingsProvider.select((s) => (s.visualizerSensitivity, s.visualizerLowPower, s.visualizerLive)));
    _sensitivity = picked.$1;
    // A busy PC gets the light mode too (see BusyMeter).
    _lowPower = picked.$2 || ref.watch(busyPcProvider);
    _still = !context.motion.decorative;
    _syncLive(picked.$3);

    final live = _live;
    final BandSource? source = live != null && live.running
        ? live
        : track != null && track.sourceId == 'local'
            ? spectrum?.value
            : null;
    final first = source != null && !identical(source, _source);
    _source = source;
    if (state != null || first) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return; // may be gone by then (stage switch)
        if (state != null) _pos.sync(state, speed: speed);
        // Draw something right away, also when paused.
        if (first) _onPos();
      });
    }

    if (source != null && track != null) return _disc(track, scheme.primary);
    if (track != null && track.sourceId != 'local') {
      return Center(child: Text(l10n.theVisualizerWorksWithSongsFrom, style: muted, textAlign: TextAlign.center));
    }
    return spectrum?.when(
          loading: () => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.analysingTheSong),
          ])),
          error: (e, _) => Center(child: Text(l10n.couldNotAnalyseThisSong, style: muted, textAlign: TextAlign.center)),
          data: (_) => Center(child: Text(l10n.theVisualizerNeedsFfmpegWhichIs, style: muted, textAlign: TextAlign.center)),
        ) ??
        const SizedBox.shrink();
  }

  Widget _disc(Track track, Color ink) {
    return LayoutBuilder(
      builder: (context, c) {
        final side = math.min(c.maxWidth, c.maxHeight);
        final d = side * VisualizerPainter.coverShare * 2;
        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: VisualizerPainter(viz: _viz, ink: ink, led: context.look.led, lowPower: _lowPower),
                ),
              ),
            ),
            // The cover turns like a record; only the layer moves, the
            // picture is not drawn again.
            AnimatedBuilder(
              animation: _viz,
              builder: (context, child) => Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationZ(_viz.spin)..scaleByDouble(1 + 0.04 * _viz.pulse, 1 + 0.04 * _viz.pulse, 1, 1),
                child: child,
              ),
              child: RepaintBoundary(
                child: SizedBox.square(
                  dimension: d,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Artwork(
                        path: track.artworkPath,
                        size: d,
                        borderRadius: BorderRadius.circular(d / 2),
                        seed: track.album,
                      ),
                      // The record's hole.
                      Container(
                        width: d * 0.09,
                        height: d * 0.09,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(color: ink.withValues(alpha: 0.35), width: 1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Makes the big cover breathe with the music: it swells a little on bass
/// hits and a soft halo behind it glows with the overall level.
///
/// Uses the same pre-computed spectrum as the visualizer. Frames are only
/// produced while playing (the position ticker stops on pause); songs
/// without a spectrum (streamed, still analysing) show the plain child.
class BeatPulse extends ConsumerStatefulWidget {
  const BeatPulse({super.key, required this.child, required this.radius});

  final Widget child;
  final BorderRadius radius;

  @override
  ConsumerState<BeatPulse> createState() => _BeatPulseState();
}

class _BeatPulseState extends ConsumerState<BeatPulse> with SingleTickerProviderStateMixin {
  late final LivePosition _pos = LivePosition(this)..addListener(_update);
  final _bass = ValueNotifier<double>(0);
  final _level = ValueNotifier<double>(0);
  final _raw = Float32List(256);
  final _clock = Stopwatch()..start();
  Spectrum? _spectrum;

  void _update() {
    final s = _spectrum;
    if (s == null || s.bands == 0) return;
    s.sample(_pos.value, _raw);
    final lows = math.max(1, s.bands ~/ 8);
    var bass = 0.0, all = 0.0;
    for (var i = 0; i < s.bands; i++) {
      if (i < lows) bass += _raw[i];
      all += _raw[i];
    }
    bass /= lows;
    all /= s.bands;
    // Only the part above a floor counts, so quiet passages stay calm; fast
    // attack, slow release like a VU meter.
    final b = ((bass - 0.45) / 0.55).clamp(0.0, 1.0);
    final l = ((all - 0.25) / 0.6).clamp(0.0, 1.0);
    // Settles by time, not by frame: the same at 60 or 120 fps.
    final frames = math.min(0.1, _clock.elapsedMicroseconds / 1e6) * 60;
    _clock
      ..reset()
      ..start();
    final keepBass = math.pow(0.85, frames).toDouble(), keepLevel = math.pow(0.92, frames).toDouble();
    _bass.value = b > _bass.value ? b : _bass.value * keepBass + b * (1 - keepBass);
    _level.value = l > _level.value ? l : _level.value * keepLevel + l * (1 - keepLevel);
  }

  @override
  void dispose() {
    _pos.dispose();
    _bass.dispose();
    _level.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(currentTrackProvider);
    final decorative = context.motion.decorative;
    final spectrum = track == null || !decorative ? null : ref.watch(spectrumProvider(track)).value;
    if (!identical(spectrum, _spectrum)) {
      _spectrum = spectrum;
      if (spectrum == null) {
        _bass.value = 0;
        _level.value = 0;
      }
    }
    final state = ref.watch(engineStateProvider).value;
    final speed = ref.watch(tuningProvider.select((t) => t.value?.speed ?? 1));
    // Settle back when paused (the ticker stops, so decay here once).
    if (state != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _pos.sync(state, speed: speed);
        if (!state.playing) {
          _bass.value = 0;
          _level.value = 0;
        }
      });
    }
    final glow = Theme.of(context).colorScheme.onSurface;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _HaloPainter(level: _level, color: glow, radius: widget.radius)),
            ),
          ),
        ),
        ValueListenableBuilder<double>(
          valueListenable: _bass,
          builder: (context, b, child) => Transform.scale(scale: 1 + 0.035 * b, child: child),
          child: RepaintBoundary(child: widget.child),
        ),
      ],
    );
  }
}

class _HaloPainter extends CustomPainter {
  _HaloPainter({required this.level, required this.color, required this.radius}) : super(repaint: level);

  final ValueNotifier<double> level;
  final Color color;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final v = level.value;
    if (v <= 0.01) return;
    final rect = Offset.zero & size;
    final spread = size.shortestSide * (0.06 + 0.12 * v);
    // Rounded light behind the cover; the blur makes it a soft halo.
    canvas.drawRRect(
      radius.toRRect(rect.inflate(spread * 0.4)),
      Paint()
        ..color = color.withValues(alpha: 0.04 + 0.12 * v)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, spread),
    );
  }

  @override
  bool shouldRepaint(_HaloPainter old) => old.color != color || old.radius != radius;
}

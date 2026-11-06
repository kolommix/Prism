import 'dart:math' as math;

import 'timeline.dart';

/// Output formats the editor can export.
enum ExportFormat {
  mp3('mp3'),
  m4a('m4a'),
  wav('wav'),
  flac('flac');

  const ExportFormat(this.extension);
  final String extension;

  bool get holdsCover => this != ExportFormat.wav;

  static ExportFormat? ofPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0) return null;
    final ext = path.substring(dot + 1).toLowerCase();
    return values.where((f) => f.extension == ext).firstOrNull;
  }
}

/// How pitch shifting is rendered.
enum PitchEngine {
  /// FFmpeg's `rubberband` filter (best quality; Windows ffmpeg.exe has it).
  rubberband,

  /// `asetrate` + `aresample` + `atempo` (works in every FFmpeg build, used
  /// with the Android FFmpegKit audio package which has no rubberband).
  resample,
}

/// What the file should be like: quality, and tags and cover to carry over or
/// replace.
class ExportSettings {
  const ExportSettings({
    this.mp3Vbr = true,
    this.mp3VbrQuality = 2,
    this.mp3Kbps = 320,
    this.m4aKbps = 256,
    this.wavBits = 16,
    this.flacLevel = 5,
    this.keepMetadata = true,
    this.tags = const {},
    this.coverPath,
    this.removeCover = false,
    this.applyGlobalEq = false,
  });

  final bool mp3Vbr;

  /// LAME `-q:a`: 0 = best (about 245 kbps), 9 = smallest.
  final int mp3VbrQuality;
  final int mp3Kbps;
  final int m4aKbps;
  final int wavBits;
  final int flacLevel;

  /// Copy the source's tags and cover into the new file.
  final bool keepMetadata;

  /// FFmpeg metadata keys (`title`, `artist`, `album`, `date`, `genre`): they
  /// win over what was carried over. An empty value removes the tag.
  final Map<String, String> tags;
  final String? coverPath;
  final bool removeCover;
  final bool applyGlobalEq;
}

String _n(double v) => v.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
String _sec(Duration d) => _n(d.inMicroseconds / 1e6);

/// `atempo` accepts 0.5..100 per instance, so slower factors are chained.
List<String> atempoChain(double factor) {
  if ((factor - 1).abs() < 1e-6) return const [];
  final out = <String>[];
  var f = factor;
  while (f < 0.5) {
    out.add('atempo=0.5');
    f /= 0.5;
  }
  out.add('atempo=${_n(f)}');
  return out;
}

/// Filters that shift pitch by [semitones] without changing tempo.
List<String> pitchFilters(double semitones, PitchEngine engine) {
  if (semitones.abs() < 1e-6) return const [];
  final ratio = math.pow(2, semitones / 12).toDouble();
  return switch (engine) {
    PitchEngine.rubberband => ['rubberband=pitch=${_n(ratio)}'],
    // Resample to a known rate, play it faster/slower (shifts pitch + tempo),
    // then undo the tempo change with atempo.
    PitchEngine.resample => [
        'aresample=48000',
        'asetrate=${_n(48000 * ratio)}',
        'aresample=48000',
        ...atempoChain(1 / ratio),
      ],
  };
}

const _common = 'aformat=sample_fmts=fltp:sample_rates=48000:channel_layouts=stereo';

/// Everything after the tempo in a segment's chain.
List<String> _segmentEffects(Segment s, Duration outputLength, PitchEngine engine) => [
      ...pitchFilters(s.pitchSemitones, engine),
      // FFmpeg's default ratio of 2 barely does anything: this one really closes.
      if (s.gateDb != null) 'agate=threshold=${_n(math.pow(10, s.gateDb! / 20).toDouble())}:ratio=20:range=0.003:attack=5:release=120',
      if (s.eqLowDb != 0) 'bass=g=${_n(s.eqLowDb)}:f=200',
      if (s.eqMidDb != 0) 'equalizer=f=1000:t=o:w=1.5:g=${_n(s.eqMidDb)}',
      if (s.eqHighDb != 0) 'treble=g=${_n(s.eqHighDb)}:f=4000',
      if (s.gainDb.abs() > 1e-6) 'volume=volume=${_n(s.gainDb)}dB',
      if (s.fadeIn > Duration.zero) 'afade=t=in:st=0:d=${_sec(s.fadeIn)}:curve=${s.curve.ffmpeg}',
      if (s.fadeOut > Duration.zero)
        'afade=t=out:st=${_sec(outputLength - s.fadeOut)}:d=${_sec(s.fadeOut)}:curve=${s.curve.ffmpeg}',
      // Common format so concat never has to guess.
      _common,
    ];

/// The files a timeline reads, in FFmpeg input order. Index 0 is the track
/// being edited.
List<String> timelineInputs(Timeline t, String main) => [
      main,
      for (final s in t.segments)
        if (s.input != null && s.input != main) s.input!,
    ].fold(<String>[], (out, e) => out.contains(e) ? out : (out..add(e)));

/// Builds the FFmpeg `-filter_complex` graph for a timeline.
///
/// Every segment becomes `atrim → asetpts → [areverse] → [atempo] → [pitch] →
/// [gate, EQ, volume, fades]`. Segments are joined with `concat`, or
/// `acrossfade` where they overlap, then come the global gain, loudness and
/// `afade`s. Source files are only read, never modified.
String buildFilterGraph(
  Timeline t, {
  required PitchEngine pitchEngine,
  List<String>? inputs,
  List<String> globalFilters = const [],
}) {
  final files = inputs ?? const <String>[];
  int inputOf(Segment s) {
    if (s.input == null) return 0;
    final i = files.indexOf(s.input!);
    return i < 0 ? 0 : i;
  }

  final chains = <String>[];
  for (var i = 0; i < t.segments.length; i++) {
    final s = t.segments[i];
    final out = s.outputLength;
    if (s.silent) {
      chains.add('anullsrc=r=48000:cl=stereo,atrim=duration=${_sec(s.sourceLength)},asetpts=PTS-STARTPTS,$_common[s$i]');
    } else if (s.isRamp) {
      // A ramp is short steady pieces, each with its own tempo.
      final steps = s.steps;
      final labels = StringBuffer();
      for (var k = 0; k < steps.length; k++) {
        final step = steps[k];
        final f = <String>[
          'atrim=start=${_sec(step.sourceStart)}:end=${_sec(step.sourceEnd)}',
          'asetpts=PTS-STARTPTS',
          if (s.reverse) 'areverse',
          ...atempoChain(step.speed),
          _common,
        ];
        chains.add('[${inputOf(s)}:a]${f.join(',')}[r${i}_$k]');
        labels.write('[r${i}_$k]');
      }
      chains.add('${labels}concat=n=${steps.length}:v=0:a=1,${_segmentEffects(s, out, pitchEngine).join(',')}[s$i]');
    } else {
      final f = <String>[
        'atrim=start=${_sec(s.sourceStart)}:end=${_sec(s.sourceEnd)}',
        'asetpts=PTS-STARTPTS',
        if (s.reverse) 'areverse',
        ...atempoChain(s.speed),
        ..._segmentEffects(s, out, pitchEngine),
      ];
      chains.add('[${inputOf(s)}:a]${f.join(',')}[s$i]');
    }
  }

  final n = t.segments.length;
  final post = <String>[
    if (t.masterGainDb.abs() > 1e-6) 'volume=volume=${_n(t.masterGainDb)}dB',
    ...globalFilters,
    if (t.loudnessLufs != null) 'loudnorm=I=${_n(t.loudnessLufs!)}:TP=-1:LRA=11',
    if (t.loudnessLufs != null) _common,
    if (t.fadeIn > Duration.zero) 'afade=t=in:st=0:d=${_sec(t.fadeIn)}${_curve(t)}',
    if (t.fadeOut > Duration.zero) 'afade=t=out:st=${_sec(t.duration - t.fadeOut)}:d=${_sec(t.fadeOut)}${_curve(t)}',
  ];

  final anyXfade = [for (var i = 0; i < n - 1; i++) t.xfadeAfter(i) > Duration.zero].any((x) => x);
  String joined;
  if (n == 1) {
    joined = '[s0]';
  } else if (!anyXfade) {
    joined = '${[for (var i = 0; i < n; i++) '[s$i]'].join()}concat=n=$n:v=0:a=1';
  } else {
    // Left to right: each join is a crossfade or a plain concat.
    var cur = '[s0]';
    for (var i = 1; i < n; i++) {
      final x = t.xfadeAfter(i - 1);
      final c = t.segments[i - 1].curve.ffmpeg;
      final join = x > Duration.zero ? 'acrossfade=d=${_sec(x)}:c1=$c:c2=$c' : 'concat=n=2:v=0:a=1';
      if (i == n - 1) {
        joined = '$cur[s$i]$join';
        return [...chains, _tail(joined, post, n)].join(';');
      }
      chains.add('$cur[s$i]$join[j$i]');
      cur = '[j$i]';
    }
    joined = cur;
  }
  return [...chains, _tail(joined, post, n)].join(';');
}

String _curve(Timeline t) => t.fadeCurve == FadeCurve.linear ? '' : ':curve=${t.fadeCurve.ffmpeg}';

String _tail(String joined, List<String> post, int n) {
  if (n == 1) return post.isEmpty ? '[s0]anull[out]' : '[s0]${post.join(',')}[out]';
  return post.isEmpty ? '$joined[out]' : '$joined[c];[c]${post.join(',')}[out]';
}

/// Full FFmpeg argument list (no shell quoting needed).
List<String> buildExportArgs({
  required Timeline timeline,
  required String input,
  required String output,
  required ExportFormat format,
  required PitchEngine pitchEngine,
  String? title,
  ExportSettings settings = const ExportSettings(),
  List<String> globalFilters = const [],
}) {
  final files = timelineInputs(timeline, input);
  final coverIndex = settings.coverPath == null ? null : files.length;
  final carryCover = settings.keepMetadata && !settings.removeCover && coverIndex == null;
  final tags = {'title': ?title, ...settings.tags};
  return [
    '-y',
    for (final f in files) ...['-i', f],
    if (format.holdsCover) ...[if (settings.coverPath case final cover?) ...['-i', cover]],
    '-filter_complex', buildFilterGraph(timeline, pitchEngine: pitchEngine, inputs: files, globalFilters: globalFilters),
    '-map', '[out]',
    if (format.holdsCover && coverIndex != null) ...['-map', '$coverIndex:v', '-c:v', 'copy', '-disposition:v', 'attached_pic'],
    // Keep the cover art for formats that can hold it.
    if (format.holdsCover && carryCover) ...['-map', '0:v?', '-c:v', 'copy', '-disposition:v', 'attached_pic'],
    '-map_metadata', settings.keepMetadata ? '0' : '-1',
    for (final e in tags.entries) ...['-metadata', '${e.key}=${e.value}'],
    ...switch (format) {
      ExportFormat.mp3 => [
          '-c:a', 'libmp3lame',
          if (settings.mp3Vbr) ...['-q:a', '${settings.mp3VbrQuality.clamp(0, 9)}'] else ...['-b:a', '${settings.mp3Kbps}k'],
          '-id3v2_version', '3',
        ],
      ExportFormat.m4a => ['-c:a', 'aac', '-b:a', '${settings.m4aKbps}k', '-movflags', '+faststart'],
      ExportFormat.wav => ['-c:a', settings.wavBits == 24 ? 'pcm_s24le' : 'pcm_s16le'],
      ExportFormat.flac => ['-c:a', 'flac', '-compression_level', '${settings.flacLevel.clamp(0, 12)}'],
    },
    output,
  ];
}

/// FFmpeg filters of the global EQ, for "apply EQ on export". Takes the band
/// gains so this file stays free of the audio_fx types.
List<String> eqExportFilters({
  required List<double> frequencies,
  required List<double> gainsDb,
  required double q,
  double bassDb = 0,
  double bassFrequency = 100,
  double bassQ = 0.7,
  double preampDb = 0,
}) =>
    [
      if (preampDb.abs() >= 0.05) 'volume=volume=${_n(preampDb)}dB',
      for (var i = 0; i < frequencies.length && i < gainsDb.length; i++)
        if (gainsDb[i].abs() >= 0.05) 'equalizer=f=${_n(frequencies[i])}:t=q:w=${_n(q)}:g=${_n(gainsDb[i])}',
      if (bassDb >= 0.05) 'bass=g=${_n(bassDb)}:f=${_n(bassFrequency)}:t=q:w=${_n(bassQ)}',
    ];

/// Arguments that read a short stretch of a file as raw 48 kHz mono (zero
/// crossing snap).
List<String> buildSnippetArgs({required String input, required Duration start, required Duration length, required String output}) => [
      '-y',
      '-ss', _sec(start < Duration.zero ? Duration.zero : start),
      '-t', _sec(length),
      '-i', input,
      '-vn', '-ac', '1', '-ar', '48000', '-f', 's16le', '-acodec', 'pcm_s16le',
      output,
    ];

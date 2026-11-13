import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../l10n/l10n.dart';
import '../../library/domain/track.dart';
import '../../player/application/player_providers.dart';
import '../../player/engine/playback_engine.dart';
import '../domain/lrc.dart';
import 'lyrics_providers.dart';

/// How the floating lyrics window looks and where it is.
class LyricsWindowState {
  const LyricsWindowState({
    this.open = false,
    this.fontSize = 30,
    this.opacity = 0.45,
    this.locked = false,
    this.x,
    this.y,
    this.width,
  });

  final bool open;

  /// Text size at 100 % screen scale.
  final double fontSize;

  /// Background 0 (fully see-through) .. 0.95.
  final double opacity;

  /// Clicks go through it to what is below.
  final bool locked;
  final int? x, y, width;

  LyricsWindowState copyWith({
    bool? open,
    double? fontSize,
    double? opacity,
    bool? locked,
    int? x,
    int? y,
    int? width,
  }) =>
      LyricsWindowState(
        open: open ?? this.open,
        fontSize: fontSize ?? this.fontSize,
        opacity: opacity ?? this.opacity,
        locked: locked ?? this.locked,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
      );
}

/// The two lines the floating window shows at [position] (lyrics offset
/// already added): the line being sung and the next one. Before the first
/// line and for songs without timed lyrics: the song's name and artist.
(String, String) lyricsWindowLines(Track? track, Lyrics? lyrics, Duration position) {
  if (track == null) return ('', '');
  final name = (track.title, track.artist.isNotEmpty ? track.artist : track.albumArtist);
  if (lyrics == null || !lyrics.synced) return name;
  final lines = lyrics.lines;
  final i = lyrics.indexAt(position);
  String text(int j) => lines[j].text.trim().isEmpty ? '♪' : lines[j].text.trim();
  if (i < 0) return (name.$1, text(0));
  return (text(i), i + 1 < lines.length ? text(i + 1) : '');
}

/// A small always-on-top window (Windows) with the line being sung, over
/// games and other apps, its background as see-through as the user likes.
/// It only works while open: no timer runs otherwise, and while open the
/// only timer is the one set for the next line.
class LyricsWindowController extends Notifier<LyricsWindowState> {
  static const _channel = MethodChannel('prism/lyricswindow');
  static const _prefix = 'lyricsWindow.';

  Timer? _nextLine;
  (String, String)? _shown;
  EngineState _engine = const EngineState();
  DateTime _engineAt = DateTime.now();

  static bool get supported => Platform.isWindows;

  @override
  LyricsWindowState build() {
    if (!supported) return const LyricsWindowState();
    _channel.setMethodCallHandler(_onCall);
    ref.onDispose(() {
      _nextLine?.cancel();
      _channel.setMethodCallHandler(null);
    });
    ref.listen(currentTrackProvider, (_, _) => _update());
    ref.listen(currentLyricsProvider, (_, _) => _update());
    ref.listen(currentLyricsOffsetProvider, (_, _) => _update());
    ref.listen(engineStateProvider, (_, s) {
      if (s.value case final v?) {
        _engine = v;
        _engineAt = DateTime.now();
        _update();
      }
    });
    unawaited(_load());
    return const LyricsWindowState();
  }

  Future<void> _load() async {
    final LyricsWindowState loaded;
    try {
      loaded = await _read();
    } on Object catch (e) {
      debugPrint('Prism lyrics window: settings not read ($e)');
      return;
    }
    if (!ref.mounted) return;
    state = loaded;
    if (loaded.open) await _show();
  }

  Future<LyricsWindowState> _read() async {
    final p = ref.read(prefsProvider);
    return LyricsWindowState(
      open: await p.getBool('${_prefix}open') ?? false,
      fontSize: await p.getDouble('${_prefix}fontSize') ?? 30,
      opacity: await p.getDouble('${_prefix}opacity') ?? 0.45,
      locked: await p.getBool('${_prefix}locked') ?? false,
      x: await p.getInt('${_prefix}x'),
      y: await p.getInt('${_prefix}y'),
      width: await p.getInt('${_prefix}w'),
    );
  }

  Future<void> _save() async {
    final p = ref.read(prefsProvider);
    final s = state;
    await p.setBool('${_prefix}open', s.open);
    await p.setDouble('${_prefix}fontSize', s.fontSize);
    await p.setDouble('${_prefix}opacity', s.opacity);
    await p.setBool('${_prefix}locked', s.locked);
    if (s.x != null) await p.setInt('${_prefix}x', s.x!);
    if (s.y != null) await p.setInt('${_prefix}y', s.y!);
    if (s.width != null) await p.setInt('${_prefix}w', s.width!);
  }

  Future<void> toggle() => setOpen(!state.open);

  Future<void> setOpen(bool open) async {
    if (!supported) return;
    state = state.copyWith(open: open);
    if (open) {
      await _show();
    } else {
      _nextLine?.cancel();
      await _invoke('hide');
    }
    await _save();
  }

  Future<void> setStyle({double? fontSize, double? opacity, bool? locked}) async {
    state = state.copyWith(fontSize: fontSize, opacity: opacity, locked: locked);
    if (state.open) await _invoke('style', _style());
    await _save();
  }

  Map<String, Object?> _style() => {'fontSize': state.fontSize, 'opacity': state.opacity, 'locked': state.locked};

  Future<void> _show() async {
    _shown = null;
    await _invoke('show', {
      ..._style(),
      'x': state.x,
      'y': state.y,
      'w': state.width ?? 0,
      'labels': [
        l10n.lyricsWindowLock,
        l10n.lyricsWindowBigger,
        l10n.lyricsWindowSmaller,
        l10n.lyricsWindowMoreSeeThrough,
        l10n.lyricsWindowLessSeeThrough,
        l10n.close,
      ],
    });
    _update();
  }

  /// Where the song is now: the last reported position plus the time since,
  /// while playing.
  Duration get _position {
    var p = _engine.position;
    if (_engine.playing) p += DateTime.now().difference(_engineAt);
    return p;
  }

  void _update() {
    if (!state.open) return;
    _nextLine?.cancel();
    final track = ref.read(currentTrackProvider);
    final lyrics = ref.read(currentLyricsProvider).value;
    final offset = ref.read(currentLyricsOffsetProvider).value ?? Duration.zero;
    final at = _position + offset;
    final lines = lyricsWindowLines(track, lyrics, at);
    if (lines != _shown) {
      _shown = lines;
      unawaited(_invoke('text', {'current': lines.$1, 'next': lines.$2}));
    }
    // Wake up exactly when the next line starts (no ticking in between).
    if (_engine.playing && lyrics != null && lyrics.synced) {
      final i = lyrics.indexAt(at);
      if (i + 1 < lyrics.lines.length) {
        final wait = lyrics.lines[i + 1].time - at;
        _nextLine = Timer(wait < Duration.zero ? Duration.zero : wait + const Duration(milliseconds: 15), _update);
      }
    }
  }

  Future<void> _invoke(String method, [Object? args]) async {
    try {
      await _channel.invokeMethod<void>(method, args);
    } on MissingPluginException {
      // Tests / another host.
    } on PlatformException catch (e) {
      debugPrint('Prism lyrics window: $e');
    }
  }

  Future<Object?> _onCall(MethodCall call) async {
    final args = call.arguments is Map ? (call.arguments as Map).cast<String, Object?>() : const <String, Object?>{};
    switch (call.method) {
      case 'closed':
        state = state.copyWith(open: false);
        _nextLine?.cancel();
        await _save();
      case 'moved':
        state = state.copyWith(
          x: (args['x'] as num?)?.toInt(),
          y: (args['y'] as num?)?.toInt(),
          width: (args['w'] as num?)?.toInt(),
        );
        await _save();
      case 'style':
        state = state.copyWith(
          fontSize: (args['fontSize'] as num?)?.toDouble(),
          opacity: (args['opacity'] as num?)?.toDouble(),
          locked: args['locked'] as bool?,
        );
        await _save();
    }
    return null;
  }
}

final lyricsWindowProvider = NotifierProvider<LyricsWindowController, LyricsWindowState>(LyricsWindowController.new);

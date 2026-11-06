import 'dart:async';

import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../application/player_controller.dart';
import '../../../l10n/l10n.dart';

/// Windows-only glue: media keys + media overlay (SMTC), the tray icon and
/// "close to tray".
///
/// The native halves live in `windows/runner/smtc_bridge.cpp` and
/// `windows/runner/tray_bridge.cpp`; they talk over two method channels.
class WindowsDesktopIntegration with WindowListener {
  WindowsDesktopIntegration(this._player);

  static const _smtc = MethodChannel('prism/smtc');
  static const _tray = MethodChannel('prism/tray');

  final PlayerController _player;
  final _subs = <StreamSubscription<Object?>>[];

  /// When true, closing the window hides it to the tray instead of quitting.
  bool closeToTray = true;

  bool? _lastPlaying;
  int? _lastTrackId;
  int _lastTimelineSec = -1;

  Future<void> init() async {
    _smtc.setMethodCallHandler(_onSmtcCall);
    _tray.setMethodCallHandler(_onTrayCall);
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);

    _subs
      ..add(_player.queueStream.listen((_) => _pushState(force: true)))
      ..add(_player.stateStream.listen((_) => _pushState()));
    await _pushState(force: true);
  }

  Future<void> _pushState({bool force = false}) async {
    final track = _player.current;
    final s = _player.state;
    final changed = force || s.playing != _lastPlaying || track?.id != _lastTrackId;
    try {
      if (changed) {
        _lastPlaying = s.playing;
        _lastTrackId = track?.id;
        await _smtc.invokeMethod('update', {
          'enabled': track != null,
          'title': track?.title ?? '',
          'artist': track?.displayArtist ?? '',
          'album': track?.displayAlbum ?? '',
          'artPath': track?.artworkPath,
          'playing': s.playing,
        });
        await _tray.invokeMethod('show', {
          'tooltip': track == null ? 'Prism' : 'Prism – ${track.title} · ${track.displayArtist}',
          'playing': s.playing,
          'labels': [l10n.trayShow, l10n.pause, l10n.play, l10n.previous, l10n.next, l10n.trayQuit],
        });
      }
      // The overlay only needs coarse timeline updates.
      final sec = s.position.inSeconds;
      if (changed || sec != _lastTimelineSec) {
        _lastTimelineSec = sec;
        await _smtc.invokeMethod('timeline', {
          'positionMs': s.position.inMilliseconds,
          'durationMs': (s.duration ?? track?.duration ?? Duration.zero).inMilliseconds,
        });
      }
    } on MissingPluginException {
      // Running in a test / unsupported host – ignore.
    }
  }

  Future<Object?> _onSmtcCall(MethodCall call) async {
    if (call.method != 'button') return null;
    switch (call.arguments as String?) {
      case 'play':
        await _player.play();
      case 'pause':
        await _player.pause();
      case 'next':
        await _player.skipNext();
      case 'previous':
        await _player.skipPrevious();
      case 'stop':
        await _player.stop();
    }
    return null;
  }

  Future<Object?> _onTrayCall(MethodCall call) async {
    if (call.method != 'action') return null;
    switch (call.arguments as String?) {
      case 'open':
        await windowManager.show();
        await windowManager.focus();
      case 'toggle':
        await _player.togglePlay();
      case 'next':
        await _player.skipNext();
      case 'previous':
        await _player.skipPrevious();
      case 'quit':
        await quit();
    }
    return null;
  }

  @override
  void onWindowClose() {
    if (closeToTray) {
      windowManager.hide();
    } else {
      quit();
    }
  }

  Future<void> quit() async {
    await _player.stop();
    try {
      await _tray.invokeMethod('hide');
    } on MissingPluginException {
      // ignore
    }
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }


  Future<void> dispose() async {
    windowManager.removeListener(this);
    for (final s in _subs) {
      await s.cancel();
    }
  }
}

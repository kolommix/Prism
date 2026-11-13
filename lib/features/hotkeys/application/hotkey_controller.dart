import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/providers.dart';
import '../../lyrics/application/lyrics_window.dart';
import '../../player/application/player_providers.dart';
import '../../player/presentation/player_extras.dart';
import '../domain/hotkeys.dart';

/// The hotkeys as set, and the ones Windows refused (another app has them).
class HotkeyState {
  const HotkeyState({this.enabled = true, this.keys = const {}, this.refused = const {}});
  final bool enabled;
  final Map<HotkeyAction, HotkeyCombo> keys;
  final Set<HotkeyAction> refused;

  HotkeyState copyWith({bool? enabled, Map<HotkeyAction, HotkeyCombo>? keys, Set<HotkeyAction>? refused}) =>
      HotkeyState(enabled: enabled ?? this.enabled, keys: keys ?? this.keys, refused: refused ?? this.refused);
}

/// System-wide hotkeys on Windows: they work while Prism is hidden in the tray
/// or another app is in front. Saved per action; an action can have no key.
class HotkeyController extends Notifier<HotkeyState> {
  static const _channel = MethodChannel('prism/hotkeys');
  static const _enabledKey = 'hotkeys.enabled';
  static const _keyPrefix = 'hotkeys.key.';

  /// Volume step per press (held keys repeat).
  static const volumeStep = 0.05;
  static const seekStep = Duration(seconds: 10);

  @override
  HotkeyState build() {
    if (!Platform.isWindows) return const HotkeyState(enabled: false);
    _channel.setMethodCallHandler(_onCall);
    ref.onDispose(() {
      _channel.setMethodCallHandler(null);
      unawaited(_register(const {}));
    });
    unawaited(_load());
    return HotkeyState(keys: Map.of(defaultHotkeys));
  }

  Future<void> _load() async {
    try {
      await _loadSaved();
    } on Object catch (e) {
      debugPrint('Prism hotkeys: settings not read ($e)');
    }
  }

  Future<void> _loadSaved() async {
    final prefs = ref.read(prefsProvider);
    final enabled = await prefs.getBool(_enabledKey) ?? true;
    final keys = <HotkeyAction, HotkeyCombo>{};
    for (final a in HotkeyAction.values) {
      final raw = await prefs.getString('$_keyPrefix${a.name}');
      if (raw == null) {
        if (defaultHotkeys[a] case final d?) keys[a] = d;
      } else if (raw.isNotEmpty) {
        if (HotkeyCombo.decode(raw) case final c?) keys[a] = c;
      }
    }
    if (!ref.mounted) return;
    state = state.copyWith(enabled: enabled, keys: keys);
    await _apply();
  }

  Future<void> setEnabled(bool on) async {
    state = state.copyWith(enabled: on);
    await ref.read(prefsProvider).setBool(_enabledKey, on);
    await _apply();
  }

  /// [combo] null = no key for this action. A key used by another action
  /// moves here.
  Future<void> setKey(HotkeyAction action, HotkeyCombo? combo) async {
    final keys = Map.of(state.keys);
    final prefs = ref.read(prefsProvider);
    if (combo != null) {
      for (final e in keys.entries.toList()) {
        if (e.key != action && e.value == combo) {
          keys.remove(e.key);
          await prefs.setString('$_keyPrefix${e.key.name}', '');
        }
      }
      keys[action] = combo;
    } else {
      keys.remove(action);
    }
    state = state.copyWith(keys: keys);
    await prefs.setString('$_keyPrefix${action.name}', combo?.encode() ?? '');
    await _apply();
  }

  Future<void> resetAll() async {
    final prefs = ref.read(prefsProvider);
    for (final a in HotkeyAction.values) {
      await prefs.remove('$_keyPrefix${a.name}');
    }
    state = state.copyWith(keys: Map.of(defaultHotkeys));
    await _apply();
  }

  /// Off while a new key is being chosen (Windows would take the keys first).
  Future<void> suspend() => _register(const {});
  Future<void> resume() => _apply();

  Future<void> _apply() => _register(state.enabled ? state.keys : const {});

  Future<void> _register(Map<HotkeyAction, HotkeyCombo> keys) async {
    try {
      final refused = await _channel.invokeMethod<List<Object?>>('set', [
        for (final e in keys.entries)
          if (e.value.valid) {'id': e.key.index, 'mods': e.value.mods, 'vk': e.value.vk, 'repeat': e.key.repeats},
      ]);
      if (!ref.mounted) return;
      state = state.copyWith(refused: {
        for (final id in refused ?? const <Object?>[])
          if (id is int && id >= 0 && id < HotkeyAction.values.length) HotkeyAction.values[id],
      });
    } on MissingPluginException {
      // Tests / another host.
    } on PlatformException catch (e) {
      debugPrint('Prism hotkeys: $e');
    }
  }

  Future<Object?> _onCall(MethodCall call) async {
    if (call.method != 'pressed') return null;
    final id = call.arguments;
    if (id is! int || id < 0 || id >= HotkeyAction.values.length) return null;
    await run(HotkeyAction.values[id]);
    return null;
  }

  /// Does what [action] says (also used by the keys inside the window).
  Future<void> run(HotkeyAction action) async {
    final player = ref.read(playerControllerProvider);
    switch (action) {
      case HotkeyAction.playPause:
        await player.togglePlay();
      case HotkeyAction.next:
        await player.skipNext();
      case HotkeyAction.previous:
        await player.skipPrevious();
      case HotkeyAction.volumeUp:
        final v = ref.read(playerVolumeProvider);
        ref.read(playerVolumeProvider.notifier).set(v + volumeStep);
      case HotkeyAction.volumeDown:
        final v = ref.read(playerVolumeProvider);
        ref.read(playerVolumeProvider.notifier).set(v - volumeStep);
      case HotkeyAction.mute:
        ref.read(playerVolumeProvider.notifier).toggleMute();
      case HotkeyAction.seekForward || HotkeyAction.seekBack:
        final s = player.state;
        final total = s.duration ?? Duration.zero;
        var to = s.position + (action == HotkeyAction.seekForward ? seekStep : -seekStep);
        if (to < Duration.zero) to = Duration.zero;
        if (total > Duration.zero && to > total) to = total - const Duration(milliseconds: 500);
        await player.seek(to);
      case HotkeyAction.lyricsWindow:
        await ref.read(lyricsWindowProvider.notifier).toggle();
      case HotkeyAction.showPrism:
        if (await windowManager.isVisible() && await windowManager.isFocused() && !await windowManager.isMinimized()) {
          await windowManager.minimize();
        } else {
          await windowManager.show();
          await windowManager.restore();
          await windowManager.focus();
        }
    }
  }
}

final hotkeysProvider = NotifierProvider<HotkeyController, HotkeyState>(HotkeyController.new);

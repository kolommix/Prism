import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The volume the user last set for each song (Settings → Playback →
/// "Remember the volume of each song", off by default). Kept on this device
/// only, by library song id; the oldest are dropped past [limit].
class SongVolumes {
  SongVolumes({SharedPreferencesAsync? prefs, this.limit = 5000}) : _prefs = prefs; // ignore: prefer_initializing_formals

  static const _key = 'player.songVolumes.v1';
  final SharedPreferencesAsync? _prefs;
  final int limit;

  /// Insertion order = last change order, so the oldest go first.
  final _map = <int, double>{}; // a map literal keeps insertion order
  Future<void>? _loading;
  Timer? _save;

  /// Reads the saved list once (later calls wait for the same read).
  Future<void> load() => _loading ??= _read();

  Future<void> _read() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      final raw = await prefs.getString(_key);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in json.entries) {
        final id = int.tryParse(e.key);
        final v = e.value;
        // A change made before the list was read wins.
        if (id != null && v is num && !_map.containsKey(id)) _map[id] = v.toDouble().clamp(0.0, 1.0);
      }
    } on Object catch (e) {
      debugPrint('Prism: song volumes not read: $e');
    }
  }

  /// The volume saved for [songId], or null.
  double? of(int songId) => _map[songId];

  /// Remembers [volume] for [songId]. Muting (0) is not remembered: a song
  /// should never come back silent.
  void remember(int songId, double volume) {
    if (volume <= 0) return;
    _map.remove(songId);
    _map[songId] = volume.clamp(0.0, 1.0);
    while (_map.length > limit) {
      _map.remove(_map.keys.first);
    }
    _save?.cancel();
    _save = Timer(const Duration(milliseconds: 800), () => unawaited(_write()));
  }

  void forget(int songId) {
    if (_map.remove(songId) == null) return;
    _save?.cancel();
    _save = Timer(const Duration(milliseconds: 800), () => unawaited(_write()));
  }

  int get length => _map.length;

  Future<void> _write() async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await load();
      await prefs.setString(_key, jsonEncode({for (final e in _map.entries) '${e.key}': double.parse(e.value.toStringAsFixed(3))}));
    } on Object catch (e) {
      debugPrint('Prism: song volumes not saved: $e');
    }
  }

  void dispose() {
    final pending = _save?.isActive ?? false;
    _save?.cancel();
    if (pending) unawaited(_write());
  }
}

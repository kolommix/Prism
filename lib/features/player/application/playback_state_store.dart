import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/playback_queue.dart';

/// What we remember between app launches.
class SavedPlayback {
  const SavedPlayback({
    required this.trackIds,
    required this.originalIds,
    required this.index,
    required this.position,
    required this.repeatMode,
    required this.shuffled,
    this.volume = 1,
  });

  final List<int> trackIds;
  final List<int> originalIds;
  final int index;
  final Duration position;
  final QueueRepeatMode repeatMode;
  final bool shuffled;

  /// Master volume 0..1, so a restart doesn't jump back to full volume.
  final double volume;

  Map<String, Object?> toJson() => {
        'ids': trackIds,
        'orig': originalIds,
        'index': index,
        'posMs': position.inMilliseconds,
        'repeat': repeatMode.name,
        'shuffled': shuffled,
        'volume': volume,
      };

  factory SavedPlayback.fromJson(Map<String, dynamic> j) => SavedPlayback(
        trackIds: [for (final v in (j['ids'] as List? ?? const [])) v as int],
        originalIds: [for (final v in (j['orig'] as List? ?? const [])) v as int],
        index: j['index'] as int? ?? 0,
        position: Duration(milliseconds: j['posMs'] as int? ?? 0),
        repeatMode: QueueRepeatMode.values.asNameMap()[j['repeat']] ?? QueueRepeatMode.off,
        shuffled: j['shuffled'] as bool? ?? false,
        volume: ((j['volume'] as num?)?.toDouble() ?? 1).clamp(0.0, 1.0),
      );
}

/// Persists [SavedPlayback]. An interface so tests can use an in-memory fake.
abstract class PlaybackStateStore {
  Future<SavedPlayback?> load();
  Future<void> save(SavedPlayback state);
}

class PrefsPlaybackStateStore implements PlaybackStateStore {
  PrefsPlaybackStateStore(this._prefs);

  static const _key = 'playback.last';
  final SharedPreferencesAsync _prefs;

  @override
  Future<SavedPlayback?> load() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) return null;
    try {
      return SavedPlayback.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> save(SavedPlayback state) => _prefs.setString(_key, jsonEncode(state.toJson()));
}

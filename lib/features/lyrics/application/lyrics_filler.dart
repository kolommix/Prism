import 'dart:async';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/library_models.dart';
import '../../settings/application/settings_controller.dart';
import '../../../l10n/l10n.dart';
import 'lyrics_providers.dart';

/// What the background lyrics download is doing, for the settings page.
class LyricsFillState {
  const LyricsFillState({this.running = false, this.done = 0, this.total = 0, this.found = 0, this.note});

  final bool running;
  final int done;
  final int total;
  final int found;
  final String? note;
}

/// Saves lyrics for every song of the library, one at a time in the
/// background, so a line can find any song (Search). Uses the same lookup as
/// the lyrics view (.lrc file, tags, then LRCLIB), so a song done here opens
/// its lyrics instantly later. Runs only while both "Find lyrics online" and
/// "Lyrics for the whole library" are on.
class LyricsFiller extends Notifier<LyricsFillState> {
  int _run = 0;

  /// LRCLIB is free and has no stated limit: stay gentle anyway.
  static const _pace = Duration(milliseconds: 1500);

  bool get _enabled {
    final s = ref.read(settingsProvider);
    return s.onlineLyrics && s.lyricsForLibrary;
  }

  @override
  LyricsFillState build() {
    ref.onDispose(() => _run++);
    ref.listen(settingsProvider.select((s) => s.onlineLyrics && s.lyricsForLibrary), (_, on) {
      if (on) {
        unawaited(start());
      } else {
        _run++;
        state = const LyricsFillState();
      }
    });
    ref.listen(scanControllerProvider, (_, next) {
      if (next is ScanFinished && _enabled) unawaited(start());
    });
    if (_enabled) {
      // Not during startup.
      Timer(const Duration(seconds: 20), () {
        if (ref.mounted) unawaited(start());
      });
    }
    return const LyricsFillState();
  }

  /// Goes through the songs with nothing saved yet. Safe to call while running.
  Future<void> start({Duration? pace}) async {
    if (state.running) return;
    final run = ++_run;
    final db = ref.read(appDatabaseProvider);
    final ids = [
      for (final r in await db
          .customSelect('SELECT id FROM tracks WHERE id NOT IN (SELECT track_id FROM lyrics_cache) ORDER BY id DESC')
          .get())
        r.read<int>('id'),
    ];
    if (run != _run) return;
    if (ids.isEmpty) {
      state = const LyricsFillState();
      return;
    }
    final repo = ref.read(lyricsRepositoryProvider);
    final library = ref.read(libraryRepositoryProvider);
    final wait = pace ?? _pace;
    var found = 0, troubles = 0;
    state = LyricsFillState(running: true, total: ids.length);
    for (var i = 0; i < ids.length; i++) {
      if (run != _run) return;
      final t = (await library.tracksByIds([ids[i]])).firstOrNull;
      if (t == null) continue;
      final lyrics = await repo.lyricsFor(t, online: true);
      if (run != _run) return;
      if (lyrics != null) {
        found++;
        troubles = 0;
      } else if (!await _hasRow(t.id)) {
        // Nothing saved, not even "none": the service did not answer. Try a
        // little later; after a few in a row stop until next time.
        if (++troubles >= 3) {
          state = LyricsFillState(total: ids.length, done: i, found: found, note: l10n.pausedTheSearchServicesAreNot);
          _run++;
          return;
        }
        i--;
        await Future<void>.delayed(wait * 20);
        continue;
      } else {
        troubles = 0;
      }
      state = LyricsFillState(running: true, total: ids.length, done: i + 1, found: found);
      await Future<void>.delayed(wait);
    }
    if (run != _run) return;
    state = LyricsFillState(total: ids.length, done: ids.length, found: found);
  }

  Future<bool> _hasRow(int id) async => (await ref
          .read(appDatabaseProvider)
          .customSelect('SELECT 1 FROM lyrics_cache WHERE track_id = ?', variables: [Variable.withInt(id)])
          .get())
      .isNotEmpty;
}

final lyricsFillerProvider = NotifierProvider<LyricsFiller, LyricsFillState>(LyricsFiller.new);

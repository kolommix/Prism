import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../core/providers.dart';
import '../../desktop/data/cover_lookup.dart';
import '../../player/application/player_providers.dart';
import '../../settings/application/settings_controller.dart';
import '../data/library_repository.dart';
import '../domain/library_models.dart';
import '../domain/track.dart';
import 'library_providers.dart';
import '../../../l10n/l10n.dart';

/// What the background search is doing, for the settings page.
class AutoTagState {
  const AutoTagState({this.running = false, this.done = 0, this.total = 0, this.found = 0, this.note});

  final bool running;
  final int done;
  final int total;
  final int found;
  final String? note;
}

/// What to change on a track for what the catalogues know (pure, tested).
/// Only fills what's missing: tags the user has are never replaced.
AutoTagChange? autoTagChangeFor(Track t, CoverInfo info, String? coverPath) {
  final noArtist = t.artist.isEmpty && t.albumArtist.isEmpty;
  final change = AutoTagChange(
    // Without an artist the title is most likely just the file name.
    title: noArtist && info.title != null && info.title!.isNotEmpty ? info.title : null,
    artist: noArtist ? info.artist : null,
    album: t.album.isEmpty ? info.album : null,
    genre: t.genre.isEmpty ? info.genre : null,
    year: t.year == null ? info.year : null,
    artworkPath: t.artworkPath == null ? coverPath : null,
  );
  return change.isEmpty ? null : change;
}

/// Finds missing covers, artists and albums for songs in the library, one at a
/// time in the background (Apple's and Deezer's public search, nothing else
/// than title and artist leaves the PC).
///
/// Only Prism's own library changes: audio files are never written, and every
/// change remembers what was there before, so it can be undone.
class AutoTagger extends Notifier<AutoTagState> {
  int _run = 0;
  CoverLookup? _lookup;

  /// Apple allows about 20 searches a minute.
  static const _pace = Duration(milliseconds: 3200);

  @override
  AutoTagState build() {
    ref.onDispose(_stop);
    ref.listen(settingsProvider.select((s) => s.autoFindInfo), (_, on) {
      if (on) {
        unawaited(start());
      } else {
        _stop();
        state = const AutoTagState();
      }
    });
    // New songs after a scan get looked up as well.
    ref.listen(scanControllerProvider, (_, next) {
      if (next is ScanFinished && ref.read(settingsProvider).autoFindInfo) unawaited(start());
    });
    if (ref.read(settingsProvider).autoFindInfo) {
      // Not during startup: the app has more important things to do first.
      Timer(const Duration(seconds: 8), () {
        if (ref.mounted) unawaited(start());
      });
    }
    return const AutoTagState();
  }

  void _stop() {
    _run++;
    _lookup?.close();
    _lookup = null;
  }

  LibraryRepository get _repo => ref.read(libraryRepositoryProvider);

  /// Looks through the songs not checked yet. Safe to call while running.
  Future<void> start({http.Client? client, Duration? pace}) async {
    if (state.running) return;
    final run = ++_run;
    final todo = await _repo.tracksMissingInfo();
    if (run != _run) return;
    if (todo.isEmpty) {
      state = const AutoTagState();
      return;
    }
    final http.Client c = client ?? http.Client();
    final lookup = CoverLookup(client: c);
    _lookup = lookup;
    final wait = pace ?? _pace;
    var found = 0, troubles = 0;
    state = AutoTagState(running: true, total: todo.length);
    for (var i = 0; i < todo.length; i++) {
      if (run != _run) return;
      final t = todo[i];
      final info = await lookup.find(t);
      if (run != _run) return;
      if (lookup.lastFailed) {
        // Offline or too many searches: that says nothing about the song, so
        // it stays on the list. Try a little later, then give up until next time.
        if (++troubles >= 3) {
          state = AutoTagState(total: todo.length, done: i, found: found, note: l10n.pausedTheSearchServicesAreNot);
          _stop();
          return;
        }
        lookup.forget(t);
        i--;
        await Future<void>.delayed(wait * 18);
        continue;
      }
      troubles = 0;
      if (info == null) {
        await _repo.markInfoChecked(t.id);
      } else {
        final cover = t.artworkPath == null ? await _saveCover(c, info.coverUrl) : null;
        if (run != _run) return;
        final change = autoTagChangeFor(t, info, cover);
        if (change == null) {
          await _repo.markInfoChecked(t.id);
        } else {
          await _repo.applyAutoTag(t, change);
          found++;
          await _refreshCurrent(t.id);
        }
      }
      state = AutoTagState(running: true, total: todo.length, done: i + 1, found: found);
      await Future<void>.delayed(wait);
    }
    if (run != _run) return;
    state = AutoTagState(total: todo.length, done: todo.length, found: found);
    _stop();
  }

  /// The song playing right now shows its new cover and artist straight away.
  Future<void> _refreshCurrent(int id) async {
    try {
      final player = ref.read(playerControllerProvider);
      if (player.current?.id != id) return;
      final fresh = await _repo.tracksByIds([id]);
      if (fresh.isNotEmpty) player.refreshTrackInfo(fresh.first);
    } on Object {
      // No player (tests) or it changed meanwhile: it shows at the next play.
    }
  }

  Future<String?> _saveCover(http.Client c, String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final dir = ref.read(artworkDirProvider);
      final file = File(p.join(dir.path, 'found-${md5.convert(utf8.encode(url))}.jpg'));
      if (await file.exists()) return file.path;
      final res = await c.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200 || res.bodyBytes.isEmpty) return null;
      if (!await dir.exists()) await dir.create(recursive: true);
      await file.writeAsBytes(res.bodyBytes, flush: false);
      return file.path;
    } on Object {
      return null; // the rest of the info still counts
    }
  }

  /// Puts every song back as it was, and doesn't look them up again.
  Future<int> undoAll() async {
    final wasOn = state.running;
    _stop();
    final n = await _repo.undoAutoTags();
    state = AutoTagState(note: l10n.undoFound(n));
    if (wasOn) _run++;
    return n;
  }

  /// Songs without a result get another chance.
  Future<void> lookAgain() async {
    _stop();
    state = const AutoTagState();
    await _repo.clearInfoChecks();
    await start();
  }
}

final autoTaggerProvider = NotifierProvider<AutoTagger, AutoTagState>(AutoTagger.new);

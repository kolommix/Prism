import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../library/application/library_providers.dart';
import '../../library/domain/library_models.dart';
import '../../library/domain/track.dart';
import '../../online/application/online_providers.dart';
import '../../online/domain/matching.dart';
import '../../tools/application/tools_providers.dart';
import '../../tools/data/tag_writer.dart';
import '../data/metadata_clients.dart';
import '../domain/metadata_candidate.dart';

final metadataSearchProvider = Provider<MetadataSearch>((ref) {
  final key = ref.watch(onlineHubProvider).config.acoustIdKey;
  final s = MetadataSearch(acoustIdKey: key, fingerprinter: fpcalcFingerprint);
  ref.onDispose(s.close);
  return s;
});

enum FixStatus { waiting, searching, found, notFound, failed, saved }

/// One song in the fixer: what was found and what the user wants to change.
class FixItem {
  const FixItem({
    required this.track,
    this.status = FixStatus.waiting,
    this.candidates = const [],
    this.chosen,
    this.values = const {},
    this.apply = const {},
    this.useCover = false,
    this.removeCover = false,
    this.coverUrls = const [],
    this.ownCover,
    this.error,
  });

  final Track track;
  final FixStatus status;
  final List<MetaCandidate> candidates;
  final MetaCandidate? chosen;

  /// New value per field (candidate's, or what the user typed).
  final Map<MetaField, String> values;

  /// Which fields will be written.
  final Set<MetaField> apply;
  final bool useCover;
  final bool removeCover;
  final List<String> coverUrls;
  final Uint8List? ownCover;
  final String? error;

  bool get canSave => apply.isNotEmpty || useCover || removeCover || ownCover != null;

  /// What would be written, in the tag writer's terms.
  TagEdit edit(Uint8List? cover) {
    String? v(MetaField f) => apply.contains(f) ? values[f]?.trim() : null;
    return TagEdit(
      title: v(MetaField.title),
      artist: v(MetaField.artist),
      album: v(MetaField.album),
      genre: v(MetaField.genre),
      year: int.tryParse(v(MetaField.year) ?? ''),
      trackNumber: int.tryParse(v(MetaField.track) ?? ''),
      cover: cover,
      removeCover: removeCover,
    );
  }

  FixItem copyWith({
    Track? track,
    FixStatus? status,
    List<MetaCandidate>? candidates,
    Object? chosen = _same,
    Map<MetaField, String>? values,
    Set<MetaField>? apply,
    bool? useCover,
    bool? removeCover,
    List<String>? coverUrls,
    Object? ownCover = _same,
    Object? error = _same,
  }) =>
      FixItem(
        track: track ?? this.track,
        status: status ?? this.status,
        candidates: candidates ?? this.candidates,
        chosen: identical(chosen, _same) ? this.chosen : chosen as MetaCandidate?,
        values: values ?? this.values,
        apply: apply ?? this.apply,
        useCover: useCover ?? this.useCover,
        removeCover: removeCover ?? this.removeCover,
        coverUrls: coverUrls ?? this.coverUrls,
        ownCover: identical(ownCover, _same) ? this.ownCover : ownCover as Uint8List?,
        error: identical(error, _same) ? this.error : error as String?,
      );

  static const _same = Object();
}

class FixState {
  const FixState({this.items = const [], this.selected = 0, this.searching = false, this.saving = false, this.savedCount = 0, this.saveError});
  final List<FixItem> items;
  final int selected;
  final bool searching;
  final bool saving;
  final int savedCount;
  final String? saveError;

  FixItem? get current => selected < items.length ? items[selected] : null;

  FixState copyWith({List<FixItem>? items, int? selected, bool? searching, bool? saving, int? savedCount, Object? saveError = _same}) => FixState(
        items: items ?? this.items,
        selected: selected ?? this.selected,
        searching: searching ?? this.searching,
        saving: saving ?? this.saving,
        savedCount: savedCount ?? this.savedCount,
        saveError: identical(saveError, _same) ? this.saveError : saveError as String?,
      );

  static const _same = Object();
}

/// Applies a candidate to an item: every field that would really change gets
/// ticked; an empty proposal leaves the field alone.
FixItem chooseCandidate(FixItem item, MetaCandidate c) {
  final diffs = diffOf(item.track, c);
  return item.copyWith(
    chosen: c,
    values: {for (final d in diffs) d.field: d.proposed.isEmpty ? d.current : d.proposed},
    apply: {for (final d in diffs) if (d.changes) d.field},
    useCover: c.coverUrls.isNotEmpty,
    removeCover: false,
    coverUrls: c.coverUrls,
    ownCover: null,
  );
}

/// The fixer's session for a set of track ids (one song, an album, a folder).
class MetadataFixController extends Notifier<FixState> {
  MetadataFixController(this.key);

  /// Track ids joined by commas.
  final String key;

  MetadataSearch get _search => ref.read(metadataSearchProvider);

  @override
  FixState build() {
    Future.microtask(_load);
    return const FixState();
  }

  Future<void> _load() async {
    final repo = ref.read(libraryRepositoryProvider);
    final ids = [for (final s in key.split(',')) ?int.tryParse(s)];
    final tracks = await repo.tracksByIds(ids);
    if (!ref.mounted) return;
    state = FixState(items: [for (final t in tracks) FixItem(track: t, values: _valuesOf(t))]);
    if (tracks.length == 1) await searchCurrent();
  }

  Map<MetaField, String> _valuesOf(Track t) => {
        MetaField.title: t.title,
        MetaField.artist: t.artist,
        MetaField.album: t.album,
        MetaField.year: t.year?.toString() ?? '',
        MetaField.track: t.trackNumber?.toString() ?? '',
        MetaField.genre: t.genre,
      };

  void _set(int i, FixItem item) {
    if (!ref.mounted) return;
    final list = [...state.items];
    list[i] = item;
    state = state.copyWith(items: list);
  }

  void select(int i) => state = state.copyWith(selected: i);

  Future<void> _searchOne(int i, {String? title, String? artist}) async {
    final item = state.items[i];
    _set(i, item.copyWith(status: FixStatus.searching, error: null));
    try {
      final found = await _search.search(item.track, title: title, artist: artist);
      if (!ref.mounted) return;
      var next = state.items[i].copyWith(status: found.isEmpty ? FixStatus.notFound : FixStatus.found, candidates: found);
      if (found.isNotEmpty && found.first.score >= MatchScorer.acceptThreshold) next = chooseCandidate(next, found.first);
      _set(i, next);
    } on Object catch (e) {
      if (!ref.mounted) return;
      _set(i, state.items[i].copyWith(status: FixStatus.failed, error: '$e'));
    }
  }

  /// "Re-search" with what the user typed.
  Future<void> searchCurrent({String? title, String? artist}) => _searchOne(state.selected, title: title, artist: artist);

  /// Looks up every song, then nudges them towards the album most agree on.
  Future<void> searchAll() async {
    if (state.searching) return;
    state = state.copyWith(searching: true);
    for (var i = 0; i < state.items.length; i++) {
      if (state.items[i].status == FixStatus.saved) continue;
      await _searchOne(i);
      if (!ref.mounted) return;
    }
    final ranked = preferCommonAlbum([for (final it in state.items) it.candidates]);
    final items = [
      for (var i = 0; i < state.items.length; i++)
        () {
          final it = state.items[i];
          if (ranked[i].isEmpty || it.status == FixStatus.saved) return it;
          final next = it.copyWith(candidates: ranked[i]);
          return ranked[i].first.score >= MatchScorer.acceptThreshold ? chooseCandidate(next, ranked[i].first) : next;
        }(),
    ];
    state = state.copyWith(items: items, searching: false);
  }

  void choose(MetaCandidate c) => _set(state.selected, chooseCandidate(state.current!, c));

  void setValue(MetaField f, String v) {
    final it = state.current!;
    _set(state.selected, it.copyWith(values: {...it.values, f: v}, apply: {...it.apply, f}));
  }

  void toggleField(MetaField f, bool on) {
    final it = state.current!;
    _set(state.selected, it.copyWith(apply: on ? {...it.apply, f} : ({...it.apply}..remove(f))));
  }

  void setUseCover(bool on) => _set(state.selected, state.current!.copyWith(useCover: on, removeCover: false));
  void setRemoveCover(bool on) => _set(state.selected, state.current!.copyWith(removeCover: on, useCover: false, ownCover: null));
  void setOwnCover(Uint8List bytes) =>
      _set(state.selected, state.current!.copyWith(ownCover: bytes, useCover: false, removeCover: false));

  /// Writes the current song only, or every song with something ticked. Tags go
  /// into the files (backup first) and the library is read again, so the
  /// database always says what the files say. Formats that can't be written
  /// (OGG) are updated in the database only.
  Future<void> save({required bool all}) async {
    if (state.saving) return;
    state = state.copyWith(saving: true, saveError: null, savedCount: 0);
    final writer = await ref.read(tagWriterProvider.future);
    final repo = ref.read(libraryRepositoryProvider);
    final folders = <String>{};
    var saved = 0;
    String? error;
    final order = all ? List.generate(state.items.length, (i) => i) : [state.selected];
    for (final i in order) {
      if (!ref.mounted) return;
      final it = state.items[i];
      if (!it.canSave || it.status == FixStatus.saved) continue;
      try {
        final cover = it.ownCover ?? (it.useCover ? await _search.fetchCover(it.coverUrls) : null);
        final edit = it.edit(cover);
        final t = it.track;
        if (t.sourceId == 'local' && TagWriter.canWrite(t.uri)) {
          await writer.write(t.uri, edit);
          if ((edit.cover != null || edit.removeCover) && t.artworkPath != null) {
            final f = File(t.artworkPath!);
            if (await f.exists()) await f.delete();
          }
          folders.add(p.dirname(t.uri));
        } else {
          await repo.applyAutoTag(t, AutoTagChange(title: edit.title, artist: edit.artist, album: edit.album, genre: edit.genre, year: edit.year));
        }
        saved++;
        _set(i, it.copyWith(status: FixStatus.saved, apply: const {}, useCover: false, removeCover: false, ownCover: null));
      } on Object catch (e) {
        error = '$e';
        _set(i, it.copyWith(error: '$e'));
      }
    }
    if (folders.isNotEmpty && ref.mounted) await ref.read(libraryScannerProvider).scanFolders(folders.toList()).drain<void>();
    PaintingBinding.instance.imageCache.clear();
    if (!ref.mounted) return;
    // Show the new values as the current ones.
    final fresh = await repo.tracksByIds([for (final it in state.items) it.track.id]);
    if (!ref.mounted) return;
    final byId = {for (final t in fresh) t.id: t};
    state = state.copyWith(
      saving: false,
      savedCount: saved,
      saveError: error,
      items: [for (final it in state.items) it.copyWith(track: byId[it.track.id] ?? it.track)],
    );
  }
}

final metadataFixProvider =
    NotifierProvider.autoDispose.family<MetadataFixController, FixState, String>(MetadataFixController.new);

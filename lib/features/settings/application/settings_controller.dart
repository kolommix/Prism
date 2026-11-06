import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/providers.dart';
import '../../../core/theme/theme_config.dart';
import '../../player/application/player_providers.dart';
import '../data/settings_store.dart';
import '../domain/app_settings.dart';

import 'dart:io';
import '../../background/data/background_files.dart';
import '../../audio_fx/application/loudness_controller.dart';
/// Where a chosen background picture or video's frames are kept. Overridden in
/// bootstrap with the app's folder.
final backgroundFilesProvider = Provider<BackgroundFiles>((ref) => BackgroundFiles(Directory.systemTemp, ref.watch(ffmpegRunnerProvider)));

final settingsStoreProvider = Provider<SettingsStore>((ref) => SettingsStore(ref.watch(prefsProvider)));

/// Settings loaded before `runApp` (so the first frame already has the right
/// theme). Overridden in bootstrap.
final initialSettingsProvider = Provider<AppSettings>((ref) => const AppSettings());

/// Holds [AppSettings], persists every change and applies side effects
/// (crossfade length goes straight to the player).
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final initial = ref.read(initialSettingsProvider);
    // Apply audio-related settings once at startup.
    Future.microtask(() => _applyAudio(initial));
    return initial;
  }

  void update(AppSettings Function(AppSettings s) change) {
    final next = change(state);
    if (next == state) return;
    final crossfadeChanged = next.crossfadeSeconds != state.crossfadeSeconds;
    state = next;
    unawaited(ref.read(settingsStoreProvider).save(next));
    if (crossfadeChanged) _applyAudio(next);
  }

  void setTheme(ThemeConfig theme) => update((s) => s.copyWith(theme: theme.sanitized()));
  void updateTheme(ThemeConfig Function(ThemeConfig t) change) => setTheme(change(state.theme));

  /// Picking a saved or imported theme also brings the background it was saved
  /// with, if any. Moving sliders in the theme editor goes through [setTheme].
  Future<void> applyTheme(ThemeConfig theme) async {
    setTheme(theme);
    final json = theme.background;
    if (json == null) return;
    final cfg = await ref.read(backgroundFilesProvider).fromThemeJson(json);
    if (cfg != null) update((s) => s.copyWith(background: cfg));
  }

  /// [theme] with the current background inside, for saving and exporting.
  Future<ThemeConfig> withCurrentBackground(ThemeConfig theme) async =>
      theme.copyWith(background: await ref.read(backgroundFilesProvider).toThemeJson(state.background));

  void _applyAudio(AppSettings s) {
    try {
      ref.read(playerControllerProvider).setCrossfade(s.crossfade);
    } on Object {
      // No player in widget tests.
    }
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// Saved/custom themes stored in SQLite (built-ins are not stored).
class SavedThemesRepository {
  SavedThemesRepository(this._db);
  final AppDatabase _db;

  Stream<List<(int, ThemeConfig)>> watchAll() => _db.select(_db.savedThemes).watch().map((rows) => [
        for (final r in rows)
          if (_tryParse(r.json) case final t?) (r.id, t),
      ]);

  Future<int> save(ThemeConfig theme) => _db
      .into(_db.savedThemes)
      .insert(SavedThemesCompanion.insert(name: theme.name, json: theme.toShareableJson()));

  Future<void> delete(int id) => (_db.delete(_db.savedThemes)..where((t) => t.id.equals(id))).go();

  Future<void> rename(int id, String name) async {
    final row = await (_db.select(_db.savedThemes)..where((t) => t.id.equals(id))).getSingleOrNull();
    final theme = row == null ? null : _tryParse(row.json);
    if (theme == null) return;
    final renamed = theme.copyWith(name: name);
    await (_db.update(_db.savedThemes)..where((t) => t.id.equals(id)))
        .write(SavedThemesCompanion(name: Value(name), json: Value(renamed.toShareableJson())));
  }

  static ThemeConfig? _tryParse(String json) {
    try {
      return ThemeConfig.fromShareableJson(json);
    } on FormatException {
      return null;
    }
  }
}

final savedThemesRepositoryProvider =
    Provider<SavedThemesRepository>((ref) => SavedThemesRepository(ref.watch(appDatabaseProvider)));

final savedThemesProvider =
    StreamProvider<List<(int, ThemeConfig)>>((ref) => ref.watch(savedThemesRepositoryProvider).watchAll());

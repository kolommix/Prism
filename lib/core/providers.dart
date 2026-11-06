import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db/app_database.dart';
import 'sources/track_source.dart';
import 'theme/album_palette.dart';

/// App-wide singletons. Values that need async setup are created in
/// `bootstrap.dart` and injected with `overrideWithValue`, so every provider
/// below is synchronous and easy to fake in tests.

final appDatabaseProvider = Provider<AppDatabase>((ref) => throw UnimplementedError('override in bootstrap'));

final prefsProvider = Provider<SharedPreferencesAsync>((ref) => SharedPreferencesAsync());

/// Directory for cached cover images.
final artworkDirProvider = Provider<Directory>((ref) => throw UnimplementedError('override in bootstrap'));

final trackSourcesProvider = Provider<TrackSourceRegistry>((ref) => throw UnimplementedError('override in bootstrap'));

final albumPaletteExtractorProvider = Provider<AlbumPaletteExtractor>((ref) => AlbumPaletteExtractor());

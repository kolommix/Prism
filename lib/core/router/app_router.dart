import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/audio_fx/presentation/equalizer_page.dart';
import '../../features/background/presentation/background_page.dart';
import '../../features/editor/presentation/editor_page.dart';
import '../../features/library/presentation/album_page.dart';
import '../../features/library/presentation/artist_page.dart';
import '../../features/library/presentation/folder_page.dart';
import '../../features/library/presentation/library_page.dart';
import '../../features/library/presentation/search_page.dart';
import '../../features/online/presentation/import_job_page.dart';
import '../../features/online/presentation/import_page.dart';
import '../../features/online/presentation/import_review_page.dart';
import '../../features/online/presentation/online_settings_page.dart';
import '../../features/player/presentation/immersive_player_page.dart';
import '../../features/player/presentation/now_playing_page.dart';
import '../../features/playlists/presentation/favorites_page.dart';
import '../../features/playlists/presentation/playlist_page.dart';
import '../../features/playlists/presentation/playlists_page.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/settings/presentation/theme_editor_page.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../features/stats/presentation/smart_playlist_page.dart';
import '../../features/stats/presentation/stats_page.dart';
import '../../features/tools/presentation/duplicates_page.dart';
import '../motion/page_transitions.dart';
import '../theme/prism_theme_extensions.dart';

import '../../features/metadata/presentation/metadata_fix_page.dart';
/// Route paths in one place so features never hard-code strings.
abstract final class Routes {
  static const library = '/library';
  static const search = '/search';
  static const playlists = '/playlists';
  static const settings = '/settings';
  static const player = '/player';

  /// Full-size player inside the app window (click on the side panel's cover).
  static const immersive = '/immersive';

  /// The same, and the Windows window goes full screen too.
  static const immersiveWindow = '/immersive?window=1';

  static String album(String name, String artist) =>
      Uri(path: '$library/album', queryParameters: {'name': name, 'artist': artist}).toString();
  static String artist(String name) => Uri(path: '$library/artist', queryParameters: {'name': name}).toString();
  static String folder(String path) => Uri(path: '$library/folder', queryParameters: {'path': path}).toString();
  static String playlist(int id) => '$playlists/$id';
  static const favorites = '$playlists/favorites';
  static const stats = '/stats';
  static String smartPlaylist(int id) => '$playlists/smart/$id';
  static const themeEditor = '$settings/theme';
  static const background = '$settings/background';
  static const equalizer = '$settings/equalizer';
  static const duplicates = '$settings/duplicates';
  static const onlineServices = '$settings/online';
  static const importPlaylists = '$playlists/import';
  static String importJob(int id) => '$playlists/import/$id';
  static const importReview = '$playlists/import/review';
  static String editor(int trackId) => '/editor/$trackId';

  /// Song info fixer for one or more songs.
  static String metadata(Iterable<int> ids) => Uri(path: '/metadata', queryParameters: {'ids': ids.join(',')}).toString();
}

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Builds the router.
///
/// * A [StatefulShellRoute] keeps each tab's stack alive (scroll position,
///   sub-pages) while switching tabs; [AppShell] cross-fades between them.
/// * The full-screen player lives on the root navigator so the mini-player
///   cover can fly into it with a [Hero].
GoRouter buildRouter() => GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: Routes.library,
  routes: [
    StatefulShellRoute(
      builder: (context, state, shell) => shell,
      navigatorContainerBuilder: (context, shell, children) => AppShell(shell: shell, children: children),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.library,
              builder: (_, _) => const LibraryPage(),
              routes: [
                GoRoute(
                  path: 'album',
                  builder: (_, s) => AlbumPage(
                    album: s.uri.queryParameters['name'] ?? '',
                    artist: s.uri.queryParameters['artist'] ?? '',
                  ),
                ),
                GoRoute(
                  path: 'artist',
                  builder: (_, s) => ArtistPage(artist: s.uri.queryParameters['name'] ?? ''),
                ),
                GoRoute(
                  path: 'folder',
                  builder: (_, s) => FolderPage(path: s.uri.queryParameters['path'] ?? ''),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.search, builder: (_, _) => const SearchPage())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.playlists,
              builder: (_, _) => const PlaylistsPage(),
              routes: [
                GoRoute(path: 'favorites', builder: (_, _) => const FavoritesPage()),
                GoRoute(
                  path: 'smart/:id',
                  builder: (_, s) => SmartPlaylistPage(id: int.tryParse(s.pathParameters['id'] ?? '') ?? 0),
                ),
                // Before ':id' so "import" isn't read as a playlist id.
                GoRoute(
                  path: 'import',
                  builder: (_, _) => const ImportPage(),
                  routes: [
                    // Before ':job' so "review" isn't read as a job id.
                    GoRoute(path: 'review', builder: (_, _) => const ImportReviewPage()),
                    GoRoute(
                      path: ':job',
                      builder: (_, s) => ImportJobPage(jobId: int.tryParse(s.pathParameters['job'] ?? '') ?? -1),
                    ),
                  ],
                ),
                GoRoute(
                  path: ':id',
                  builder: (_, s) => PlaylistPage(playlistId: int.tryParse(s.pathParameters['id'] ?? '') ?? -1),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [GoRoute(path: Routes.stats, builder: (_, _) => const StatsPage())],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.settings,
              builder: (_, _) => const SettingsPage(),
              routes: [
                GoRoute(path: 'theme', builder: (_, _) => const ThemeEditorPage()),
                GoRoute(path: 'background', builder: (_, _) => const BackgroundPage()),
                GoRoute(path: 'equalizer', builder: (_, _) => const EqualizerPage()),
                GoRoute(path: 'duplicates', builder: (_, _) => const DuplicatesPage()),
                GoRoute(path: 'online', builder: (_, _) => const OnlineSettingsPage()),
              ],
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/metadata',
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, s) => MetadataFixPage(idsKey: s.uri.queryParameters['ids'] ?? ''),
    ),
    GoRoute(
      path: '/editor/:id',
      parentNavigatorKey: rootNavigatorKey,
      builder: (_, s) => EditorPage(trackId: int.tryParse(s.pathParameters['id'] ?? '') ?? -1),
    ),
    GoRoute(
      path: Routes.player,
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        opaque: false,
        transitionDuration: context.motion.d(const Duration(milliseconds: 450)),
        reverseTransitionDuration: context.motion.d(const Duration(milliseconds: 350)),
        transitionsBuilder: (context, animation, _, child) => PrismPageTransitions.buildSheetUp(animation, child),
        child: const NowPlayingPage(),
      ),
    ),
    GoRoute(
      path: Routes.immersive,
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        transitionDuration: context.motion.d(const Duration(milliseconds: 550)),
        reverseTransitionDuration: context.motion.d(const Duration(milliseconds: 400)),
        // Plain fade: the cover flies across on its own (Hero).
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic), child: child),
        child: ImmersivePlayerPage(windowFullScreen: state.uri.queryParameters['window'] == '1'),
      ),
    ),
  ],
);

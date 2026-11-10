import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/widgets/led_dot.dart';
import '../../../l10n/l10n.dart';
import '../../library/application/library_providers.dart';
import '../../library/presentation/add_folder.dart';
import '../../shell/presentation/prism_logo.dart';

/// A short tour on the very first start: what Prism is, adding music, the
/// player, playlists and imports, making it yours. Shown once; Settings can
/// show it again.
abstract final class WelcomeTour {
  static const seenKey = 'tour.seen';

  /// Shows the tour on a fresh install. People who used Prism before (they
  /// have a saved session) skip it.
  static Future<void> maybeShow(BuildContext context, WidgetRef ref) async {
    final prefs = ref.read(prefsProvider);
    if (await prefs.getBool(seenKey) ?? false) return;
    final usedBefore = await prefs.getString('playback.last') != null;
    await prefs.setBool(seenKey, true);
    if (usedBefore || !context.mounted) return;
    await show(context);
  }

  static Future<void> show(BuildContext context) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _TourDialog(),
      );

  /// For tests: forget that it was seen.
  static Future<void> reset(SharedPreferencesAsync prefs) => prefs.remove(seenKey);
}

class _Page {
  const _Page({required this.title, required this.body, this.icon, this.logo = false, this.folder = false});
  final IconData? icon;
  final bool logo;
  final String title;
  final String body;

  /// Has the "add your music" buttons.
  final bool folder;
}

class _TourDialog extends ConsumerStatefulWidget {
  const _TourDialog();

  @override
  ConsumerState<_TourDialog> createState() => _TourDialogState();
}

class _TourDialogState extends ConsumerState<_TourDialog> {
  final _pages = PageController();
  int _index = 0;
  bool _adding = false;
  String? _added;

  static final _desktop = Platform.isWindows;

  List<_Page> get _content => [
        _Page(logo: true, title: l10n.tourWelcomeTitle, body: l10n.tourWelcomeBody),
        _Page(icon: Icons.create_new_folder_outlined, title: l10n.tourMusicTitle, body: l10n.tourMusicBody, folder: true),
        _Page(
          icon: Icons.play_circle_outline_rounded,
          title: l10n.tourPlayerTitle,
          body: _desktop ? l10n.tourPlayerBodyDesktop : l10n.tourPlayerBodyPhone,
        ),
        _Page(icon: Icons.queue_music_rounded, title: l10n.tourPlaylistsTitle, body: l10n.tourPlaylistsBody),
        _Page(
          icon: Icons.tune_rounded,
          title: l10n.tourYoursTitle,
          body: _desktop ? l10n.tourYoursBodyDesktop : l10n.tourYoursBodyPhone,
        ),
      ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _go(int i) {
    final pages = _content.length;
    if (i >= pages) {
      Navigator.of(context).pop();
      return;
    }
    if (i < 0) return;
    setState(() => _index = i);
    final d = context.motion.d(PrismMotion.medium);
    if (d == Duration.zero) {
      _pages.jumpToPage(i);
    } else {
      _pages.animateToPage(i, duration: d, curve: PrismMotion.curve);
    }
  }

  Future<void> _addFolder({String? path}) async {
    setState(() => _adding = true);
    try {
      await addLibraryFolder(context, ref, path: path);
      final folders = await ref.read(libraryRepositoryProvider).folders();
      if (mounted && folders.isNotEmpty) setState(() => _added = folders.last);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _content;
    final last = _index == pages.length - 1;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _go(_index + 1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _go(_index - 1),
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: context.shape.large),
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: SizedBox(
                      height: 380,
                      child: PageView(
                        controller: _pages,
                        onPageChanged: (i) => setState(() => _index = i),
                        children: [for (final p in pages) _page(p, scheme, text)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < pages.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: i == _index
                              ? const LedDot(size: 7)
                              : Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: scheme.onSurface.withValues(alpha: 0.25),
                                  ),
                                ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!last)
                        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.tourSkip)),
                      Expanded(
                        // Long labels (Russian, narrow phones) wrap instead of overflowing.
                        child: OverflowBar(
                          alignment: MainAxisAlignment.end,
                          overflowAlignment: OverflowBarAlignment.end,
                          spacing: 4,
                          overflowSpacing: 4,
                          children: [
                            if (_index > 0)
                              TextButton(onPressed: () => _go(_index - 1), child: Text(l10n.tourBack)),
                            FilledButton(
                              onPressed: () => _go(_index + 1),
                              child: Text(last ? l10n.tourDone : l10n.tourNext),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _page(_Page p, ColorScheme scheme, TextTheme text) {
    final music = p.folder ? defaultMusicFolder() : null;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (p.logo)
            const PrismLogo(size: 44)
          else
            Icon(p.icon, size: 40, color: scheme.onSurface),
          const SizedBox(height: 20),
          Text(p.title, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Text(p.body, style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant, height: 1.45)),
          if (p.folder) ...[
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (music != null)
                  FilledButton.tonalIcon(
                    onPressed: _adding ? null : () => _addFolder(path: music),
                    icon: const Icon(Icons.library_music_outlined),
                    label: Text(l10n.tourUseMusicFolder),
                  ),
                OutlinedButton.icon(
                  onPressed: _adding ? null : _addFolder,
                  icon: const Icon(Icons.folder_open_rounded),
                  label: Text(l10n.tourChooseFolder),
                ),
              ],
            ),
            if (_added != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const LedDot(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.tourFolderAdded(_added!),
                      style: text.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

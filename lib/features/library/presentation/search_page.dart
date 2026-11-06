import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/smooth_scroll.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../online/application/online_providers.dart';
import '../../online/domain/external_track.dart';
import '../../online/domain/online_error.dart';
import '../application/library_providers.dart';
import 'widgets/library_widgets.dart';
import 'widgets/track_tile.dart';
import '../../../l10n/l10n.dart';

/// One search box for everything: the local library (instant, debounced
/// 150 ms) plus every enabled online service (debounced 450 ms, each in its
/// own section – one slow or broken service never hides the others).
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;

  /// Sources the user turned off with the chips (library = null key).
  final _hidden = <OnlineService?>{};

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(searchQueryProvider);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () => ref.read(searchQueryProvider.notifier).set(q));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    ref.watch(onlineRevisionProvider);
    final services = [for (final m in ref.watch(onlineHubProvider).searchable) m.service];
    final showLocal = !_hidden.contains(null);
    final online = [
      for (final s in services)
        if (!_hidden.contains(s)) s,
    ];
    final text = Theme.of(context).textTheme;

    Widget header(String title, IconData icon) => SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: text.titleSmall),
          ],
        ),
      ),
    );
    Widget note(String msg) => SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(msg, style: text.bodyMedium),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: SmoothCustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _controller,
                  autofocus: false,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: services.isEmpty ? l10n.songsArtistsAlbums : l10n.songsArtistsAlbumsHereAndOnline,
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _controller.clear();
                              _onChanged('');
                            },
                          ),
                  ),
                ),
              ),
            ),
            if (services.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 6,
                    children: [
                      for (final s in <OnlineService?>[null, ...services])
                        FilterChip(
                          label: Text(s?.label ?? l10n.xLibrary),
                          selected: !_hidden.contains(s),
                          onSelected: (on) => setState(() => on ? _hidden.remove(s) : _hidden.add(s)),
                        ),
                    ],
                  ),
                ),
              ),
            if (query.trim().isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    services.isEmpty ? l10n.typeToSearchYourLibrary : l10n.typeToSearchYourLibraryAnd,
                  ),
                ),
              )
            else ...[
              if (showLocal) ...[
                if (online.isNotEmpty) header(l10n.yourLibrary, Icons.library_music_rounded),
                // Keep old results visible while the next query runs (no flicker).
                switch (results) {
                  AsyncValue(:final value?) when value.isEmpty => note(l10n.nothingFoundInYourLibrary),
                  AsyncValue(:final value?) => SliverAnimatedOpacity(
                    opacity: results.isLoading ? 0.6 : 1,
                    duration: context.motion.d(PrismMotion.short),
                    sliver: TrackSliverList(tracks: online.isEmpty ? value : value.take(30).toList()),
                  ),
                  AsyncValue(:final error?) => note('$error'),
                  _ => const SliverToBoxAdapter(child: LinearProgressIndicator()),
                },
              ],
              for (final s in online) ...[
                header(s.label, s == OnlineService.youtube ? Icons.smart_display_rounded : Icons.cloud_rounded),
                _OnlineResults(service: s, query: query),
              ],
            ],
            SliverPadding(padding: EdgeInsets.only(bottom: bottomInset(context))),
          ],
        ),
      ),
    );
  }
}

class _OnlineResults extends ConsumerWidget {
  const _OnlineResults({required this.service, required this.query});
  final OnlineService service;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final res = ref.watch(onlineSearchProvider((service: service, query: query)));
    return switch (res) {
      AsyncValue(:final value?) when value.isEmpty && !res.isLoading => SliverToBoxAdapter(
        child: Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 8), child: Text(l10n.nothingFound)),
      ),
      AsyncValue(:final value?) when !res.isLoading => SliverList.builder(
        itemCount: value.length,
        itemBuilder: (_, i) => TrackTile(
          track: value[i],
          onTap: () => playTracksAnywhere(ref, value, startIndex: i),
        ),
      ),
      AsyncValue(:final error?) when !res.isLoading => SliverToBoxAdapter(
        child: ListTile(
          leading: Icon(Icons.cloud_off_rounded, color: Theme.of(context).colorScheme.error),
          title: Text(describeOnlineError(error)),
          trailing: IconButton(
            tooltip: l10n.tryAgain,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(onlineSearchProvider((service: service, query: query))),
          ),
        ),
      ),
      _ => const SliverToBoxAdapter(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: LinearProgressIndicator()),
      ),
    };
  }
}

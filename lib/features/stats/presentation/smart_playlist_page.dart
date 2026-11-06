import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../library/presentation/library_page.dart';
import '../../library/presentation/widgets/library_widgets.dart';
import '../../playlists/presentation/playlist_dialogs.dart';
import '../application/stats_providers.dart';
import '../domain/smart_playlist.dart';
import '../../../l10n/l10n.dart';

/// Tracks of one smart playlist (updates live as you listen).
class SmartPlaylistPage extends ConsumerWidget {
  const SmartPlaylistPage({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(smartPlaylistsProvider).value;
    final p = all?.where((x) => x.id == id).firstOrNull;
    if (p == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(child: all == null ? const CircularProgressIndicator() : Text(l10n.smartPlaylistNotFound)),
      );
    }
    return CollectionPage(
      tracks: ref.watch(smartTracksProvider(p)),
      header: (list) => CollectionHeader(
        title: smartPlaylistLabel(p.name),
        subtitle: '${l10n.nSongs(list.length)} · ${describeRules(p)}',
        artworkPath: list.where((t) => t.artworkPath != null).firstOrNull?.artworkPath,
        icon: Icons.sort_rounded,
        tracks: list,
        actions: [
          if (p.id > 0) ...[
            const SizedBox(width: 8),
            IconButton(
              tooltip: l10n.editRules,
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => showSmartPlaylistEditor(context, ref, initial: p),
            ),
            IconButton(
              tooltip: l10n.delete,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                if (!await confirmDelete(context, '"${p.name}"')) return;
                await ref.read(statsRepositoryProvider).deleteSmartPlaylist(p.id);
                if (context.mounted) context.pop();
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// Short human description of the rules ("played 2+ times · 2000–2009").
String describeRules(SmartPlaylist p) => p.rules.isEmpty
    ? l10n.allSongs
    : p.rules
        .map((r) => switch (r) {
              MostPlayedRule(:final minPlays, :final days) =>
                '${l10n.playedNPlus(minPlays)}${days == null ? '' : ' ${l10n.inDays(days)}'}',
              RecentlyAddedRule(:final days) => l10n.addedInTheLastDays(days),
              GenreRule(:final genre) => l10n.genre(genre),
              YearRule(:final from, :final to) => l10n.year2(from ?? '…', to ?? '…'),
              NotPlayedForRule(:final days) => l10n.notPlayedForDays(days),
            })
        .join(' · ');

/// Create or edit a smart playlist.
Future<void> showSmartPlaylistEditor(BuildContext context, WidgetRef ref, {SmartPlaylist? initial}) async {
  final result = await showDialog<SmartPlaylist>(
    context: context,
    useRootNavigator: true,
    builder: (context) => _SmartEditor(initial: initial ?? SmartPlaylist(name: l10n.mySmartPlaylist, rules: [SmartRule.mostPlayed()])),
  );
  if (result != null) await ref.read(statsRepositoryProvider).saveSmartPlaylist(result);
}

class _SmartEditor extends StatefulWidget {
  const _SmartEditor({required this.initial});
  final SmartPlaylist initial;

  @override
  State<_SmartEditor> createState() => _SmartEditorState();
}

class _SmartEditorState extends State<_SmartEditor> {
  late final _name = TextEditingController(text: widget.initial.name);
  late List<SmartRule> _rules = [...widget.initial.rules];
  late SmartSort _sort = widget.initial.sort;
  late int _limit = widget.initial.limit;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Widget _numberField(String label, int? value, ValueChanged<int?> onChanged) => SizedBox(
        width: 90,
        child: TextFormField(
          initialValue: value?.toString() ?? '',
          decoration: InputDecoration(labelText: label, isDense: true),
          keyboardType: TextInputType.number,
          onChanged: (v) => onChanged(int.tryParse(v)),
        ),
      );

  Widget _ruleRow(int i) {
    final r = _rules[i];
    void set(SmartRule n) => setState(() => _rules[i] = n);
    final fields = switch (r) {
      MostPlayedRule(:final minPlays, :final days) => [
          _numberField(l10n.minPlays, minPlays, (v) => set(SmartRule.mostPlayed(minPlays: v ?? 1, days: days))),
          _numberField(l10n.inDays2, days, (v) => set(SmartRule.mostPlayed(minPlays: minPlays, days: v))),
        ],
      RecentlyAddedRule(:final days) => [_numberField('days', days, (v) => set(SmartRule.recentlyAdded(days: v ?? 30)))],
      GenreRule(:final genre) => [
          SizedBox(
            width: 150,
            child: TextFormField(
              initialValue: genre,
              decoration: const InputDecoration(labelText: 'genre', isDense: true),
              onChanged: (v) => set(SmartRule.genre(genre: v)),
            ),
          ),
        ],
      YearRule(:final from, :final to) => [
          _numberField('from', from, (v) => set(SmartRule.year(from: v, to: to))),
          _numberField('to', to, (v) => set(SmartRule.year(from: from, to: v))),
        ],
      NotPlayedForRule(:final days) => [_numberField('days', days, (v) => set(SmartRule.notPlayedFor(days: v ?? 90)))],
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        DropdownButton<String>(
          value: r.runtimeType.toString(),
          items: [
            DropdownMenuItem(value: 'MostPlayedRule', child: Text(l10n.mostPlayed)),
            DropdownMenuItem(value: 'RecentlyAddedRule', child: Text(l10n.recentlyAdded)),
            DropdownMenuItem(value: 'GenreRule', child: Text(l10n.genre2)),
            DropdownMenuItem(value: 'YearRule', child: Text(l10n.year)),
            DropdownMenuItem(value: 'NotPlayedForRule', child: Text(l10n.notPlayedFor)),
          ],
          onChanged: (v) => set(switch (v) {
            'RecentlyAddedRule' => const SmartRule.recentlyAdded(),
            'GenreRule' => const SmartRule.genre(genre: ''),
            'YearRule' => const SmartRule.year(),
            'NotPlayedForRule' => const SmartRule.notPlayedFor(),
            _ => const SmartRule.mostPlayed(),
          }),
        ),
        const SizedBox(width: 8),
        ...fields.expand((f) => [f, const SizedBox(width: 8)]),
        const Spacer(),
        IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _rules.removeAt(i))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial.id > 0 ? l10n.editSmartPlaylist : l10n.newSmartPlaylist),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: _name, decoration: InputDecoration(labelText: l10n.name)),
            const SizedBox(height: 12),
            Text(l10n.songsThatMatchAllRules),
            for (var i = 0; i < _rules.length; i++) _ruleRow(i),
            TextButton.icon(
              onPressed: () => setState(() => _rules = [..._rules, const SmartRule.recentlyAdded()]),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addRule),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Text(l10n.sortBy),
              DropdownButton<SmartSort>(
                value: _sort,
                items: [
                  DropdownMenuItem(value: SmartSort.plays, child: Text(l10n.mostPlayed)),
                  DropdownMenuItem(value: SmartSort.recentlyAdded, child: Text(l10n.recentlyAdded)),
                  DropdownMenuItem(value: SmartSort.title, child: Text(l10n.title)),
                  DropdownMenuItem(value: SmartSort.random, child: Text(l10n.random)),
                ],
                onChanged: (v) => setState(() => _sort = v ?? _sort),
              ),
              const SizedBox(width: 16),
              _numberField(l10n.maxSongs, _limit, (v) => _limit = (v ?? 100).clamp(1, 5000)),
            ]),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            widget.initial.copyWith(
              name: _name.text.trim().isEmpty ? l10n.smartPlaylist : _name.text.trim(),
              rules: _rules,
              sort: _sort,
              limit: _limit,
            ),
          ),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Grid tile used in the playlists page.
class SmartPlaylistTile extends StatelessWidget {
  const SmartPlaylistTile({super.key, required this.playlist, required this.onTap});
  final SmartPlaylist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: scheme.onSurface.withValues(alpha: 0.08),
        ),
        child: Icon(Icons.sort_rounded, color: scheme.onSurface),
      ),
      title: Text(smartPlaylistLabel(playlist.name)),
      subtitle: Text(describeRules(playlist), maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}


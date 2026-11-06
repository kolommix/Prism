import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/smooth_scroll.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/widgets/artwork.dart';
import '../../../core/widgets/glass.dart';
import '../../../l10n/l10n.dart';
import '../../player/presentation/widgets/waveform_seek_bar.dart';
import '../application/metadata_controller.dart';
import '../domain/metadata_candidate.dart';

String metaFieldLabel(MetaField f) => switch (f) {
      MetaField.title => l10n.title,
      MetaField.artist => l10n.artist,
      MetaField.album => l10n.album,
      MetaField.year => l10n.year,
      MetaField.track => l10n.track,
      MetaField.genre => l10n.genre2,
      MetaField.cover => l10n.cover,
    };

/// Fixes song info: manual edit, search with side-by-side comparison, and batch
/// fixing of an album or folder.
class MetadataFixPage extends ConsumerWidget {
  const MetadataFixPage({super.key, required this.idsKey});

  /// Track ids joined by commas.
  final String idsKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(metadataFixProvider(idsKey));
    final ctrl = ref.read(metadataFixProvider(idsKey).notifier);
    final batch = s.items.length > 1;
    final cur = s.current;

    ref.listen(metadataFixProvider(idsKey).select((x) => (x.saving, x.savedCount, x.saveError)), (prev, next) {
      if (prev?.$1 != true || next.$1) return;
      final m = ScaffoldMessenger.maybeOf(context);
      if (next.$3 != null) {
        m?.showSnackBar(SnackBar(content: Text(l10n.metaSaveFailed(next.$3!))));
      } else if (next.$2 > 0) {
        m?.showSnackBar(SnackBar(content: Text(l10n.metaSavedN(next.$2))));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.metaTitle),
        actions: [
          if (batch)
            TextButton.icon(
              icon: const Icon(Icons.travel_explore_rounded, size: 18),
              label: Text(l10n.metaSearchAll),
              onPressed: s.searching ? null : ctrl.searchAll,
            ),
          if (batch)
            TextButton.icon(
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: Text(l10n.metaSaveAll),
              onPressed: s.saving || s.items.every((i) => !i.canSave) ? null : () => ctrl.save(all: true),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 8),
            child: FilledButton(
              onPressed: s.saving || cur == null || !cur.canSave ? null : () => ctrl.save(all: false),
              child: Text(l10n.metaSave),
            ),
          ),
        ],
        bottom: s.saving || s.searching
            ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator(minHeight: 2))
            : null,
      ),
      body: cur == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 860;
              final detail = _Detail(key: ValueKey(cur.track.id), item: cur, ctrl: ctrl);
              if (!batch) return detail;
              final list = _BatchList(state: s, ctrl: ctrl);
              if (wide) {
                return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SizedBox(width: 300, child: list),
                  const VerticalDivider(width: 1),
                  Expanded(child: detail),
                ]);
              }
              return Column(children: [
                SizedBox(height: 180, child: list),
                const Divider(height: 1),
                Expanded(child: detail),
              ]);
            }),
    );
  }
}

class _BatchList extends StatelessWidget {
  const _BatchList({required this.state, required this.ctrl});
  final FixState state;
  final MetadataFixController ctrl;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SmoothScroll(
      builder: (scroll) => ListView.builder(
        controller: scroll,
        itemCount: state.items.length,
        itemBuilder: (context, i) {
          final it = state.items[i];
          final best = it.chosen?.score;
          return ListTile(
            dense: true,
            selected: i == state.selected,
            leading: _StatusIcon(status: it.status),
            title: Text(it.track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              it.chosen == null ? it.track.displayArtist : '${it.chosen!.artist} · ${it.chosen!.album}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: best == null ? null : Text('${(best * 100).round()} %', style: text.labelSmall),
            onTap: () => ctrl.select(i),
          );
        },
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final FixStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (status) {
      FixStatus.waiting => Icon(Icons.radio_button_unchecked_rounded, size: 18, color: scheme.onSurfaceVariant),
      FixStatus.searching => const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      FixStatus.found => Icon(Icons.search_rounded, size: 18, color: context.look.led),
      FixStatus.notFound => Icon(Icons.search_off_rounded, size: 18, color: scheme.onSurfaceVariant),
      FixStatus.failed => Icon(Icons.error_outline_rounded, size: 18, color: scheme.error),
      FixStatus.saved => Icon(Icons.check_rounded, size: 18, color: scheme.onSurface),
    };
  }
}

class _Detail extends StatefulWidget {
  const _Detail({super.key, required this.item, required this.ctrl});
  final FixItem item;
  final MetadataFixController ctrl;

  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  late final _title = TextEditingController(text: widget.item.track.title);
  late final _artist = TextEditingController(text: widget.item.track.artist);

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final ctrl = widget.ctrl;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SmoothListView(padding: const EdgeInsets.all(16), children: [
      GlassPanel(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          SizedBox(width: 260, child: TextField(controller: _title, decoration: InputDecoration(labelText: l10n.title, isDense: true))),
          SizedBox(width: 200, child: TextField(controller: _artist, decoration: InputDecoration(labelText: l10n.artist, isDense: true))),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.search_rounded, size: 18),
            label: Text(l10n.metaResearch),
            onPressed: it.status == FixStatus.searching ? null : () => ctrl.searchCurrent(title: _title.text, artist: _artist.text),
          ),
        ]),
      ),
      if (it.error != null) ...[
        const SizedBox(height: 8),
        Text(it.error!, style: text.bodySmall?.copyWith(color: scheme.error)),
      ],
      if (it.status == FixStatus.notFound) ...[
        const SizedBox(height: 8),
        Text(l10n.metaNothingFound, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      ],
      const SizedBox(height: 12),
      _DiffTable(item: it, ctrl: ctrl),
      const SizedBox(height: 12),
      _CoverRow(item: it, ctrl: ctrl),
      if (it.candidates.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(l10n.metaCandidates, style: text.titleSmall),
        const SizedBox(height: 6),
        for (final c in it.candidates.take(14))
          _CandidateTile(candidate: c, selected: identical(c, it.chosen), track: it, onTap: () => ctrl.choose(c)),
      ],
    ]);
  }
}

/// Current value, arrow, new value (editable), tick = write this field.
class _DiffTable extends StatelessWidget {
  const _DiffTable({required this.item, required this.ctrl});
  final FixItem item;
  final MetadataFixController ctrl;

  String _current(MetaField f) => switch (f) {
        MetaField.title => item.track.title,
        MetaField.artist => item.track.artist,
        MetaField.album => item.track.album,
        MetaField.year => item.track.year?.toString() ?? '',
        MetaField.track => item.track.trackNumber?.toString() ?? '',
        MetaField.genre => item.track.genre,
        MetaField.cover => '',
      };

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return GlassPanel(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(children: [
        for (final f in MetaField.values)
          if (f != MetaField.cover)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(children: [
                SizedBox(
                  width: 28,
                  child: Checkbox(
                    value: item.apply.contains(f),
                    visualDensity: VisualDensity.compact,
                    onChanged: (v) => ctrl.toggleField(f, v ?? false),
                  ),
                ),
                const SizedBox(width: 4),
                SizedBox(width: 92, child: Text(metaFieldLabel(f), style: text.labelMedium)),
                Expanded(
                  child: Text(
                    _current(f).isEmpty ? '—' : _current(f),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward_rounded, size: 14)),
                Expanded(
                  child: _ValueField(
                    key: ValueKey('$f${item.chosen.hashCode}'),
                    initial: item.values[f] ?? '',
                    changed: item.apply.contains(f),
                    onChanged: (v) => ctrl.setValue(f, v),
                  ),
                ),
              ]),
            ),
      ]),
    );
  }
}

class _ValueField extends StatefulWidget {
  const _ValueField({super.key, required this.initial, required this.changed, required this.onChanged});
  final String initial;
  final bool changed;
  final ValueChanged<String> onChanged;

  @override
  State<_ValueField> createState() => _ValueFieldState();
}

class _ValueFieldState extends State<_ValueField> {
  late final _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _c,
        onChanged: widget.onChanged,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: widget.changed ? FontWeight.w600 : null),
        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
      );
}

class _CoverRow extends StatelessWidget {
  const _CoverRow({required this.item, required this.ctrl});
  final FixItem item;
  final MetadataFixController ctrl;

  Future<void> _pick() async {
    final f = await FilePicker.pickFile(type: FileType.image, dialogTitle: l10n.chooseCoverImage);
    if (f != null) ctrl.setOwnCover(await f.readAsBytes());
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final url = item.coverUrls.firstOrNull;
    return GlassPanel(
      padding: const EdgeInsets.all(12),
      child: Wrap(spacing: 12, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Artwork(path: item.track.artworkPath, size: 72, seed: item.track.album, icon: Icons.album_rounded),
        const Icon(Icons.arrow_forward_rounded, size: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(context.shape.radius / 2),
          child: SizedBox.square(
            dimension: 72,
            child: item.ownCover != null
                ? Image.memory(item.ownCover!, fit: BoxFit.cover)
                : url == null
                    ? const ColoredBox(color: Colors.black12, child: Icon(Icons.image_not_supported_outlined))
                    : Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.image_not_supported_outlined)),
          ),
        ),
        Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.cover, style: text.labelMedium),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Checkbox(
              value: item.useCover,
              visualDensity: VisualDensity.compact,
              onChanged: item.coverUrls.isEmpty ? null : (v) => ctrl.setUseCover(v ?? false),
            ),
            Text(l10n.metaUseCover),
          ]),
        ]),
        OutlinedButton(onPressed: _pick, child: Text(l10n.changeCover)),
        TextButton(onPressed: () => ctrl.setRemoveCover(!item.removeCover), child: Text(item.removeCover ? l10n.edKeepCover : l10n.removeCover)),
      ]),
    );
  }
}

class _CandidateTile extends StatelessWidget {
  const _CandidateTile({required this.candidate, required this.selected, required this.track, required this.onTap});
  final MetaCandidate candidate;
  final bool selected;
  final FixItem track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = candidate;
    final bits = [
      c.artist,
      c.album,
      if (c.year != null) '${c.year}',
      if (c.durationMs > 0) formatDuration(Duration(milliseconds: c.durationMs)),
      c.source,
    ].where((b) => b.isNotEmpty).join(' · ');
    return ListTile(
      dense: true,
      selected: selected,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: SizedBox(
        width: 40,
        child: Text('${(c.score * 100).round()} %', style: Theme.of(context).textTheme.labelMedium, textAlign: TextAlign.end),
      ),
      title: Text(c.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(bits, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}

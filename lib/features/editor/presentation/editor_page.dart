import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/smooth_scroll.dart';
import '../../../core/motion/spring_button.dart';
import '../../../core/theme/prism_theme_extensions.dart';
import '../../../core/widgets/glass.dart';
import '../../../l10n/l10n.dart';
import '../../library/application/library_providers.dart';
import '../../library/domain/track.dart';
import '../../player/presentation/widgets/waveform_seek_bar.dart';
import '../application/editor_controller.dart';
import '../domain/edit_decision_list.dart';
import 'edit_waveform.dart';
import 'export_dialog.dart';
import 'segment_panels.dart';

/// Non-destructive audio editor for one track.
class EditorPage extends ConsumerStatefulWidget {
  const EditorPage({super.key, required this.trackId});
  final int trackId;

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  WaveView? _view;

  EditorController get _ctrl => ref.read(editorControllerProvider(widget.trackId).notifier);
  EditorState get _s => ref.read(editorControllerProvider(widget.trackId));

  void _snack(String msg) => ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(msg)));

  void _setView(WaveView v) {
    setState(() => _view = v);
    _ctrl.setView(v.start, v.length);
  }

  WaveView _viewOf(EditorState s) {
    final total = s.timeline!.duration;
    final stored = _view ?? (s.restoredViewLength > Duration.zero ? WaveView(start: s.restoredViewStart, length: s.restoredViewLength) : null);
    return (stored ?? WaveView(start: Duration.zero, length: total)).clampTo(total);
  }

  void _zoomBy(double factor) {
    final s = _s;
    if (!s.ready) return;
    final v = _viewOf(s);
    final center = s.previewPlaying ? _ctrl.currentPosition() : s.cursor;
    final len = Duration(microseconds: (v.length.inMicroseconds / factor).round());
    _setView(WaveView(start: center - len ~/ 2, length: len).clampTo(s.timeline!.duration));
  }

  void _zoomToFit() {
    final s = _s;
    if (s.ready) _setView(WaveView(start: Duration.zero, length: s.timeline!.duration));
  }

  void _nudge(int ms) {
    final s = _s;
    if (!s.ready) return;
    final total = s.timeline!.duration;
    final t = s.cursor + Duration(milliseconds: ms);
    _ctrl.seekPreview(t < Duration.zero ? Duration.zero : (t > total ? total : t));
  }

  /// Keeps the playing position on screen by turning the page.
  void _follow(EditorState s, WaveView v) {
    if (!s.previewPlaying || !s.followPlayhead) return;
    final pos = s.previewPos;
    if (pos < v.start || pos > v.start + v.length * 0.92) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _setView(WaveView(start: pos - v.length ~/ 10, length: v.length).clampTo(s.timeline!.duration));
      });
    }
  }

  void _withSelection(void Function(int a, int b) run) {
    final s = _s;
    if (!s.hasSelection) return _snack(l10n.dragOnTheWaveformToSelect);
    run(s.selStart.inMilliseconds, s.selEnd.inMilliseconds);
  }

  void _splitHere() {
    final s = _s;
    if (s.ready) _ctrl.apply(EditOp.split(atMs: s.cursor.inMilliseconds));
  }

  Future<void> _askLoop() async {
    if (!_s.hasSelection) return _snack(l10n.dragOnTheWaveformToSelect);
    final v = await askValue(context, l10n.edLoopTitle, 2, 16, 2, (v) => l10n.nTimes(v.round()), divisions: 14);
    if (v != null) _withSelection((a, b) => _ctrl.apply(EditOp.loop(startMs: a, endMs: b, times: v.round())));
  }

  Future<void> _askMerge() async {
    final picked = await showDialog<List<Track>>(
      context: context,
      builder: (_) => _MergeDialog(excludeId: widget.trackId),
    );
    if (picked != null && picked.isNotEmpty) await _ctrl.merge(picked);
  }

  Future<void> _ringtone() async {
    try {
      if (RingtoneService.supported && await RingtoneService.needsPermission()) {
        await RingtoneService.openPermission();
        _snack(l10n.edRingtoneAllow);
        return;
      }
      final path = await _ctrl.makeRingtone();
      if (path == null) return;
      if (RingtoneService.supported) {
        await RingtoneService.set(path, _s.track!.title);
        _snack(l10n.edRingtoneDone);
      } else {
        final uri = await FilePicker.saveFile(
          fileName: '${_s.track!.title} (ringtone).m4a',
          bytes: await File(path).readAsBytes(),
          dialogTitle: l10n.edRingtoneSave,
          mimeType: 'audio/mp4',
        );
        if (uri != null) _snack(l10n.exported);
      }
    } on Object catch (e) {
      _snack(l10n.exportFailed(e));
    }
  }

  void _quick(bool done) {
    if (!done) _snack(l10n.edNothingToDo);
  }

  Future<void> _askLoudness() async {
    final current = _s.timeline?.loudnessLufs;
    final v = await askValue(context, l10n.edLoudnessTitle, -30, -8, current ?? -14, (v) => '${fmtNum(v, 0)} LUFS', divisions: 22);
    if (v != null) _ctrl.apply(EditOp.loudness(lufs: v.roundToDouble()));
  }

  Map<ShortcutActivator, VoidCallback> get _shortcuts => {
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): _ctrl.undo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): _ctrl.redo,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): _ctrl.redo,
        const SingleActivator(LogicalKeyboardKey.space): _ctrl.togglePreview,
        const SingleActivator(LogicalKeyboardKey.keyS): _splitHere,
        const SingleActivator(LogicalKeyboardKey.delete): () => _withSelection((a, b) => _ctrl.apply(EditOp.cut(startMs: a, endMs: b))),
        const SingleActivator(LogicalKeyboardKey.delete, shift: true): () =>
            _withSelection((a, b) => _ctrl.apply(EditOp.silence(startMs: a, endMs: b))),
        const SingleActivator(LogicalKeyboardKey.keyT): () => _withSelection((a, b) => _ctrl.apply(EditOp.trim(startMs: a, endMs: b))),
        const SingleActivator(LogicalKeyboardKey.keyD, control: true): () =>
            _withSelection((a, b) => _ctrl.apply(EditOp.duplicate(startMs: a, endMs: b))),
        const SingleActivator(LogicalKeyboardKey.keyA, control: true): _ctrl.selectAll,
        const SingleActivator(LogicalKeyboardKey.keyR): () => _withSelection((a, b) => _ctrl.apply(EditOp.reverse(startMs: a, endMs: b))),
        const SingleActivator(LogicalKeyboardKey.keyL): _ctrl.toggleLoop,
        const SingleActivator(LogicalKeyboardKey.keyB): () => _ctrl.setPreviewB(!_s.previewB),
        const SingleActivator(LogicalKeyboardKey.escape): () => _ctrl.setSelection(null, null),
        const SingleActivator(LogicalKeyboardKey.equal): () => _zoomBy(1.5),
        const SingleActivator(LogicalKeyboardKey.minus): () => _zoomBy(1 / 1.5),
        const SingleActivator(LogicalKeyboardKey.digit0): _zoomToFit,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _nudge(-1000),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _nudge(1000),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): () => _nudge(-50),
        const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): () => _nudge(50),
        const SingleActivator(LogicalKeyboardKey.home): () => _ctrl.seekPreview(Duration.zero),
        const SingleActivator(LogicalKeyboardKey.end): () => _ctrl.seekPreview(_s.timeline?.duration ?? Duration.zero),
        const SingleActivator(LogicalKeyboardKey.keyE, control: true): () => showExportDialog(context, _ctrl, _s),
      };

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(editorControllerProvider(widget.trackId));
    final text = Theme.of(context).textTheme;
    final t = s.timeline;

    if (!s.ready || t == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.editor)),
        body: Center(
          child: s.error != null
              ? Text(s.error!)
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(l10n.readingWaveform),
                ]),
        ),
      );
    }

    final view = _viewOf(s);
    _follow(s, view);
    final zoom = t.duration.inMicroseconds / view.length.inMicroseconds;

    final waveColumn = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
        child: Wrap(spacing: 12, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(l10n.editedVsOriginal(formatDuration(t.duration), formatDuration(s.sourceDuration)), style: text.labelMedium),
          if (s.hasSelection) Text(l10n.selection(formatDuration(s.selStart), formatDuration(s.selEnd)), style: text.labelMedium),
          if (s.previewRendering) Text(l10n.edRenderingPreview, style: text.labelMedium),
        ]),
      ),
      Expanded(
        child: GlassPanel(
          padding: const EdgeInsets.all(8),
          child: EditWaveform(
            timeline: t,
            pyramid: s.pyramid,
            others: s.others,
            view: view,
            onViewChanged: _setView,
            selection: s.selA == null || s.selB == null ? null : (s.selA!, s.selB!),
            onSelection: _ctrl.setSelection,
            onSelectionEnd: _ctrl.refineSelection,
            cursor: s.cursor,
            onCursor: _ctrl.seekPreview,
            snapPoints: s.snapPoints,
            position: _ctrl.currentPosition,
            playing: s.previewPlaying,
            beats: s.snapBeats && s.analysis != null ? [for (final b in s.analysis!.beats) t.sourceToOutput(b)] : const [],
          ),
        ),
      ),
      const SizedBox(height: 6),
      WaveOverview(timeline: t, pyramid: s.pyramid, others: s.others, view: view, onViewChanged: _setView),
      const SizedBox(height: 6),
      SegmentLane(
        timeline: t,
        cursor: s.cursor,
        selection: s.hasSelection ? (s.selStart, s.selEnd) : null,
        onSelect: _ctrl.setSelection,
        onMove: (from, to) => _ctrl.apply(EditOp.move(from: from, to: to)),
      ),
      const SizedBox(height: 6),
      _PreviewBar(state: s, ctrl: _ctrl, zoom: zoom, onZoom: _zoomBy, onFit: _zoomToFit),
    ]);

    final tools = _ToolsPanel(
      state: s,
      ctrl: _ctrl,
      onSplit: _splitHere,
      onLoop: _askLoop,
      onMerge: _askMerge,
      onRingtone: _ringtone,
      onQuick: _quick,
      onLoudness: _askLoudness,
      withSelection: _withSelection,
    );

    return CallbackShortcuts(
      bindings: _shortcuts,
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            title: Text(s.track!.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(tooltip: l10n.undoCtrlZ, icon: const Icon(Icons.undo_rounded), onPressed: s.history.canUndo ? _ctrl.undo : null),
              IconButton(tooltip: l10n.redoCtrlY, icon: const Icon(Icons.redo_rounded), onPressed: s.history.canRedo ? _ctrl.redo : null),
              Padding(
                padding: const EdgeInsets.only(right: 8, left: 4),
                child: FilledButton.icon(
                  icon: const Icon(Icons.ios_share_rounded, size: 18),
                  label: Text(l10n.edExport),
                  onPressed: s.busy == null ? () => showExportDialog(context, _ctrl, s) : null,
                ),
              ),
            ],
          ),
          body: Stack(children: [
            LayoutBuilder(builder: (context, c) {
              final wide = c.maxWidth >= 920;
              if (wide) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Expanded(child: waveColumn),
                    const SizedBox(width: 12),
                    SizedBox(width: 340, child: tools),
                  ]),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(flex: 5, child: waveColumn),
                  const SizedBox(height: 8),
                  Expanded(flex: 4, child: tools),
                ]),
              );
            }),
            if (s.busy != null)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black45,
                  child: Center(
                    child: GlassPanel(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(s.busy!, style: text.titleMedium),
                        const SizedBox(height: 12),
                        SizedBox(width: 260, child: LinearProgressIndicator(value: s.progress)),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _ctrl.cancelExport, child: Text(l10n.cancel)),
                      ]),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Edit / Segment / Quick tabs.
class _ToolsPanel extends StatelessWidget {
  const _ToolsPanel({
    required this.state,
    required this.ctrl,
    required this.onSplit,
    required this.onLoop,
    required this.onMerge,
    required this.onRingtone,
    required this.onQuick,
    required this.onLoudness,
    required this.withSelection,
  });

  final EditorState state;
  final EditorController ctrl;
  final VoidCallback onSplit, onLoop, onMerge, onRingtone, onLoudness;
  final void Function(bool done) onQuick;
  final void Function(void Function(int a, int b)) withSelection;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final touch = Platform.isAndroid;
    return GlassPanel(
      padding: EdgeInsets.zero,
      child: DefaultTabController(
        length: 3,
        child: Column(children: [
          TabBar(tabs: [Tab(text: l10n.edTabEdit), Tab(text: l10n.edTabSegment), Tab(text: l10n.edTabQuick)]),
          Expanded(
            child: TabBarView(children: [
              SmoothListView(padding: const EdgeInsets.all(12), children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _Tool(Icons.vertical_split_rounded, l10n.splitAtCursor, onSplit),
                  _Tool(Icons.content_cut_rounded, l10n.edRippleDelete, () => withSelection((a, b) => ctrl.apply(EditOp.cut(startMs: a, endMs: b)))),
                  _Tool(Icons.backspace_outlined, l10n.edDeleteGap, () => withSelection((a, b) => ctrl.apply(EditOp.silence(startMs: a, endMs: b)))),
                  _Tool(Icons.crop_rounded, l10n.trimToSelection, () => withSelection((a, b) => ctrl.apply(EditOp.trim(startMs: a, endMs: b)))),
                  _Tool(Icons.content_copy_rounded, l10n.edDuplicate, () => withSelection((a, b) => ctrl.apply(EditOp.duplicate(startMs: a, endMs: b)))),
                  _Tool(Icons.repeat_rounded, l10n.edLoopN, onLoop),
                  _Tool(Icons.swap_horiz_rounded, l10n.edReverse, () => withSelection((a, b) => ctrl.apply(EditOp.reverse(startMs: a, endMs: b)))),
                  _Tool(Icons.playlist_add_rounded, l10n.edMerge, onMerge),
                  _Tool(Icons.restart_alt_rounded, l10n.reset2, state.history.canUndo ? ctrl.resetAll : null),
                ]),
                const SizedBox(height: 12),
                Text(touch ? l10n.edHelpTouch : l10n.edHelpDesktop, style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                if (state.error != null) ...[
                  const SizedBox(height: 8),
                  Text(state.error!, style: text.bodySmall?.copyWith(color: scheme.error)),
                ],
              ]),
              SegmentInspector(state: state, ctrl: ctrl),
              SmoothListView(padding: const EdgeInsets.all(12), children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _Tool(Icons.content_cut_rounded, l10n.edAutoTrim, () => onQuick(ctrl.autoTrim())),
                  _Tool(Icons.compress_rounded, l10n.edRemoveSilence, () => onQuick(ctrl.removeSilence())),
                  _Tool(Icons.equalizer_rounded, l10n.edNormalize, () => onQuick(ctrl.normalize())),
                  _Tool(Icons.graphic_eq_rounded, l10n.edLoudness, onLoudness),
                  _Tool(Icons.notifications_active_outlined, RingtoneService.supported ? l10n.edRingtoneSet : l10n.edRingtone, onRingtone),
                ]),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.playThisEditInThePlayer),
                  subtitle: Text(l10n.livePresetTheOriginalFileIs),
                  value: state.livePreset,
                  onChanged: ctrl.setLivePreset,
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SpringButton(
        child: ActionChip(avatar: Icon(icon, size: 18), label: Text(label), onPressed: onTap),
      );
}

/// Play/pause, A/B, loop, snapping and zoom.
class _PreviewBar extends StatelessWidget {
  const _PreviewBar({required this.state, required this.ctrl, required this.zoom, required this.onZoom, required this.onFit});
  final EditorState state;
  final EditorController ctrl;
  final double zoom;
  final void Function(double) onZoom;
  final VoidCallback onFit;

  @override
  Widget build(BuildContext context) {
    final pos = state.previewPlaying ? state.previewPos : state.cursor;
    final led = context.look.led;
    Widget toggle(IconData icon, String tip, bool on, VoidCallback tap) => IconButton(
          tooltip: tip,
          visualDensity: VisualDensity.compact,
          isSelected: on,
          icon: Icon(icon, size: 20, color: on ? led : null),
          onPressed: tap,
        );
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Wrap(spacing: 4, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SpringIconButton(
          filled: true,
          size: 24,
          tooltip: state.previewPlaying ? l10n.pausePreview : l10n.playPreview,
          onPressed: ctrl.togglePreview,
          icon: AnimatedSwitcher(
            duration: context.motion.d(PrismMotion.short),
            child: Icon(state.previewPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, key: ValueKey(state.previewPlaying)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(formatDuration(pos), style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
        ),
        SegmentedButton<bool>(
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: [
            ButtonSegment(value: false, label: Text(l10n.aOriginal)),
            ButtonSegment(value: true, label: Text(l10n.bEdited)),
          ],
          selected: {state.previewB},
          showSelectedIcon: false,
          onSelectionChanged: (v) => ctrl.setPreviewB(v.first),
        ),
        toggle(Icons.repeat_one_rounded, l10n.edLoopSel, state.loopSelection, ctrl.toggleLoop),
        toggle(Icons.my_location_rounded, l10n.edFollow, state.followPlayhead, ctrl.toggleFollow),
        toggle(Icons.linear_scale_rounded, l10n.edSnapZero, state.snapZero, ctrl.toggleSnapZero),
        toggle(Icons.av_timer_rounded, l10n.edSnapBeats, state.snapBeats, ctrl.toggleSnapBeats),
        toggle(Icons.volume_off_outlined, l10n.edSnapSilence, state.snapSilence, ctrl.toggleSnapSilence),
        IconButton(tooltip: l10n.edZoomOut, visualDensity: VisualDensity.compact, icon: const Icon(Icons.zoom_out_rounded, size: 20), onPressed: () => onZoom(1 / 1.5)),
        TextButton(onPressed: onFit, child: Text('${fmtNum(zoom, zoom < 10 ? 1 : 0)}x')),
        IconButton(tooltip: l10n.edZoomIn, visualDensity: VisualDensity.compact, icon: const Icon(Icons.zoom_in_rounded, size: 20), onPressed: () => onZoom(1.5)),
      ]),
    );
  }
}

/// Picks songs from the library to add to the end of the edit.
class _MergeDialog extends ConsumerStatefulWidget {
  const _MergeDialog({required this.excludeId});
  final int excludeId;

  @override
  ConsumerState<_MergeDialog> createState() => _MergeDialogState();
}

class _MergeDialogState extends ConsumerState<_MergeDialog> {
  final _picked = <Track>[];
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(tracksProvider).value ?? const <Track>[];
    final q = _query.toLowerCase();
    final list = [
      for (final t in all)
        if (t.id != widget.excludeId && (q.isEmpty || t.title.toLowerCase().contains(q) || t.displayArtist.toLowerCase().contains(q))) t,
    ];
    return AlertDialog(
      title: Text(l10n.edMergeTitle),
      content: SizedBox(
        width: 460,
        height: 420,
        child: Column(children: [
          TextField(
            autofocus: true,
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: l10n.search),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SmoothScroll(builder: (scroll) => ListView.builder(
              controller: scroll,
              itemCount: list.length,
              itemBuilder: (context, i) {
                final t = list[i];
                final on = _picked.contains(t);
                return CheckboxListTile(
                  value: on,
                  dense: true,
                  title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(t.displayArtist, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onChanged: (_) => setState(() => on ? _picked.remove(t) : _picked.add(t)),
                );
              },
            )),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: _picked.isEmpty ? null : () => Navigator.pop(context, _picked),
          child: Text(l10n.edAddN(_picked.length)),
        ),
      ],
    );
  }
}

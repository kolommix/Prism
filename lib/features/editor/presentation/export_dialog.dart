import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../application/edit_exporter.dart';
import '../application/editor_controller.dart';
import '../domain/export_command.dart';

/// Export options, then runs the export (progress and Cancel are on the page).
Future<void> showExportDialog(BuildContext context, EditorController ctrl, EditorState state) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final choice = await showDialog<_ExportChoice>(context: context, builder: (_) => _ExportDialog(state: state));
  if (choice == null) return;
  try {
    switch (choice.target) {
      case ExportTarget.newTrack:
        final path = await ctrl.saveAsNewTrack(choice.format, choice.settings);
        if (path != null) messenger?.showSnackBar(SnackBar(content: Text(l10n.savedAndAddedToYourLibrary(path))));
      case ExportTarget.file:
        final res = await ctrl.renderForFile(choice.format, choice.settings);
        if (res == null) return;
        final uri = await FilePicker.saveFile(
          fileName: res.$1,
          bytes: Uint8List.fromList(res.$2),
          dialogTitle: l10n.exportEdit,
          mimeType: switch (choice.format) {
            ExportFormat.mp3 => 'audio/mpeg',
            ExportFormat.m4a => 'audio/mp4',
            ExportFormat.wav => 'audio/wav',
            ExportFormat.flac => 'audio/flac',
          },
        );
        if (uri != null) messenger?.showSnackBar(SnackBar(content: Text(l10n.exported)));
      case ExportTarget.overwrite:
        final backup = await ctrl.overwriteOriginal(choice.settings);
        if (backup != null) messenger?.showSnackBar(SnackBar(content: Text(l10n.edOverwriteDone(backup))));
    }
  } on ExportException catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.exportFailed(e.message))));
  } on Object catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(l10n.exportFailed(e))));
  }
}

class _ExportChoice {
  const _ExportChoice(this.target, this.format, this.settings);
  final ExportTarget target;
  final ExportFormat format;
  final ExportSettings settings;
}

class _ExportDialog extends StatefulWidget {
  const _ExportDialog({required this.state});
  final EditorState state;

  @override
  State<_ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<_ExportDialog> {
  ExportTarget _target = ExportTarget.newTrack;
  ExportFormat _format = ExportFormat.mp3;
  bool _vbr = true;
  double _vbrQ = 2;
  int _mp3Kbps = 320;
  int _m4aKbps = 256;
  int _wavBits = 16;
  double _flac = 5;
  bool _keep = true;
  bool _eq = false;
  String? _cover;
  bool _removeCover = false;
  late final _title = TextEditingController(text: widget.state.track?.title ?? '');
  late final _artist = TextEditingController(text: widget.state.track?.artist ?? '');
  late final _album = TextEditingController(text: widget.state.track?.album ?? '');
  late final _year = TextEditingController(text: widget.state.track?.year?.toString() ?? '');

  ExportFormat get _effectiveFormat =>
      _target == ExportTarget.overwrite ? (ExportFormat.ofPath(widget.state.track!.uri) ?? _format) : _format;

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _album.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final res = await FilePicker.pickFiles(type: FileType.image, dialogTitle: l10n.chooseCoverImage);
    final path = res.isEmpty ? null : res.single.path;
    if (path != null) {
      setState(() {
        _cover = path;
        _removeCover = false;
      });
    }
  }

  ExportSettings _settings() {
    final t = widget.state.track!;
    final tags = <String, String>{
      if (_title.text != t.title) 'title': _title.text,
      if (_artist.text != t.artist) 'artist': _artist.text,
      if (_album.text != t.album) 'album': _album.text,
      if (_year.text != (t.year?.toString() ?? '')) 'date': _year.text,
    };
    return ExportSettings(
      mp3Vbr: _vbr,
      mp3VbrQuality: _vbrQ.round(),
      mp3Kbps: _mp3Kbps,
      m4aKbps: _m4aKbps,
      wavBits: _wavBits,
      flacLevel: _flac.round(),
      keepMetadata: _keep,
      tags: tags,
      coverPath: _cover,
      removeCover: _removeCover,
      applyGlobalEq: _eq,
    );
  }

  Widget _kbps(int value, List<int> options, ValueChanged<int> onChanged) => DropdownButton<int>(
        value: value,
        isExpanded: true,
        items: [for (final k in options) DropdownMenuItem(value: k, child: Text(l10n.edBitrate(k)))],
        onChanged: (v) => setState(() => onChanged(v ?? value)),
      );

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final format = _effectiveFormat;
    return AlertDialog(
      title: Text(l10n.edExport),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            RadioGroup<ExportTarget>(
              groupValue: _target,
              onChanged: (v) => setState(() => _target = v ?? _target),
              child: Column(children: [
                RadioListTile(dense: true, contentPadding: EdgeInsets.zero, value: ExportTarget.newTrack, title: Text(l10n.saveAsNewTrack)),
                RadioListTile(dense: true, contentPadding: EdgeInsets.zero, value: ExportTarget.file, title: Text(l10n.exportToFile)),
                RadioListTile(dense: true, contentPadding: EdgeInsets.zero, value: ExportTarget.overwrite, title: Text(l10n.edOverwrite)),
              ]),
            ),
            const Divider(),
            if (_target != ExportTarget.overwrite)
              SegmentedButton<ExportFormat>(
                segments: [for (final f in ExportFormat.values) ButtonSegment(value: f, label: Text(f.extension.toUpperCase()))],
                selected: {_format},
                showSelectedIcon: false,
                onSelectionChanged: (v) => setState(() => _format = v.first),
              ),
            const SizedBox(height: 8),
            if (format == ExportFormat.mp3) ...[
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.edVbr),
                value: _vbr,
                onChanged: (v) => setState(() => _vbr = v),
              ),
              if (_vbr) ...[
                Text(l10n.edVbrQuality(_vbrQ.round()), style: text.bodyMedium),
                Slider(value: _vbrQ, min: 0, max: 9, divisions: 9, onChanged: (v) => setState(() => _vbrQ = v)),
              ] else
                _kbps(_mp3Kbps, const [128, 160, 192, 256, 320], (v) => _mp3Kbps = v),
            ],
            if (format == ExportFormat.m4a) _kbps(_m4aKbps, const [128, 192, 256, 320], (v) => _m4aKbps = v),
            if (format == ExportFormat.wav)
              DropdownButton<int>(
                value: _wavBits,
                isExpanded: true,
                items: [for (final b in const [16, 24]) DropdownMenuItem(value: b, child: Text(l10n.edWavBits(b)))],
                onChanged: (v) => setState(() => _wavBits = v ?? 16),
              ),
            if (format == ExportFormat.flac) ...[
              Text(l10n.edFlacLevel(_flac.round()), style: text.bodyMedium),
              Slider(value: _flac, min: 0, max: 12, divisions: 12, onChanged: (v) => setState(() => _flac = v)),
            ],
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.edApplyEq),
              value: _eq,
              onChanged: (v) => setState(() => _eq = v),
            ),
            const Divider(),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.edKeepTags),
              value: _keep,
              onChanged: (v) => setState(() => _keep = v),
            ),
            TextField(controller: _title, decoration: InputDecoration(labelText: l10n.title)),
            TextField(controller: _artist, decoration: InputDecoration(labelText: l10n.artist)),
            TextField(controller: _album, decoration: InputDecoration(labelText: l10n.album)),
            TextField(controller: _year, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: l10n.year)),
            const SizedBox(height: 8),
            if (format.holdsCover)
              Wrap(spacing: 8, children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: Text(_cover == null ? l10n.changeCover : _cover!.split(RegExp(r'[\\/]')).last),
                  onPressed: _pickCover,
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _cover = null;
                    _removeCover = !_removeCover;
                  }),
                  child: Text(_removeCover ? l10n.edKeepCover : l10n.removeCover),
                ),
              ]),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(context, _ExportChoice(_target, _effectiveFormat, _settings())),
          child: Text(l10n.edExport),
        ),
      ],
    );
  }
}

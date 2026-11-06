import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/artwork.dart';
import '../../library/domain/track.dart';
import '../application/tools_providers.dart';
import '../data/tag_writer.dart';
import '../../../l10n/l10n.dart';

/// Edit title / artist / album / genre / year / track number / cover.
Future<void> showTagEditor(BuildContext context, Track track) => showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _TagEditor(track: track),
    );

class _TagEditor extends ConsumerStatefulWidget {
  const _TagEditor({required this.track});
  final Track track;

  @override
  ConsumerState<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends ConsumerState<_TagEditor> {
  late final _title = TextEditingController(text: widget.track.title);
  late final _artist = TextEditingController(text: widget.track.artist);
  late final _album = TextEditingController(text: widget.track.album);
  late final _genre = TextEditingController(text: widget.track.genre);
  late final _year = TextEditingController(text: widget.track.year?.toString() ?? '');
  late final _number = TextEditingController(text: widget.track.trackNumber?.toString() ?? '');
  Uint8List? _cover;
  bool _removeCover = false;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_title, _artist, _album, _genre, _year, _number]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _changed(TextEditingController c, String old) => c.text.trim() == old ? null : c.text.trim();

  Future<void> _pickCover() async {
    final f = await FilePicker.pickFile(type: FileType.image, dialogTitle: l10n.chooseCoverImage);
    if (f == null) return;
    final bytes = await f.readAsBytes();
    if (!mounted) return; // dialog closed while the picker was open
    setState(() {
      _cover = bytes;
      _removeCover = false;
    });
  }

  Future<void> _save() async {
    final t = widget.track;
    final edit = TagEdit(
      title: _changed(_title, t.title),
      artist: _changed(_artist, t.artist),
      album: _changed(_album, t.album),
      genre: _changed(_genre, t.genre),
      year: int.tryParse(_year.text.trim()) == t.year ? null : int.tryParse(_year.text.trim()),
      trackNumber: int.tryParse(_number.text.trim()) == t.trackNumber ? null : int.tryParse(_number.text.trim()),
      cover: _cover,
      removeCover: _removeCover,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await saveTags(ref, t, edit);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(l10n.tagsSavedABackupOfThe)));
      }
    } on Object catch (e) {
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.track;
    final writable = TagWriter.canWrite(t.uri);
    Widget field(String label, TextEditingController c, {bool number = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: TextField(
            controller: c,
            enabled: writable && !_saving,
            keyboardType: number ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(labelText: label),
          ),
        );
    return AlertDialog(
      title: Text(l10n.editTags2),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(
                    dimension: 120,
                    child: _cover != null
                        ? Image.memory(_cover!, fit: BoxFit.cover)
                        : (_removeCover ? const Artwork(path: null, size: 120) : Artwork(path: t.artworkPath, size: 120, seed: t.album)),
                  ),
                ),
                TextButton(onPressed: writable && !_saving ? _pickCover : null, child: Text(l10n.changeCover)),
                TextButton(
                  onPressed: writable && !_saving
                      ? () => setState(() {
                            _removeCover = true;
                            _cover = null;
                          })
                      : null,
                  child: Text(l10n.removeCover),
                ),
              ]),
              const SizedBox(width: 16),
              Expanded(
                child: Column(children: [
                  field(l10n.title, _title),
                  field(l10n.artist, _artist),
                  field(l10n.album, _album),
                ]),
              ),
            ]),
            Row(children: [
              Expanded(child: field(l10n.genre2, _genre)),
              const SizedBox(width: 12),
              SizedBox(width: 90, child: field(l10n.year, _year, number: true)),
              const SizedBox(width: 12),
              SizedBox(width: 90, child: field(l10n.track, _number, number: true)),
            ]),
            const SizedBox(height: 8),
            Text(File(t.uri).path, style: Theme.of(context).textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (!writable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(l10n.thisFormatOggCanOnlyBe, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: Text(l10n.cancel)),
        FilledButton(
          onPressed: writable && !_saving ? _save : null,
          child: _saving ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l10n.saveToFile),
        ),
      ],
    );
  }
}

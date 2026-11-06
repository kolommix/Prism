import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/prism_theme_extensions.dart';
import '../../../l10n/l10n.dart';
import '../../library/domain/track.dart';
import '../domain/playlist_share.dart';

/// Share a playlist: a code to paste anywhere, or a `.liner` file.
Future<void> showShareDialog(BuildContext context, String name, List<Track> tracks) => showDialog<void>(
      context: context,
      builder: (_) => _ShareDialog(name: name, tracks: tracks),
    );

class _ShareDialog extends StatefulWidget {
  const _ShareDialog({required this.name, required this.tracks});
  final String name;
  final List<Track> tracks;

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  late final String _code = encodeSharedPlaylist(widget.name, widget.tracks);
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _code));
    if (mounted) setState(() => _copied = true);
  }

  Future<void> _save() async {
    final safe = widget.name.replaceAll(RegExp(r'[^\p{L}\p{N} _\-]+', unicode: true), '').trim();
    final messenger = ScaffoldMessenger.maybeOf(context);
    final saved = await FilePicker.saveFile(
      dialogTitle: l10n.shareSaveFile,
      fileName: '${safe.isEmpty ? l10n.shareDefaultName : safe}.$shareExtension',
      bytes: utf8.encode(_code),
    );
    if (saved != null) messenger?.showSnackBar(SnackBar(content: Text(l10n.shareSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final long = _code.length > shareLinkSafeLength;
    return AlertDialog(
      title: Text(l10n.shareTitle),
      content: SizedBox(
        width: 460,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.shareHint(widget.tracks.length), style: text.bodyMedium),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 96),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(context.shape.radius / 2),
            ),
            child: SingleChildScrollView(child: SelectableText(_code, style: text.bodySmall)),
          ),
          if (long) ...[
            const SizedBox(height: 8),
            Text(l10n.shareLong, style: text.bodySmall?.copyWith(color: scheme.tertiary)),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close)),
        OutlinedButton.icon(onPressed: _save, icon: const Icon(Icons.save_alt_rounded, size: 18), label: Text(l10n.shareSaveFile)),
        FilledButton.icon(
          onPressed: _copy,
          icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 18),
          label: Text(_copied ? l10n.copied : l10n.copy),
        ),
      ],
    );
  }
}

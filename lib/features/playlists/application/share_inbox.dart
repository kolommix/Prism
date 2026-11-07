import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/prism_theme_extensions.dart';
import '../../../l10n/l10n.dart';
import '../../online/domain/import_intake.dart';

/// Things to import that arrived from outside the import screen, waiting for it
/// to take them.
class ImportInbox extends Notifier<List<ImportRequest>> {
  @override
  List<ImportRequest> build() => const [];

  void put(ImportRequest request) => state = [...state, request];
  List<ImportRequest> takeAll() {
    final s = state;
    state = const [];
    return s;
  }
}

final importInboxProvider = NotifierProvider<ImportInbox, List<ImportRequest>>(ImportInbox.new);

/// Playlists from the system. Android delivers `liner://` links, `.liner` files
/// and the share sheet through the launching intent; Windows through the command
/// line (a second start hands them to the running window and exits) and through
/// drag and drop.
class DeepLinks {
  DeepLinks(this.onRequest);

  final void Function(ImportRequest request) onRequest;
  static const _channel = MethodChannel('prism/deeplink');
  static const _dropChannel = MethodChannel('prism/drop');

  /// Something is being dragged over the window (Windows).
  static final dragging = ValueNotifier<bool>(false);

  Object? _last;
  DateTime _lastAt = DateTime(0);

  Future<void> start(List<String> args) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'open') await handle(call.arguments);
    });
    if (Platform.isWindows) {
      _dropChannel.setMethodCallHandler((call) async {
        switch (call.method) {
          case 'enter':
            dragging.value = true;
          case 'leave':
            dragging.value = false;
          case 'drop':
            dragging.value = false;
            final data = (call.arguments as Map).cast<String, Object?>();
            final files = (data['files'] as List? ?? const []).cast<String>();
            for (final f in files) {
              await handle(f);
            }
            final text = data['text'] as String?;
            if (files.isEmpty && text != null && text.trim().isNotEmpty) await handle(text);
        }
      });
    }
    for (final a in args) {
      if (isImportFile(a) || classifyImportText(a) is! UnknownInput) await handle(a);
    }
    if (Platform.isAndroid) {
      try {
        final first = await _channel.invokeMethod<Object?>('getInitial');
        if (first != null) await handle(first);
      } on Object {
        // Nothing shared at start.
      }
    }
  }

  /// [value] is text or a path, or (Android, a shared file) `{name, text}`.
  @visibleForTesting
  Future<void> handle(Object? value) async {
    // The same share can arrive as a start value and as a message.
    final now = DateTime.now();
    if (value == _last || (value is Map && _last is Map && mapEquals(value, _last as Map)))  {
      if (now.difference(_lastAt) < const Duration(seconds: 5)) return;
    }
    _last = value;
    _lastAt = now;
    if (value is Map) {
      final name = value['name'] as String?;
      final text = value['text'] as String?;
      if (text == null) return;
      onRequest(name == null ? ImportRequest.text(text) : ImportRequest.file(name, text));
      return;
    }
    if (value is! String) return;
    if (classifyImportText(value) case FileInput(:final path)) {
      try {
        onRequest(ImportRequest.file(path, decodeImportBytes(await File(path).readAsBytes())));
      } on Object {
        onRequest(ImportRequest.text(value));
      }
      return;
    }
    onRequest(ImportRequest.text(value));
  }
}

/// Covers the window while a file or link is dragged over it. Costs nothing
/// otherwise.
class DropOverlay extends StatelessWidget {
  const DropOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DeepLinks.dragging,
      builder: (context, on, _) {
        if (!on) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return Positioned.fill(
          child: IgnorePointer(
            child: Material(
              color: scheme.surface.withValues(alpha: 0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.playlist_add_rounded, size: 48, color: context.look.led),
                    const SizedBox(height: 12),
                    Text(l10n.importDropHere, style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

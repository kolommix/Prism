import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../online/domain/external_track.dart';
import '../domain/playlist_share.dart';

/// A shared playlist that arrived from outside the app, waiting for the import
/// screen to show it.
class ShareInbox extends Notifier<ImportedList?> {
  @override
  ImportedList? build() => null;

  void put(ImportedList list) => state = list;
  ImportedList? take() {
    final s = state;
    state = null;
    return s;
  }
}

final shareInboxProvider = NotifierProvider<ShareInbox, ImportedList?>(ShareInbox.new);

/// `liner://` links and `.liner` files from the system. Android delivers them
/// through the launching intent, Windows through the command line (a second
/// start hands them to the running window and exits).
class DeepLinks {
  DeepLinks(this.onText);

  final void Function(String text) onText;
  static const _channel = MethodChannel('prism/deeplink');

  Future<void> start(List<String> args) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'open' && call.arguments is String) await _handle(call.arguments as String);
    });
    for (final a in args) {
      await _handle(a);
    }
    if (Platform.isAndroid) {
      try {
        final first = await _channel.invokeMethod<String>('getInitial');
        if (first != null) await _handle(first);
      } on Object {
        // No link at start.
      }
    }
  }

  Future<void> _handle(String value) async {
    if (isSharedPlaylistText(value)) {
      onText(value);
      return;
    }
    // A file path from the command line.
    if (value.toLowerCase().endsWith('.$shareExtension')) {
      try {
        onText(await File(value).readAsString());
      } on Object {
        // Gone or unreadable: nothing to show.
      }
    }
  }
}

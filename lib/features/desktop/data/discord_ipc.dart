import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import '../../../l10n/l10n.dart';

/// The Prism app registered on Discord: built in, so nobody has to touch the
/// developer portal. An application id is public (it travels in every status),
/// not a secret. Settings can still override it with your own.
const prismDiscordClientId = '1568018022571180102';

// ------------------------------------------------------------------ frames

/// Discord IPC frame: little-endian int32 opcode, int32 length, UTF-8 JSON.
Uint8List encodeFrame(int op, Map<String, Object?> payload) {
  final body = utf8.encode(jsonEncode(payload));
  final b = ByteData(8 + body.length)
    ..setInt32(0, op, Endian.little)
    ..setInt32(4, body.length, Endian.little);
  final out = b.buffer.asUint8List();
  out.setRange(8, out.length, body);
  return out;
}

/// Parses (op, length) from an 8-byte header.
(int, int) decodeHeader(Uint8List h) {
  final b = ByteData.sublistView(h);
  return (b.getInt32(0, Endian.little), b.getInt32(4, Endian.little));
}

/// SET_ACTIVITY payload for a song (pure, tested).
Map<String, Object?> activityFrame({
  required String title,
  required String artist,
  required String album,
  required bool playing,
  required Duration position,
  required Duration duration,
  required int nowMs,
  required int pid,
  String? largeImageKey,
  String? coverUrl,
  String? linkUrl,
  List<(String, String)> buttons = const [],
  (String, int, int)? party,
}) {
  final start = nowMs - position.inMilliseconds;
  final image = coverUrl != null && coverUrl.isNotEmpty ? coverUrl : largeImageKey;
  final hasImage = image != null && image.isNotEmpty;
  final hasIcons = largeImageKey != null && largeImageKey.isNotEmpty && coverUrl == null;
  final who = artist.isEmpty ? l10n.unknownArtist : artist;
  return {
    'cmd': 'SET_ACTIVITY',
    'nonce': '$nowMs',
    'args': {
      'pid': pid,
      'activity': {
        'type': 2, // "Listening to"
        // Member list shows "Listening to <song>" instead of the app name.
        'status_display_type': 2,
        'details': title.isEmpty ? l10n.unknownSong : _cut(title),
        'state': _cut(playing ? who : l10n.paused(who)),
        if (linkUrl != null && linkUrl.isNotEmpty) 'details_url': linkUrl,
        // Progress bar while playing; none while paused.
        if (playing && duration > Duration.zero)
          'timestamps': {'start': start, 'end': start + duration.inMilliseconds},
        'assets': {
          if (hasImage) 'large_image': image,
          'large_text': _cut(album.isEmpty ? 'Prism' : album),
          if (hasIcons) ...{
            'small_image': playing ? 'play' : 'pause',
            'small_text': playing ? l10n.playingInPrism : l10n.paused2,
          },
        },
        if (buttons.isNotEmpty)
          'buttons': [
            for (final (label, url) in buttons.take(2)) {'label': label.length > 30 ? label.substring(0, 30) : label, 'url': url},
          ],
        // "Listening together" shows as a group on the profile.
        if (party != null)
          'party': {
            'id': party.$1,
            'size': [party.$2, party.$3],
          },
      },
    },
  };
}

/// The same activity with only the plain fields: used when Discord refuses
/// an extra (links and buttons depend on the Discord version).
Map<String, Object?> plainActivity(Map<String, Object?> frame) {
  final args = frame['args'] as Map<String, Object?>?;
  final activity = args?['activity'] as Map<String, Object?>?;
  if (args == null || activity == null) return frame;
  return {
    ...frame,
    'args': {
      ...args,
      'activity': {
        for (final e in activity.entries)
          if (e.key != 'buttons' && e.key != 'details_url' && e.key != 'party') e.key: e.value,
      },
    },
  };
}

String _cut(String s) => s.length <= 120 ? (s.length < 2 ? '$s ' : s) : '${s.substring(0, 117)}...';

// ------------------------------------------------------- Win32 named pipe

final class _K32 {
  _K32() : _lib = DynamicLibrary.open('kernel32.dll');
  final DynamicLibrary _lib;

  late final createFile = _lib.lookupFunction<
      IntPtr Function(Pointer<Utf16>, Uint32, Uint32, Pointer<Void>, Uint32, Uint32, IntPtr),
      int Function(Pointer<Utf16>, int, int, Pointer<Void>, int, int, int)>('CreateFileW');
  late final writeFile = _lib.lookupFunction<Int32 Function(IntPtr, Pointer<Uint8>, Uint32, Pointer<Uint32>, Pointer<Void>),
      int Function(int, Pointer<Uint8>, int, Pointer<Uint32>, Pointer<Void>)>('WriteFile');
  late final readFile = _lib.lookupFunction<Int32 Function(IntPtr, Pointer<Uint8>, Uint32, Pointer<Uint32>, Pointer<Void>),
      int Function(int, Pointer<Uint8>, int, Pointer<Uint32>, Pointer<Void>)>('ReadFile');
  late final closeHandle = _lib.lookupFunction<Int32 Function(IntPtr), int Function(int)>('CloseHandle');
}

/// Blocking client for Discord's local IPC pipe (use from an isolate).
class DiscordIpc {
  DiscordIpc({this.pipeBase = r'\\.\pipe\discord-ipc-'});

  final String pipeBase;
  final _k = _K32();
  int _handle = -1;

  static const _genericRW = 0x80000000 | 0x40000000;
  static const _openExisting = 3;

  bool get connected => _handle != -1;

  /// Pipe found but Discord said no (wrong id). Null while it's not running.
  String? get refusal => lastReply?['code'] != null ? (lastReply?['message'] as String? ?? 'Refused') : null;

  /// The Discord user from the handshake.
  String? get userName {
    final data = lastReply?['data'];
    if (data is! Map) return null;
    final user = data['user'];
    if (user is! Map) return null;
    final name = user['global_name'] ?? user['username'];
    return name is String ? name : null;
  }

  /// Connects to the first pipe 0..9 and performs the handshake.
  bool connect(String clientId) {
    lastReply = null;
    for (var i = 0; i < 10 && _handle == -1; i++) {
      final name = '$pipeBase$i'.toNativeUtf16();
      final h = _k.createFile(name, _genericRW, 0, nullptr, _openExisting, 0, 0);
      calloc.free(name);
      if (h != -1 && h != 0) _handle = h;
    }
    if (_handle == -1) return false;
    lastReply = send(0, {'v': 1, 'client_id': clientId});
    // A wrong ID still answers, with {code: 4000, message: Invalid Client ID}.
    if (lastReply == null || lastReply!['code'] != null) {
      close();
      return false;
    }
    return true;
  }

  /// Last handshake reply (READY, or an error like "Invalid Client ID").
  Map<String, dynamic>? lastReply;

  /// Writes a frame and reads one reply; null on any error (then closed).
  Map<String, dynamic>? send(int op, Map<String, Object?> payload) {
    if (_handle == -1) return null;
    final frame = encodeFrame(op, payload);
    final buf = calloc<Uint8>(frame.length);
    final n = calloc<Uint32>();
    try {
      buf.asTypedList(frame.length).setAll(0, frame);
      if (_k.writeFile(_handle, buf, frame.length, n, nullptr) == 0) throw const OSError('write');
      final header = _read(8);
      final (_, len) = decodeHeader(header);
      final body = _read(len);
      return jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
    } on Object {
      close();
      return null;
    } finally {
      calloc.free(buf);
      calloc.free(n);
    }
  }

  Uint8List _read(int len) {
    final out = Uint8List(len);
    final buf = calloc<Uint8>(len == 0 ? 1 : len);
    final n = calloc<Uint32>();
    try {
      var got = 0;
      while (got < len) {
        if (_k.readFile(_handle, buf + got, len - got, n, nullptr) == 0 || n.value == 0) throw const OSError('read');
        got += n.value;
      }
      out.setAll(0, buf.asTypedList(len));
      return out;
    } finally {
      calloc.free(buf);
      calloc.free(n);
    }
  }

  void close() {
    if (_handle != -1) _k.closeHandle(_handle);
    _handle = -1;
  }
}

// ------------------------------------------------- background isolate

/// How the status is doing, for the settings page.
enum DiscordLink { off, needsId, notRunning, badId, connected }

class DiscordStatus {
  const DiscordStatus(this.link, {this.user, this.message});
  final DiscordLink link;
  final String? user;
  final String? message;
}

/// Keeps one Discord connection in a background isolate (pipe reads block).
/// Send activities with [update]; null clears the presence. If Discord isn't
/// running it keeps trying, and shows the song as soon as Discord starts.
class DiscordPresence {
  DiscordPresence({this.onStatus});

  final void Function(DiscordStatus)? onStatus;
  SendPort? _port;
  Isolate? _isolate;
  ReceivePort? _inbox;

  Future<void> start() async {
    if (!Platform.isWindows || _isolate != null) return;
    final inbox = ReceivePort();
    _inbox = inbox;
    final ready = Completer<SendPort>();
    inbox.listen((msg) {
      if (msg is SendPort) {
        ready.complete(msg);
      } else if (msg is List) {
        onStatus?.call(DiscordStatus(DiscordLink.values[msg[0] as int], user: msg[1] as String?, message: msg[2] as String?));
      }
    });
    _isolate = await Isolate.spawn(_main, inbox.sendPort);
    _port = await ready.future;
  }

  void update(String clientId, Map<String, Object?>? activity) => _port?.send([clientId, activity]);

  void stop() {
    _port?.send(null);
    _inbox?.close();
    _inbox = null;
    _isolate = null;
    _port = null;
  }

  static void _main(SendPort reply) {
    final inbox = ReceivePort();
    reply.send(inbox.sendPort);
    final ipc = DiscordIpc();
    var client = '';
    Map<String, Object?>? last;
    String? reported;

    void report(DiscordLink link, {String? user, String? message}) {
      final key = '${link.index}|$user|$message';
      if (key == reported) return;
      reported = key;
      reply.send([link.index, user, message]);
    }

    void apply() {
      if (client.isEmpty) return;
      if (!ipc.connected) {
        if (!ipc.connect(client)) {
          final refused = ipc.refusal;
          if (refused != null) {
            report(DiscordLink.badId, message: refused);
          } else {
            report(DiscordLink.notRunning);
          }
          return;
        }
        report(DiscordLink.connected, user: ipc.userName);
      }
      final frame = last ?? {'cmd': 'SET_ACTIVITY', 'nonce': 'clear', 'args': {'pid': pid}};
      final answer = ipc.send(1, frame);
      if (answer == null) {
        report(DiscordLink.notRunning); // Discord was closed; retried below
      } else if (answer['evt'] == 'ERROR' && last != null) {
        ipc.send(1, plainActivity(frame));
      }
    }

    final retry = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!ipc.connected) apply();
    });
    inbox.listen((msg) {
      if (msg == null) {
        retry.cancel();
        ipc.close();
        inbox.close();
        return;
      }
      final list = msg as List;
      final id = list[0] as String;
      last = (list[1] as Map?)?.cast<String, Object?>();
      if (id != client) {
        ipc.close();
        client = id;
      }
      apply();
    });
  }
}

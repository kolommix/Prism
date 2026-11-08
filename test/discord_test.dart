import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:prism/features/desktop/data/discord_ipc.dart';

void main() {
  test('frame encoding', () {
    final f = encodeFrame(1, {'a': 'Г©'});
    final (op, len) = decodeHeader(Uint8List.sublistView(f, 0, 8));
    expect((op, len), (1, f.length - 8));
    expect(jsonDecode(utf8.decode(f.sublist(8))), {'a': 'Г©'});
  });

  test('activity: listening, timestamps while playing, paused state', () {
    final a = activityFrame(
      title: 'Song',
      artist: 'Band',
      album: 'LP',
      playing: true,
      position: const Duration(seconds: 30),
      duration: const Duration(minutes: 3),
      nowMs: 100000,
      pid: 42,
      largeImageKey: 'prism',
    );
    final act = (a['args'] as Map)['activity'] as Map;
    expect((act['type'], act['details'], act['state']), (2, 'Song', 'Band'));
    expect(act['timestamps'], {'start': 70000, 'end': 250000});
    final paused = activityFrame(
        title: 'Song', artist: 'Band', album: '', playing: false, position: Duration.zero, duration: Duration.zero, nowMs: 0, pid: 1);
    final pa = (paused['args'] as Map)['activity'] as Map;
    expect((pa['state'], pa.containsKey('timestamps')), ('Paused · Band', false));
  });

  test('paused: the bar starts ahead, so it stays still and keeps the length', () {
    Map<String, Object?> frame(int now) => activityFrame(
        title: 'Song', artist: 'Band', album: '', playing: false, position: const Duration(seconds: 42),
        duration: const Duration(seconds: 124), nowMs: now, pid: 1);
    final act = (frame(1000)['args'] as Map)['activity'] as Map;
    final times = act['timestamps'] as Map;
    expect(times['start'] as int, greaterThan(1000 + const Duration(days: 300).inMilliseconds));
    expect((times['end'] as int) - (times['start'] as int), 124000, reason: 'Discord shows the real length');
    // Discord refused it: a plain status with its own clock, not none at all.
    final plain = (plainActivity(frame(1000))['args'] as Map)['activity'] as Map;
    expect(plain.containsKey('timestamps'), isFalse);
    expect(plain['details'], 'Song');
    // A playing bar is never dropped.
    final playing = activityFrame(
        title: 'Song', artist: 'Band', album: '', playing: true, position: const Duration(seconds: 42),
        duration: const Duration(seconds: 124), nowMs: 100000, pid: 1);
    expect(((plainActivity(playing)['args'] as Map)['activity'] as Map).containsKey('timestamps'), isTrue);
  });

  test('activity: album art, links and listening together', () {
    final a = activityFrame(
      title: 'Song',
      artist: 'Band',
      album: 'LP',
      playing: true,
      position: Duration.zero,
      duration: const Duration(minutes: 3),
      nowMs: 1000,
      pid: 42,
      coverUrl: 'https://img.example/c.jpg',
      linkUrl: 'https://example.com/s',
      buttons: const [('A very long button label that does not fit', 'https://a'), ('B', 'https://b'), ('C', 'https://c')],
      party: ('K7QXA', 3, 8),
    );
    final act = (a['args'] as Map)['activity'] as Map;
    expect((act['assets'] as Map)['large_image'], 'https://img.example/c.jpg');
    expect((act['buttons'] as List).length, 2, reason: 'Discord allows two');
    expect(((act['buttons'] as List).first as Map)['label'].length, lessThanOrEqualTo(32));
    expect(act['party'], {'id': 'K7QXA', 'size': [3, 8]});
    // Extras can be dropped when Discord refuses them.
    final plain = (plainActivity(a)['args'] as Map)['activity'] as Map;
    expect((plain.containsKey('buttons'), plain.containsKey('party'), plain['details']), (false, false, 'Song'));
  });

  test('talks the real pipe protocol (fake Discord pipe server)', () async {
    final dir = await Directory.systemTemp.createTemp('prism_discord_');
    final log = p.join(dir.path, 'frames.txt');
    // A PowerShell named-pipe server playing Discord: logs frames, answers each.
    final script = '''
\$pipe = New-Object System.IO.Pipes.NamedPipeServerStream('prism-test-ipc-0', [System.IO.Pipes.PipeDirection]::InOut)
\$pipe.WaitForConnection()
for (\$k = 0; \$k -lt 2; \$k++) {
  \$h = New-Object byte[] 8; \$r = 0; while (\$r -lt 8) { \$r += \$pipe.Read(\$h, \$r, 8 - \$r) }
  \$op = [BitConverter]::ToInt32(\$h, 0); \$len = [BitConverter]::ToInt32(\$h, 4)
  \$b = New-Object byte[] \$len; \$r = 0; while (\$r -lt \$len) { \$r += \$pipe.Read(\$b, \$r, \$len - \$r) }
  Add-Content -Encoding UTF8 '$log' ("\$op " + [Text.Encoding]::UTF8.GetString(\$b))
  \$resp = [Text.Encoding]::UTF8.GetBytes('{"cmd":"DISPATCH","evt":"READY"}')
  \$pipe.Write([BitConverter]::GetBytes([int]1), 0, 4); \$pipe.Write([BitConverter]::GetBytes([int]\$resp.Length), 0, 4)
  \$pipe.Write(\$resp, 0, \$resp.Length); \$pipe.Flush()
}
\$pipe.Dispose()
''';
    final server = await Process.start('powershell', ['-NoProfile', '-Command', script]);
    try {
      final ipc = DiscordIpc(pipeBase: r'\\.\pipe\prism-test-ipc-');
      var ok = false;
      // PowerShell can take many seconds to start on a build server.
      for (var i = 0; i < 300 && !ok; i++) {
        ok = ipc.connect('123456');
        if (!ok) await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(ok, isTrue, reason: 'handshake');
      final reply = ipc.send(1, activityFrame(
        title: 'Song', artist: 'Band', album: 'LP', playing: true, position: Duration.zero,
        duration: const Duration(minutes: 3), nowMs: 1, pid: 7));
      expect(reply?['evt'], 'READY');
      ipc.close();
      await server.exitCode.timeout(const Duration(seconds: 10));
      final lines = File(log).readAsLinesSync().map((l) => l.replaceFirst('\uFEFF', '')).toList();
      expect(lines.first, '0 {"v":1,"client_id":"123456"}');
      expect(lines.last, startsWith('1 {"cmd":"SET_ACTIVITY"'));
      expect(lines.last, contains('"details":"Song"'));
    } finally {
      server.kill();
      await dir.delete(recursive: true);
    }
  }, skip: Platform.isWindows ? null : 'Windows named pipes only');
}

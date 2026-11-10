import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/platform/background_process.dart';

void main() {
  final windows = Platform.isWindows;

  test('runs a process from another isolate and returns its output', () async {
    final r = await BackgroundProcess.run(windows ? 'cmd' : 'sh', windows ? ['/c', 'echo hi & echo oops 1>&2 & exit 3'] : ['-c', 'echo hi; echo oops >&2; exit 3']);
    expect(r.exitCode, 3);
    expect(r.stdout.trim(), 'hi');
    expect(r.stderr.trim(), 'oops');
  });

  test('a missing program gives -2 instead of throwing', () async {
    final r = await BackgroundProcess.run('no-such-program-prism', const []);
    expect(r.exitCode, -2);
  });

  test('kill and timeout end it', () async {
    final long = windows ? ['cmd', '/c', 'ping -n 30 127.0.0.1 >nul'] : ['sh', '-c', 'sleep 30'];
    final p = await BackgroundProcess.start(long.first, long.sublist(1));
    p.kill();
    final killed = await p.done.timeout(const Duration(seconds: 10));
    expect(killed.exitCode, isNot(0));
    final t = await BackgroundProcess.run(long.first, long.sublist(1), timeout: const Duration(milliseconds: 300));
    expect(t.exitCode, -1);
  });
}

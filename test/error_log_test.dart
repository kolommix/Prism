import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/diagnostics/error_log.dart';
import 'package:prism/core/diagnostics/error_ui.dart';

void main() {
  final log = ErrorLog.instance;
  setUp(log.resetForTest);

  test('records an error with its type and stack, and repeats are counted', () {
    try {
      throw const FormatException('bad tag');
    } on FormatException catch (e, st) {
      log.record(e, st, where: 'tags', message: 'Could not read tags');
      log.record(e, st, where: 'tags', message: 'Could not read tags');
    }
    expect(log.entries.value, hasLength(1));
    final e = log.entries.value.single;
    expect(e.repeats, 2);
    expect(e.details, contains('FormatException'));
    expect(e.details, contains('error_log_test.dart'));
    final report = log.report();
    expect(report, contains('Prism '));
    expect(report, contains('ERROR tags: Could not read tags (x2)'));
  });

  test('notes are kept apart from errors and fire no message', () async {
    final fired = <ErrorEntry>[];
    final sub = log.onError.listen(fired.add);
    log.note('import', 'file refused');
    log.failed('import', 'YouTube blocks this song');
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(fired.map((e) => e.message), ['YouTube blocks this song']);
    expect(log.report(withNotes: false), isNot(contains('file refused')));
  });

  test('writes to the log file and hides the home folder', () async {
    final dir = await Directory.systemTemp.createTemp('prism_log');
    addTearDown(() async {
      log.resetForTest();
      await dir.delete(recursive: true);
    });
    await log.start(dir);
    final home = Platform.environment[Platform.isWindows ? 'USERPROFILE' : 'HOME']!;
    log.failed('import', 'Could not save $home${Platform.pathSeparator}Music${Platform.pathSeparator}a.m4a');
    await log.flush();
    final text = await File('${dir.path}/logs/prism-errors.txt').readAsString();
    expect(text, contains('Could not save ~'));
    expect(text, isNot(contains(home)));
    expect(await log.fileText(), contains('Could not save ~'));
    await log.clear();
    expect(log.entries.value, isEmpty);
  });

  testWidgets('an error inside a page can be copied', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
      return null;
    });
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ErrorText(StateError('db closed'), where: 'stats'))));
    expect(find.textContaining('db closed'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.copy_rounded));
    await tester.pump();
    expect(copied, contains('stats'));
    expect(copied, contains('StateError'));
  });
}

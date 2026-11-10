// Plain-text copies of every info Markdown file on GitHub, for people who
// open them in Notepad: a .txt next to each .md (the .md stays: GitHub's page
// and the release notes are made from it).
//
// Found by itself, so a new doc can't be forgotten: every .md in the project
// root, docs/ and third_party/ (not inside the vendored packages), except the
// working notes that never go to GitHub.
//
//   dart run tool/md_to_txt.dart          (run after editing any .md)
//   dart run tool/md_to_txt.dart --check  (CI: fails when a .txt is missing or stale)
import 'dart:io';

/// Working notes kept on this PC only (.gitignore), no copies for them.
const notOnGitHub = {'CLAUDE.md', 'STATUS.md', 'PROGRESS.md'};

List<String> get files => [
      for (final dir in ['.', 'docs', 'third_party'])
        if (Directory(dir).existsSync())
          for (final e in Directory(dir).listSync()..sort((a, b) => a.path.compareTo(b.path)))
            if (e is File && e.path.toLowerCase().endsWith('.md') && !notOnGitHub.contains(e.uri.pathSegments.last))
              e.path.replaceAll(r'\', '/').replaceFirst(RegExp(r'^\./'), ''),
    ];

String toText(String md) {
  final out = <String>[];
  var inCode = false;
  for (var line in md.replaceAll('\r\n', '\n').split('\n')) {
    if (line.trimLeft().startsWith('```')) {
      inCode = !inCode;
      continue;
    }
    if (inCode) {
      out.add('    $line');
      continue;
    }
    // Pictures and HTML tags mean nothing in a text file.
    line = line.replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '').replaceAll(RegExp(r'<[^>]+>'), '');
    // [text](url) -> text (url), unless the text already is the url.
    line = line.replaceAllMapped(RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), (m) => m[1] == m[2] ? m[1]! : '${m[1]} (${m[2]})');
    line = line
        .replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m[1]!)
        .replaceAllMapped(RegExp(r'(?<![\w*])\*([^*\n]+)\*(?![\w*])'), (m) => m[1]!)
        .replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m[1]!);
    final h = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
    if (h != null) {
      final title = h[2]!.trim();
      if (out.isNotEmpty && out.last.isNotEmpty) out.add('');
      if (h[1]!.length <= 2) {
        out
          ..add(title.toUpperCase())
          ..add((h[1]!.length == 1 ? '=' : '-') * title.length);
      } else {
        out.add('$title:');
      }
      continue;
    }
    if (RegExp(r'^\s*(-{3,}|\*{3,})\s*$').hasMatch(line)) {
      out.add('-' * 40);
      continue;
    }
    // Table rows: cells separated by two spaces, the |---| line dropped.
    if (line.trimLeft().startsWith('|')) {
      if (RegExp(r'^\s*\|[\s:|-]+\|\s*$').hasMatch(line)) continue;
      line = line.trim().replaceAll(RegExp(r'^\||\|$'), '').split('|').map((c) => c.trim()).join('  |  ');
    }
    out.add(line.replaceAll(RegExp(r'\s+$'), ''));
  }
  return '${out.join('\r\n').trim()}\r\n';
}

void main(List<String> args) {
  final check = args.contains('--check');
  var stale = false;
  for (final md in files) {
    final src = File(md);
    if (!src.existsSync()) continue;
    final txt = File(md.replaceFirst(RegExp(r'\.md$'), '.txt'));
    // UTF-8 with BOM, so Notepad on older Windows shows Russian right.
    final want = '﻿${toText(src.readAsStringSync())}';
    String body(String s) => s.startsWith('﻿') ? s.substring(1) : s;
    final have = txt.existsSync() ? body(txt.readAsStringSync()) : null;
    if (have == body(want)) continue;
    if (check) {
      stderr.writeln('${txt.path} is out of date: run dart run tool/md_to_txt.dart');
      stale = true;
    } else {
      txt.writeAsStringSync(want);
      stdout.writeln('wrote ${txt.path}');
    }
  }
  if (stale) exitCode = 1;
}

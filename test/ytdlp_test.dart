import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/online/domain/online_error.dart';
import 'package:prism/features/online/services/youtube/ytdlp.dart';

void main() {
  test('reads the hash of yt-dlp.exe from the release list', () {
    const sums = 'aa11  yt-dlp\nF5389D36  yt-dlp.exe\nbb22  yt-dlp_x86.exe\n';
    expect(YtDlp.shaFor(sums, 'yt-dlp.exe'), 'f5389d36');
    expect(YtDlp.shaFor(sums, 'yt-dlp_x86.exe'), 'bb22');
    expect(YtDlp.shaFor(sums, 'missing.exe'), isNull);
  });

  test("yt-dlp's errors become the right kind", () {
    expect(YtDlp.describeFailure(-1, '').kind, OnlineErrorKind.offline, reason: 'timeout');
    expect(
      YtDlp.describeFailure(1, 'ERROR: [youtube] x: Unable to download webpage: <urlopen error [Errno 11001] getaddrinfo failed>').kind,
      OnlineErrorKind.offline,
    );
    expect(
      YtDlp.describeFailure(1, "ERROR: [youtube] x: Sign in to confirm you're not a bot").kind,
      OnlineErrorKind.rateLimited,
    );
    expect(YtDlp.describeFailure(1, 'ERROR: [youtube] x: Video unavailable').kind, OnlineErrorKind.notFound,
        reason: 'a blocked song: the downloader tries another upload');
    final other = YtDlp.describeFailure(1, 'WARNING: a\nERROR: something new broke');
    expect(other.kind, OnlineErrorKind.badResponse);
    expect(other.message, contains('something new broke'));
  });

  test('a copy fetched by Prism wins over the shipped one', () async {
    final dir = await Directory.systemTemp.createTemp('prism_ytdlp_');
    addTearDown(() => dir.delete(recursive: true));
    final y = YtDlp(toolsDir: dir);
    addTearDown(y.close);
    expect(await y.executable(), YtDlp.bundled());
    await File('${dir.path}${Platform.pathSeparator}yt-dlp.exe').writeAsString('x');
    expect(await y.executable(), endsWith('${dir.path}${Platform.pathSeparator}yt-dlp.exe'));
  });
}

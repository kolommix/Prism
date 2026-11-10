import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

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
    final own = File('${dir.path}/yt-dlp/yt-dlp.exe');
    await own.create(recursive: true);
    expect(p.normalize((await y.executable())!), p.normalize(own.path));
  });

  test('uses Windows certificates (antivirus HTTPS scanning)', () {
    final args = YtDlp.args('abc', 'out');
    final i = args.indexOf('--compat-options');
    expect(args[i + 1], 'no-certifi');
    expect(args.last, endsWith('watch?v=abc'));
  });

  test('a refused certificate says what to do', () {
    final e = YtDlp.describeFailure(1, 'ERROR: [SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed');
    expect(e.kind, OnlineErrorKind.badResponse);
    expect(e.message, contains('antivirus'));
  });

  test('an antivirus refusing to start it is seen', () {
    expect(YtDlp.killedFromOutside(225), isTrue);
    expect(YtDlp.killedFromOutside(-1073741790), isTrue);
    expect(YtDlp.killedFromOutside(1), isFalse);
  });

  test('unpacks the yt-dlp zip and never writes outside the folder', () async {
    final dir = await Directory.systemTemp.createTemp('prism_ytdlp_zip_');
    addTearDown(() => dir.delete(recursive: true));
    final zip = Archive()
      ..add(ArchiveFile.bytes('yt-dlp.exe', [1, 2, 3]))
      ..add(ArchiveFile.bytes('_internal/python.dll', [4]))
      ..add(ArchiveFile.bytes('../escape.txt', [5]));
    await YtDlp.extractZip(ZipEncoder().encode(zip), Directory('${dir.path}/out'));
    expect(await File('${dir.path}/out/yt-dlp.exe').readAsBytes(), [1, 2, 3]);
    expect(await File('${dir.path}/out/_internal/python.dll').exists(), isTrue);
    expect(await File('${dir.path}/escape.txt').exists(), isFalse);
  });
}

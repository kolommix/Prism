import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../../l10n/l10n.dart';
import '../../domain/external_track.dart';
import '../../domain/online_error.dart';

/// Saves YouTube audio with yt-dlp (github.com/yt-dlp/yt-dlp, public domain).
///
/// Since late 2026 YouTube gives readers like youtube_explode only the first
/// megabyte of most music uploads. yt-dlp keeps up with YouTube's changes
/// every few days and still saves them (measured: blocked songs saved whole in
/// 4-5 s, no JavaScript runtime needed). Windows only: it is one `.exe`.
///
/// Where it comes from: the copy shipped next to `prism.exe`, or a newer one
/// Prism fetched itself into `<app support>/tools` from yt-dlp's official
/// release, checked against that release's SHA-256 list. Prism fetches one when
/// there is none, and when saving fails and the copy is older than a day
/// (YouTube changes break old versions). Only used once the user said yes to
/// saving songs, and that question says so.
class YtDlp {
  YtDlp({required this.toolsDir, http.Client? client, this.ffmpeg}) : _http = client ?? http.Client();

  final Directory toolsDir;
  final String? ffmpeg;
  final http.Client _http;

  static const releaseApi = 'https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest';
  static const _exe = 'yt-dlp.exe';

  /// After this long, a failing save first fetches the newest yt-dlp.
  static const updateEvery = Duration(days: 1);
  static const timeout = Duration(minutes: 4);

  static bool get supported => Platform.isWindows;

  File get _own => File(p.join(toolsDir.path, _exe));
  File get _checked => File(p.join(toolsDir.path, 'yt-dlp.checked'));

  /// The copy shipped with Prism (or in the source tree when developing).
  static String? bundled() {
    final candidates = [
      p.join(File(Platform.resolvedExecutable).parent.path, _exe),
      p.join(Directory.current.path, 'windows', 'third_party', 'yt-dlp', _exe),
    ];
    return candidates.where((c) => File(c).existsSync()).firstOrNull;
  }

  Future<String?> executable() async => await _own.exists() ? _own.path : bundled();

  /// Saves the audio of video [id] as `<pathWithoutExt>.<ext>`; returns the
  /// extension. Throws [OnlineException].
  Future<String> download(String id, String pathWithoutExt) async {
    var exe = await executable();
    if (exe == null) {
      await update();
      exe = _own.path;
    }
    try {
      return await _run(exe, id, pathWithoutExt);
    } on OnlineException catch (e) {
      // Offline stays offline; anything else may be YouTube having changed.
      if (e.kind == OnlineErrorKind.offline || !await _mayUpdate()) rethrow;
      await update();
      return _run(_own.path, id, pathWithoutExt);
    }
  }

  Future<bool> _mayUpdate() async {
    if (!await _checked.exists()) return true;
    final last = DateTime.tryParse((await _checked.readAsString()).trim());
    return last == null || DateTime.now().difference(last) > updateEvery;
  }

  Future<String> _run(String exe, String id, String pathWithoutExt) async {
    final proc = await Process.start(exe, [
      '--no-config',
      '--no-playlist',
      '--no-progress',
      '--no-warnings',
      '--no-mtime',
      '--concurrent-fragments', '4',
      '-f', 'bestaudio[ext=m4a]/bestaudio',
      if (ffmpeg != null) ...['--ffmpeg-location', ffmpeg!],
      '-o', '$pathWithoutExt.%(ext)s',
      '--print', 'after_move:filepath',
      'https://www.youtube.com/watch?v=$id',
    ]);
    final out = StringBuffer(), err = StringBuffer();
    final a = proc.stdout.transform(const Utf8Decoder(allowMalformed: true)).listen(out.write).asFuture<void>();
    final b = proc.stderr.transform(const Utf8Decoder(allowMalformed: true)).listen(err.write).asFuture<void>();
    _running.add(proc);
    final code = await proc.exitCode.timeout(timeout, onTimeout: () {
      proc.kill();
      return -1;
    });
    _running.remove(proc);
    await Future.wait([a, b]).timeout(const Duration(seconds: 5), onTimeout: () => const []);
    final path = out.toString().trim().split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).lastOrNull;
    if (code == 0 && path != null && await File(path).exists()) return p.extension(path).replaceFirst('.', '');
    throw describeFailure(code, err.toString());
  }

  /// What went wrong, from yt-dlp's error text.
  static OnlineException describeFailure(int code, String stderr) {
    final text = stderr.toLowerCase();
    final last = stderr.trim().split('\n').where((l) => l.contains('ERROR')).lastOrNull?.trim();
    if (code == -1) {
      return OnlineException(OnlineErrorKind.offline, service: OnlineService.youtube, message: l10n.youtubeDidNotAnswerInTime);
    }
    if (text.contains('getaddrinfo') || text.contains('unable to connect') || text.contains('timed out')) {
      return OnlineException(OnlineErrorKind.offline, service: OnlineService.youtube);
    }
    if (text.contains('sign in to confirm') || text.contains('http error 429')) {
      return OnlineException(OnlineErrorKind.rateLimited, service: OnlineService.youtube, message: l10n.youtubeAsksToSlowDownToo);
    }
    if (text.contains('video unavailable') || text.contains('private video') || text.contains('not available')) {
      return OnlineException(OnlineErrorKind.notFound, service: OnlineService.youtube, message: l10n.youtubeBlocksThisSong);
    }
    final short = last == null ? 'exit $code' : (last.length > 160 ? '${last.substring(0, 160)}…' : last);
    return OnlineException(OnlineErrorKind.badResponse, service: OnlineService.youtube, message: l10n.youtubeExtractorFailedYoutubeMayHave(short));
  }

  /// Fetches the newest yt-dlp from its official release and checks it
  /// against the release's SHA-256 list before using it.
  Future<void> update() async {
    try {
      final rel = await _http.get(Uri.parse(releaseApi), headers: {'Accept': 'application/vnd.github+json'});
      if (rel.statusCode != 200) throw OnlineException(OnlineErrorKind.badResponse, service: OnlineService.youtube);
      final assets = (jsonDecode(rel.body) as Map<String, dynamic>)['assets'] as List;
      String? url(String name) =>
          assets.cast<Map<String, dynamic>>().where((a) => a['name'] == name).firstOrNull?['browser_download_url'] as String?;
      final exeUrl = url(_exe), sumsUrl = url('SHA2-256SUMS');
      if (exeUrl == null || sumsUrl == null) throw OnlineException(OnlineErrorKind.badResponse, service: OnlineService.youtube);
      final sums = await _http.get(Uri.parse(sumsUrl));
      final want = shaFor(sums.body, _exe);
      final bin = await _http.get(Uri.parse(exeUrl));
      if (bin.statusCode != 200 || want == null || sha256.convert(bin.bodyBytes).toString() != want) {
        throw OnlineException(OnlineErrorKind.badResponse, service: OnlineService.youtube, message: l10n.ytdlpCheckFailed);
      }
      await toolsDir.create(recursive: true);
      final tmp = File('${_own.path}.new');
      await tmp.writeAsBytes(bin.bodyBytes, flush: true);
      if (await _own.exists()) await _own.delete();
      await tmp.rename(_own.path);
      await _checked.writeAsString(DateTime.now().toIso8601String());
    } on OnlineException {
      rethrow;
    } on SocketException {
      throw OnlineException(OnlineErrorKind.offline, service: OnlineService.youtube);
    } on http.ClientException {
      throw OnlineException(OnlineErrorKind.offline, service: OnlineService.youtube);
    }
  }

  /// The hash for [name] in a `SHA2-256SUMS` file (`hash  name` lines).
  static String? shaFor(String sums, String name) {
    for (final line in const LineSplitter().convert(sums)) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length == 2 && parts[1].replaceFirst('*', '') == name) return parts[0].toLowerCase();
    }
    return null;
  }

  void close() => _http.close();

  static final _running = <Process>{};

  /// Ends saves still running (quitting): they would go on without Prism.
  static void stopAll() {
    for (final p in _running) {
      p.kill();
    }
    _running.clear();
  }
}

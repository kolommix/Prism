import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../../core/platform/background_process.dart';
import '../../../../core/platform/system_proxy.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/external_track.dart';
import '../../domain/online_error.dart';

/// Saves YouTube audio with yt-dlp (github.com/yt-dlp/yt-dlp, public domain).
///
/// Since late 2026 YouTube gives readers like youtube_explode only the first
/// megabyte of most music uploads. yt-dlp keeps up with YouTube's changes
/// every few days and still saves them (measured: blocked songs saved whole in
/// 4-5 s, no JavaScript runtime needed). Windows only.
///
/// Prism uses the unpacked build (`yt-dlp_win.zip`: `yt-dlp.exe` + `_internal`),
/// not the one-file `yt-dlp.exe`: that one unpacks Python into %TEMP% on every
/// run, which antivirus programs often block or quarantine. It also checks
/// HTTPS against Windows' own certificates (`no-certifi`), so antivirus
/// programs that scan HTTPS with their own certificate don't break it.
///
/// Where it comes from: the copy shipped in `yt-dlp` next to `prism.exe`, or a
/// newer one Prism fetched itself into `<app support>/tools/yt-dlp` from
/// yt-dlp's official release, checked against that release's SHA-256 list.
/// Prism fetches one when there is none, and when saving fails and the copy is
/// older than a day (YouTube changes break old versions). Only used once the
/// user said yes to saving songs, and that question says so.
class YtDlp {
  YtDlp({required this.toolsDir, http.Client? client, this.ffmpeg}) : _http = client ?? http.Client();

  final Directory toolsDir;
  final String? ffmpeg;
  final http.Client _http;

  static const releaseApi = 'https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest';
  static const _exe = 'yt-dlp.exe';
  static const _zip = 'yt-dlp_win.zip';

  /// After this long, a failing save first fetches the newest yt-dlp.
  static const updateEvery = Duration(days: 1);
  static const timeout = Duration(minutes: 4);

  static bool get supported => Platform.isWindows;

  Directory get _ownDir => Directory(p.join(toolsDir.path, 'yt-dlp'));
  File get _own => File(p.join(_ownDir.path, _exe));
  File get _checked => File(p.join(toolsDir.path, 'yt-dlp.checked'));

  /// The copy shipped with Prism (or in the source tree when developing).
  static String? bundled() {
    final candidates = [
      p.join(File(Platform.resolvedExecutable).parent.path, 'yt-dlp', _exe),
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
      // Offline stays offline, blocked stays blocked; anything else may be
      // YouTube having changed.
      if (e.kind == OnlineErrorKind.offline || identical(e, _blockedError) || !await _mayUpdate()) rethrow;
      await update();
      return _run(_own.path, id, pathWithoutExt);
    }
  }

  Future<bool> _mayUpdate() async {
    if (!await _checked.exists()) return true;
    final last = DateTime.tryParse((await _checked.readAsString()).trim());
    return last == null || DateTime.now().difference(last) > updateEvery;
  }

  /// An antivirus program stopped yt-dlp from starting, or removed it. Names
  /// the folder to allow.
  OnlineException get _blocked => _blockedError ??= OnlineException(
        OnlineErrorKind.badResponse,
        service: OnlineService.youtube,
        message: l10n.ytdlpBlockedByAntivirus(p.dirname(bundled() ?? _own.path)),
      );
  OnlineException? _blockedError;

  Future<String> _run(String exe, String id, String pathWithoutExt) async {
    if (!await File(exe).exists()) throw _blocked;
    // From a background isolate: starting a process blocks the calling
    // thread (see BackgroundProcess), and imports start one per song.
    // The same way out as the rest of Prism (a VPN app's system proxy).
    final proxy = SystemProxy.instance.proxyFor(Uri.parse('https://www.youtube.com/'));
    final proc = await BackgroundProcess.start(exe, args(id, pathWithoutExt, ffmpeg: ffmpeg, proxy: proxy), timeout: timeout);
    _running.add(proc);
    final r = await proc.done;
    _running.remove(proc);
    final code = r.exitCode;
    final out = r.stdout, err = r.stderr;
    // Windows refused to start it.
    if (code == -2) throw _blocked;
    // Stopped from outside before it said anything (antivirus).
    if (killedFromOutside(code) && err.isEmpty) throw _blocked;
    final path = out.trim().split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).lastOrNull;
    if (code == 0 && path != null && await File(path).exists()) return p.extension(path).replaceFirst('.', '');
    throw describeFailure(code, err);
  }

  /// The command line for one song.
  static List<String> args(String id, String pathWithoutExt, {String? ffmpeg, String? proxy}) => [
        '--no-config',
        '--no-playlist',
        '--no-progress',
        '--no-warnings',
        '--no-mtime',
        // Windows' certificates instead of yt-dlp's own list: antivirus HTTPS
        // scanning adds its certificate to Windows only.
        '--compat-options', 'no-certifi',
        '--concurrent-fragments', '4',
        // A network that blocks or slows YouTube must fail in seconds, not
        // after yt-dlp's ten patient retries per request.
        '--socket-timeout', '15',
        '--retries', '3',
        '--fragment-retries', '3',
        '--extractor-retries', '1',
        '-f', 'bestaudio[ext=m4a]/bestaudio',
        if (ffmpeg != null) ...['--ffmpeg-location', ffmpeg],
        if (proxy != null) ...['--proxy', 'http://$proxy'],
        '-o', '$pathWithoutExt.%(ext)s',
        '--print', 'after_move:filepath',
        'https://www.youtube.com/watch?v=$id',
      ];

  /// Exit codes of a process Windows or an antivirus refused or ended:
  /// access denied (5, or STATUS_ACCESS_DENIED), "file contains a virus" (225).
  static bool killedFromOutside(int code) => code == 5 || code == 225 || code == -1073741790;

  /// What went wrong, from yt-dlp's error text.
  static OnlineException describeFailure(int code, String stderr) {
    final text = stderr.toLowerCase();
    final last = stderr.trim().split('\n').where((l) => l.contains('ERROR')).lastOrNull?.trim();
    if (code == -1) {
      return OnlineException(OnlineErrorKind.offline, service: OnlineService.youtube, message: l10n.youtubeDidNotAnswerInTime);
    }
    if (text.contains('certificate_verify_failed') || text.contains('certificate verify failed')) {
      return OnlineException(OnlineErrorKind.badResponse, service: OnlineService.youtube, message: l10n.ytdlpCertificateRefused);
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
      final zipUrl = url(_zip), sumsUrl = url('SHA2-256SUMS');
      if (zipUrl == null || sumsUrl == null) throw OnlineException(OnlineErrorKind.badResponse, service: OnlineService.youtube);
      final sums = await _http.get(Uri.parse(sumsUrl));
      final want = shaFor(sums.body, _zip);
      final bin = await _http.get(Uri.parse(zipUrl));
      if (bin.statusCode != 200 || want == null || sha256.convert(bin.bodyBytes).toString() != want) {
        throw OnlineException(OnlineErrorKind.badResponse, service: OnlineService.youtube, message: l10n.ytdlpCheckFailed);
      }
      await toolsDir.create(recursive: true);
      final tmp = Directory('${_ownDir.path}.new');
      if (await tmp.exists()) await tmp.delete(recursive: true);
      await extractZip(bin.bodyBytes, tmp);
      if (await _ownDir.exists()) await _ownDir.delete(recursive: true);
      await tmp.rename(_ownDir.path);
      // The one-file copy older versions kept here.
      final old = File(p.join(toolsDir.path, _exe));
      if (await old.exists()) await old.delete();
      await _checked.writeAsString(DateTime.now().toIso8601String());
    } on OnlineException {
      rethrow;
    } on SocketException {
      throw OnlineException(OnlineErrorKind.offline, service: OnlineService.youtube);
    } on http.ClientException {
      throw OnlineException(OnlineErrorKind.offline, service: OnlineService.youtube);
    } on FileSystemException {
      // An antivirus holding or removing the new files.
      throw _blocked;
    }
  }

  /// Unpacks a zip into [dir], never writing outside it.
  static Future<void> extractZip(List<int> bytes, Directory dir) async {
    final zip = ZipDecoder().decodeBytes(bytes);
    final root = p.normalize(dir.absolute.path);
    for (final f in zip.files) {
      if (!f.isFile) continue;
      final out = p.normalize(p.join(root, f.name));
      if (!p.isWithin(root, out)) continue;
      final file = File(out);
      await file.parent.create(recursive: true);
      await file.writeAsBytes(f.content);
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

  static final _running = <BackgroundProcess>{};

  /// Ends saves still running (quitting): they would go on without Prism.
  static void stopAll() {
    for (final p in _running) {
      p.kill();
    }
    _running.clear();
  }
}

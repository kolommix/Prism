import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/prism_theme_extensions.dart';
import '../../l10n/l10n.dart';
import 'update_check.dart';

/// Updating without uninstalling.
///
/// Windows: Prism downloads the new installer from its own GitHub release,
/// checks it against GitHub's size and SHA-256 for that upload, starts it
/// quietly and quits. The installer replaces the program files in place (same
/// app id, so it is an update, never a second install), keeps the library,
/// playlists and settings (they live in %APPDATA%, which it never touches),
/// and starts Prism again. Friends see a small progress window, nothing to click.
/// Android: the APK for the phone's processor opens in the browser; installing
/// it over the old one keeps everything (same signing key).
class UpdateDownloader {
  UpdateDownloader({http.Client? client, Directory? dir})
      : _client = client ?? http.Client(),
        _dir = dir ?? Directory(p.join(Directory.systemTemp.path, 'Prism-update'));

  final http.Client _client;
  final Directory _dir;

  /// Downloads [asset] (or reuses a finished earlier download) and checks it.
  /// Throws [UpdateCheckException].
  Future<File> download(ReleaseAsset asset, {void Function(double progress)? onProgress}) async {
    await _dir.create(recursive: true);
    final file = File(p.join(_dir.path, p.basename(asset.name)));
    if (await file.exists() && await _matches(file, asset)) return file;
    final part = File('${file.path}.part');
    try {
      final res = await _client.send(http.Request('GET', Uri.parse(asset.url))).timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) throw UpdateCheckException(l10n.updateFailed('HTTP ${res.statusCode}'));
      final sink = part.openWrite();
      final hash = _HashSink();
      final hasher = sha256.startChunkedConversion(hash);
      var got = 0;
      try {
        await for (final chunk in res.stream.timeout(const Duration(seconds: 60))) {
          sink.add(chunk);
          hasher.add(chunk);
          got += chunk.length;
          if (asset.size > 0) onProgress?.call((got / asset.size).clamp(0, 1).toDouble());
        }
      } finally {
        await sink.close();
        hasher.close();
      }
      final sha = hash.value?.toString();
      if (got != asset.size || (asset.sha256 != null && sha != asset.sha256)) {
        throw UpdateCheckException(l10n.updateBroken);
      }
      if (await file.exists()) await file.delete();
      await part.rename(file.path);
      return file;
    } on UpdateCheckException {
      await _drop(part);
      rethrow;
    } on Object catch (e) {
      await _drop(part);
      throw UpdateCheckException(l10n.updateFailed(e));
    }
  }

  static Future<bool> _matches(File f, ReleaseAsset a) async {
    if (await f.length() != a.size) return false;
    if (a.sha256 == null) return true;
    return (await sha256.bind(f.openRead()).first).toString() == a.sha256;
  }

  static Future<void> _drop(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } on FileSystemException {
      // Next try overwrites it.
    }
  }

  void close() => _client.close();
}

class _HashSink implements Sink<Digest> {
  Digest? value;
  @override
  void add(Digest data) => value = data;
  @override
  void close() {}
}

/// The installer's switches for a quiet update: a small progress window only,
/// no questions, Prism (if still open, say in the tray) is closed for it, and the installer
/// starts Prism again at the end (installer\prism.iss, `skipifnotsilent`).
List<String> silentInstallerArgs({required bool russian}) =>
    ['/SILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/CLOSEAPPLICATIONS', '/FORCECLOSEAPPLICATIONS', '/LANG=${russian ? 'ru' : 'en'}'];

/// How Prism quits for an update (main.dart sets the real quit).
Future<void> Function() quitForUpdate = () async => exit(0);

Future<void> showUpdateDialog(BuildContext context, ReleaseInfo r) => showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(release: r),
    );

enum _Step { ask, downloading, installing, failed }

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key, required this.release, this.downloader, this.startInstaller, this.windows});

  final ReleaseInfo release;

  /// For tests.
  final UpdateDownloader? downloader;
  final Future<void> Function(File setup)? startInstaller;
  final bool? windows;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  _Step _step = _Step.ask;
  double _progress = 0;
  String? _error;
  late final bool _windows = widget.windows ?? Platform.isWindows;
  late final ReleaseAsset? _file = updateFileFor(widget.release, windows: _windows, dartVersion: Platform.version);
  UpdateDownloader? _downloader;

  @override
  void dispose() {
    if (widget.downloader == null) _downloader?.close();
    super.dispose();
  }

  Future<void> _update() async {
    final file = _file;
    if (file == null) return _openPage();
    if (!_windows) {
      await launchUrl(Uri.parse(file.url), mode: LaunchMode.externalApplication);
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() {
      _step = _Step.downloading;
      _progress = 0;
    });
    try {
      final d = _downloader = widget.downloader ?? UpdateDownloader();
      final setup = await d.download(file, onProgress: (v) {
        if (mounted && (v - _progress).abs() >= 0.01) setState(() => _progress = v);
      });
      if (!mounted) return;
      setState(() => _step = _Step.installing);
      final start = widget.startInstaller ??
          (File f) async {
            await Process.start(f.path, silentInstallerArgs(russian: l10n.localeName.startsWith('ru')),
                mode: ProcessStartMode.detached);
            // Gone before the installer looks for running copies.
            await Future<void>.delayed(const Duration(milliseconds: 600));
            await quitForUpdate();
          };
      await start(setup);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _Step.failed;
        _error = e is UpdateCheckException ? e.message : l10n.updateFailed(e);
      });
    }
  }

  Future<void> _openPage() async {
    await launchUrl(Uri.parse(widget.release.url), mode: LaunchMode.externalApplication);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.release;
    final text = Theme.of(context).textTheme;
    final muted = text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final Widget body;
    final List<Widget> actions;
    switch (_step) {
      case _Step.ask:
        body = SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (r.notes.trim().isNotEmpty) ...[Text(r.notes.trim()), const SizedBox(height: 16)],
              Text(
                _file == null ? l10n.updateHowTo : (_windows ? l10n.updateWindowsHint : l10n.updateAndroidHint),
                style: muted,
              ),
            ],
          ),
        );
        actions = [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.updateLater)),
          FilledButton(
            onPressed: _file == null ? _openPage : _update,
            child: Text(_file == null ? l10n.updateOpen : (_windows ? l10n.updateNow : l10n.updateDownloadApk)),
          ),
        ];
      case _Step.downloading:
        body = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.updateDownloading(fmtNum((_progress * 100).round()))),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: context.shape.small,
              child: LinearProgressIndicator(value: _progress, minHeight: 6),
            ),
          ],
        );
        actions = const [];
      case _Step.installing:
        body = Row(
          children: [
            const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 16),
            Expanded(child: Text(l10n.updateInstalling)),
          ],
        );
        actions = const [];
      case _Step.failed:
        body = Text(_error ?? l10n.updateBroken);
        actions = [
          TextButton(onPressed: _openPage, child: Text(l10n.updateOpen)),
          FilledButton(onPressed: _update, child: Text(l10n.tryAgain)),
        ];
    }
    return PopScope(
      canPop: _step == _Step.ask || _step == _Step.failed,
      child: AlertDialog(
        title: Text(l10n.updateAvailable(r.version)),
        content: SizedBox(width: 460, child: body),
        actions: actions,
      ),
    );
  }
}

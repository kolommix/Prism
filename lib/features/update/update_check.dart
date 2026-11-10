import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_version.dart';
import '../../l10n/l10n.dart';
import 'update_installer.dart';

/// The newest published version.
class ReleaseInfo {
  const ReleaseInfo({required this.version, required this.url, this.notes = '', this.assets = const []});
  final String version;
  final String url;
  final String notes;

  /// Files of the release (installer, APKs), only ones on Prism's GitHub.
  final List<ReleaseAsset> assets;
}

/// One downloadable file of a release.
class ReleaseAsset {
  const ReleaseAsset({required this.name, required this.url, required this.size, this.sha256});
  final String name;
  final String url;
  final int size;

  /// From GitHub's own record of the upload (`digest: sha256:...`), when given.
  final String? sha256;

  /// Only files that really come from Prism's releases.
  static ReleaseAsset? fromJson(Object? j) {
    if (j is! Map) return null;
    final name = j['name'], url = j['browser_download_url'], size = j['size'], digest = j['digest'];
    if (name is! String || url is! String || size is! int) return null;
    if (!url.startsWith('https://github.com/$githubRepo/releases/download/')) return null;
    final sha = digest is String && digest.startsWith('sha256:') ? digest.substring(7).toLowerCase() : null;
    return ReleaseAsset(name: name, url: url, size: size, sha256: sha);
  }
}

/// The file that updates this install: the Windows installer, or the APK for
/// this phone's processor ([dartVersion] says which: `on "android_arm64"`).
ReleaseAsset? updateFileFor(ReleaseInfo r, {required bool windows, String? dartVersion}) {
  if (windows) {
    final setup = RegExp(r'^Prism-Setup-.*\.exe$');
    return r.assets.where((a) => setup.hasMatch(a.name)).firstOrNull;
  }
  final v = dartVersion ?? '';
  final abi = v.contains('android_arm64')
      ? 'arm64-v8a'
      : v.contains('android_arm')
          ? 'armeabi-v7a'
          : null;
  final apks = r.assets.where((a) => a.name.endsWith('.apk')).toList();
  if (abi != null) {
    final exact = apks.where((a) => a.name.contains(abi)).firstOrNull;
    if (exact != null) return exact;
  }
  // The universal one works everywhere.
  return apks.where((a) => !a.name.contains('arm64-v8a') && !a.name.contains('armeabi')).firstOrNull ?? apks.firstOrNull;
}

/// True when [latest] ("v1.2.0") is newer than [current] ("1.1.9+3").
bool isNewerVersion(String latest, String current) {
  List<int> parts(String v) {
    final clean = v.trim().replaceFirst(RegExp('^[vV]'), '').split('+').first.split('-').first;
    return [for (final p in clean.split('.')) int.tryParse(p) ?? 0];
  }

  final a = parts(latest), b = parts(current);
  for (var i = 0; i < 3; i++) {
    final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
    if (x != y) return x > y;
  }
  return false;
}

class UpdateCheckException implements Exception {
  UpdateCheckException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Asks GitHub for the latest release. Null = nothing published yet. Sends
/// nothing but the request itself.
Future<ReleaseInfo?> fetchLatestRelease({http.Client? client}) async {
  final c = client ?? http.Client();
  try {
    final res = await c.get(
      Uri.https('api.github.com', '/repos/$githubRepo/releases/latest'),
      headers: {'Accept': 'application/vnd.github+json', 'User-Agent': 'Prism/$appVersion'},
    ).timeout(const Duration(seconds: 10));
    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) throw UpdateCheckException(l10n.updateFailed('HTTP ${res.statusCode}'));
    final j = jsonDecode(utf8.decode(res.bodyBytes));
    if (j is! Map || j['tag_name'] is! String) throw UpdateCheckException(l10n.updateFailed('format'));
    return ReleaseInfo(
      version: (j['tag_name'] as String).replaceFirst(RegExp('^[vV]'), ''),
      // Only ever opens Prism's own GitHub page.
      url: j['html_url'] is String && (j['html_url'] as String).startsWith('https://github.com/$githubRepo/')
          ? j['html_url'] as String
          : 'https://github.com/$githubRepo/releases/latest',
      notes: j['body'] as String? ?? '',
      assets: [
        if (j['assets'] case final List list)
          for (final a in list) ?ReleaseAsset.fromJson(a),
      ],
    );
  } on UpdateCheckException {
    rethrow;
  } on Object catch (e) {
    throw UpdateCheckException(l10n.updateFailed(e));
  } finally {
    if (client == null) c.close();
  }
}

/// Checks and tells the user, for the button in Settings → About.
Future<void> checkForUpdatesInteractive(BuildContext context) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(SnackBar(content: Text(l10n.updateChecking), duration: const Duration(seconds: 2)));
  try {
    final latest = await fetchLatestRelease();
    if (!context.mounted) return;
    messenger?.hideCurrentSnackBar();
    if (latest == null || !isNewerVersion(latest.version, appVersion)) {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.updateNone(appVersion))));
      return;
    }
    await showUpdateDialog(context, latest);
  } on UpdateCheckException catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// The quiet check at startup: at most once a day, and only says something when
/// there is a new version. Failures stay silent; the button still works.
Future<ReleaseInfo?> quietUpdateCheck(SharedPreferencesAsync prefs, {http.Client? client, DateTime? now}) async {
  const key = 'update.lastCheckMs';
  final t = now ?? DateTime.now();
  try {
    final last = await prefs.getInt(key) ?? 0;
    if (t.millisecondsSinceEpoch - last < const Duration(days: 1).inMilliseconds) return null;
    await prefs.setInt(key, t.millisecondsSinceEpoch);
    final latest = await fetchLatestRelease(client: client);
    return latest != null && isNewerVersion(latest.version, appVersion) ? latest : null;
  } on Object {
    return null;
  }
}

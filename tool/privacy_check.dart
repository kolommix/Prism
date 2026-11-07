// Fails the build when Prism starts asking for more than docs/PRIVACY.md says.
//
//   dart run tool/privacy_check.dart --lock pubspec.lock
//   dart run tool/privacy_check.dart --manifest build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml
//   dart run tool/privacy_check.dart --windows build/windows/x64/runner/Release
//
// Works on the MERGED manifest on purpose: that's where permissions added by
// libraries show up.
import 'dart:io';
import 'dart:typed_data';

/// The full list of what Prism may ask for. New one: add it to docs/PRIVACY.md
/// and the in-app Privacy section first, then here.
const allowedPermissions = {
  'android.permission.READ_MEDIA_AUDIO',
  'android.permission.READ_EXTERNAL_STORAGE',
  'android.permission.WAKE_LOCK',
  'android.permission.FOREGROUND_SERVICE',
  'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK',
  'android.permission.POST_NOTIFICATIONS',
  'android.permission.INTERNET',
  'android.permission.ACCESS_NETWORK_STATE',
  'android.permission.RECORD_AUDIO',
  'android.permission.MODIFY_AUDIO_SETTINGS',
  'android.permission.WRITE_SETTINGS',
};

/// Own broadcast guard AndroidX adds to every app.
final _generated = RegExp(r'\.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION$');

/// Packages that read location or send analytics / crash reports. The umbrella
/// permission_handler links permission_handler_windows, which starts a Windows
/// Geolocator when the app launches: use permission_handler_android directly.
final bannedPackages = RegExp(
  r'^(geolocator.*|geocod.*|location.*|permission_handler|permission_handler_windows|'
  r'firebase.*|sentry.*|.*crashlytics.*|.*analytics.*|.*telemetry.*|amplitude.*|mixpanel.*|appcenter.*|'
  r'device_info.*|android_id|advertising_id|flutter_udid|network_info.*)$',
);

/// Every permission in a manifest, also `uses-permission-sdk-23` ones.
List<String> permissionsIn(String manifest) => [
  for (final tag in RegExp(r'<uses-permission(?:-sdk-\d+)?\s[^>]*>', dotAll: true).allMatches(manifest))
    ?RegExp(r'android:name\s*=\s*"([^"]+)"').firstMatch(tag[0]!)?[1],
];

/// Problems with a merged manifest; empty = fine.
List<String> checkManifest(String manifest) {
  final problems = <String>[];
  for (final p in permissionsIn(manifest).toSet()) {
    if (p.contains('LOCATION')) {
      problems.add('LOCATION permission in the merged manifest: $p');
    } else if (!allowedPermissions.contains(p) && !_generated.hasMatch(p)) {
      problems.add('Permission not listed in docs/PRIVACY.md: $p');
    }
  }
  return problems;
}

/// Problems with pubspec.lock; empty = fine.
List<String> checkLock(String lock) => [
  for (final m in RegExp(r'^  ([a-z0-9_]+):\s*$', multiLine: true).allMatches(lock))
    if (bannedPackages.hasMatch(m[1]!)) 'Banned package in pubspec.lock: ${m[1]}',
];

/// True when [bytes] mention the Windows location API, in ASCII or UTF-16.
bool mentionsGeolocation(Uint8List bytes) {
  const needle = 'Windows.Devices.Geolocation';
  return _find(bytes, needle.codeUnits) || _find(bytes, [for (final c in needle.codeUnits) ...[c, 0]]);
}

bool _find(Uint8List hay, List<int> needle) {
  final first = needle.first;
  for (var i = 0; i <= hay.length - needle.length; i++) {
    if (hay[i] != first) continue;
    var j = 1;
    while (j < needle.length && hay[i + j] == needle[j]) {
      j++;
    }
    if (j == needle.length) return true;
  }
  return false;
}

/// Problems with a Windows build folder; empty = fine.
List<String> checkWindowsBuild(Directory dir) => [
  for (final f in dir.listSync(recursive: true).whereType<File>())
    if ((f.path.endsWith('.dll') || f.path.endsWith('.exe')) && mentionsGeolocation(f.readAsBytesSync()))
      'Uses the Windows location API: ${f.path}',
];

void main(List<String> args) {
  final problems = <String>[];
  var checked = 0;
  for (var i = 0; i + 1 < args.length; i += 2) {
    final path = args[i + 1];
    checked++;
    switch (args[i]) {
      case '--manifest':
        problems.addAll(checkManifest(File(path).readAsStringSync()));
      case '--lock':
        problems.addAll(checkLock(File(path).readAsStringSync()));
      case '--windows':
        problems.addAll(checkWindowsBuild(Directory(path)));
      default:
        stderr.writeln('Unknown option ${args[i]}');
        exit(2);
    }
  }
  if (checked == 0) {
    stderr.writeln('Nothing to check. Options: --manifest <file> --lock <file> --windows <folder>');
    exit(2);
  }
  if (problems.isEmpty) {
    stdout.writeln('Privacy check passed ($checked checked).');
    return;
  }
  for (final p in problems) {
    stderr.writeln(Platform.environment.containsKey('GITHUB_ACTIONS') ? '::error::$p' : p);
  }
  exit(1);
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:crypto/crypto.dart';
import 'package:prism/features/update/update_check.dart';
import 'package:prism/features/update/update_installer.dart';

void main() {
  test('version compare', () {
    expect(isNewerVersion('v1.2.0', '1.1.9'), isTrue);
    expect(isNewerVersion('1.10.0', '1.9.0'), isTrue, reason: 'numbers, not text');
    expect(isNewerVersion('v1.1.0', '1.1.0+5'), isFalse);
    expect(isNewerVersion('1.0.9', '1.1.0'), isFalse);
    expect(isNewerVersion('2', '1.9.9'), isTrue);
    expect(isNewerVersion('garbage', '1.0.0'), isFalse);
  });

  test('reads the latest release', () async {
    final r = await fetchLatestRelease(client: MockClient((req) async {
      expect(req.url.path, endsWith('/releases/latest'));
      return http.Response('{"tag_name":"v1.2.0","html_url":"https://github.com/kolommix/Prism/releases/tag/v1.2.0","body":"Notes"}', 200);
    }));
    expect(r!.version, '1.2.0');
    expect(r.url, 'https://github.com/kolommix/Prism/releases/tag/v1.2.0');
    expect(r.notes, 'Notes');
  });

  test('a link to anywhere else opens Prism''s release page instead', () async {
    final r = await fetchLatestRelease(client: MockClient((_) async => http.Response('{"tag_name":"v1.2.0","html_url":"https://evil.example/x"}', 200)));
    expect(r!.url, 'https://github.com/kolommix/Prism/releases/latest');
  });

  group('one-click update', () {
    const base = 'https://github.com/kolommix/Prism/releases/download/v1.3.0';
    final release = ReleaseInfo(version: '1.3.0', url: 'u', assets: [
      ReleaseAsset(name: 'Prism-1.3.0.apk', url: '$base/Prism-1.3.0.apk', size: 1),
      ReleaseAsset(name: 'Prism-1.3.0-arm64-v8a.apk', url: '$base/Prism-1.3.0-arm64-v8a.apk', size: 1),
      ReleaseAsset(name: 'Prism-1.3.0-armeabi-v7a.apk', url: '$base/Prism-1.3.0-armeabi-v7a.apk', size: 1),
      ReleaseAsset(name: 'Prism-Setup-1.3.0.exe', url: '$base/Prism-Setup-1.3.0.exe', size: 1),
      ReleaseAsset(name: 'README.txt', url: '$base/README.txt', size: 1),
    ]);

    test('picks the installer on Windows and the right APK on a phone', () {
      expect(updateFileFor(release, windows: true)!.name, 'Prism-Setup-1.3.0.exe');
      expect(updateFileFor(release, windows: false, dartVersion: '3.13.7 (stable) on "android_arm64"')!.name, 'Prism-1.3.0-arm64-v8a.apk');
      expect(updateFileFor(release, windows: false, dartVersion: '3.13.7 (stable) on "android_arm"')!.name, 'Prism-1.3.0-armeabi-v7a.apk');
      expect(updateFileFor(release, windows: false, dartVersion: '3.13.7 (stable) on "android_x64"')!.name, 'Prism-1.3.0.apk');
      expect(updateFileFor(const ReleaseInfo(version: '1', url: 'u'), windows: true), isNull, reason: 'no files: the download page');
    });

    test('release files are read with their GitHub hash, files from elsewhere are dropped', () async {
      final r = await fetchLatestRelease(client: MockClient((_) async => http.Response(
            '{"tag_name":"v1.3.0","html_url":"https://github.com/kolommix/Prism/releases/tag/v1.3.0","assets":['
            '{"name":"Prism-Setup-1.3.0.exe","browser_download_url":"$base/Prism-Setup-1.3.0.exe","size":5,"digest":"sha256:ABC"},'
            '{"name":"Prism-Setup-1.3.0.exe","browser_download_url":"https://evil.example/Prism-Setup.exe","size":5}]}',
            200,
          )));
      expect(r!.assets, hasLength(1));
      expect(r.assets.single.sha256, 'abc');
    });

    test('download is checked: wrong size or hash is refused, a good one is kept', () async {
      final dir = await Directory.systemTemp.createTemp('prism_upd_');
      addTearDown(() => dir.delete(recursive: true));
      final body = List<int>.generate(5000, (i) => i % 251);
      final sha = sha256.convert(body).toString();
      final client = MockClient((_) async => http.Response.bytes(body, 200));
      final d = UpdateDownloader(client: client, dir: dir);
      final good = ReleaseAsset(name: 'Prism-Setup-1.3.0.exe', url: '$base/Prism-Setup-1.3.0.exe', size: 5000, sha256: sha);
      final progress = <double>[];
      final file = await d.download(good, onProgress: progress.add);
      expect(await file.readAsBytes(), body);
      expect(progress.last, 1.0);

      final badHash = ReleaseAsset(name: 'x.exe', url: '$base/x.exe', size: 5000, sha256: '00');
      await expectLater(d.download(badHash), throwsA(isA<UpdateCheckException>()));
      expect(File('${dir.path}/x.exe').existsSync(), isFalse, reason: 'nothing damaged is left to run');
      final badSize = ReleaseAsset(name: 'y.exe', url: '$base/y.exe', size: 9999);
      await expectLater(d.download(badSize), throwsA(isA<UpdateCheckException>()));
    });

    test('the installer runs quietly and in the app language', () {
      expect(silentInstallerArgs(russian: true), containsAll(['/SILENT', '/SUPPRESSMSGBOXES', '/CLOSEAPPLICATIONS', '/LANG=ru']));
      final iss = File('installer/prism.iss').readAsStringSync();
      expect(iss, contains('skipifnotsilent'), reason: 'Prism starts again after a quiet update');
      expect(iss, contains('function ShouldSkipPage'), reason: 'an update asks nothing again');
    });
  });

  test('nothing published yet is not an error', () async {
    expect(await fetchLatestRelease(client: MockClient((_) async => http.Response('', 404))), isNull);
  });

  test('errors are clear ones', () async {
    expect(
      () => fetchLatestRelease(client: MockClient((_) async => http.Response('', 403))),
      throwsA(isA<UpdateCheckException>()),
    );
    expect(
      () => fetchLatestRelease(client: MockClient((_) async => throw const SocketException('offline'))),
      throwsA(isA<UpdateCheckException>()),
    );
    expect(
      () => fetchLatestRelease(client: MockClient((_) async => http.Response('[]', 200))),
      throwsA(isA<UpdateCheckException>()),
    );
  });

  group('repo safety', () {
    final ignore = File('.gitignore').readAsStringSync();
    test('.gitignore keeps secrets and big files out', () {
      for (final p in ['online_config.json', '*.jks', '*.keystore', 'key.properties', '*.mp3', '*.flac', 'windows/third_party/', '/dist/']) {
        expect(ignore, contains(p), reason: p);
      }
    });

    test('no secret in the workflow, only references', () {
      final yml = File('.github/workflows/release.yml').readAsStringSync();
      expect(yml, contains('secrets.ANDROID_KEYSTORE_BASE64'));
      expect(RegExp(r'storePassword=[^$]').hasMatch(yml), isFalse);
    });
  });
}

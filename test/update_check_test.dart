import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prism/features/update/update_check.dart';

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
      return http.Response('{"tag_name":"v1.2.0","html_url":"https://x/y","body":"Notes"}', 200);
    }));
    expect(r!.version, '1.2.0');
    expect(r.url, 'https://x/y');
    expect(r.notes, 'Notes');
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

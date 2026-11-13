import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prism/core/platform/system_proxy.dart';
import 'package:prism/features/online/application/import_file_check.dart';
import 'package:prism/features/online/data/network_check.dart';
import 'package:prism/features/online/domain/external_track.dart';
import 'package:prism/features/online/domain/import_intake.dart';
import 'package:prism/features/online/domain/online_error.dart';
import 'package:prism/features/online/services/youtube/explode_backend.dart';
import 'package:prism/features/online/services/youtube/ytdlp.dart';

void main() {
  group('saved file check', () {
    late Directory dir;
    setUp(() async => dir = await Directory.systemTemp.createTemp('prism_chk_'));
    tearDown(() => dir.delete(recursive: true));

    File write(String name, List<int> bytes) => File('${dir.path}/$name')..writeAsBytesSync(bytes);
    List<int> noise(int n, [int seed = 1]) {
      final r = Random(seed);
      return [for (var i = 0; i < n; i++) 1 + r.nextInt(255)];
    }

    test('a file with a hole of zeros after the first piece is refused', () async {
      // What the old reader wrote when YouTube stopped answering part way:
      // the first megabyte of sound, then zeros, then the last piece.
      final f = write('holey.m4a', [...noise(1024 * 1024), ...List.filled(512 * 1024, 0), ...noise(300 * 1024, 2)]);
      final r = await const ImportFileCheck().check(f);
      expect(r.ok, isFalse);
      expect(r.reason, 'zero hole');
    });

    test('tiny and missing files are refused, whole ones pass', () async {
      expect((await const ImportFileCheck().check(write('tiny.m4a', noise(500)))).ok, isFalse);
      expect((await const ImportFileCheck().check(File('${dir.path}/none.m4a'))).ok, isFalse);
      expect((await const ImportFileCheck().check(write('ok.m4a', noise(2 * 1024 * 1024)))).ok, isTrue);
    });

    test('zero padding in the tags at the start is fine', () async {
      final f = write('tags.mp3', [...List.filled(100 * 1024, 0), ...noise(2 * 1024 * 1024)]);
      expect((await const ImportFileCheck().check(f)).ok, isTrue);
    });

    test('decoded length must fit the length the service gave', () {
      expect(ImportFileCheck.lengthFits(200000, 200000), isTrue);
      expect(ImportFileCheck.lengthFits(197000, 200000), isTrue);
      expect(ImportFileCheck.lengthFits(30000, 200000), isFalse, reason: 'cut off after the first megabyte');
      expect(ImportFileCheck.lengthFits(30000, 0), isTrue, reason: 'nothing to compare with');
    });

    test('decoder error lines are counted, progress lines are not', () {
      expect(ImportFileCheck.decodeErrors('size=N/A time=00:03:20.00 bitrate=N/A speed= 500x\n'), 0);
      expect(
        ImportFileCheck.decodeErrors('[aac @ 0x1] Error decoding AAC frame\n[aac @ 0x1] Reserved bit set.\nsize=N/A time=00:00:10.00\n'),
        2,
      );
    });
  });

  group('reader pieces', () {
    test('only whole pieces are taken', () {
      expect(ExplodeBackend.pieceOf(206, List.filled(10, 1), 0, 9, 100), hasLength(10));
      expect(ExplodeBackend.pieceOf(206, List.filled(4, 1), 0, 9, 100), isNull, reason: 'short piece = hole');
      expect(ExplodeBackend.pieceOf(206, const [], 0, 9, 100), isNull, reason: 'empty answer = hole');
      expect(ExplodeBackend.pieceOf(200, List.generate(100, (i) => i), 10, 19, 100), List.generate(10, (i) => i + 10));
      expect(ExplodeBackend.pieceOf(200, List.filled(50, 1), 10, 19, 100), isNull);
    });
  });

  group('system proxy', () {
    test('one proxy for everything, with the usual bypass list', () {
      final p = ProxySetting.parseWindows('127.0.0.1:7890', 'localhost;127.*;10.*;<local>;*.lan')!;
      expect(p.forUrl(Uri.parse('https://www.youtube.com/watch?v=x')), '127.0.0.1:7890');
      expect(p.forUrl(Uri.parse('http://api.deezer.com/')), '127.0.0.1:7890');
      expect(p.forUrl(Uri.parse('http://router.lan/')), isNull);
      expect(p.forUrl(Uri.parse('http://printer/')), isNull, reason: '<local> = names without a dot');
    });

    test('per-scheme proxies; SOCKS only means direct', () {
      final p = ProxySetting.parseWindows('http=10.0.0.2:3128;https=10.0.0.2:3129;socks=10.0.0.2:1080', '')!;
      expect(p.forUrl(Uri.parse('https://a.com/')), '10.0.0.2:3129');
      expect(p.forUrl(Uri.parse('http://a.com/')), '10.0.0.2:3128');
      expect(ProxySetting.parseWindows('socks=127.0.0.1:1080', ''), isNull);
    });

    test('home network and this computer always go direct (listen together, stream proxy)', () {
      final p = ProxySetting.parseWindows('127.0.0.1:7890', '')!;
      for (final u in ['ws://127.0.0.1:47800/', 'ws://192.168.1.20:47800/', 'http://localhost:5000/', 'ws://172.20.0.3/', 'ws://10.1.2.3/']) {
        expect(p.forUrl(Uri.parse(u)), isNull, reason: u);
      }
      expect(p.forUrl(Uri.parse('wss://broker.emqx.io:8084/mqtt')), '127.0.0.1:7890');
    });

    test('environment variables', () {
      final p = ProxySetting.fromEnvironment(const {'HTTPS_PROXY': 'http://user@proxy.local:8080/', 'NO_PROXY': 'example.com,.corp'})!;
      expect(p.forUrl(Uri.parse('https://youtube.com/')), 'proxy.local:8080');
      expect(p.forUrl(Uri.parse('https://example.com/')), isNull);
      expect(p.forUrl(Uri.parse('https://x.corp/')), isNull);
      expect(ProxySetting.fromEnvironment(const {}), isNull);
    });

    test('yt-dlp goes the same way', () {
      expect(YtDlp.args('id', 'out', proxy: '127.0.0.1:7890'), containsAllInOrder(['--proxy', 'http://127.0.0.1:7890']));
      expect(YtDlp.args('id', 'out'), isNot(contains('--proxy')));
    });

    test('reading the real Windows setting does not throw', () {
      expect(() => SystemProxy.instance.findProxy(Uri.parse('https://www.youtube.com/')), returnsNormally);
    }, testOn: 'windows');
  });

  group('offline or just blocked', () {
    NetworkCheck check(int status) => NetworkCheck(client: () => MockClient((_) async => http.Response('', status)));

    test('internet works: says the service can not be reached, not "offline"', () async {
      final e = await check(204).explain(OnlineException(OnlineErrorKind.offline, service: OnlineService.youtube));
      expect(e.internetWorks, isTrue);
      expect(e.message, contains('YouTube'));
      expect(e.message, isNot(contains('offline')));
      expect(importProblemFor(e).message, e.message);
    });

    test('no internet: stays "offline"', () async {
      final down = NetworkCheck(client: () => MockClient((_) async => throw const SocketException('no route')));
      final e = await down.explain(OnlineException(OnlineErrorKind.offline, service: OnlineService.youtube));
      expect(e.internetWorks, isFalse);
      expect(e.kind, OnlineErrorKind.offline);
    });

    test('other errors are left alone and nothing is asked', () async {
      var asked = 0;
      final c = NetworkCheck(
        client: () => MockClient((_) async {
          asked++;
          return http.Response('', 204);
        }),
      );
      final e = OnlineException(OnlineErrorKind.rateLimited, service: OnlineService.youtube);
      expect(identical(await c.explain(e), e), isTrue);
      expect(asked, 0);
    });

    test('one blocked "am I online" address does not mean offline', () async {
      final c = NetworkCheck(
        client: () => MockClient((r) async {
          if (r.url.host.contains('msftconnecttest')) throw const SocketException('blocked');
          return http.Response('', 204);
        }),
      );
      expect(await c.internetWorks(), isTrue);
    });

    test('a service is reachable when all its addresses answer, whatever the answer', () async {
      final asked = <String>[];
      NetworkCheck net({String? dead}) => NetworkCheck(
            client: () => MockClient((r) async {
              asked.add(r.url.host);
              if (r.url.host == dead) throw const SocketException('blocked');
              return http.Response('', 404);
            }),
          );
      expect(await net().reachable(OnlineService.youtube), isTrue);
      expect(asked, ['www.youtube.com'], reason: 'searching needs only youtube.com');
      expect(await net(dead: 'redirector.googlevideo.com').reachable(OnlineService.youtube), isTrue);
      expect(await net(dead: 'redirector.googlevideo.com').reachable(OnlineService.youtube, saving: true), isFalse, reason: 'saving needs the audio servers too');
      expect(await net(dead: 'api.music.yandex.net').reachable(OnlineService.yandex), isFalse);
      expect(await net().reachable(OnlineService.file), isTrue);
    });

    test('a changed connection (VPN on) is noticed once', () async {
      var sig = 'wifi';
      var fired = 0;
      final w = NetworkWatch(signature: () async => sig, every: const Duration(milliseconds: 10));
      w.start(() => fired++);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(fired, 0, reason: 'nothing changed');
      sig = 'wifi;vpn';
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(fired, 1);
      expect(w.watching, isFalse);
      sig = 'wifi';
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(fired, 1, reason: 'stopped after the first change');
    });

    test('reading the real adapters does not throw', () async {
      expect(await NetworkWatch.currentSignature(), isNotEmpty);
    });

    test('yt-dlp gives up on a dead connection in seconds', () {
      expect(YtDlp.args('id', 'out'), containsAllInOrder(['--socket-timeout', '15', '--retries', '3']));
    });
  });
}

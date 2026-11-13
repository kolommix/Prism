@Tags(['network'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/desktop/data/cover_lookup.dart';
import 'package:prism/features/library/domain/track.dart';

/// Real Apple + Deezer search: songs named the way files and videos name them.
void main() {
  final cases = <String, (Track, String)>{
    'video title + VEVO channel': (
      const Track(
        id: 1,
        sourceId: 'youtube',
        uri: 'x',
        title: 'Arctic Monkeys - Do I Wanna Know? (Official Video)',
        artist: 'ArcticMonkeysVEVO',
        durationMs: 272000,
      ),
      'Arctic Monkeys',
    ),
    'Russian song from a video': (
      const Track(id: 2, sourceId: 'youtube', uri: 'x', title: 'Дора - Трудный возраст (Lyric Video)', artist: 'Дора', durationMs: 0),
      'Дора',
    ),
    'untagged Russian file': (const Track(id: 3, uri: 'x', title: '02. Сплин - Выхода нет', durationMs: 0), 'Сплин'),
    'tagged Russian song': (const Track(id: 4, uri: 'x', title: 'Группа крови', artist: 'Кино', durationMs: 0), 'Кино'),
  };
  for (final e in cases.entries) {
    test(e.key, () async {
      final lookup = CoverLookup();
      final info = await lookup.find(e.value.$1);
      expect(info?.coverUrl, isNotNull, reason: 'failed=${lookup.lastFailed}');
      // ignore: avoid_print
      print('${e.key}: ${info!.artist} - ${info.title} (${info.album})');
      expect(info.artist!.toLowerCase(), anyOf(contains(e.value.$2.toLowerCase()), contains('kino')));
      lookup.close();
    }, timeout: const Timeout(Duration(seconds: 60)));
  }
}

@Tags(['network'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/lyrics/data/lyrics_repository.dart';

/// Real lrclib.net: songs named the way files and videos name them.
void main() {
  final client = LrclibClient();
  final cases = <String, Track>{
    'YouTube video title + VEVO channel': const Track(
      id: 1,
      sourceId: 'youtube',
      uri: 'x',
      title: 'Arctic Monkeys - Do I Wanna Know? (Official Video)',
      artist: 'ArcticMonkeysVEVO',
      durationMs: 272000,
    ),
    'Russian song, YouTube topic channel': const Track(
      id: 2,
      sourceId: 'youtube',
      uri: 'x',
      title: 'Кукла колдуна',
      artist: 'Король и Шут - Topic',
      durationMs: 204000,
    ),
    'file without tags': const Track(id: 3, uri: 'x', title: '05. Queen - Bohemian Rhapsody (Remastered 2011)', durationMs: 355000),
    'tagged, remaster suffix': const Track(id: 4, uri: 'x', title: 'Smells Like Teen Spirit - Remastered 2021', artist: 'Nirvana', durationMs: 301000),
  };
  for (final e in cases.entries) {
    test(e.key, () async {
      final r = await client.lookup(e.value);
      expect(r, isA<LrclibFound>(), reason: '$r');
    }, timeout: const Timeout(Duration(seconds: 60)));
  }
}

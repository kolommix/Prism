@Tags(['network'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/metadata/data/metadata_clients.dart';

/// The song info fixer against the real services.
/// Run: flutter test --tags network test/platform/metadata_live_test.dart
void main() {
  test('finds a known song with album, year and a real cover', () async {
    final search = MetadataSearch();
    addTearDown(search.close);
    const song = Track(id: 1, uri: 'x.mp3', title: 'Hey Jude', artist: 'The Beatles', durationMs: 431000);
    final found = await search.search(song);
    final sources = found.map((c) => c.source).toSet();
    // ignore: avoid_print
    print('sources $sources, best: ${found.first.title} / ${found.first.artist} / ${found.first.album} / ${found.first.year} (${found.first.score})');
    expect(sources, containsAll(['MusicBrainz', 'iTunes']));
    expect(found.first.score, greaterThan(0.85));
    expect(found.first.title.toLowerCase(), contains('hey jude'));
    final withCover = found.firstWhere((c) => c.coverUrls.isNotEmpty);
    final cover = await search.fetchCover(withCover.coverUrls);
    expect(cover, isNotNull);
    expect(cover!.length, greaterThan(1000));
  }, timeout: const Timeout(Duration(minutes: 1)));
}

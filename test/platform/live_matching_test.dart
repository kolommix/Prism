// 'audio' too: excluded from the quick unit run (flutter test --exclude-tags audio).
@Tags(['audio', 'network'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/online/application/match_service.dart';
import 'package:prism/features/online/data/online_http.dart';
import 'package:prism/features/online/domain/link_parser.dart';
import 'package:prism/features/online/domain/matching.dart';
import 'package:prism/features/online/services/link_only/link_modules.dart';
import 'package:prism/features/online/services/youtube/explode_backend.dart';
import 'package:prism/features/online/services/youtube/youtube_module.dart';

/// Real services: a public Deezer playlist is imported and its first songs
/// are matched on YouTube (extractor) with an empty local library. Prints
/// every match so the scoring can be eyeballed.
///
/// Run: flutter test --tags network test/platform/live_matching_test.dart
void main() {
  test('Deezer playlist → YouTube matches', () async {
    final list = await DeezerModule(OnlineHttp()).openLink(parseMusicLink('https://www.deezer.com/playlist/908622995')!);
    final yt = YoutubeModule(catalog: ExplodeBackend());
    final matcher = MatchService(localSearch: (_) async => const [], localByUri: (_) async => null, playable: () => [yt]);
    // The catalog alone is enough to search; pretend it can stream.
    final songs = list.tracks.take(12).toList();
    var good = 0;
    for (final s in songs) {
      final found = await yt.search(MatchScorer.queryFor(s), limit: 8);
      final best = MatchScorer.best(s, found);
      final level = best?.score.confidence ?? MatchConfidence.none;
      if (level == MatchConfidence.high || level == MatchConfidence.medium) good++;
      // ignore: avoid_print
      print('${level.name.padRight(6)} ${(best?.score.value ?? 0).toStringAsFixed(2)}  $s  →  '
          '${best?.track.title} [${best?.track.artist}] ${best == null ? '' : '${best.track.durationMs ~/ 1000}s vs ${s.durationMs ~/ 1000}s'}');
    }
    expect(matcher, isNotNull);
    expect(good / songs.length, greaterThanOrEqualTo(0.75));
  }, timeout: const Timeout(Duration(minutes: 3)));
}

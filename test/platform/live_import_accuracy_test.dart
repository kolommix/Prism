// 'audio' too: excluded from the quick unit run (flutter test --exclude-tags audio).
@Tags(['audio', 'network'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/online/application/match_service.dart';
import 'package:prism/features/online/domain/external_track.dart';
import 'package:prism/features/online/domain/matching.dart';
import 'package:prism/features/online/services/youtube/explode_backend.dart';
import 'package:prism/features/online/services/youtube/youtube_module.dart';

/// Songs a real import got wrong or missed (a friend's photo, as the text
/// reader saw it, and a Yandex list), matched live on YouTube Music +
/// YouTube with an empty library. Prints every pick.
///
/// Run: flutter test --tags network test/platform/live_import_accuracy_test.dart
void main() {
  ExternalTrack w(String artist, String title, int sec, {bool photo = false, String? alt}) => ExternalTrack(
        service: photo ? OnlineService.file : OnlineService.yandex,
        title: title,
        artists: [artist],
        durationMs: sec * 1000,
        guessed: photo,
        altArtists: [?alt],
      );

  final songs = [
    // The photo (artist as the Russian reader saw it, the English reading as the other).
    w('СИРЫЕ', 'переломай мои кости', 168, photo: true, alt: 'CUPSIZE'),
    w('СИРЫЕ', 'тварьтварьтварьтварь', 186, photo: true, alt: 'CUPSIZE'),
    w('onda andar', 'online pirate statbn XD', 122, photo: true),
    w('Aaron Cherof', 'Echo in the Wind', 296, photo: true),
    w('VALORANT', 'one (greater than one)', 131, photo: true),
    // Left unmatched by the Yandex import.
    w('TV Girl', "Taking What's Not Yours", 206),
    w('Tame Impala', 'Alter Ego', 288),
    w('onda andar', 'KIDSCRY2DAY', 135),
    w('onda andar', 'type london', 104),
    w('kyNZai', 'они смотрят', 126),
    w('тенденция', 'универ', 147),
    w('Lady Gaga', 'Perfect Celebrity', 229),
    w('ШИПЫ', 'SPIKES IN MY HEAD', 141),
    w('Avith Ortega', 'Morbid Curiosity', 227),
    w('Geek Music', 'Celeste: Resurrections', 264),
    w('Whybaby_ff', 'Konton Boogie', 155),
  ];

  test('songs a real import got wrong', () async {
    final yt = YoutubeModule(catalog: ExplodeBackend());
    final matcher = MatchService(localSearch: (_) async => const [], localByUri: (_) async => null, playable: () => [yt]);
    var good = 0;
    for (final s in songs) {
      final r = await matcher.match(s);
      final level = r.matched ? r.score.confidence : MatchConfidence.none;
      if (level == MatchConfidence.high || level == MatchConfidence.medium) good++;
      final t = r.track;
      // ignore: avoid_print
      print('${level.name.padRight(6)} ${r.score.value.toStringAsFixed(2)}  $s  →  '
          '${t == null ? '-' : '${t.title} [${t.artist}${t.album.isEmpty ? '' : ' / ${t.album}'}] ${t.durationMs ~/ 1000}s vs ${s.durationMs ~/ 1000}s'}'
          '${r.wanted == null ? '' : '  (names → ${r.wanted})'}${r.note == null ? '' : '  note: ${r.note}'}');
    }
    expect(good / songs.length, greaterThanOrEqualTo(0.75));
  }, timeout: const Timeout(Duration(minutes: 4)));
}

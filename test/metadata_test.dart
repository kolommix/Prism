import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/metadata/application/metadata_controller.dart';
import 'package:prism/features/metadata/data/metadata_clients.dart';
import 'package:prism/features/metadata/domain/metadata_candidate.dart';
import 'package:prism/features/tools/data/tag_writer.dart';

const _track = Track(id: 1, uri: 'a.mp3', title: 'Black Knife', artist: 'Toby Fox', album: '', durationMs: 180000);

String mbAnswer() => jsonEncode({
      'recordings': [
        {
          'title': 'Black Knife',
          'length': 181000,
          'artist-credit': [
            {'name': 'Toby Fox', 'joinphrase': ' & '},
            {'name': 'Someone'},
          ],
          'tags': [
            {'name': 'rock', 'count': 1},
            {'name': 'soundtrack', 'count': 5},
          ],
          'releases': [
            {
              'id': 'r-comp',
              'title': 'Best Of',
              'date': '2019-01-01',
              'status': 'Official',
              'release-group': {'id': 'g-comp', 'primary-type': 'Compilation'},
            },
            {
              'id': 'r-album',
              'title': 'Deltarune',
              'date': '2021-09-17',
              'status': 'Official',
              'release-group': {'id': 'g-album', 'primary-type': 'Album'},
              'media': [
                {
                  'track': [
                    {'number': '7'},
                  ],
                },
              ],
            },
          ],
        },
        {'title': 'No releases', 'artist-credit': [{'name': 'X'}]},
      ],
    });

void main() {
  test('MusicBrainz answer: albums first, credits joined, top tag, cover urls', () {
    final list = parseMusicBrainz(mbAnswer());
    expect(list.first.album, 'Deltarune');
    expect(list.first.artist, 'Toby Fox & Someone');
    expect(list.first.year, 2021);
    expect(list.first.trackNumber, 7);
    expect(list.first.genre, 'soundtrack');
    expect(list.first.coverUrls, [
      'https://coverartarchive.org/release/r-album/front-500',
      'https://coverartarchive.org/release-group/g-album/front-500',
    ]);
    expect(list.map((c) => c.album), containsAll(['Deltarune', 'Best Of', '']));
  });

  test('broken answers give nothing instead of crashing', () {
    expect(parseMusicBrainz('{}'), isEmpty);
    expect(parseMusicBrainz('{"recordings": "no"}'), isEmpty);
    expect(parseAcoustId('{"results": 3}'), isEmpty);
  });

  test('AcoustID answer keeps its fingerprint score', () {
    final list = parseAcoustId(jsonEncode({
      'results': [
        {
          'score': 0.97,
          'recordings': [
            {
              'title': 'Song',
              'duration': 200,
              'artists': [{'name': 'A'}],
              'releasegroups': [
                {'id': 'g', 'title': 'Single', 'type': 'Single'},
                {'id': 'h', 'title': 'Album', 'type': 'Album'},
              ],
            },
          ],
        },
      ],
    }));
    expect(list.single.album, 'Album');
    expect(list.single.score, 0.97);
    expect(list.single.durationMs, 200000);
    expect(rankCandidates(_track, list).single.score, 0.97);
  });

  test('search query escapes Lucene characters', () {
    final q = musicBrainzQuery('Song', 'Guns & Roses:');
    expect(q, contains(r'artist:"Guns \& Roses\:"'));
    expect(musicBrainzQuery('Song', ''), 'recording:"song"');
  });

  test('the right song outranks a different one', () {
    final ranked = rankCandidates(_track, const [
      MetaCandidate(source: 'x', title: 'Something Else', artist: 'Nobody', durationMs: 90000),
      MetaCandidate(source: 'x', title: 'Black Knife', artist: 'Toby Fox', durationMs: 181000),
    ]);
    expect(ranked.first.title, 'Black Knife');
    expect(ranked.first.score, greaterThan(0.85));
    expect(ranked.last.score, lessThan(0.5));
  });

  test('with equal scores, more info then the earliest wins', () {
    final ranked = rankCandidates(_track, const [
      MetaCandidate(source: 'x', title: 'Black Knife', artist: 'Toby Fox', durationMs: 181000),
      MetaCandidate(source: 'x', title: 'Black Knife', artist: 'Toby Fox', album: 'Best Of', year: 2024, durationMs: 181000),
      MetaCandidate(source: 'x', title: 'Black Knife', artist: 'Toby Fox', album: 'Deltarune', year: 2021, durationMs: 181000),
    ]);
    expect(ranked.first.album, 'Deltarune');
    expect(ranked.last.album, '');
  });

  test('an album most songs agree on wins', () {
    MetaCandidate c(String album, double s) => MetaCandidate(source: 'x', title: 't', album: album, score: s);
    final out = preferCommonAlbum([
      [c('Best Of', 0.9), c('Album', 0.86)],
      [c('Album', 0.9)],
      [c('Album', 0.88), c('Other', 0.87)],
    ]);
    expect(out[0].first.album, 'Album');
  });

  test('the diff shows only real changes', () {
    final d = diffOf(_track, const MetaCandidate(source: 'x', title: 'Black Knife', artist: 'Toby Fox', album: 'Deltarune', year: 2021));
    expect(d.where((x) => x.changes).map((x) => x.field), [MetaField.album, MetaField.year]);
  });

  test('choosing a candidate ticks what changes; the edit writes only that', () {
    final item = chooseCandidate(
      const FixItem(track: _track),
      const MetaCandidate(source: 'x', title: 'Black Knife', artist: 'Toby Fox', album: 'Deltarune', year: 2021, coverUrls: ['u']),
    );
    expect(item.apply, {MetaField.album, MetaField.year});
    expect(item.useCover, isTrue);
    final TagEdit e = item.edit(null);
    expect(e.album, 'Deltarune');
    expect(e.year, 2021);
    expect(e.title, isNull, reason: 'same as the file, left alone');
    expect(e.artist, isNull);
  });

  test('an unticked field is not written', () {
    final item = chooseCandidate(const FixItem(track: _track), const MetaCandidate(source: 'x', title: 'New', album: 'A'));
    final off = item.copyWith(apply: {MetaField.album});
    expect(off.edit(null).title, isNull);
    expect(off.edit(null).album, 'A');
  });

  group('search', () {
    MockClient client({int mbStatus = 200, int appleStatus = 200}) => MockClient((req) async {
          if (req.url.host == 'musicbrainz.org') {
            expect(req.headers['User-Agent'], startsWith('Prism/'), reason: 'MusicBrainz blocks anonymous clients');
            expect(req.headers['User-Agent'], isNot(contains('@')));
            return http.Response.bytes(utf8.encode(mbAnswer()), mbStatus);
          }
          return http.Response.bytes(
            utf8.encode(jsonEncode({
              'results': [
                {'trackName': 'Black Knife', 'artistName': 'Toby Fox', 'artworkUrl100': 'http://x/100x100bb.jpg', 'collectionName': 'OST'},
              ],
            })),
            appleStatus,
          );
        });

    MetadataSearch search(MockClient c) => MetadataSearch(client: c, musicBrainzLimit: RateLimiter(Duration.zero));

    test('merges services, best first', () async {
      final r = await search(client()).search(_track);
      expect(r.map((c) => c.source).toSet(), {'MusicBrainz', 'iTunes'});
      expect(r.first.score, greaterThan(0.8));
    });

    test('one dead service only costs its own results', () async {
      final r = await search(client(mbStatus: 500)).search(_track);
      expect(r.map((c) => c.source).toSet(), {'iTunes'});
    });

    test('all dead is an error the screen can show', () async {
      expect(() => search(client(mbStatus: 500, appleStatus: 500)).search(_track), throwsA(isA<MetadataLookupException>()));
    });

    test('503 from MusicBrainz backs off and tries again', () async {
      var calls = 0;
      final c = MockClient((req) async {
        if (req.url.host != 'musicbrainz.org') return http.Response('{"results":[]}', 200);
        calls++;
        return calls == 1 ? http.Response('slow down', 503) : http.Response.bytes(utf8.encode(mbAnswer()), 200);
      });
      final r = await search(c).search(_track);
      expect(calls, 2);
      expect(r, isNotEmpty);
    });

    test('a bad cover url falls through to the next', () async {
      final c = MockClient((req) async {
        if (req.url.path.contains('dead')) return http.Response('nope', 404);
        return http.Response.bytes([0xFF, 0xD8, 0xFF, 0xE0, 1, 2], 200);
      });
      final b = await search(c).fetchCover(['http://x/dead', 'http://x/good']);
      expect(b, isNotNull);
    });

    test('something that is not a picture is refused', () async {
      final c = MockClient((_) async => http.Response('<html>', 200));
      expect(await search(c).fetchCover(['http://x/a']), isNull);
    });
  });

  test('rate limiter keeps jobs apart and in order', () async {
    final limiter = RateLimiter(const Duration(milliseconds: 40));
    final times = <DateTime>[];
    await Future.wait([
      for (var i = 0; i < 3; i++)
        limiter.run(() async {
          times.add(DateTime.now());
        }),
    ]);
    expect(times[1].difference(times[0]).inMilliseconds, greaterThanOrEqualTo(35));
    expect(times[2].difference(times[1]).inMilliseconds, greaterThanOrEqualTo(35));
  });
}


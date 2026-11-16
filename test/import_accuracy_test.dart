import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/online/application/match_service.dart';
import 'package:prism/features/online/domain/external_track.dart';
import 'package:prism/features/online/domain/matching.dart';
import 'package:prism/features/online/services/music_service_module.dart';
import 'package:prism/features/online/services/youtube/youtube_module.dart';
import 'package:prism/features/online/services/youtube/ytmusic_songs.dart';

ExternalTrack want(String title, List<String> artists, {int sec = 0, bool guessed = false, List<String> alt = const []}) =>
    ExternalTrack(
      service: guessed ? OnlineService.file : OnlineService.yandex,
      title: title,
      artists: artists,
      durationMs: sec * 1000,
      guessed: guessed,
      altArtists: alt,
    );

Track video(String title, String channel, {required int ms, String id = 'aaaaaaaaaaa', String album = ''}) => Track(
      id: 0,
      sourceId: youtubeSourceId,
      uri: 'https://www.youtube.com/watch?v=$id',
      title: title,
      artist: channel,
      album: album,
      durationMs: ms,
    );

/// Answers catalogue songs and videos from fixed lists, records queries.
class _Service extends MusicServiceModule {
  _Service({this.songs = const [], this.videos = const []});
  final List<Track> songs, videos;
  final songQueries = <String>[], videoQueries = <String>[];

  @override
  OnlineService get service => OnlineService.youtube;
  @override
  Set<ModuleFeature> get features => const {ModuleFeature.search, ModuleFeature.stream};
  @override
  String? get playableSourceId => youtubeSourceId;
  @override
  Future<List<Track>> searchSongs(String query, {int limit = 10}) async {
    songQueries.add(query);
    return songs;
  }

  @override
  Future<List<Track>> search(String query, {int limit = 20}) async {
    videoQueries.add(query);
    return videos;
  }
}

MatchService _matcher(_Service s, {List<Track> library = const []}) =>
    MatchService(localSearch: (_) async => library, localByUri: (_) async => null, playable: () => [s]);

void main() {
  test('YouTube Music answer: song name, artists, album, exact length', () {
    final json = jsonDecode(File('test/fixtures/ytmusic_songs.json').readAsStringSync()) as Map<String, dynamic>;
    final songs = YtMusicSongs.parse(json);
    expect(songs, isNotEmpty);
    final first = songs.first;
    expect(first.id, 'BU-eVgBpxyc');
    expect(first.title, 'переломай мои кости');
    expect(first.channel, 'CUPSIZE');
    expect(first.album, 'в моих легких выросли цветы');
    expect(first.durationMs, (2 * 60 + 48) * 1000);
    expect(first.song, isTrue);
    expect(first.thumbnailUrl, contains('w544-h544'));
    final track = YoutubeModule.trackFromVideo(first);
    expect(track.album, isNotEmpty);
    expect(youtubeIdOf(track), 'BU-eVgBpxyc');
  });

  group('wrong picks from a real import are refused', () {
    test('a 1:30 piece for a 3:25 song', () {
      final s = MatchScorer.score(
        want('Watson from Cyberpunk: Edgerunners Season 2', ['Petite Meller', 'Oslo Green'], sec: 205),
        video('Petite Meller, Oslo Green - Watson from Cyberpunk Edgerunners Season 2', 'Petite Meller', ms: 89600),
      );
      expect(s.value, lessThan(MatchScorer.acceptThreshold));
    });

    test('another song of the same artist that shares a few words', () {
      final s = MatchScorer.score(
        want('In Love With Myself from Cyberpunk: Edgerunners 2', ['Petite Meller', 'Kalman Chodakiewitz'], sec: 173),
        Track(id: 5, uri: '/m/w.m4a', title: 'Watson from Cyberpunk: Edgerunners Season 2', artist: 'Petite Meller, Oslo Green', durationMs: 89600),
      );
      expect(s.value, lessThan(MatchScorer.acceptThreshold));
    });

    test('a bracket part on one side only still matches', () {
      final s = MatchScorer.score(
        want("Can't Tell Me Nothing (из фильма «Мальчишник в Вегасе»)", ['Kanye West'], sec: 272),
        video("Kanye West - Can't Tell Me Nothing", 'Kanye West', ms: 271000),
      );
      expect(s.confidence, MatchConfidence.high);
    });
  });

  test('a picture-read artist in the wrong letters matches by its other reading, names corrected', () async {
    final service = _Service(songs: [
      video('переломай мои кости', 'CUPSIZE', ms: 168000, id: 'BU-eVgBpxyc', album: 'в моих легких выросли цветы'),
    ]);
    final r = await _matcher(service).match(want('переломай мои кости', ['СИРЫЕ'], sec: 168, guessed: true, alt: ['CUPSIZE']));
    expect(r.matched, isTrue);
    expect(r.score.confidence, MatchConfidence.high);
    expect(r.wanted?.artist, 'CUPSIZE');
    expect(r.wanted?.altArtists, isEmpty);
    // A sure catalogue song: no video search needed.
    expect(service.videoQueries, isEmpty);
  });

  test('catalogue spelling replaces a picture misreading ("statbn")', () async {
    final service = _Service(songs: [
      video('online pirate station XD', 'ONDA ANDAR', ms: 122000, id: '7cUafhItc5Y', album: 'KIDSCRY2DAY'),
    ]);
    final r = await _matcher(service).match(want('online pirate statbn XD', ['onda andar'], sec: 122, guessed: true));
    expect(r.matched, isTrue);
    expect(r.wanted?.title, 'online pirate station XD');
    expect(r.wanted?.artist, 'ONDA ANDAR');
  });

  test('names from a service are never rewritten', () async {
    final service = _Service(songs: [video('Song', 'Band', ms: 200000, album: 'LP')]);
    final r = await _matcher(service).match(want('Song', ['Band'], sec: 200));
    expect(r.matched, isTrue);
    expect(r.wanted, isNull);
  });

  test('videos are searched when the catalogue has nothing sure', () async {
    final service = _Service(videos: [video('Band - Song (Official Video)', 'BandVEVO', ms: 201000)]);
    final r = await _matcher(service).match(want('Song', ['Band'], sec: 200));
    expect(r.matched, isTrue);
    expect(service.songQueries, ['Band Song']);
    expect(service.videoQueries, ['Band Song']);
  });

  test('the other reading is searched too when the first finds nothing', () async {
    final service = _Service();
    await _matcher(service).match(want('Song', ['СИРЫЕ'], guessed: true, alt: ['CUPSIZE']));
    expect(service.songQueries, ['СИРЫЕ Song', 'CUPSIZE Song']);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/online/domain/external_track.dart';
import 'package:prism/features/online/domain/import_parsers.dart';
import 'package:prism/features/online/domain/link_parser.dart';
import 'package:prism/features/online/domain/matching.dart';

ExternalTrack want(String title, String artist, {int sec = 0}) => ExternalTrack(
      service: OnlineService.spotify,
      title: title,
      artists: splitArtists(artist),
      durationMs: sec * 1000,
    );

Track local(String title, String artist, {int sec = 200, int id = 1}) =>
    Track(id: id, uri: '/music/$id.mp3', title: title, artist: artist, durationMs: sec * 1000);

Track yt(String title, String channel, {int sec = 200, int id = 100}) => Track(
      id: id,
      sourceId: 'youtube',
      uri: 'https://www.youtube.com/watch?v=$id',
      title: title,
      artist: channel,
      durationMs: sec * 1000,
    );

void main() {
  group('cleanTitle', () {
    test('drops noise in brackets and dash tails', () {
      expect(cleanTitle('Bohemian Rhapsody (Remastered 2011)'), 'bohemian rhapsody');
      expect(cleanTitle('Bohemian Rhapsody - Remastered 2011'), 'bohemian rhapsody');
      expect(cleanTitle('Blinding Lights [Official Video]'), 'blinding lights');
      expect(cleanTitle('Stay (feat. Justin Bieber)'), 'stay');
      expect(cleanTitle('Stay feat. Justin Bieber'), 'stay');
      expect(cleanTitle('Song - 2009 Remaster - Mono'), 'song');
    });

    test('keeps words that change the recording', () {
      expect(cleanTitle('Song (Live at Wembley)'), 'song live at wembley');
      expect(cleanTitle('Song - Acoustic'), 'song acoustic');
    });
  });

  group('MatchScorer', () {
    test('same song in the local library is high', () {
      final s = MatchScorer.score(want('Blinding Lights', 'The Weeknd', sec: 200), local('Blinding Lights', 'The Weeknd', sec: 201));
      expect(s.confidence, MatchConfidence.high);
    });

    test('accents, case and remaster tags do not matter', () {
      final s = MatchScorer.score(
        want('Déjà Vu - 2015 Remaster', 'Beyoncé', sec: 240),
        local('deja vu', 'beyonce', sec: 241),
      );
      expect(s.confidence, MatchConfidence.high);
    });

    test('YouTube "Artist - Title (Official Video)" with a VEVO channel', () {
      final s = MatchScorer.score(
        want('Shake It Off', 'Taylor Swift', sec: 219),
        yt('Taylor Swift - Shake It Off (Official Video)', 'TaylorSwiftVEVO', sec: 242),
      );
      expect(s.value, greaterThanOrEqualTo(0.7), reason: '$s');
    });

    test('Topic channel with exact length beats the music video', () {
      final w = want('Shake It Off', 'Taylor Swift', sec: 219);
      final best = MatchScorer.best(w, [
        yt('Taylor Swift - Shake It Off (Official Video)', 'TaylorSwiftVEVO', sec: 242, id: 1),
        yt('Shake It Off', 'Taylor Swift - Topic', sec: 219, id: 2),
      ]);
      expect(best!.track.id, 2);
      expect(best.score.confidence, MatchConfidence.high);
    });

    test('karaoke, nightcore and sped-up versions are pushed out', () {
      final w = want('Shake It Off', 'Taylor Swift', sec: 219);
      for (final title in [
        'Shake It Off (Karaoke Version)',
        'Nightcore - Shake It Off',
        'Taylor Swift - Shake It Off (sped up)',
      ]) {
        final s = MatchScorer.score(w, yt(title, 'Some Channel', sec: 219));
        expect(s.confidence, MatchConfidence.none, reason: '$title → $s');
        expect(s.note, isNotNull);
      }
    });

    test('live version only matches when a live version is wanted', () {
      final studio = want('Song', 'Band', sec: 200);
      final live = want('Song (Live)', 'Band', sec: 260);
      final liveCand = local('Song - Live', 'Band', sec: 260);
      expect(MatchScorer.score(studio, liveCand).value, lessThan(MatchScorer.score(live, liveCand).value));
      expect(MatchScorer.score(live, liveCand).confidence, MatchConfidence.high);
    });

    test('same title by another artist (a cover) stays below medium', () {
      final s = MatchScorer.score(want('Hallelujah', 'Leonard Cohen', sec: 280), local('Hallelujah', 'Pentatonix', sec: 280));
      expect(s.value, lessThan(0.7));
    });

    test('right artist cannot rescue a different song', () {
      final s = MatchScorer.score(want('Yesterday', 'The Beatles', sec: 125), local('Let It Be', 'The Beatles', sec: 125));
      expect(s.confidence, MatchConfidence.none);
    });

    test('very different length lowers the score', () {
      final w = want('Song', 'Band', sec: 200);
      final near = MatchScorer.score(w, local('Song', 'Band', sec: 202));
      final far = MatchScorer.score(w, local('Song', 'Band', sec: 600));
      expect(near.value, greaterThan(far.value));
      expect(far.duration, 0);
    });

    test('unknown length is neutral, not a failure', () {
      final s = MatchScorer.score(want('Song Title', 'Band'), local('Song Title', 'Band', sec: 200));
      expect(s.confidence, isNot(MatchConfidence.none));
    });

    test('featured artists on either side still match', () {
      final s = MatchScorer.score(
        want('Stay', 'The Kid LAROI, Justin Bieber', sec: 141),
        local('Stay (with Justin Bieber)', 'The Kid LAROI', sec: 141),
      );
      expect(s.confidence, MatchConfidence.high, reason: '$s');
    });

    test('small typos are tolerated', () {
      final s = MatchScorer.score(want('Smells Like Teen Spirit', 'Nirvana', sec: 301), local('Smells Like Teen Spirt', 'Nirvana', sec: 301));
      expect(s.confidence, MatchConfidence.high);
    });

    test('non-latin titles match', () {
      final s = MatchScorer.score(want('Группа крови', 'Кино', sec: 286), local('Группа крови', 'Кино', sec: 287));
      expect(s.confidence, MatchConfidence.high);
    });

    test('best() keeps the earlier candidate on ties (callers put local first)', () {
      final w = want('Song', 'Band', sec: 200);
      final best = MatchScorer.best(w, [local('Song', 'Band', id: 1), local('Song', 'Band', id: 2)]);
      expect(best!.track.id, 1);
      expect(MatchScorer.best(w, const []), isNull);
    });

    test('queryFor drops noise', () {
      expect(MatchScorer.queryFor(want('Song (Official Video) - Remastered', 'Band, Other')), 'Band song');
    });
  });

  group('duplicates in an import', () {
    test('same song twice (even remastered) is flagged, other versions are not', () {
      final list = [
        want('Song', 'Band', sec: 200),
        want('Other', 'Band', sec: 180),
        want('Song - Remastered 2011', 'Band', sec: 201),
        want('Song', 'Band', sec: 400), // extended, different length
        want('Song', 'Someone Else', sec: 200),
      ];
      expect(findImportDuplicates(list), {2: 0});
    });
  });

  group('link parser', () {
    ParsedLink? l(String s) => parseMusicLink(s);

    test('Spotify', () {
      expect(l('https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M?si=abc'),
          ParsedLink(OnlineService.spotify, LinkKind.playlist, '37i9dQZF1DXcBWIGoYBM5M', Uri()));
      expect(l('https://open.spotify.com/intl-de/album/4aawyAB9vmqN3uQ7FjRGTy')!.kind, LinkKind.album);
      expect(l('spotify:track:4uLU6hMCjMI75M1A2tKUQC')!.kind, LinkKind.track);
      expect(l('https://open.spotify.com/collection/tracks')!.kind, LinkKind.likes);
    });

    test('YouTube and YouTube Music', () {
      expect(l('https://www.youtube.com/playlist?list=PLx0sYbCqOb8TBPRdmBHs5Iftvv9TPboYG')!.id, 'PLx0sYbCqOb8TBPRdmBHs5Iftvv9TPboYG');
      expect(l('https://music.youtube.com/playlist?list=OLAK5uy_abc')!.kind, LinkKind.playlist);
      expect(l('https://music.youtube.com/browse/VLPL123')!.id, 'PL123');
      expect(l('https://youtu.be/dQw4w9WgXcQ')!.kind, LinkKind.track);
      expect(l('youtube.com/watch?v=dQw4w9WgXcQ')!.id, 'dQw4w9WgXcQ');
      // A video inside a playlist imports the playlist; mixes are skipped.
      expect(l('https://www.youtube.com/watch?v=abc&list=PL9')!.kind, LinkKind.playlist);
      expect(l('https://www.youtube.com/watch?v=abc&list=RDabc')!.kind, LinkKind.track);
    });

    test('SoundCloud, Apple Music, Deezer', () {
      expect(l('https://soundcloud.com/artist/sets/my-set')!.id, 'artist/sets/my-set');
      expect(l('https://soundcloud.com/someone/likes')!.kind, LinkKind.likes);
      expect(l('https://on.soundcloud.com/abc')!.kind, LinkKind.shortLink);
      expect(l('https://music.apple.com/us/playlist/todays-hits/pl.f4d106fed2bd41149aaacabb233eb5eb')!.id,
          'pl.f4d106fed2bd41149aaacabb233eb5eb');
      expect(l('https://music.apple.com/us/album/x/1440857781?i=1440857795')!.kind, LinkKind.track);
      expect(l('https://www.deezer.com/en/playlist/908622995')!.id, '908622995');
      expect(l('https://deezer.page.link/abc')!.kind, LinkKind.shortLink);
    });

    test('anything else is null', () {
      expect(l('hello'), isNull);
      expect(l('https://example.com/playlist/1'), isNull);
    });
  });

  group('file import', () {
    test('Exportify CSV keeps "Tyler, The Creator" together', () {
      const csv = '"Track URI","Track Name","Artist Name(s)","Album Name","Track Duration (ms)","ISRC"\n'
          '"spotify:track:abc123","EARFQUAKE","Tyler, The Creator","IGOR","190066","USQX91900587"\n'
          '"spotify:track:def456","Stay","The Kid LAROI,Justin Bieber","F*CK LOVE 3","141805",""\n';
      final lists = parseImportFile('My List.csv', csv);
      expect(lists.single.name, 'My List');
      final a = lists.single.tracks;
      expect(a[0].artists, ['Tyler, The Creator']);
      expect(a[0].durationMs, 190066);
      expect(a[0].externalId, 'abc123');
      expect(a[0].service, OnlineService.spotify);
      expect(a[1].artists, ['The Kid LAROI', 'Justin Bieber']);
    });

    test('TuneMyMusic CSV with several playlists, semicolons and quotes', () {
      const csv = 'Track name;Artist name;Album;Playlist name;Type;ISRC\r\n'
          'Song "A";Band;Alb;Road trip;Playlist;\r\n'
          'Song B;Band & Friend;Alb;Gym;Playlist;\r\n'
          '"Song; C";Band;;Road trip;Playlist;\r\n';
      final lists = parseImportFile('export.csv', csv);
      expect(lists.map((l) => l.name), ['Road trip', 'Gym']);
      expect(lists.first.tracks.map((t) => t.title), ['Song "A"', 'Song; C']);
      expect(lists.last.tracks.single.artists, ['Band', 'Friend']);
    });

    test('CSV without a title column explains what is missing', () {
      expect(() => parseImportFile('x.csv', 'a,b\n1,2\n'), throwsA(isA<ImportFormatException>()));
    });

    test('M3U with EXTINF, relative paths and URLs', () {
      const m3u = '#EXTM3U\n#PLAYLIST:Chill\n#EXTINF:215,Band - Song One\nsub/one.mp3\n'
          '#EXTINF:-1,Radio\nhttp://radio.example/stream\nC:\\Music\\Other Band - Two.flac\n';
      final list = parseImportFile(r'C:\lists\chill.m3u8', m3u).single;
      expect(list.name, 'Chill');
      expect(list.tracks[0].title, 'Song One');
      expect(list.tracks[0].artists, ['Band']);
      expect(list.tracks[0].durationMs, 215000);
      expect(list.tracks[0].url, r'C:\lists\sub\one.mp3');
      expect(list.tracks[1].url, 'http://radio.example/stream');
      expect(list.tracks[2].title, 'Two');
      expect(list.tracks[2].artists, ['Other Band']);
    });

    test('JSON: plain list, {name, tracks} and Spotify data export', () {
      expect(parseImportFile('a.json', '[{"title":"A","artist":"X","duration":"3:05"}]').single.tracks.single.durationMs, 185000);
      final named = parseImportFile('b.json', '{"name":"Mix","tracks":[{"name":"B","artists":[{"name":"Y"},{"name":"Z"}],"duration_ms":1000}]}');
      expect(named.single.name, 'Mix');
      expect(named.single.tracks.single.artists, ['Y', 'Z']);
      final export = parseImportFile(
        'Playlist1.json',
        '{"playlists":[{"name":"Old","items":[{"track":{"trackName":"C","artistName":"W","albumName":"Q","trackUri":"spotify:track:xyz"}}]}]}',
      );
      expect(export.single.name, 'Old');
      expect(export.single.tracks.single.externalId, 'xyz');
    });

    test('durations in many formats', () {
      expect(parseDurationText('3:25'), 205000);
      expect(parseDurationText('1:02:03'), 3723000);
      expect(parseDurationText('205'), 205000);
      expect(parseDurationText('205000'), 205000);
      expect(parseDurationText(''), 0);
    });
  });
}

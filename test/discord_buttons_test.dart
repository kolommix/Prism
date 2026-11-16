import 'package:flutter_test/flutter_test.dart';
import 'package:prism/features/desktop/application/desktop_extras.dart';
import 'package:prism/features/desktop/data/cover_lookup.dart';
import 'package:prism/features/desktop/data/discord_ipc.dart';
import 'package:prism/features/library/domain/track.dart';

void main() {
  const song = Track(id: 1, uri: r'C:\Music\song.mp3', title: 'Song', artist: 'Band');
  final info = CoverInfo(linkUrl: 'https://music.apple.com/x', linkLabel: 'Apple Music');

  test('"Get Prism" takes the second button, the song link stays first', () {
    final buttons = discordButtons(song, info, 'Song', 'Band', prismButton: true);
    expect(buttons.length, 2);
    expect(buttons.first.$2, startsWith('https://www.youtube.com/results?search_query='));
    expect(buttons.last.$2, 'https://github.com/kolommix/Prism/releases/latest');
    final frame = activityFrame(
      title: 'Song',
      artist: 'Band',
      album: '',
      playing: true,
      position: Duration.zero,
      duration: const Duration(minutes: 3),
      nowMs: 1700000000000,
      pid: 7,
      buttons: buttons,
    );
    final sent = ((frame['args'] as Map)['activity'] as Map)['buttons'] as List;
    expect(sent.length, 2);
    expect((sent.last as Map)['url'], prismDownloadUrl);
  });

  test('switched off: the Apple Music / Deezer link as before', () {
    final buttons = discordButtons(song, info, 'Song', 'Band');
    expect(buttons.last.$2, 'https://music.apple.com/x');
  });
}

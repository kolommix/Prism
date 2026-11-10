import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/core/theme/theme_builder.dart';
import 'package:prism/core/theme/theme_config.dart';
import 'package:prism/features/library/application/library_providers.dart';
import 'package:prism/features/player/application/player_controller.dart';
import 'package:prism/features/player/application/player_providers.dart';
import 'package:prism/features/player/domain/playback_queue.dart';
import 'package:prism/features/player/presentation/queue_list.dart';

import 'helpers.dart';
import 'player_controller_test.dart' show FakeEngine, MemoryStore;

void main() {
  testWidgets('the up-next list follows the playing song', (tester) async {
    final songs = [for (var i = 1; i <= 30; i++) t(i, title: 'Song $i')];
    final queue = StreamController<PlaybackQueue>();
    addTearDown(queue.close);
    PlaybackQueue at(int index) =>
        PlaybackQueue(tracks: songs, originalOrder: songs, index: index, repeatMode: QueueRepeatMode.off, shuffled: false);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        playerControllerProvider.overrideWithValue(PlayerController(engine: FakeEngine(), store: MemoryStore())),
        queueProvider.overrideWith((ref) => queue.stream),
        currentTrackProvider.overrideWithValue(songs.first),
        favoriteIdsProvider.overrideWith((ref) => Stream.value(<int>{})),
      ],
      child: MaterialApp(
        theme: buildPrismTheme(const ThemeConfig(), platformBrightness: Brightness.dark, reduceMotion: false),
        home: const Scaffold(body: SizedBox(height: 300, child: QueueList())),
      ),
    ));
    queue.add(at(0));
    await tester.pumpAndSettle();
    final list = tester.widget<Scrollable>(find.byType(Scrollable).first).controller!;
    expect(list.offset, 0);

    // Next song, and then a jump further: the playing one ends up at the top.
    for (final index in [1, 12]) {
      queue.add(at(index));
      await tester.pumpAndSettle();
      final top = tester.getTopLeft(find.byType(Scrollable).first).dy;
      final row = tester.getTopLeft(find.text('Song ${index + 1}')).dy;
      expect(row - top, lessThan(30), reason: 'song ${index + 1} at the top');
    }
  });
}

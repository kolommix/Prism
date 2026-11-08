import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:prism/core/db/app_database.dart';
import 'package:prism/features/library/data/library_repository.dart';
import 'package:prism/features/library/domain/artist_names.dart';
import 'package:prism/features/library/domain/track.dart';
import 'package:prism/features/player/presentation/widgets/track_text.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('one tag, several artists', () {
    expect(artistNames('Rat Boy, IBDY'), ['Rat Boy', 'IBDY']);
    expect(artistNames('VALORANT Music, Grabbitz & bbno\$'), ['VALORANT Music', 'Grabbitz', 'bbno\$']);
    expect(artistNames('A feat. B'), ['A', 'B']);
    expect(artistNames('A x B'), ['A', 'B']);
    expect(artistNames('Xzibit'), ['Xzibit'], reason: 'an x inside a name is not a separator');
    expect(hasArtist('Takai The Maid, Komak The Maid', 'komak the maid'), isTrue);
    expect(hasArtist('Pirate Boys', 'Rat Boy'), isFalse);
  });

  test('the artist page has every song they are on', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = LibraryRepository(db);
    var n = 0;
    await repo.upsertTracks([
      for (final (artist, albumArtist) in [
        ('Rat Boy', ''),
        ('Rat Boy, IBDY', ''),
        ('IBDY', ''),
        ('Pirate Boys', ''),
        ('Someone', 'Rat Boy'),
      ])
        TracksCompanion.insert(
          uri: '/m/${n++}.mp3',
          folder: '/m',
          title: 'S$n',
          artist: Value(artist),
          albumArtist: Value(albumArtist),
        ),
    ]);
    final ratBoy = await repo.watchArtistTracks('Rat Boy').first;
    expect(ratBoy.map((t) => t.artist), unorderedEquals(['Rat Boy', 'Rat Boy, IBDY', 'Someone']));
    final ibdy = await repo.watchArtistTracks('IBDY').first;
    expect(ibdy.map((t) => t.artist), unorderedEquals(['Rat Boy, IBDY', 'IBDY']));
  });

  testWidgets('tapping a name opens that artist', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const Scaffold(
          body: TrackText(track: Track(id: 1, uri: '/a.mp3', title: 'Who\'s Ready', artist: 'Rat Boy, IBDY')),
        ),
      ),
      GoRoute(path: '/library/artist', builder: (_, s) => Text('artist page: ${s.uri.queryParameters['name']}')),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    final rich = find.byType(RichText).last;
    // The second name sits at the right end of the line.
    final box = tester.getRect(rich);
    await tester.tapAt(Offset(box.right - 4, box.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('artist page: IBDY'), findsOneWidget);
  });
}

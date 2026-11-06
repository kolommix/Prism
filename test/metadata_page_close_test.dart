import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:prism/core/db/app_database.dart';
import 'package:prism/core/providers.dart';
import 'package:prism/features/library/data/library_repository.dart';
import 'package:prism/features/metadata/application/metadata_controller.dart';
import 'package:prism/features/metadata/data/metadata_clients.dart';

void main() {
  test('closing the page while a search runs is safe', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await LibraryRepository(db).upsertTracks([TracksCompanion.insert(uri: '/m/a.mp3', title: 'Song', folder: '/m')]);
    final id = (await db.select(db.tracks).get()).single.id;

    final answer = Completer<http.Response>();
    final started = Completer<void>();
    final container = ProviderContainer(overrides: [
      appDatabaseProvider.overrideWithValue(db),
      metadataSearchProvider.overrideWithValue(MetadataSearch(
        client: MockClient((_) {
          if (!started.isCompleted) started.complete();
          return answer.future;
        }),
        musicBrainzLimit: RateLimiter(Duration.zero),
      )),
    ]);
    addTearDown(container.dispose);

    final errors = <Object>[];
    await runZonedGuarded(() async {
      final sub = container.listen(metadataFixProvider('$id'), (_, _) {});
      await started.future.timeout(const Duration(seconds: 5));
      // The page closes, then the answer arrives.
      sub.close();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      answer.complete(http.Response('{"recordings":[],"results":[]}', 200));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }, (e, _) => errors.add(e));
    expect(errors, isEmpty);
  });
}

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/library_item.dart';
import 'package:voxlivre/src/features/library/domain/library_snapshot.dart';
import 'package:voxlivre/src/features/library/infrastructure/drift_library_repository.dart';
import 'package:voxlivre/src/features/library/infrastructure/library_api.dart';
import 'package:voxlivre/src/features/library/infrastructure/library_database.dart';

import '../../../../helpers/app_harness.dart';
import '../../../../helpers/fake_http.dart';

/// Un livre tel que `GET /v1/library` le renvoie.
Map<String, Object?> wireItem(String id, {String status = 'in_progress'}) => {
  'status': status,
  'progressPercent': 40,
  'document': {
    'id': id,
    'title': 'Droit civil $id',
    'status': 'text_ready',
    'pageCount': 120,
    'charCount': 250000,
    'extractionError': null,
    'createdAt': '2026-10-01T08:00:00.000Z',
  },
  'conversion': {
    'id': 'c-$id',
    'status': 'ready',
    'voiceId': 'fr-f2',
    'failureReason': null,
    'partCount': 4,
    'partsReady': 4,
    'playableDurationMs': 3600000,
    'completedAt': '2026-10-01T09:00:00.000Z',
  },
  'position': {
    'conversionId': 'c-$id',
    'wordIndex': 1200,
    'audioMs': 1440000,
    'recordedAt': '2026-10-12T20:00:00.000Z',
    'updatedAt': '2026-10-12T20:00:01.000Z',
  },
};

void main() {
  // Une base par test : drift prévient sinon d'ouvertures multiples.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late LibraryDatabase db;
  late FixedClock clock;

  setUp(() {
    db = LibraryDatabase(NativeDatabase.memory());
    clock = FixedClock(DateTime.utc(2026, 10, 13, 12));
  });
  tearDown(() => db.close());

  DriftLibraryRepository repositoryOn(FakeHttp http) =>
      DriftLibraryRepository(db, LibraryApi(http.client()), clock);

  test('lit toutes les pages puis remplit le cache', () async {
    final http = FakeHttp(
      (r) => r.queryParameters['cursor'] == null
          ? reply(200, {
              'items': [wireItem('a'), wireItem('b')],
              'nextCursor': 'page-2',
            })
          : reply(200, {
              'items': [wireItem('c', status: 'ready')],
              'nextCursor': null,
            }),
    );
    final repository = repositoryOn(http);

    expect((await repository.refresh()).isOk, isTrue);

    expect(http.requests.map((r) => r.queryParameters), [
      {'limit': 50},
      {'limit': 50, 'cursor': 'page-2'},
    ]);
    final snapshot = await repository.watch().first;
    expect(snapshot.items.map((i) => i.documentId), ['a', 'b', 'c']);
    expect(snapshot.refreshedAt, clock.instant);
    expect(await repository.lastRefresh(), clock.instant);

    final a = snapshot.items.first;
    expect(a.title, 'Droit civil a');
    expect(a.status, LibraryStatus.inProgress);
    expect(a.conversion?.playable, const Duration(hours: 1));
    expect(a.position?.audio, const Duration(minutes: 24));
    expect(a.position?.recordedAt, DateTime.utc(2026, 10, 12, 20));
    expect(snapshot.items.last.status, LibraryStatus.ready);
  });

  test(
    'un rafraîchissement remplace le cache : un livre supprimé part',
    () async {
      var items = [wireItem('a'), wireItem('b')];
      final http = FakeHttp(
        (_) => reply(200, {'items': items, 'nextCursor': null}),
      );
      final repository = repositoryOn(http);
      final seen = <LibrarySnapshot>[];
      final subscription = repository.watch().listen(seen.add);
      addTearDown(subscription.cancel);

      await repository.refresh();
      items = [wireItem('b')];
      await repository.refresh();
      await pumpEventQueue();

      expect(seen.first.loaded, isFalse);
      expect(seen.last.items.map((i) => i.documentId), ['b']);
    },
  );

  test('hors ligne, le cache reste intact', () async {
    var online = true;
    final http = FakeHttp(
      (_) => online
          ? reply(200, {
              'items': [wireItem('a')],
              'nextCursor': null,
            })
          : reply(503, {'status': 503}),
    );
    final repository = repositoryOn(http);
    await repository.refresh();

    online = false;
    final result = await repository.refresh();

    expect(switch (result) {
      Err(:final error) => error.code,
      Ok() => null,
    }, 'SERVER_ERROR');
    expect((await repository.watch().first).items, hasLength(1));
  });

  test('un livre illisible est écarté, pas toute la bibliothèque', () async {
    final http = FakeHttp(
      (_) => reply(200, {
        'items': [
          wireItem('a'),
          {
            'status': 'ready',
            'document': {'id': 'b', 'title': 7},
          },
          {'status': 'ready'},
        ],
        'nextCursor': null,
      }),
    );
    final repository = repositoryOn(http);

    await repository.refresh();

    expect(
      (await repository.watch().first).items.map((i) => i.documentId),
      ['a'],
    );
  });

  test('la fin de session vide le cache et sa date', () async {
    final http = FakeHttp(
      (_) => reply(200, {
        'items': [wireItem('a')],
        'nextCursor': null,
      }),
    );
    final repository = repositoryOn(http);
    await repository.refresh();

    await repository.clear();

    final snapshot = await repository.watch().first;
    expect(snapshot.items, isEmpty);
    expect(snapshot.loaded, isFalse);
  });

  test('une réponse sans fin de pages s’arrête au garde-fou', () async {
    final http = FakeHttp(
      (_) => reply(200, {
        'items': <Object?>[],
        'nextCursor': 'encore',
      }),
    );

    await LibraryApi(http.client()).fetchAll();

    expect(http.requests, hasLength(LibraryApi.maxPages));
  });
}

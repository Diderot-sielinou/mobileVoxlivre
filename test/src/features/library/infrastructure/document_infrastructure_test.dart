import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_sheet.dart';
import 'package:voxlivre/src/features/library/infrastructure/document_api.dart';
import 'package:voxlivre/src/features/library/infrastructure/drift_document_repository.dart';
import 'package:voxlivre/src/features/library/infrastructure/drift_library_repository.dart';
import 'package:voxlivre/src/features/library/infrastructure/library_api.dart';
import 'package:voxlivre/src/features/library/infrastructure/library_database.dart';

import '../../../../helpers/app_harness.dart';
import '../../../../helpers/fake_http.dart';
import 'library_infrastructure_test.dart' show wireItem;

/// Un document tel que `GET /v1/documents/:id` le renvoie.
Map<String, Object?> wireDocument(
  String id, {
  String status = 'text_ready',
  String title = 'Droit civil',
}) => {
  'id': id,
  'title': title,
  'status': status,
  'pageCount': 120,
  'charCount': 214300,
  'extractionError': null,
  'extractionMethod': 'ocr',
  'ocrProgress': status == 'extracting' ? {'done': 20, 'total': 120} : null,
  'reviewRequired': true,
  'reviewedAt': null,
  'createdAt': '2026-10-01T08:00:00.000Z',
};

final Map<String, Object?> wireOutline = {
  'items': [
    {'title': 'Introduction', 'level': 1, 'pageNumber': 1},
    {'title': 'Les contrats', 'level': 2, 'pageNumber': 12},
  ],
};

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late LibraryDatabase db;

  setUp(() => db = LibraryDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  DriftDocumentRepository repositoryOn(FakeHttp http) =>
      DriftDocumentRepository(db, DocumentApi(http.client()));

  /// Remplit la bibliothèque en cache avec le livre [id].
  Future<void> shelve(String id) async {
    final http = FakeHttp(
      (_) => reply(200, {
        'items': [wireItem(id)],
        'nextCursor': null,
      }),
    );
    await DriftLibraryRepository(
      db,
      LibraryApi(http.client()),
      FixedClock(DateTime.utc(2026, 10, 14)),
    ).refresh();
  }

  test(
    'texte prêt : la fiche et sa table des matières vont au cache',
    () async {
      final http = FakeHttp(
        (r) => r.path.endsWith('/outline')
            ? reply(200, wireOutline)
            : reply(200, wireDocument('a')),
      );
      final repository = repositoryOn(http);
      expect(await repository.watch('a').first, isNull);

      expect((await repository.refresh('a')).isOk, isTrue);

      expect(http.requests.map((r) => r.path), [
        '/v1/documents/a',
        '/v1/documents/a/outline',
      ]);
      final sheet = (await repository.watch('a').first)!;
      expect(sheet.title, 'Droit civil');
      expect(sheet.stage, DocumentStage.textReady);
      expect(sheet.pageCount, 120);
      expect(sheet.charCount, 214300);
      expect(sheet.method, ExtractionMethod.ocr);
      expect(sheet.reviewPending, isTrue);
      expect(sheet.outline.map((e) => (e.title, e.level, e.pageNumber)), [
        ('Introduction', 1, 1),
        ('Les contrats', 2, 12),
      ]);
    },
  );

  test('texte en préparation : pas de table, la progression du scan', () async {
    final http = FakeHttp(
      (_) => reply(200, wireDocument('a', status: 'extracting')),
    );
    final repository = repositoryOn(http);

    await repository.refresh('a');

    expect(http.requests, hasLength(1));
    final sheet = (await repository.watch('a').first)!;
    expect(sheet.stage.working, isTrue);
    expect(sheet.ocrProgress, (done: 20, total: 120));
    expect(sheet.outline, isEmpty);
  });

  test(
    'la table ratée garde l’ancienne ; hors ligne, la fiche reste',
    () async {
      var outlineUp = true;
      var online = true;
      final http = FakeHttp(
        (r) => !online
            ? reply(503, {'status': 503})
            : r.path.endsWith('/outline')
            ? (outlineUp
                  ? reply(200, wireOutline)
                  : reply(503, {'status': 503}))
            : reply(200, wireDocument('a')),
      );
      final repository = repositoryOn(http);
      await repository.refresh('a');

      outlineUp = false;
      expect((await repository.refresh('a')).isOk, isTrue);
      expect((await repository.watch('a').first)!.outline, hasLength(2));

      online = false;
      expect((await repository.refresh('a')).isErr, isTrue);
      expect((await repository.watch('a').first)!.title, 'Droit civil');
    },
  );

  test('table pas encore prête (409) : liste vide, pas une erreur', () async {
    final http = FakeHttp(
      (_) => reply(409, {'status': 409, 'code': 'DOCUMENT_TEXT_NOT_READY'}),
    );

    final result = await DocumentApi(http.client()).outline('a');

    expect(switch (result) {
      Ok(:final value) => value,
      Err() => null,
    }, isEmpty);
  });

  test('renommer met à jour la fiche et la bibliothèque en cache', () async {
    await shelve('a');
    final http = FakeHttp(
      (r) => r.method == 'PATCH'
          ? reply(200, wireDocument('a', title: 'Obligations L2'))
          : r.path.endsWith('/outline')
          ? reply(200, wireOutline)
          : reply(200, wireDocument('a')),
    );
    final repository = repositoryOn(http);
    await repository.refresh('a');

    expect((await repository.rename('a', 'Obligations L2')).isOk, isTrue);

    expect(http.requests.last.data, {'title': 'Obligations L2'});
    expect((await repository.watch('a').first)!.title, 'Obligations L2');
    final item = await db.select(db.cachedLibraryItems).getSingle();
    final document =
        (jsonDecode(item.payload) as Map<String, Object?>)['document']!
            as Map<String, Object?>;
    expect(document['title'], 'Obligations L2');
  });

  test('renommer hors ligne ne change rien', () async {
    final http = FakeHttp((_) => reply(503, {'status': 503}));

    expect((await repositoryOn(http).rename('a', 'X')).isErr, isTrue);
  });

  group('supprimer', () {
    late bool conflict;
    late bool gone;
    late DriftDocumentRepository repository;

    setUp(() async {
      conflict = false;
      gone = false;
      await shelve('a');
      final http = FakeHttp(
        (r) => switch (r.method) {
          'DELETE' when conflict => reply(409, {
            'status': 409,
            'code': 'DOCUMENT_DELETION_CONFLICT',
          }),
          'DELETE' when gone => reply(404, {
            'status': 404,
            'code': 'DOCUMENT_NOT_FOUND',
          }),
          'DELETE' => reply(204),
          _ => reply(200, wireDocument('a', status: 'extracting')),
        },
      );
      repository = repositoryOn(http);
      await repository.refresh('a');
    });

    Future<int> cachedRows() async =>
        (await db.select(db.cachedDocuments).get()).length +
        (await db.select(db.cachedLibraryItems).get()).length;

    test('pendant une conversion : refusé, le cache reste', () async {
      conflict = true;

      final result = await repository.delete('a');

      expect(switch (result) {
        Err(:final error) => error.code,
        Ok() => null,
      }, 'DOCUMENT_DELETION_CONFLICT');
      expect(await cachedRows(), 2);
    });

    test('supprimé : retiré de la fiche et de la bibliothèque', () async {
      expect((await repository.delete('a')).isOk, isTrue);
      expect(await cachedRows(), 0);
    });

    test('déjà supprimé ailleurs (404) : nettoyé aussi', () async {
      gone = true;
      expect((await repository.delete('a')).isOk, isTrue);
      expect(await cachedRows(), 0);
    });

    test('la fin de session vide aussi les fiches', () async {
      await DriftLibraryRepository(
        db,
        LibraryApi(FakeHttp((_) => reply(503)).client()),
        FixedClock(DateTime.utc(2026, 10, 14)),
      ).clear();
      expect(await cachedRows(), 0);
    });
  });

  test('une fiche en cache illisible donne null, sans planter', () async {
    await db
        .into(db.cachedDocuments)
        .insert(
          CachedDocumentsCompanion.insert(
            documentId: 'a',
            payload: '{"id": "a", "title": 7}',
          ),
        );

    expect(
      await repositoryOn(FakeHttp((_) => reply(503))).watch('a').first,
      isNull,
    );
  });

  test('migration v1 → v3 : fiches et pages créées', () async {
    final dir = await Directory.systemTemp.createTemp('voxlivre-db');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/library.sqlite');

    // Une base v1 : sans `cached_documents` ni `cached_pages`.
    final v2 = LibraryDatabase(NativeDatabase(file));
    await v2.customStatement('DROP TABLE cached_documents');
    await v2.customStatement('DROP TABLE cached_pages');
    await v2.customStatement('PRAGMA user_version = 1');
    await v2.close();

    final upgraded = LibraryDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    expect(await upgraded.select(upgraded.cachedDocuments).get(), isEmpty);
    expect(await upgraded.select(upgraded.cachedPages).get(), isEmpty);
  });
}

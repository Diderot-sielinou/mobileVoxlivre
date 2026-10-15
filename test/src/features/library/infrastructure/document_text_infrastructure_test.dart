import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_page.dart';
import 'package:voxlivre/src/features/library/infrastructure/document_api.dart';
import 'package:voxlivre/src/features/library/infrastructure/document_text_api.dart';
import 'package:voxlivre/src/features/library/infrastructure/drift_document_repository.dart';
import 'package:voxlivre/src/features/library/infrastructure/drift_document_text_repository.dart';
import 'package:voxlivre/src/features/library/infrastructure/library_database.dart';

import '../../../../helpers/fake_http.dart';
import 'document_infrastructure_test.dart' show wireDocument, wireOutline;

/// Une page telle que `GET /v1/documents/:id/pages` la renvoie.
Map<String, Object?> wirePage(int n, {String? text, double? confidence}) => {
  'pageNumber': n,
  'text': text ?? 'Texte $n',
  'charCount': 7,
  'setAside': [
    {'text': '— $n —', 'reason': 'page_number'},
  ],
  'confidence': confidence,
  'updatedAt': '2026-10-15T08:00:00.000Z',
};

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late LibraryDatabase db;

  setUp(() => db = LibraryDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  DriftDocumentTextRepository repositoryOn(FakeHttp http) =>
      DriftDocumentTextRepository(db, DocumentTextApi(http.client()));

  test(
    'lit les pages lot par lot, puis le cache les rend dans l’ordre',
    () async {
      final http = FakeHttp(
        (r) => r.queryParameters['cursor'] == null
            ? reply(200, {
                'items': [wirePage(2, confidence: 0.62), wirePage(1)],
                'nextCursor': 'lot-2',
              })
            : reply(200, {
                'items': [wirePage(3, confidence: 1)],
                'nextCursor': null,
              }),
      );
      final repository = repositoryOn(http);

      expect((await repository.refreshPages('a')).isOk, isTrue);

      expect(http.requests.map((r) => r.queryParameters), [
        {'limit': 50},
        {'limit': 50, 'cursor': 'lot-2'},
      ]);
      final pages = await repository.watchPages('a').first;
      expect(pages.map((p) => p.pageNumber), [1, 2, 3]);
      expect(pages[1].confidence, 0.62);
      expect(pages[1].needsReview, isTrue);
      expect(pages[2].confidence, 1.0, reason: 'un entier JSON est lu');
      expect(pages.first.setAside.single.reason, SetAsideReason.pageNumber);
    },
  );

  test('enregistrer une page met le cache à jour ; hors ligne, rien', () async {
    var online = true;
    final http = FakeHttp(
      (r) => !online
          ? reply(503, {'status': 503})
          : r.method == 'PUT'
          ? reply(200, wirePage(1, text: 'Corrigé'))
          : reply(200, {
              'items': [wirePage(1)],
              'nextCursor': null,
            }),
    );
    final repository = repositoryOn(http);
    await repository.refreshPages('a');

    expect((await repository.savePage('a', 1, 'Corrigé')).isOk, isTrue);
    expect(http.requests.last.path, '/v1/documents/a/pages/1');
    expect(http.requests.last.data, {'text': 'Corrigé'});
    expect((await repository.watchPages('a').first).single.text, 'Corrigé');

    online = false;
    expect((await repository.savePage('a', 1, 'Autre')).isErr, isTrue);
    expect((await repository.refreshPages('a')).isErr, isTrue);
    expect((await repository.watchPages('a').first).single.text, 'Corrigé');
  });

  test('« J’ai relu » met la fiche à jour et garde la table', () async {
    final documents = DriftDocumentRepository(
      db,
      DocumentApi(
        FakeHttp(
          (r) => r.path.endsWith('/outline')
              ? reply(200, wireOutline)
              : reply(200, wireDocument('a')),
        ).client(),
      ),
    );
    await documents.refresh('a');
    expect((await documents.watch('a').first)!.reviewPending, isTrue);

    final http = FakeHttp(
      (_) => reply(200, {
        ...wireDocument('a'),
        'reviewedAt': '2026-10-15T09:00:00.000Z',
      }),
    );
    expect((await repositoryOn(http).markReviewed('a')).isOk, isTrue);
    expect(http.requests.single.path, '/v1/documents/a/review');

    final sheet = (await documents.watch('a').first)!;
    expect(sheet.reviewPending, isFalse);
    expect(sheet.outline, hasLength(2));

    // Fiche jamais lue : elle est créée.
    expect((await repositoryOn(http).markReviewed('b')).isOk, isTrue);
    expect(await documents.watch('b').first, isNotNull);
  });

  test('« J’ai relu » refusé : la fiche ne change pas', () async {
    final http = FakeHttp(
      (_) => reply(409, {'status': 409, 'code': 'DOCUMENT_TEXT_NOT_READY'}),
    );
    final result = await repositoryOn(http).markReviewed('a');
    expect(switch (result) {
      Err(:final error) => error.code,
      Ok() => null,
    }, 'DOCUMENT_TEXT_NOT_READY');
  });

  test(
    'une page illisible est écartée ; supprimer le document les efface',
    () async {
      await db
          .into(db.cachedPages)
          .insert(
            CachedPagesCompanion.insert(
              documentId: 'a',
              pageNumber: 1,
              payload: jsonEncode(wirePage(1)),
            ),
          );
      await db
          .into(db.cachedPages)
          .insert(
            CachedPagesCompanion.insert(
              documentId: 'a',
              pageNumber: 2,
              payload: '{"pageNumber": "deux"}',
            ),
          );
      final repository = repositoryOn(FakeHttp((_) => reply(503)));
      expect(
        (await repository.watchPages('a').first).map((p) => p.pageNumber),
        [1],
      );

      await DriftDocumentRepository(
        db,
        DocumentApi(FakeHttp((_) => reply(204)).client()),
      ).delete('a');
      expect(await db.select(db.cachedPages).get(), isEmpty);
    },
  );

  test('migration v2 → v3 : la table des pages est créée', () async {
    final dir = await Directory.systemTemp.createTemp('voxlivre-db');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/library.sqlite');

    final v3 = LibraryDatabase(NativeDatabase(file));
    await v3.customStatement('DROP TABLE cached_pages');
    await v3.customStatement('PRAGMA user_version = 2');
    await v3.close();

    final upgraded = LibraryDatabase(NativeDatabase(file));
    addTearDown(upgraded.close);
    expect(await upgraded.select(upgraded.cachedPages).get(), isEmpty);
  });
}

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_page.dart';
import 'package:voxlivre/src/features/library/domain/document_text_repository.dart';
import 'package:voxlivre/src/features/library/infrastructure/document_page_dto.dart';
import 'package:voxlivre/src/features/library/infrastructure/document_text_api.dart';
import 'package:voxlivre/src/features/library/infrastructure/library_database.dart';

/// [DocumentTextRepository] : pages en cache drift (même base que la
/// bibliothèque), rafraîchies par [DocumentTextApi] (ADR-0006).
final class DriftDocumentTextRepository implements DocumentTextRepository {
  const DriftDocumentTextRepository(this._db, this._api);

  final LibraryDatabase _db;
  final DocumentTextApi _api;

  static final _log = Logger('library');

  @override
  Stream<List<DocumentPage>> watchPages(String documentId) {
    final query = _db.select(_db.cachedPages)
      ..where((t) => t.documentId.equals(documentId))
      ..orderBy([(t) => OrderingTerm.asc(t.pageNumber)]);
    return query.watch().map(
      (rows) => [
        for (final row in rows) ?_decode(row.payload),
      ],
    );
  }

  @override
  Future<Result<void, Failure>> refreshPages(String documentId) async {
    final fetched = await _api.pages(documentId);
    switch (fetched) {
      case Err(:final error):
        return Result.err(error);
      case Ok(value: final pages):
        await _db.transaction(() async {
          await (_db.delete(
            _db.cachedPages,
          )..where((t) => t.documentId.equals(documentId))).go();
          for (final json in pages) {
            if (json['pageNumber'] case final int number) {
              await _db
                  .into(_db.cachedPages)
                  .insert(_row(documentId, number, json));
            }
          }
        });
        return const Result.ok(null);
    }
  }

  @override
  Future<Result<void, Failure>> savePage(
    String documentId,
    int pageNumber,
    String text,
  ) async {
    final saved = await _api.savePage(documentId, pageNumber, text);
    switch (saved) {
      case Err(:final error):
        return Result.err(error);
      case Ok(value: final json):
        await _db
            .into(_db.cachedPages)
            .insertOnConflictUpdate(_row(documentId, pageNumber, json));
        return const Result.ok(null);
    }
  }

  @override
  Future<Result<void, Failure>> markReviewed(String documentId) async {
    final reviewed = await _api.review(documentId);
    switch (reviewed) {
      case Err(:final error):
        return Result.err(error);
      case Ok(value: final json):
        // La table des matières en cache reste celle déjà lue.
        await _db
            .into(_db.cachedDocuments)
            .insert(
              CachedDocumentsCompanion.insert(
                documentId: documentId,
                payload: jsonEncode(json),
              ),
              onConflict: DoUpdate(
                (_) => CachedDocumentsCompanion(
                  payload: Value(jsonEncode(json)),
                ),
              ),
            );
        return const Result.ok(null);
    }
  }

  static CachedPagesCompanion _row(
    String documentId,
    int pageNumber,
    Map<String, Object?> json,
  ) => CachedPagesCompanion.insert(
    documentId: documentId,
    pageNumber: pageNumber,
    payload: jsonEncode(json),
  );

  static DocumentPage? _decode(String payload) {
    try {
      return DocumentPageDto.fromJson(
        jsonDecode(payload) as Map<String, Object?>,
      ).toDomain();
      // Forme inattendue : erreur de type ou de format.
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      _log.warning('page en cache illisible : ${e.runtimeType}');
      return null;
    }
  }
}

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_repository.dart';
import 'package:voxlivre/src/features/library/domain/document_sheet.dart';
import 'package:voxlivre/src/features/library/infrastructure/document_api.dart';
import 'package:voxlivre/src/features/library/infrastructure/document_dto.dart';
import 'package:voxlivre/src/features/library/infrastructure/library_database.dart';

/// [DocumentRepository] : fiches en cache drift (même base que la
/// bibliothèque), rafraîchies par [DocumentApi] (ADR-0006).
final class DriftDocumentRepository implements DocumentRepository {
  const DriftDocumentRepository(this._db, this._api);

  final LibraryDatabase _db;
  final DocumentApi _api;

  static final _log = Logger('library');

  @override
  Stream<DocumentSheet?> watch(String documentId) {
    final query = _db.select(_db.cachedDocuments)
      ..where((t) => t.documentId.equals(documentId));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _decode(row.payload, row.outline),
    );
  }

  @override
  Future<Result<void, Failure>> refresh(String documentId) async {
    final fetched = await _api.fetch(documentId);
    switch (fetched) {
      case Err(:final error):
        return Result.err(error);
      case Ok(value: final json):
        // La table des matières n'existe qu'une fois le texte prêt ; un
        // échec ici garde la fiche (la table sera relue plus tard).
        String? outline;
        if (json['status'] == 'text_ready') {
          if (await _api.outline(documentId) case Ok(value: final items)) {
            outline = jsonEncode(items);
          }
        }
        await _db
            .into(_db.cachedDocuments)
            .insert(
              CachedDocumentsCompanion.insert(
                documentId: documentId,
                payload: jsonEncode(json),
                outline: Value(outline),
              ),
              onConflict: DoUpdate(
                (old) => CachedDocumentsCompanion.custom(
                  payload: Constant(jsonEncode(json)),
                  // Sans nouvelle table (réseau), on garde l'ancienne.
                  outline: outline == null ? old.outline : Constant(outline),
                ),
              ),
            );
        return const Result.ok(null);
    }
  }

  @override
  Future<Result<void, Failure>> rename(String documentId, String title) async {
    final renamed = await _api.rename(documentId, title);
    switch (renamed) {
      case Err(:final error):
        return Result.err(error);
      case Ok(value: final json):
        await _db.transaction(() async {
          await (_db.update(
            _db.cachedDocuments,
          )..where((t) => t.documentId.equals(documentId))).write(
            CachedDocumentsCompanion(payload: Value(jsonEncode(json))),
          );
          await _renameInLibrary(documentId, json['title']! as String);
        });
        return const Result.ok(null);
    }
  }

  @override
  Future<Result<void, Failure>> delete(String documentId) async {
    final deleted = await _api.delete(documentId);
    switch (deleted) {
      case Err(:final error) when error.code != 'DOCUMENT_NOT_FOUND':
        return Result.err(error);
      // Déjà supprimé (autre appareil, nouvel essai) : on nettoie aussi.
      case Err() || Ok():
        await _db.transaction(() async {
          await (_db.delete(
            _db.cachedDocuments,
          )..where((t) => t.documentId.equals(documentId))).go();
          await (_db.delete(
            _db.cachedLibraryItems,
          )..where((t) => t.documentId.equals(documentId))).go();
          await (_db.delete(
            _db.cachedPages,
          )..where((t) => t.documentId.equals(documentId))).go();
        });
        return const Result.ok(null);
    }
  }

  /// Le livre en cache garde le JSON de la bibliothèque : on y change le
  /// titre, sans attendre le prochain rafraîchissement.
  Future<void> _renameInLibrary(String documentId, String title) async {
    final row = await (_db.select(
      _db.cachedLibraryItems,
    )..where((t) => t.documentId.equals(documentId))).getSingleOrNull();
    if (row == null) return;
    final item = jsonDecode(row.payload) as Map<String, Object?>;
    final document = item['document'];
    if (document is! Map<String, Object?>) return;
    item['document'] = {...document, 'title': title};
    await (_db.update(_db.cachedLibraryItems)
          ..where((t) => t.documentId.equals(documentId)))
        .write(CachedLibraryItemsCompanion(payload: Value(jsonEncode(item))));
  }

  static DocumentSheet? _decode(String payload, String? outline) {
    try {
      final entries = outline == null
          ? const <OutlineEntry>[]
          : [
              for (final e in jsonDecode(outline) as List<Object?>)
                OutlineEntryDto.fromJson(e! as Map<String, Object?>).toDomain(),
            ];
      return DocumentDto.fromJson(
        jsonDecode(payload) as Map<String, Object?>,
      ).toDomain(entries);
      // Forme inattendue : erreur de type ou de format.
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      _log.warning('fiche en cache illisible : ${e.runtimeType}');
      return null;
    }
  }
}

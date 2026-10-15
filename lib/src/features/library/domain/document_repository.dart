import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_sheet.dart';

/// Les fiches des documents, hors ligne d'abord comme la bibliothèque
/// (ADR-0006).
abstract interface class DocumentRepository {
  /// La fiche en cache (`null` si jamais lue), puis ses mises à jour.
  Stream<DocumentSheet?> watch(String documentId);

  /// Relit la fiche et sa table des matières, puis met le cache à jour.
  Future<Result<void, Failure>> refresh(String documentId);

  /// Renomme le document (titre déjà validé) ; met aussi à jour la
  /// bibliothèque en cache.
  Future<Result<void, Failure>> rename(String documentId, String title);

  /// Supprime le document ; le retire aussi de la bibliothèque en cache.
  /// Refusé (`DOCUMENT_DELETION_CONFLICT`) pendant une conversion.
  Future<Result<void, Failure>> delete(String documentId);
}

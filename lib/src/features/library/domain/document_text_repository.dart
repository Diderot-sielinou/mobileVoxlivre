import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_page.dart';

/// Le texte d'un document page par page (RF-06), hors ligne d'abord :
/// les pages lues restent sur l'appareil ; corriger demande le réseau.
abstract interface class DocumentTextRepository {
  /// Les pages en cache (vide si jamais lues), puis leurs mises à jour.
  Stream<List<DocumentPage>> watchPages(String documentId);

  /// Relit toutes les pages, puis met le cache à jour.
  Future<Result<void, Failure>> refreshPages(String documentId);

  /// Enregistre le texte corrigé (déjà validé) d'une page.
  Future<Result<void, Failure>> savePage(
    String documentId,
    int pageNumber,
    String text,
  );

  /// « J'ai relu le texte » : lève la relecture imposée ; la fiche en
  /// cache est mise à jour.
  Future<Result<void, Failure>> markReviewed(String documentId);
}

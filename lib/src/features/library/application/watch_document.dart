import 'package:voxlivre/src/features/library/domain/document_repository.dart';
import 'package:voxlivre/src/features/library/domain/document_sheet.dart';

/// La fiche d'un document telle qu'en cache, puis à chaque mise à jour.
final class WatchDocument {
  const WatchDocument(this._repository);

  final DocumentRepository _repository;

  Stream<DocumentSheet?> call(String documentId) =>
      _repository.watch(documentId);
}

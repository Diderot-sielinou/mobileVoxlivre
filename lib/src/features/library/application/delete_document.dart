import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_repository.dart';

/// Supprime définitivement un document (texte, audio, position,
/// marque-pages). Hors ligne, rien n'est supprimé : l'échec est rendu.
final class DeleteDocument {
  const DeleteDocument(this._repository);

  final DocumentRepository _repository;

  Future<Result<void, Failure>> call(String documentId) =>
      _repository.delete(documentId);
}

import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_repository.dart';

/// Relit la fiche d'un document sur le réseau.
final class RefreshDocument {
  const RefreshDocument(this._repository);

  final DocumentRepository _repository;

  Future<Result<void, Failure>> call(String documentId) =>
      _repository.refresh(documentId);
}

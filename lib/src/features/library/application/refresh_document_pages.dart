import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_text_repository.dart';

/// Relit le texte d'un document sur le réseau.
final class RefreshDocumentPages {
  const RefreshDocumentPages(this._repository);

  final DocumentTextRepository _repository;

  Future<Result<void, Failure>> call(String documentId) =>
      _repository.refreshPages(documentId);
}

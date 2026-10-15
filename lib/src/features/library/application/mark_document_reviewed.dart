import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_text_repository.dart';

/// « J'ai relu le texte » : la conversion devient possible (RF-06).
final class MarkDocumentReviewed {
  const MarkDocumentReviewed(this._repository);

  final DocumentTextRepository _repository;

  Future<Result<void, Failure>> call(String documentId) =>
      _repository.markReviewed(documentId);
}

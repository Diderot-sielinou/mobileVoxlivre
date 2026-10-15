import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_page.dart';
import 'package:voxlivre/src/features/library/domain/document_text_repository.dart';

/// Enregistre une page corrigée : le texte est validé ici, sans appel s'il
/// est refusé (`INVALID_PAGE_TEXT`).
final class SaveDocumentPage {
  const SaveDocumentPage(this._repository);

  final DocumentTextRepository _repository;

  Future<Result<void, Failure>> call(
    String documentId,
    int pageNumber,
    String text,
  ) async {
    switch (PageText.parse(text)) {
      case Err(:final error):
        return Result.err(error);
      case Ok(value: final valid):
        return _repository.savePage(documentId, pageNumber, valid);
    }
  }
}

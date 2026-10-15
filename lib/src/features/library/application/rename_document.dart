import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_repository.dart';
import 'package:voxlivre/src/features/library/domain/document_title.dart';

/// Renomme un document : le titre est validé ici, sans appel s'il est
/// refusé (`INVALID_DOCUMENT_TITLE`).
final class RenameDocument {
  const RenameDocument(this._repository);

  final DocumentRepository _repository;

  Future<Result<void, Failure>> call(String documentId, String title) async {
    switch (DocumentTitle.parse(title)) {
      case Err(:final error):
        return Result.err(error);
      case Ok(value: final valid):
        return _repository.rename(documentId, valid);
    }
  }
}

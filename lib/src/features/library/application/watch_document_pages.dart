import 'package:voxlivre/src/features/library/domain/document_page.dart';
import 'package:voxlivre/src/features/library/domain/document_text_repository.dart';

/// Les pages d'un document telles qu'en cache, puis à chaque mise à jour.
final class WatchDocumentPages {
  const WatchDocumentPages(this._repository);

  final DocumentTextRepository _repository;

  Stream<List<DocumentPage>> call(String documentId) =>
      _repository.watchPages(documentId);
}

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/features/library/application/clear_library.dart';
import 'package:voxlivre/src/features/library/application/delete_document.dart';
import 'package:voxlivre/src/features/library/application/import_document.dart';
import 'package:voxlivre/src/features/library/application/mark_document_reviewed.dart';
import 'package:voxlivre/src/features/library/application/pick_pdf.dart';
import 'package:voxlivre/src/features/library/application/refresh_document.dart';
import 'package:voxlivre/src/features/library/application/refresh_document_pages.dart';
import 'package:voxlivre/src/features/library/application/refresh_library.dart';
import 'package:voxlivre/src/features/library/application/rename_document.dart';
import 'package:voxlivre/src/features/library/application/save_document_page.dart';
import 'package:voxlivre/src/features/library/application/watch_document.dart';
import 'package:voxlivre/src/features/library/application/watch_document_pages.dart';
import 'package:voxlivre/src/features/library/application/watch_library.dart';
import 'package:voxlivre/src/features/library/infrastructure/api_document_uploads.dart';
import 'package:voxlivre/src/features/library/infrastructure/drift_document_repository.dart';
import 'package:voxlivre/src/features/library/infrastructure/drift_document_text_repository.dart';
import 'package:voxlivre/src/features/library/infrastructure/drift_library_repository.dart';
import 'package:voxlivre/src/features/library/infrastructure/file_selector_pdf_source.dart';
import 'package:voxlivre/src/features/library/infrastructure/library_database.dart';
import 'package:voxlivre/src/features/library/library_providers.dart';
import 'package:voxlivre/src/shared/http/http_providers.dart';

import '../../../helpers/fake_http.dart';

void main() {
  test('la composition relie la base, l’API et les cas d’usage', () async {
    final db = LibraryDatabase(NativeDatabase.memory());
    // Ordre inverse à la fin : le conteneur (et ses flux), puis la base.
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        libraryDatabaseProvider.overrideWithValue(db),
        apiClientProvider.overrideWithValue(
          FakeHttp(
            (_) => reply(200, {'items': <Object?>[], 'nextCursor': null}),
          ).client(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(libraryRepositoryProvider),
      isA<DriftLibraryRepository>(),
    );
    expect(container.read(watchLibraryProvider), isA<WatchLibrary>());
    expect(container.read(refreshLibraryProvider), isA<RefreshLibrary>());
    expect(container.read(clearLibraryProvider), isA<ClearLibrary>());
    expect(
      container.read(documentRepositoryProvider),
      isA<DriftDocumentRepository>(),
    );
    expect(container.read(watchDocumentProvider), isA<WatchDocument>());
    expect(container.read(refreshDocumentProvider), isA<RefreshDocument>());
    expect(container.read(renameDocumentProvider), isA<RenameDocument>());
    expect(container.read(deleteDocumentProvider), isA<DeleteDocument>());
    expect(
      container.read(documentTextRepositoryProvider),
      isA<DriftDocumentTextRepository>(),
    );
    expect(
      container.read(watchDocumentPagesProvider),
      isA<WatchDocumentPages>(),
    );
    expect(
      container.read(refreshDocumentPagesProvider),
      isA<RefreshDocumentPages>(),
    );
    expect(container.read(saveDocumentPageProvider), isA<SaveDocumentPage>());
    expect(
      container.read(markDocumentReviewedProvider),
      isA<MarkDocumentReviewed>(),
    );
    expect(container.read(pdfSourceProvider), isA<FileSelectorPdfSource>());
    expect(
      container.read(documentUploadsProvider),
      isA<ApiDocumentUploads>(),
    );
    expect(container.read(pickPdfProvider), isA<PickPdf>());
    expect(container.read(importDocumentProvider), isA<ImportDocument>());

    final seen = <bool>[];
    container.listen(
      librarySnapshotProvider,
      (_, next) => seen.addAll([?next.value?.loaded]),
      fireImmediately: true,
    );
    await container.read(refreshLibraryProvider)();
    // drift prévient ses flux de façon asynchrone.
    for (var i = 0; i < 20 && !seen.contains(true); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(seen, contains(true));
  });
}

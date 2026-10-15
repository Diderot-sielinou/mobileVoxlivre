import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/library/application/clear_library.dart';
import 'package:voxlivre/src/features/library/application/delete_document.dart';
import 'package:voxlivre/src/features/library/application/refresh_document.dart';
import 'package:voxlivre/src/features/library/application/refresh_library.dart';
import 'package:voxlivre/src/features/library/application/rename_document.dart';
import 'package:voxlivre/src/features/library/application/watch_document.dart';
import 'package:voxlivre/src/features/library/application/watch_library.dart';
import 'package:voxlivre/src/features/library/domain/document_repository.dart';
import 'package:voxlivre/src/features/library/domain/document_sheet.dart';
import 'package:voxlivre/src/features/library/domain/library_repository.dart';
import 'package:voxlivre/src/features/library/domain/library_snapshot.dart';
import 'package:voxlivre/src/features/library/infrastructure/document_api.dart';
import 'package:voxlivre/src/features/library/infrastructure/drift_document_repository.dart';
import 'package:voxlivre/src/features/library/infrastructure/drift_library_repository.dart';
import 'package:voxlivre/src/features/library/infrastructure/library_api.dart';
import 'package:voxlivre/src/features/library/infrastructure/library_database.dart';
import 'package:voxlivre/src/shared/http/http_providers.dart';
import 'package:voxlivre/src/shared/time/clock_providers.dart';

/// Composition de la bibliothèque (ADR-0002, ADR-0006).

/// Base locale `library.sqlite`, fermée avec l'app.
final libraryDatabaseProvider = Provider<LibraryDatabase>((ref) {
  final db = LibraryDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => DriftLibraryRepository(
    ref.watch(libraryDatabaseProvider),
    LibraryApi(ref.watch(apiClientProvider)),
    ref.watch(clockProvider),
  ),
);

final watchLibraryProvider = Provider<WatchLibrary>(
  (ref) => WatchLibrary(ref.watch(libraryRepositoryProvider)),
);

final refreshLibraryProvider = Provider<RefreshLibrary>(
  (ref) => RefreshLibrary(
    ref.watch(libraryRepositoryProvider),
    ref.watch(clockProvider),
  ),
);

final clearLibraryProvider = Provider<ClearLibrary>(
  (ref) => ClearLibrary(ref.watch(libraryRepositoryProvider)),
);

/// Le cache de la bibliothèque, à jour.
final librarySnapshotProvider = StreamProvider<LibrarySnapshot>(
  (ref) => ref.watch(watchLibraryProvider)(),
);

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DriftDocumentRepository(
    ref.watch(libraryDatabaseProvider),
    DocumentApi(ref.watch(apiClientProvider)),
  ),
);

final watchDocumentProvider = Provider<WatchDocument>(
  (ref) => WatchDocument(ref.watch(documentRepositoryProvider)),
);

final refreshDocumentProvider = Provider<RefreshDocument>(
  (ref) => RefreshDocument(ref.watch(documentRepositoryProvider)),
);

final renameDocumentProvider = Provider<RenameDocument>(
  (ref) => RenameDocument(ref.watch(documentRepositoryProvider)),
);

final deleteDocumentProvider = Provider<DeleteDocument>(
  (ref) => DeleteDocument(ref.watch(documentRepositoryProvider)),
);

/// La fiche d'un document en cache, à jour.
// Type de famille non exporté par flutter_riverpod 3 : il est inféré.
// ignore: specify_nonobvious_property_types
final documentSheetProvider = StreamProvider.family<DocumentSheet?, String>(
  (ref, id) => ref.watch(watchDocumentProvider)(id),
);

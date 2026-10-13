import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/library/application/clear_library.dart';
import 'package:voxlivre/src/features/library/application/refresh_library.dart';
import 'package:voxlivre/src/features/library/application/watch_library.dart';
import 'package:voxlivre/src/features/library/domain/library_repository.dart';
import 'package:voxlivre/src/features/library/domain/library_snapshot.dart';
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

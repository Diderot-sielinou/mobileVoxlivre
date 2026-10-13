import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/features/library/application/clear_library.dart';
import 'package:voxlivre/src/features/library/application/refresh_library.dart';
import 'package:voxlivre/src/features/library/application/watch_library.dart';
import 'package:voxlivre/src/features/library/infrastructure/drift_library_repository.dart';
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

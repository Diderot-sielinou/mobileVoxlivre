import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/app/session_effects.dart';
import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/domain/current_user.dart';
import 'package:voxlivre/src/features/library/application/clear_library.dart';
import 'package:voxlivre/src/features/library/application/refresh_library.dart';
import 'package:voxlivre/src/features/library/application/watch_library.dart';
import 'package:voxlivre/src/features/library/domain/library_snapshot.dart';

import '../../../../helpers/app_harness.dart';
import '../../auth/fakes.dart';
import '../fakes.dart';

void main() {
  late FakeLibraryRepository repository;
  late FixedClock clock;

  setUp(() {
    repository = FakeLibraryRepository(remote: [book('a')]);
    clock = FixedClock(repository.now);
  });

  group('RefreshLibrary', () {
    test('un cache vide se remplit', () async {
      final result = await RefreshLibrary(repository, clock)();

      expect(result.isOk, isTrue);
      expect(repository.refreshes, 1);
      expect(repository.snapshot.items, hasLength(1));
    });

    test('un cache de moins de 2 min n’est pas relu, sauf demande', () async {
      final refresh = RefreshLibrary(repository, clock);
      await refresh();

      clock.advance(const Duration(minutes: 1));
      await refresh();
      expect(repository.refreshes, 1);

      await refresh(force: true);
      expect(repository.refreshes, 2);

      clock.advance(const Duration(minutes: 3));
      await refresh();
      expect(repository.refreshes, 3);
    });

    test('un échec remonte son code', () async {
      repository.failure = 'NETWORK_UNAVAILABLE';

      final result = await RefreshLibrary(repository, clock)();

      expect(result.isErr, isTrue);
      expect(repository.snapshot.loaded, isFalse);
    });
  });

  test('WatchLibrary suit le cache, ClearLibrary le vide', () async {
    final seen = <LibrarySnapshot>[];
    final subscription = WatchLibrary(repository)().listen(seen.add);
    addTearDown(subscription.cancel);

    await repository.refresh();
    await ClearLibrary(repository)();
    await Future<void>.delayed(Duration.zero);

    expect(seen.map((s) => s.items.length), [0, 1, 0]);
  });

  test('la fin de session vide la bibliothèque (ADR-0006)', () async {
    final session = AuthSession(MemorySessionStore('t'), token: 't');
    final subscription = clearAccountDataOnSignOut(
      session,
      [ClearLibrary(repository).call],
    );
    addTearDown(subscription.cancel);

    session.attachUser(const CurrentUser(id: 'u1'));
    await Future<void>.delayed(Duration.zero);
    expect(repository.clears, 0, reason: 'un compte reçu ne vide rien');

    await session.close();
    await Future<void>.delayed(Duration.zero);
    expect(repository.clears, 1);
  });
}

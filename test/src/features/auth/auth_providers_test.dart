import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/application/request_code.dart';
import 'package:voxlivre/src/features/auth/application/restore_session.dart';
import 'package:voxlivre/src/features/auth/application/sign_out.dart';
import 'package:voxlivre/src/features/auth/application/verify_code.dart';
import 'package:voxlivre/src/features/auth/auth_providers.dart';
import 'package:voxlivre/src/features/auth/infrastructure/better_auth_gateway.dart';
import 'package:voxlivre/src/shared/http/http_providers.dart';

import '../../../helpers/fake_http.dart';
import 'fakes.dart';

void main() {
  test('la composition relie la passerelle HTTP et les cas d’usage', () async {
    final session = AuthSession(MemorySessionStore('t'), token: 't');
    final container = ProviderContainer(
      overrides: [
        authSessionProvider.overrideWithValue(session),
        apiClientProvider.overrideWithValue(
          FakeHttp((_) => reply(200, {})).client(),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(authGatewayProvider), isA<BetterAuthGateway>());
    expect(container.read(requestCodeProvider), isA<RequestCode>());
    expect(container.read(verifyCodeProvider), isA<VerifyCode>());
    expect(container.read(restoreSessionProvider), isA<RestoreSession>());
    expect(container.read(signOutProvider), isA<SignOut>());

    final states = <SessionState>[];
    container.listen(
      sessionStateProvider,
      (_, next) => states.addAll([?next.value]),
      fireImmediately: true,
    );
    await Future<void>.delayed(Duration.zero);
    await session.close();
    await Future<void>.delayed(Duration.zero);
    expect(states.map((s) => s.runtimeType), [SignedIn, SignedOut]);
  });

  test('la session doit être fournie au démarrage', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(() => container.read(authSessionProvider), throwsA(anything));
  });
}

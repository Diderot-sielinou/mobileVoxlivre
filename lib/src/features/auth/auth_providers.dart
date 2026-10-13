import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/application/request_code.dart';
import 'package:voxlivre/src/features/auth/application/restore_session.dart';
import 'package:voxlivre/src/features/auth/application/sign_out.dart';
import 'package:voxlivre/src/features/auth/application/verify_code.dart';
import 'package:voxlivre/src/features/auth/domain/auth_gateway.dart';
import 'package:voxlivre/src/features/auth/infrastructure/better_auth_gateway.dart';
import 'package:voxlivre/src/shared/http/http_providers.dart';

/// Composition de l'auth (ADR-0002) : ports → adaptateurs, cas d'usage.

/// Session de l'app, créée au démarrage avec le jeton lu (ADR-0005).
final authSessionProvider = Provider<AuthSession>(
  (ref) =>
      throw UnimplementedError('authSessionProvider est fourni au démarrage'),
);

/// État de la session : l'état courant, puis chaque changement.
final sessionStateProvider = StreamProvider<SessionState>((ref) async* {
  final session = ref.watch(authSessionProvider);
  yield session.state;
  yield* session.changes;
});

final authGatewayProvider = Provider<AuthGateway>(
  (ref) => BetterAuthGateway(ref.watch(apiClientProvider)),
);

final requestCodeProvider = Provider<RequestCode>(
  (ref) => RequestCode(ref.watch(authGatewayProvider)),
);

final verifyCodeProvider = Provider<VerifyCode>(
  (ref) => VerifyCode(
    ref.watch(authGatewayProvider),
    ref.watch(authSessionProvider),
  ),
);

final restoreSessionProvider = Provider<RestoreSession>(
  (ref) => RestoreSession(
    ref.watch(authGatewayProvider),
    ref.watch(authSessionProvider),
  ),
);

final signOutProvider = Provider<SignOut>(
  (ref) =>
      SignOut(ref.watch(authGatewayProvider), ref.watch(authSessionProvider)),
);

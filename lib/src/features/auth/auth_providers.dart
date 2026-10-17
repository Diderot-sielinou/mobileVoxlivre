import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/application/request_code.dart';
import 'package:voxlivre/src/features/auth/application/restore_session.dart';
import 'package:voxlivre/src/features/auth/application/sign_in_with_google.dart';
import 'package:voxlivre/src/features/auth/application/sign_out.dart';
import 'package:voxlivre/src/features/auth/application/verify_code.dart';
import 'package:voxlivre/src/features/auth/domain/auth_gateway.dart';
import 'package:voxlivre/src/features/auth/domain/google_account.dart';
import 'package:voxlivre/src/features/auth/infrastructure/better_auth_gateway.dart';
import 'package:voxlivre/src/features/auth/infrastructure/sdk_google_account.dart';
import 'package:voxlivre/src/shared/http/http_providers.dart';

/// Composition de l'auth (ADR-0002) : ports → adaptateurs, cas d'usage.

/// Session de l'app, créée au démarrage avec le jeton lu (ADR-0005).
final authSessionProvider = Provider<AuthSession>(
  (ref) =>
      throw UnimplementedError('authSessionProvider est fourni au démarrage'),
);

/// État de la session : l'état courant, puis chaque changement.
final sessionStateProvider = StreamProvider<SessionState>((ref) {
  final session = ref.watch(authSessionProvider);
  // Abonné aux changements avant de rendre l'état courant : un `async*`
  // s'abonnerait après le premier `yield` et pourrait manquer un changement.
  final controller = StreamController<SessionState>();
  final changes = session.changes.listen(controller.add);
  controller.add(session.state);
  ref.onDispose(() {
    unawaited(changes.cancel());
    unawaited(controller.close());
  });
  return controller.stream;
});

final authGatewayProvider = Provider<AuthGateway>(
  (ref) => BetterAuthGateway(ref.watch(apiClientProvider)),
);

/// Client OAuth Web de Google, fourni au démarrage depuis la configuration
/// (ADR-0015) ; `null` : pas de connexion Google.
final googleServerClientIdProvider = Provider<String?>((ref) => null);

/// Compte Google du téléphone (ADR-0015).
final googleAccountProvider = Provider<GoogleAccount>(
  (ref) => SdkGoogleAccount(ref.watch(googleServerClientIdProvider)),
);

/// La connexion Google est proposée seulement si l'app connaît son client.
final googleSignInEnabledProvider = Provider<bool>(
  (ref) => ref.watch(googleServerClientIdProvider) != null,
);

final signInWithGoogleProvider = Provider<SignInWithGoogle>(
  (ref) => SignInWithGoogle(
    ref.watch(googleAccountProvider),
    ref.watch(authGatewayProvider),
    ref.watch(authSessionProvider),
  ),
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
  (ref) => SignOut(
    ref.watch(authGatewayProvider),
    ref.watch(authSessionProvider),
    ref.watch(googleAccountProvider),
  ),
);

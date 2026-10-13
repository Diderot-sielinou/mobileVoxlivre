import 'dart:async';

import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/domain/auth_gateway.dart';

/// Déconnexion : prévient le serveur sans attendre, et efface toujours la
/// session locale, même hors ligne (ADR-0005).
final class SignOut {
  const SignOut(this._gateway, this._session);

  final AuthGateway _gateway;
  final AuthSession _session;

  Future<void> call() async {
    // La requête part avec le jeton courant avant qu'il soit effacé.
    unawaited(_gateway.signOut());
    await _session.close();
  }
}

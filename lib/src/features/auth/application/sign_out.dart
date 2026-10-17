import 'dart:async';

import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/domain/auth_gateway.dart';
import 'package:voxlivre/src/features/auth/domain/google_account.dart';

/// Déconnexion : prévient le serveur sans attendre, et efface toujours la
/// session locale, même hors ligne (ADR-0005). Oublie aussi le compte
/// Google : la connexion suivante redemande lequel (ADR-0015).
final class SignOut {
  const SignOut(this._gateway, this._session, this._google);

  final AuthGateway _gateway;
  final AuthSession _session;
  final GoogleAccount _google;

  Future<void> call() async {
    // La requête part avec le jeton courant avant qu'il soit effacé.
    unawaited(_gateway.signOut());
    unawaited(_google.forget());
    await _session.close();
  }
}

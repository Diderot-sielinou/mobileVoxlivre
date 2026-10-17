import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/domain/auth_gateway.dart';
import 'package:voxlivre/src/features/auth/domain/google_account.dart';

/// Connexion par Google : choix du compte, échange de son ID token contre
/// une session, puis chargement du compte (ADR-0015).
final class SignInWithGoogle {
  const SignInWithGoogle(this._google, this._gateway, this._session);

  final GoogleAccount _google;
  final AuthGateway _gateway;
  final AuthSession _session;

  Future<Result<void, Failure>> call() async {
    final idToken = await _google.idToken();
    final String token;
    switch (idToken) {
      case Err(:final error):
        return Result.err(error);
      case Ok(:final value):
        final exchanged = await _gateway.signInWithGoogle(value);
        switch (exchanged) {
          case Err(:final error):
            // Compte refusé : le prochain essai redemande lequel.
            await _google.forget();
            return Result.err(error);
          case Ok(value: final session):
            token = session;
        }
    }
    await _session.open(token);
    // Comme après un code : le compte se recharge au prochain démarrage.
    if (await _gateway.currentUser() case Ok(value: final user)) {
      _session.attachUser(user);
    }
    return const Result.ok(null);
  }
}

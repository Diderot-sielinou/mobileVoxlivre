import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';

/// Le compte Google choisi sur le téléphone (ADR-0015). Rend un ID token
/// que le backend vérifie ; les échecs portent un code `GOOGLE_*`.
abstract interface class GoogleAccount {
  /// Demande un compte à l'utilisateur ; rend son ID token.
  Future<Result<String, Failure>> idToken();

  /// Oublie le compte choisi : la prochaine connexion redemande lequel.
  Future<void> forget();
}

/// L'utilisateur a fermé le choix du compte : rien à afficher.
final class GoogleSignInCancelled extends Failure {
  const GoogleSignInCancelled() : super('GOOGLE_SIGN_IN_CANCELLED');
}

/// Google indisponible sur ce téléphone (services Google absents, client
/// mal configuré) ou échec inattendu.
final class GoogleSignInUnavailable extends Failure {
  const GoogleSignInUnavailable([String message = ''])
    : super('GOOGLE_SIGN_IN_UNAVAILABLE', message: message);
}

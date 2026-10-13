import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/auth/domain/current_user.dart';
import 'package:voxlivre/src/features/auth/domain/sign_in_target.dart';

/// Le service d'authentification (le backend). Les échecs portent le `code`
/// du backend (`INVALID_OTP`, `OTP_EXPIRED`, `TOO_MANY_ATTEMPTS`,
/// `OTP_RATE_LIMITED`…) ou un code réseau (`NETWORK_UNAVAILABLE`…).
abstract interface class AuthGateway {
  /// Envoie un code à 6 chiffres à [target].
  Future<Result<void, Failure>> requestCode(SignInTarget target);

  /// Valide [code] pour [target] ; rend le jeton de session signé.
  Future<Result<String, Failure>> verifyCode(SignInTarget target, String code);

  /// Le compte de la session courante.
  Future<Result<CurrentUser, Failure>> currentUser();

  /// Ferme la session côté serveur.
  Future<Result<void, Failure>> signOut();
}

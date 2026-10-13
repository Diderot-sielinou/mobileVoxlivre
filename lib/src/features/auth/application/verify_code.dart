import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/domain/auth_gateway.dart';
import 'package:voxlivre/src/features/auth/domain/sign_in_target.dart';

/// Valide le code reçu : ouvre la session, puis charge le compte.
final class VerifyCode {
  const VerifyCode(this._gateway, this._session);

  final AuthGateway _gateway;
  final AuthSession _session;

  Future<Result<void, Failure>> call(SignInTarget target, String code) async {
    final verified = await _gateway.verifyCode(target, code);
    switch (verified) {
      case Err(:final error):
        return Result.err(error);
      case Ok(value: final token):
        await _session.open(token);
    }
    // Le compte n'est pas nécessaire pour entrer : un échec ici (réseau) se
    // rattrape au prochain démarrage.
    if (await _gateway.currentUser() case Ok(value: final user)) {
      _session.attachUser(user);
    }
    return const Result.ok(null);
  }
}

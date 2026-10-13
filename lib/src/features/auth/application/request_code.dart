import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/auth/domain/auth_gateway.dart';
import 'package:voxlivre/src/features/auth/domain/sign_in_target.dart';

/// Demande un code de connexion pour [SignInTarget].
final class RequestCode {
  const RequestCode(this._gateway);

  final AuthGateway _gateway;

  Future<Result<void, Failure>> call(SignInTarget target) =>
      _gateway.requestCode(target);
}

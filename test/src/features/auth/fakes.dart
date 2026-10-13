import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/auth/domain/auth_gateway.dart';
import 'package:voxlivre/src/features/auth/domain/current_user.dart';
import 'package:voxlivre/src/features/auth/domain/session_store.dart';
import 'package:voxlivre/src/features/auth/domain/sign_in_target.dart';

/// Échec de test portant [code].
final class FakeFailure extends Failure {
  const FakeFailure(super.code);
}

/// Stockage en mémoire.
final class MemorySessionStore implements SessionStore {
  MemorySessionStore([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;

  @override
  Future<void> clear() async => token = null;
}

/// Passerelle scriptée : chaque réponse est réglable, chaque appel noté.
final class FakeAuthGateway implements AuthGateway {
  Result<void, Failure> requestResult = const Result.ok(null);
  Result<String, Failure> verifyResult = const Result.ok('jeton-signé');
  Result<CurrentUser, Failure> userResult = const Result.ok(
    CurrentUser(id: 'u1', email: 'lecteur@mail.com'),
  );
  final calls = <String>[];

  @override
  Future<Result<void, Failure>> requestCode(SignInTarget target) async {
    calls.add('request ${target.masked}');
    return requestResult;
  }

  @override
  Future<Result<String, Failure>> verifyCode(
    SignInTarget target,
    String code,
  ) async {
    calls.add('verify $code');
    return verifyResult;
  }

  @override
  Future<Result<CurrentUser, Failure>> currentUser() async {
    calls.add('me');
    return userResult;
  }

  @override
  Future<Result<void, Failure>> signOut() async {
    calls.add('sign-out');
    return const Result.ok(null);
  }
}

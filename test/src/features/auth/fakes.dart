import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/auth/domain/auth_gateway.dart';
import 'package:voxlivre/src/features/auth/domain/current_user.dart';
import 'package:voxlivre/src/features/auth/domain/google_account.dart';
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
  Result<String, Failure> googleResult = const Result.ok('jeton-google');
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
  Future<Result<String, Failure>> signInWithGoogle(String idToken) async {
    calls.add('google $idToken');
    return googleResult;
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

/// Compte Google scripté : l'ID token rendu est réglable, chaque appel noté.
final class FakeGoogleAccount implements GoogleAccount {
  Result<String, Failure> idTokenResult = const Result.ok('id-token');
  final calls = <String>[];

  @override
  Future<Result<String, Failure>> idToken() async {
    calls.add('choose');
    return idTokenResult;
  }

  @override
  Future<void> forget() async => calls.add('forget');
}

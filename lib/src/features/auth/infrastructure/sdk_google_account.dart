import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/auth/domain/google_account.dart';

/// [GoogleAccount] par le SDK Google d'Android (Credential Manager). Le
/// jeton demandé a pour audience le client OAuth Web, celui que le backend
/// vérifie. Sans ce client, Google est indisponible.
final class SdkGoogleAccount implements GoogleAccount {
  SdkGoogleAccount(this._serverClientId, [GoogleSignIn? sdk])
    : _sdk = sdk ?? GoogleSignIn.instance;

  final String? _serverClientId;
  final GoogleSignIn _sdk;
  Future<void>? _initialized;

  static final _log = Logger('auth.google');

  @override
  Future<Result<String, Failure>> idToken() async {
    final serverClientId = _serverClientId;
    if (serverClientId == null) {
      return const Result.err(GoogleSignInUnavailable('client non configuré'));
    }
    try {
      await (_initialized ??= _sdk.initialize(serverClientId: serverClientId));
      final account = await _sdk.authenticate();
      final token = account.authentication.idToken;
      if (token == null || token.isEmpty) {
        return const Result.err(GoogleSignInUnavailable('ID token absent'));
      }
      return Result.ok(token);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const Result.err(GoogleSignInCancelled());
      }
      // Code seulement : la description peut citer le compte.
      _log.warning('Connexion Google refusée : ${e.code.name}');
      return Result.err(GoogleSignInUnavailable(e.code.name));
    }
  }

  @override
  Future<void> forget() async {
    if (_initialized == null) return;
    try {
      await _sdk.signOut();
    } on GoogleSignInException catch (e) {
      _log.warning('Oubli du compte Google impossible : ${e.code.name}');
    }
  }
}

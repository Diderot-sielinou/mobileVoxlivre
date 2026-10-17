import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/auth/domain/auth_gateway.dart';
import 'package:voxlivre/src/features/auth/domain/current_user.dart';
import 'package:voxlivre/src/features/auth/domain/sign_in_target.dart';
import 'package:voxlivre/src/features/auth/infrastructure/me_dto.dart';
import 'package:voxlivre/src/shared/http/api_client.dart';
import 'package:voxlivre/src/shared/http/api_failure.dart';

/// [AuthGateway] sur les routes better-auth du backend (ADR-0004 du backend)
/// et `GET /v1/me`.
final class BetterAuthGateway implements AuthGateway {
  const BetterAuthGateway(this._api);

  final ApiClient _api;

  /// En-tête du jeton signé (plugin `bearer`) ; le `token` du corps n'est
  /// pas accepté par le backend (`requireSignature`).
  static const tokenHeader = 'set-auth-token';

  @override
  Future<Result<void, Failure>> requestCode(SignInTarget target) =>
      switch (target) {
        PhoneTarget(:final phone) => _api.post(
          '/api/auth/phone-number/send-otp',
          body: {'phoneNumber': phone.e164},
          decode: _ignore,
        ),
        EmailTarget(:final email) => _api.post(
          '/api/auth/email-otp/send-verification-otp',
          body: {'email': email.value, 'type': 'sign-in'},
          decode: _ignore,
        ),
      };

  @override
  Future<Result<String, Failure>> verifyCode(SignInTarget target, String code) {
    final request = switch (target) {
      PhoneTarget(:final phone) => _api.post(
        '/api/auth/phone-number/verify',
        body: {'phoneNumber': phone.e164, 'code': code},
        decode: (r) => r.header(tokenHeader),
      ),
      EmailTarget(:final email) => _api.post(
        '/api/auth/sign-in/email-otp',
        body: {'email': email.value, 'otp': code},
        decode: (r) => r.header(tokenHeader),
      ),
    };
    return _sessionToken(request);
  }

  /// Fournisseur `google` de better-auth, flux par ID token (ADR-0030 du
  /// backend) : même jeton signé en en-tête que pour un code.
  @override
  Future<Result<String, Failure>> signInWithGoogle(String idToken) =>
      _sessionToken(
        _api.post(
          '/api/auth/sign-in/social',
          body: {
            'provider': 'google',
            'idToken': {'token': idToken},
          },
          decode: (r) => r.header(tokenHeader),
        ),
      );

  /// Jeton de session lu dans [tokenHeader] ; son absence est une réponse
  /// inattendue.
  Future<Result<String, Failure>> _sessionToken(
    Future<Result<String?, Failure>> request,
  ) {
    return request.then(
      (result) => switch (result) {
        Ok(value: final token?) when token.isNotEmpty => Result.ok(token),
        Ok() => const Result.err(
          ApiFailure(
            ApiFailure.unexpectedResponse,
            requestId: '-',
            status: 200,
            message: 'en-tête $tokenHeader absent',
          ),
        ),
        Err(:final error) => Result.err(error),
      },
    );
  }

  @override
  Future<Result<CurrentUser, Failure>> currentUser() => _api.get(
    '/v1/me',
    decode: (r) => MeDto.fromJson(r.json! as Map<String, Object?>).toDomain(),
  );

  @override
  Future<Result<void, Failure>> signOut() =>
      _api.post('/api/auth/sign-out', body: const {}, decode: _ignore);

  static void _ignore(Object? _) {}
}

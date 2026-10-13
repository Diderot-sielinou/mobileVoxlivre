import 'dart:async';

import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/shared/http/auth_token_source.dart';

/// Branche l'[AuthSession] sur le client HTTP (ADR-0005) : il lit le jeton
/// courant et ferme la session quand l'API le refuse.
final class SessionTokenSource implements AuthTokenSource {
  const SessionTokenSource(this._session);

  final AuthSession _session;

  @override
  String? get token => _session.token;

  @override
  void onUnauthorized() => unawaited(_session.close());
}

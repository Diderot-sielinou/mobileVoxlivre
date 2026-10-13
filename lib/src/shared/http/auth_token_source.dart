/// Fournit le jeton de session à l'`ApiClient` (ADR-0005).
///
/// Implémentée par la fonctionnalité auth et branchée par `app/` : `shared`
/// ne connaît pas auth.
abstract interface class AuthTokenSource {
  /// Jeton à envoyer en `Authorization: Bearer`, `null` sans session.
  String? get token;

  /// L'API a refusé (401) une requête qui portait un jeton : la session
  /// n'est plus valable.
  void onUnauthorized();
}

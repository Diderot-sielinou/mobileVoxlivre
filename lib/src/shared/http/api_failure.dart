import 'package:voxlivre/src/core/failure.dart';

/// Échec d'un appel à l'API (ADR-0004).
///
/// [code] est toujours présent : celui du Problem Details du backend, sinon
/// un code déduit du statut ([codeForStatus]), sinon un code réseau
/// ([networkUnavailable], [timeout]…). [status] vaut `null` quand aucune
/// réponse n'est arrivée.
final class ApiFailure extends Failure {
  /// Échec identifié par [code], pour la requête [requestId].
  const ApiFailure(
    super.code, {
    required this.requestId,
    this.status,
    super.message,
    super.details,
  });

  /// Pas de connexion, DNS ou serveur injoignable.
  static const networkUnavailable = 'NETWORK_UNAVAILABLE';

  /// Délai de connexion, d'envoi ou de réception dépassé.
  static const timeout = 'TIMEOUT';

  /// Requête annulée par l'app.
  static const cancelled = 'CANCELLED';

  /// Réponse reçue mais illisible (corps non JSON, forme inattendue).
  static const unexpectedResponse = 'UNEXPECTED_RESPONSE';

  /// Statut HTTP de la réponse, `null` sans réponse.
  final int? status;

  /// Identifiant envoyé dans `x-request-id` : il retrouve la ligne de
  /// journal du backend (à montrer au support).
  final String requestId;

  /// Code d'une réponse en erreur dont le Problem Details n'a pas de `code`
  /// (erreur de validation Nest, proxy…).
  static String codeForStatus(int status) => switch (status) {
    400 => 'BAD_REQUEST',
    401 => 'UNAUTHORIZED',
    403 => 'FORBIDDEN',
    404 => 'NOT_FOUND',
    409 => 'CONFLICT',
    413 => 'PAYLOAD_TOO_LARGE',
    429 => 'RATE_LIMITED',
    >= 500 => 'SERVER_ERROR',
    _ => 'HTTP_ERROR',
  };

  @override
  String toString() => 'ApiFailure($code, status: $status, $requestId)';
}

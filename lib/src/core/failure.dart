/// Base de tous les échecs attendus de l'application (calque de
/// `DomainError` du backend).
///
/// [code] est stable et lisible par la machine ; pour une erreur de l'API, il
/// reprend le `code` du Problem Details (`QUOTA_EXCEEDED`,
/// `DOCUMENT_REVIEW_REQUIRED`…) : l'interface choisit son message à partir du
/// code, jamais à partir d'un texte. [details] ne transporte jamais de donnée
/// personnelle.
abstract class Failure {
  /// Échec identifié par [code], avec un [message] pour les journaux.
  const Failure(this.code, {this.message = '', this.details = const {}});

  /// Code stable, en majuscules (`DOCUMENT_NOT_FOUND`).
  final String code;

  /// Explication technique, destinée aux journaux et non à l'utilisateur.
  final String message;

  /// Données structurées utiles à l'écran (ex. unités manquantes).
  final Map<String, Object?> details;

  @override
  String toString() => '$runtimeType($code)';
}

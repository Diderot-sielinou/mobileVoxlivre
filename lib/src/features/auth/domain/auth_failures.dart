import 'package:voxlivre/src/core/failure.dart';

/// Numéro refusé avant tout appel : pas un mobile camerounais (même règle
/// que le backend, ADR-0017 du backend). Même code que l'erreur du backend.
final class InvalidPhoneNumber extends Failure {
  const InvalidPhoneNumber() : super('INVALID_PHONE_NUMBER');
}

/// Adresse e-mail mal formée, refusée avant tout appel.
final class InvalidEmailAddress extends Failure {
  const InvalidEmailAddress() : super('INVALID_EMAIL');
}

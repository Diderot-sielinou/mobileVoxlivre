/// Nature d'une offre (ADR-0019 du backend).
enum OfferKind {
  /// Unités pour 30 jours.
  pass,

  /// Unités sans expiration.
  credits;

  static OfferKind fromWire(String value) =>
      value == 'pass' ? OfferKind.pass : OfferKind.credits;
}

/// Une offre du catalogue : le prix vient toujours du serveur.
final class Offer {
  const Offer({
    required this.code,
    required this.kind,
    required this.priceXaf,
    required this.units,
    this.durationDays,
  });

  final String code;
  final OfferKind kind;

  /// Prix en francs CFA, entier.
  final int priceXaf;
  final int units;

  /// Durée d'un pass, en jours.
  final int? durationDays;
}

/// Le solde du compte, par source.
final class Balance {
  const Balance({
    required this.freeRemaining,
    required this.passRemaining,
    required this.credits,
    this.passEndsAt,
    this.nextPassStartsAt,
  });

  final int freeRemaining;
  final int passRemaining;
  final int credits;

  /// Fin du pass en cours.
  final DateTime? passEndsAt;

  /// Début d'un pass acheté pendant le pass en cours.
  final DateTime? nextPassStartsAt;

  int get total => freeRemaining + passRemaining + credits;
}

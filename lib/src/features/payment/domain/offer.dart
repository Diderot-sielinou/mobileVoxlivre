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

/// Nature d'une ligne du portefeuille.
enum WalletEntryKind {
  /// Achat d'une offre (+).
  purchase,

  /// Conversion (−).
  consumption,

  /// Remboursement d'une conversion échouée (+).
  refund;

  static WalletEntryKind fromWire(String value) => switch (value) {
    'purchase' => WalletEntryKind.purchase,
    'refund' => WalletEntryKind.refund,
    _ => WalletEntryKind.consumption,
  };
}

/// Une ligne de l'historique des unités (ADR-0019 du backend).
final class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.kind,
    required this.units,
    required this.createdAt,
    this.offerCode,
    this.conversionId,
  });

  final String id;
  final WalletEntryKind kind;

  /// Signé : + achat ou remboursement, − consommation.
  final int units;
  final DateTime createdAt;
  final String? offerCode;
  final String? conversionId;
}

/// Une page de l'historique ; [nextCursor] `null` : fin.
final class WalletPage {
  const WalletPage({required this.entries, this.nextCursor});

  final List<WalletEntry> entries;
  final String? nextCursor;
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

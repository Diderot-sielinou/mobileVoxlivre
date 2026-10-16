/// État d'un paiement (ADR-0021 du backend).
enum PaymentStatus {
  /// Demande envoyée au téléphone : on attend le code PIN.
  pending,

  /// Confirmé, offre accordée.
  succeeded,

  /// Refusé, annulé ou numéro refusé : rien n'a été débité.
  failed,

  /// Sans réponse dans le délai : rien n'a été débité.
  expired,

  /// Montant reçu différent du prix : examiné à la main.
  amountMismatch;

  static PaymentStatus fromWire(String value) => switch (value) {
    'succeeded' => PaymentStatus.succeeded,
    'failed' => PaymentStatus.failed,
    'expired' => PaymentStatus.expired,
    'amount_mismatch' => PaymentStatus.amountMismatch,
    _ => PaymentStatus.pending,
  };

  bool get isFinal => this != PaymentStatus.pending;
}

/// Un paiement, tel que le serveur le montre (jamais le numéro entier).
final class Payment {
  const Payment({
    required this.id,
    required this.status,
    required this.offerCode,
    required this.amountXaf,
    required this.phoneSuffix,
    required this.createdAt,
    this.failureCode,
    this.completedAt,
  });

  final String id;
  final PaymentStatus status;
  final String offerCode;
  final int amountXaf;

  /// Deux derniers chiffres du numéro débité.
  final String phoneSuffix;

  /// `invalid_phone`, `declined`, `no_provider_reference`.
  final String? failureCode;
  final DateTime createdAt;
  final DateTime? completedAt;
}

/// Numéro Mobile Money camerounais (MTN, Orange) : `+2376` + 8 chiffres
/// (ADR-0021 du backend). Rend `null` si la saisie n'en est pas un ;
/// espaces, points, tirets et indicatif sont tolérés.
String? normalizeCameroonMobile(String raw) {
  var digits = raw.replaceAll(RegExp(r'[\s.\-()]'), '');
  if (digits.startsWith('+')) digits = digits.substring(1);
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (!RegExp(r'^\d+$').hasMatch(digits)) return null;
  if (digits.length == 9) digits = '237$digits';
  if (!RegExp(r'^2376\d{8}$').hasMatch(digits)) return null;
  return '+$digits';
}

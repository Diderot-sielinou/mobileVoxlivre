import 'package:voxlivre/src/features/payment/domain/offer.dart';
import 'package:voxlivre/src/features/payment/domain/payment.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

/// Nom d'une offre (le catalogue n'a pas de libellé).
String offerTitle(Offer offer) => switch (offer.kind) {
  OfferKind.pass => 'Pass ${offer.durationDays ?? 30} jours',
  OfferKind.credits => 'Crédits ${VoxFormat.count(offer.units)} unités',
};

/// Détail d'une offre.
String offerDetail(Offer offer) => switch (offer.kind) {
  OfferKind.pass =>
    '${VoxFormat.count(offer.units)} unités pendant '
        '${offer.durationDays ?? 30} jours',
  OfferKind.credits => 'Sans date d’expiration',
};

/// Le numéro débité, masqué : « +237 6•• •• •• 47 ».
String maskedPhone(String suffix) => '+237 6•• •• •• $suffix';

/// Pourquoi le paiement n'a pas pu partir (étape « Payer »), par code.
/// Chaque message dit si de l'argent a pu partir.
String startErrorText(String code) => switch (code) {
  'INVALID_PAYMENT_PHONE' =>
    'Ce numéro n’est pas un numéro Orange Money ou MTN MoMo du Cameroun.',
  'PAYMENT_IN_PROGRESS_CONFLICT' =>
    'Un paiement attend déjà votre validation. Validez-le sur votre '
        'téléphone, ou patientez quelques minutes avant de réessayer.',
  'RATE_LIMIT_PAYMENT_ATTEMPTS' =>
    'Trop de tentatives pour le moment. Réessayez dans une heure.',
  'OFFER_NOT_FOUND' =>
    'Cette offre n’est plus proposée. Revenez aux offres pour en choisir '
        'une autre.',
  'INFRASTRUCTURE_PAYMENT_UNAVAILABLE' =>
    'Le paiement Mobile Money n’est pas disponible pour le moment. Rien '
        'n’a été débité. Réessayez plus tard.',
  'NETWORK_UNAVAILABLE' || 'TIMEOUT' =>
    'Pas de connexion. Rien n’a été débité ; réessayez quand le réseau '
        'revient.',
  _ => 'Le paiement n’a pas pu démarrer. Rien n’a été débité. Réessayez.',
};

/// Titre et explication d'un paiement non abouti.
({String title, String detail}) failureText(Payment payment) =>
    switch (payment.status) {
      PaymentStatus.expired => (
        title: 'Demande expirée',
        detail:
            'La validation n’est pas arrivée à temps. Rien n’a été '
            'prélevé.',
      ),
      PaymentStatus.amountMismatch => (
        title: 'Paiement à vérifier',
        detail:
            'Le montant reçu ne correspond pas au prix. Aucune unité n’a '
            'été ajoutée : contactez le support avec la référence '
            'ci-dessous.',
      ),
      _ when payment.failureCode == 'invalid_phone' => (
        title: 'Numéro refusé',
        detail: 'L’opérateur n’accepte pas ce numéro. Rien n’a été prélevé.',
      ),
      _ => (
        title: 'Paiement refusé ou annulé',
        detail:
            'Aucun montant n’a été prélevé. Causes fréquentes : code '
            'secret erroné, solde Mobile Money insuffisant, demande '
            'refusée sur le téléphone.',
      ),
    };

/// Référence courte à donner au support.
String paymentReference(Payment payment) =>
    payment.id.replaceAll('-', '').substring(0, 10).toUpperCase();

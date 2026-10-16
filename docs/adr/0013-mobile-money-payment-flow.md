# 0013. Paiement Mobile Money : un parcours, une clé par tentative, statut relu

- Statut : accepted
- Date : 2026-10-16

## Contexte

Le backend (ADR-0021 du backend) encaisse par Campay : `POST /v1/payments`
{offerCode, phoneNumber} avec l'en-tête **`Idempotency-Key`** obligatoire →
202 `pending` ; le client valide sur son téléphone (code PIN) ; l'app relit
`GET /v1/payments/:id` (lecture en base seulement) jusqu'à `succeeded`,
`failed`, `expired` ou `amount_mismatch`. Le prix vient du catalogue
(`GET /v1/billing/offers`), jamais du client. Campay déduit l'opérateur du
numéro. Il n'existe ni route d'annulation ni liste des paiements. En
production, le paiement est **désactivé** (503
`INFRASTRUCTURE_PAYMENT_UNAVAILABLE`) jusqu'à l'ouverture chez Campay.

## Décision

- **Fonctionnalité `features/payment/`** : port `PaymentGateway` (offres,
  solde, lancer, relire), port `PaymentMemory` (appareil), cas d'usage
  `LoadOffers`, `StartPayment`, `CheckPayment`, `ClearPaymentMemory`. Elle
  servira aussi au Profil (« Unités & offres »).
- **Un seul écran-parcours** (`/payment`, plein écran au-dessus des
  onglets) : offres → payer → en attente → réussi / non abouti. Retour
  arrière d'étape en étape. La conversion l'ouvre par une action fournie
  par le routeur (ADR-0008) et relit son solde au retour.
- **Numéro** : mobiles camerounais seulement, normalisés en `+2376XXXXXXXX`
  dans l'app (6…, 2376…, +2376…, espaces tolérés) ; le serveur reste juge
  (422). **Pas de choix d'opérateur** (validé par le porteur) : l'attente
  montre `*150#` (Orange) et `*126#` (MTN).
- **Clé d'idempotence** : un UUID v4 par **tentative**. Gardée pour
  réessayer après un échec incertain (réseau, délai, 503) : pas de double
  débit. Nouvelle clé si l'offre ou le numéro change, ou après un échec
  définitif.
- **Attente** : statut relu toutes les **3 s**, et à la demande (« J'ai déjà
  validé »). Au-delà de **15 min**, la relecture s'arrête : « toujours en
  attente », vérification à la main.
- **Sur l'appareil** (`flutter_secure_storage`) : le dernier numéro qui a
  payé (pré-rempli) et l'identifiant du paiement en attente. Au démarrage
  d'une session, un paiement en attente rouvre le parcours sur l'attente.
  Tout est effacé à la déconnexion ; rien n'est journalisé.
- **Messages par code** : `declined`, `expired`, `amount_mismatch`,
  `INVALID_PAYMENT_PHONE`, `PAYMENT_IN_PROGRESS_CONFLICT`,
  `RATE_LIMIT_PAYMENT_ATTEMPTS`, `OFFER_NOT_FOUND`,
  `INFRASTRUCTURE_PAYMENT_UNAVAILABLE` (« pas disponible pour le moment,
  rien n'a été débité »), réseau. Chaque échec dit si de l'argent a pu
  partir.

## Conséquences

- Pas de reçu PDF ni d'opérateur sur le reçu (aucune donnée côté backend).
- L'essai réel se fait contre un backend local en Campay démo (la
  production est désactivée), l'app pointée par `config/local.json`.
- À l'ouverture chez Campay, rien ne change dans l'app.

# 0008. Fonctionnalité « conversion » et passage de données entre fonctionnalités par la route

- Statut : accepted
- Date : 2026-10-15

## Contexte

La conversion d'un texte en audio (choix de la voix, coût en unités,
lancement, suivi) est une fonctionnalité distincte de la bibliothèque : le
lecteur l'utilisera aussi. Ses écrans ont pourtant besoin de données que
`library` possède (titre, nombre de caractères du document, identifiant de
la conversion en cours). Une fonctionnalité n'importe pas l'intérieur d'une
autre (ADR-0001).

Le backend : `GET /v1/voices` (gamme standard ×1 ou naturelle ×4),
`GET /v1/billing/account` (palier gratuit — voix standard seulement —,
pass, crédits, plafond par conversion), `GET /v1/billing/offers` (poids des
gammes), `POST /v1/documents/:id/conversions` (202, ou la conversion
existante sans nouveau débit ; 402 `QUOTA_EXCEEDED` avec `requested`,
`usable`, `available`), `GET /v1/conversions/:id` (statut, progression).

## Décision

- Nouvelle fonctionnalité `features/conversion/` (domaine, cas d'usage,
  adaptateur API, écrans), avec son fichier de composition.
- **Entre fonctionnalités, on passe par la route**, composée dans
  `app/router.dart` (seul endroit qui connaît les deux) :
  `/library/documents/:id/convert?title=…&chars=…` et
  `/library/documents/:id/conversions/:conversionId`. La fiche reçoit des
  rappels (`onConvert`, `onOpenConversion`) ; elle ne connaît pas
  l'écran de conversion. Paramètres de requête plutôt que `extra` : ils
  survivent à une restauration de la navigation.
- Le **coût affiché** est calculé (caractères × poids de la gamme) et
  comparé au solde utilisable pour la gamme ; **le backend reste juge** :
  son 402 fait foi.
- Pas de cache hors ligne : lancer une conversion demande le réseau ; le
  suivi relit `GET /v1/conversions/:id` toutes les 10 s, écran visible.

## Conséquences

- Une donnée passée par la route peut être périmée (nombre de caractères
  changé depuis) : sans effet sur le débit, calculé par le backend.
- Le même motif servira au lecteur (`…/conversions/:id/listen`).

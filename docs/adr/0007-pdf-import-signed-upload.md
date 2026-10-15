# 0007. Import d'un PDF : envoi direct par URL signée, relance complète

- Statut : accepted
- Date : 2026-10-15

## Contexte

Le backend fait importer un PDF en trois appels (ADR-0007 du backend) :
`POST /v1/documents` (titre, taille, attestation de droits) renvoie le
document et une URL `PUT` signée (15 min, en-têtes `content-type` et
`content-length` imposés) ; le fichier part **directement** vers le
stockage objet ; `POST /v1/documents/:id/upload-confirmation` vérifie
taille et signature `%PDF-`, puis lance l'extraction. Plafond 50 Mo ; les
envois abandonnés sont purgés côté backend. Le réseau camerounais coupe
souvent ; la maquette « Envoi » promet une reprise par morceaux de 512 Ko.

## Décision

- **Où** : dans la fonctionnalité `library` (même objet « document » que
  la fiche : titre, cache, navigation), cas d'usage `ImportDocument`.
- **Choix du fichier** : `file_selector` (paquet flutter.dev, sélecteur
  système, aucune permission). Sur Android il copie le fichier dans le
  cache de l'app : la copie est **effacée** après l'import (réussi, raté ou
  annulé) — c'est un document personnel.
- **Envoi** : `SignedUpload` dans `shared/http/`, un `dio` **à part**, sans
  adresse de base ni jeton (l'URL signée est la seule autorisation ; le
  jeton de session ne doit jamais partir vers le stockage). Le fichier est
  lu en flux, avec progression et annulation. `ApiClient` reste le seul
  accès à `voxlivre-api` (ADR-0004).
- **Contrôles avant tout appel** : titre (règles du backend), taille
  ≤ 50 Mo, signature `%PDF-`, attestation cochée.
- **Coupure** : une URL `PUT` unique ne se reprend pas en cours de
  route ; la reprise par morceaux demanderait l'envoi « multipart » côté
  backend (décision backend, proposée au porteur). En v1 : **l'envoi
  complet est relancé** jusqu'à 3 fois sur erreur réseau ; si l'URL a
  expiré (403), un nouveau document est demandé.
- **Après la confirmation** : la bibliothèque est rafraîchie et l'app
  ouvre la fiche, qui suit déjà l'extraction (ADR-0006).
- **Premier plan seulement** : l'envoi s'arrête si l'app est tuée (l'écran
  le dit) ; un envoi en tâche de fond serait une autre décision.

## Conséquences

- Nouvelle dépendance : `file_selector`.
- Un envoi coupé à 90 % repart de zéro : coût en data sur un gros PDF,
  accepté pour la v1.
- Les éléments des maquettes que le backend ne fournit pas (reprise par
  morceaux, notification « livre prêt ») ne sont pas affichés.

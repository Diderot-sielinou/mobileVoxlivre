# 0009. Import d'un PDF : envoi par morceaux, repris où il s'était arrêté

- Statut : accepted
- Date : 2026-10-15
- Remplace la règle « relance complète » de l'ADR-0007 pour les fichiers
  de plus de 5 Mio ; le reste de l'ADR-0007 tient (sélecteur, contrôles
  locaux, `SignedUpload` sans jeton, copie effacée, premier plan).

## Contexte

Le backend sait désormais recevoir un PDF par morceaux (ADR-0029 du
backend, en production) : `POST /v1/documents` avec `multipart: true`
répond, au-delà de 5 Mio, `multipart: { partSize, partCount }` ;
`POST /v1/documents/:id/upload-parts` rend les morceaux **déjà reçus** et
une URL `PUT` signée (taille exacte) par morceau manquant ; la confirmation
assemble. Morceaux de 5 Mio (minimum S3).

## Décision

- L'app demande toujours `multipart: true` ; le backend décide (≤ 5 Mio :
  un seul `PUT`, chemin de l'ADR-0007 inchangé).
- Par morceaux : `upload-parts` → envoi, l'un après l'autre, des morceaux
  manquants (chaque morceau lu en flux dans le fichier, `SignedUpload`) →
  confirmation.
- **Coupure** : pause (3 s, 8 s, 15 s), puis `upload-parts` à nouveau : seuls
  les morceaux absents repartent. Le compteur de relances revient à zéro
  dès qu'un morceau passe (une connexion qui coupe souvent avance quand
  même) ; trois échecs d'affilée sans progrès arrêtent l'import. Une URL
  expirée (403) se traite comme une coupure : la reprise en signe une neuve.
- Progression = octets des morceaux reçus + octets du morceau en cours.

## Conséquences

- Une coupure fait perdre au plus 5 Mio au lieu du fichier entier.
- Un appel `upload-parts` de plus par reprise (petit JSON).

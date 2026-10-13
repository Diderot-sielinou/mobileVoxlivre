# 0003. Environnements par fichier de configuration, jamais de valeur en dur

- Statut : accepted
- Date : 2026-10-12

## Contexte

Le backend tourne en local (`http://10.0.2.2:8080` vu de l'émulateur
Android) et en production (`https://api.voxlivre.store`). Le dépôt
`cinaf-engine-infra` sépare ses environnements et ne versionne que des
fichiers `*.example`.

## Décision

- Un fichier par environnement : `config/dev.json`, `config/prod.json`, **non
  versionnés** ; `config/*.json.example` versionnés.
- Lancement : `flutter run --dart-define-from-file=config/dev.json`.
- Les valeurs sont lues une fois au démarrage dans un objet `AppConfig`
  validé (URL obligatoire, environnement connu) ; une valeur manquante fait
  échouer le démarrage avec un message clair.
- Pas de flavors Android natifs pour l'instant : un seul identifiant
  d'application ; à revoir si dev et prod doivent cohabiter sur un téléphone.

## Conséquences

- Aucune URL ni clé dans le code ; la CI fournit `config/prod.json` à la
  construction de la version de production.

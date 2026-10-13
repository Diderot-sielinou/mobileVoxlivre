# Voxlivre — application mobile (Flutter)

Application Android de **Voxlivre** : lecture synchronisée audio-texte à partir
de PDF (« Lisez. Écoutez. Vivez le livre. »). Elle consomme l'API
`voxlivre-api` (`../backendVoxlivre`, en production sur
`https://api.voxlivre.store`).

## Choix d'architecture

- **Hexagonale par fonctionnalité**, calquée sur le backend : chaque
  fonctionnalité (`auth`, `library`, `document`, `conversion`, `player`…) a ses
  couches `domain` (Dart pur), `application`, `infrastructure`, `presentation`.
- **Hors ligne d'abord** : connexion instable et data chère au Cameroun ; un
  livre converti se lit sans réseau.
- **Android d'abord** (minSdk 24), iOS plus tard.
- Les justifications détaillées sont dans `docs/adr/`.

## Arborescence

```text
lib/            code de l'application
test/           tests (unitaires, widgets, architecture)
android/        projet Android (identifiant store.voxlivre.app)
docs/           ADR et guides d'ingénierie
config/         configuration par environnement (*.json.example versionnés)
```

## Démarrage

```bash
flutter pub get
flutter run
```

## Hypothèses

- Flutter 3.32 (Dart 3.8), JDK 17, SDK Android installés.
- API locale du backend sur le port 8080 pour le développement.

## Limites actuelles

Projet en cours d'initialisation : structure, qualité et configuration
d'abord ; les écrans viendront ensuite (maquettes Stitch dans
`../doc-projet/design_market_stich_voxlivre/`).

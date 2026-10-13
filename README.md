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
assets/fonts/   polices embarquées (OFL) : texte lisible hors ligne
```

## Démarrage

```bash
make hooks                                  # une fois après le clone
cp config/dev.json.example config/dev.json  # adapter si besoin
make get
make run                                    # ENV=prod make run pour la production
```

Sans `--dart-define-from-file`, l'app refuse de démarrer et dit quoi
corriger (ADR-0003). `make check` lance ce que vérifie la CI.

## Hypothèses

- Flutter 3.32 (Dart 3.8), JDK 17, SDK Android installés.
- API locale du backend sur le port 8080 pour le développement
  (`10.0.2.2` = la machine hôte vue de l'émulateur Android).
- Navigation : 4 onglets (Bibliothèque, Importer, Statistiques, Profil),
  choix modifiable.

## Limites actuelles

Projet en cours d'initialisation : les 4 onglets affichent une page
d'attente ; les écrans viendront ensuite (maquettes Stitch dans
`../doc-projet/design_market_stich_voxlivre/`).

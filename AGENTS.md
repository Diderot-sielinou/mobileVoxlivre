# AGENTS.md — Règles non-négociables pour l'app mobile Voxlivre

Chargé en contexte par les agents IA (Claude, Copilot…) et lu par les humains.
Court et directif. Le détail va dans [docs/code-engineering/](docs/code-engineering/),
les justifications dans [docs/adr/](docs/adr/). Pendant backend :
`../backendVoxlivre/AGENTS.md` (mêmes principes).

## Objectif

App **Flutter Android** de Voxlivre : importer un PDF, le convertir en livre
audio, l'écouter avec le texte surligné mot à mot, **hors ligne**. Marché :
Cameroun francophone (connexion instable, data chère, téléphones d'entrée de
gamme, Mobile Money). Backend : `voxlivre-api` (`https://api.voxlivre.store`).
Design : système « Encre & Aurore » (`../doc-projet/`).

## Stack imposée

- Flutter 3.32+ / Dart 3.8+, Android d'abord (minSdk 24, `store.voxlivre.app`)
- Riverpod (état **et** injection), go_router, dio, freezed/json_serializable,
  drift (hors ligne), flutter_secure_storage (jeton)
- Lint : very_good_analysis, 0 avertissement

## Règles non-négociables

### Architecture hexagonale par fonctionnalité ([ADR-0001](docs/adr/0001-hexagonal-feature-architecture.md))

```
lib/src/
  core/                 Result, Failure, Clock — Dart pur
  shared/               design system, client HTTP, stockage — partagés
  app/                  bootstrap, routeur, providers racine
  features/<fonctionnalité>/
    <f>_providers.dart  composition : relie ports et adaptateurs (seul presentation l'importe)
    domain/             entités, objets valeur, ports (abstract interface class) — Dart PUR
    application/        cas d'usage (1 fichier = 1 cas d'usage)
    infrastructure/     adaptateurs : API (dio), base locale (drift), audio
    presentation/       écrans, widgets, contrôleurs d'état
```

- `domain/` n'importe **jamais** Flutter, Riverpod, dio, drift, ni une autre
  couche — **vérifié par `test/architecture/`**, la CI casse.
- `application/` dépend de **ports**, jamais d'adaptateurs ni de `presentation/`.
- Une fonctionnalité n'importe pas l'intérieur d'une autre : elle passe par
  `core/`, `shared/` ou un port.
- Les cas d'usage renvoient `Result<T, Failure>` — pas d'exception métier.
- Changer de fournisseur (stockage, audio, API) = un nouvel adaptateur.

### Données et réseau

- **Aucun** secret, URL ou identifiant en dur : tout passe par
  `--dart-define-from-file=config/<env>.json` (seuls les `.example` sont versionnés).
- Erreur d'API = Problem Details (RFC 7807) → `Failure` avec le `code` stable
  du backend ; l'interface choisit son message par code.
- Hors ligne d'abord : un livre téléchargé se lit sans réseau ; position et
  marque-pages s'écrivent localement puis se synchronisent (« le plus récent
  gagne », instant de l'appareil).
- Jeton de session dans `flutter_secure_storage`, jamais ailleurs.

### Interface et accessibilité ([design system](../doc-projet/design_market_stich_voxlivre/DESIGN.md))

- Couleurs, typos, rayons, espacements **uniquement** par les jetons du thème
  (`shared/design/`) — jamais de couleur en dur dans un widget.
- Zones tactiles ≥ 48 dp ; texte ≥ 14 ; contraste AA ; `Semantics` sur tout
  bouton-icône ; un état n'est jamais porté par la couleur seule.
- « Réduire les animations » du système respecté (`MediaQuery.disableAnimationsOf`).
- Textes en **français** ; les données des maquettes Stitch sont fictives.

### Journaux et données personnelles

- Jamais `print` : passer par le logger de l'app.
- Aucune donnée personnelle dans les journaux (numéro, e-mail, code, jeton,
  texte des documents, notes).

### Tests ([testing.md](docs/code-engineering/testing.md))

- `domain/` + `application/` : tests unitaires, sans Flutter.
- `presentation/` : tests de widgets, ports remplacés par des faux (overrides Riverpod).
- `test/architecture/` : règle des dépendances.
- La couverture minimale ne baisse jamais.

## Choses à NE PAS faire

- Commit sans scope (`feat:` au lieu de `feat(player):`)
- `--no-verify` sans raison écrite
- Désactiver une règle de lint sans commentaire d'invariant
- Logique métier dans un widget (l'extraire en cas d'usage)
- Importer Flutter, dio ou drift dans `domain/`
- Ajouter une dépendance « au cas où » (elle arrive avec la fonctionnalité qui l'utilise)

## Workflow

- **Conventional Commits** avec **scope obligatoire**, en anglais, header ≤ 100 caractères.
- Hooks : pre-commit (format + analyse), commit-msg (format du message).
- Décision d'architecture → ADR dans `docs/adr/` **avant** le code.
- Un commit = un sujet.

## Pour les agents IA

- Lire ce fichier avant tout changement non trivial.
- En cas de doute, ouvrir `docs/code-engineering/` plutôt que deviner.
- N'inventer aucun pattern non documenté : proposer un ADR.

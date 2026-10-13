# 0001. Architecture hexagonale par fonctionnalité, règle vérifiée par un test

- Statut : accepted
- Date : 2026-10-12

## Contexte

- Le backend est hexagonal (ports et adaptateurs, ESLint qui casse le build
  si `domain/` importe une bibliothèque technique). Le mobile parle le même
  langage métier (documents, conversions, marque-pages, unités).
- Le mobile change souvent de technique : stockage hors ligne, lecteur
  audio, client HTTP, voire passage à iOS. Le métier (règles de
  synchronisation, calcul de l'index d'un mot, coût en unités) ne doit pas en
  dépendre.

## Options

1. **Par couche** (`lib/models`, `lib/screens`, `lib/services`) : simple au
   début, illisible à 30 écrans, rien n'empêche un écran d'appeler l'API.
2. **Clean architecture par fonctionnalité**, 4 couches, règle vérifiée.
3. Paquets Dart séparés par couche (monorepo melos) : isolation forte,
   lourde pour une personne.

## Décision

**Option 2.** `lib/src/features/<fonctionnalité>/{domain,application,infrastructure,presentation}`,
plus `core/` (Dart pur), `shared/` (design system, réseau, stockage) et
`app/` (bootstrap, routeur, providers racine).

| Couche | Peut importer | Ne peut pas importer |
|---|---|---|
| `domain` | `core/`, son propre `domain` | Flutter, Riverpod, dio, drift, tout autre dossier |
| `application` | `domain`, `core/` | `infrastructure`, `presentation`, Flutter |
| `infrastructure` | `domain`, `application`, `core/`, `shared/` | `presentation` |
| `presentation` | `application`, `domain`, `core/`, `shared/`, le fichier de composition | `infrastructure` (passe par les providers) |
| composition (`<f>_providers.dart`, à la racine de la fonctionnalité) | toutes les couches de sa fonctionnalité, `core/`, `shared/` | — ; importé **seulement** par `presentation` (ADR-0002) |

Une fonctionnalité n'importe pas l'intérieur d'une autre. La règle est
vérifiée par `test/architecture/dependency_rule_test.dart`, qui lit les
imports de chaque fichier : la CI casse.

## Conséquences

- Un test plutôt qu'un plugin de lint : aucune dépendance, message clair,
  même effet bloquant qu'ESLint côté backend.
- Les ports sont des `abstract interface class` ; les adaptateurs les
  implémentent dans `infrastructure/`.

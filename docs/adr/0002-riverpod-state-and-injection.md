# 0002. Riverpod pour l'état et l'injection des dépendances

- Statut : accepted
- Date : 2026-10-12

## Contexte

L'architecture hexagonale (ADR-0001) suppose que les cas d'usage reçoivent
leurs ports de l'extérieur, et que les tests remplacent les adaptateurs par
des faux (comme `overrideProvider` dans les e2e du backend).

## Options

1. **Riverpod** : état réactif + conteneur de dépendances ; `ProviderScope(overrides: …)`
   dans les tests ; pas de `BuildContext` nécessaire.
2. **Bloc + get_it** : deux outils (état et injection), localisateur global.
3. `provider` + `ChangeNotifier` : simple, mais injection et tests moins nets.

## Décision

**Riverpod.** Un provider par port (il rend l'adaptateur), un provider par cas
d'usage (il reçoit ses ports par `ref.watch`), des contrôleurs d'état pour
la présentation. Aucun localisateur global.

Les providers des ports et des cas d'usage d'une fonctionnalité sont
déclarés dans **un fichier de composition** à sa racine,
`features/<f>/<f>_providers.dart` — l'équivalent du `*.module.ts` de Nest,
qui relie chaque port à son adaptateur. C'est le seul fichier de la
fonctionnalité qui voit toutes ses couches ; seul `presentation/` l'importe.

Pourquoi pas dans les couches : `domain/` et `application/` restent sans
Riverpod (Dart pur, testables sans Flutter), et `presentation/` n'a pas le
droit d'importer `infrastructure/` (ADR-0001), donc ne peut pas atteindre un
provider déclaré là.

## Conséquences

- Les tests de widgets remplacent un port par un faux en une ligne.
- Le câblage d'une fonctionnalité se lit en un seul fichier.
- `test/architecture/` refuse qu'une couche autre que `presentation/`
  importe le fichier de composition.
- Les providers transverses (configuration, routeur, client HTTP) vivent dans
  `app/` ou `shared/`.

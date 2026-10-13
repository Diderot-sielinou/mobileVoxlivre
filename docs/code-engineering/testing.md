# Tests

| Niveau | Où | Outils | Ce qu'on vérifie |
|---|---|---|---|
| Unitaire | `test/src/**/domain`, `…/application`, `core` | `flutter_test`, faux écrits à la main | règles métier, cas d'usage, sans Flutter ni réseau |
| Adaptateur | `test/src/**/infrastructure` | faux client HTTP, base drift en mémoire | traduction réponse/erreur → domaine |
| Widget | `test/src/**/presentation` | `flutter_test`, `ProviderScope(overrides:)` | écran, états, accessibilité (`Semantics`) |
| Architecture | `test/architecture/` | lecture des imports | règle des dépendances (ADR-0001) |
| Intégration | `integration_test/` (plus tard) | appareil ou émulateur | parcours complets |

- Les tests reprennent l'arborescence de `lib/` (`lib/src/core/result.dart`
  → `test/src/core/result_test.dart`).
- Un faux par port, partagé dans `test/support/` quand plusieurs tests s'en servent.
- Accessibilité : les tests de widgets d'un écran passent
  `meetsGuideline(androidTapTargetGuideline)`, `labeledTapTargetGuideline`
  et `textContrastGuideline` ; les contrastes des jetons sont vérifiés par
  `test/src/shared/design/vox_theme_test.dart`.
- Configuration : les tests n'ont pas de `--dart-define` ; ils fournissent
  `appConfigProvider` par override.
- Couverture : `flutter test --coverage` ; le seuil plancher ne baisse jamais.

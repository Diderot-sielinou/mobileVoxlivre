# Ajouter une fonctionnalité (architecture hexagonale, ADR-0001)

## Recette

```
lib/src/features/<fonctionnalité>/
  <fonctionnalité>_providers.dart   composition : port → adaptateur, cas d'usage (ADR-0002)
  domain/
    <entite>.dart              entité ou objet valeur, Dart pur (freezed autorisé)
    <nom>_repository.dart      port : abstract interface class
  application/
    <verbe>_<objet>.dart       un cas d'usage = une classe, une méthode `call`
  infrastructure/
    <source>_<nom>_repository.dart   adaptateur (API dio, drift…)
  presentation/
    <ecran>_screen.dart        écran
    <ecran>_controller.dart    état de l'écran (Notifier Riverpod)
    widgets/
```

1. **Le port d'abord**, dans `domain/` : ce dont le métier a besoin, dans le
   vocabulaire du métier (`BookmarkRepository.save(bookmark)`), pas celui
   de la technique (`postJson`).
2. **Le cas d'usage** dans `application/` : reçoit ses ports au constructeur,
   renvoie `Result<T, Failure>`.
3. **L'adaptateur** dans `infrastructure/` : implémente le port, traduit les
   erreurs techniques en `Failure` (un `DioException` ne sort jamais de cette couche).
4. **Les providers**, dans le fichier de composition : un par port (il rend
   l'adaptateur), un par cas d'usage (il lit ses ports par `ref.watch`).
   Les tests remplacent le provider du port par un faux.
5. **L'écran** : un contrôleur appelle le cas d'usage ; le widget affiche
   l'état et n'a aucune règle métier.

## Règle des dépendances

`domain` ← `application` ← `infrastructure` / `presentation` ; le fichier
de composition voit tout et n'est importé que par `presentation` ; `core/` ne
dépend de rien ; une fonctionnalité n'importe pas l'intérieur d'une autre.
Vérifié par `test/architecture/dependency_rule_test.dart`.

## Erreurs

- Échec attendu (réseau absent, code faux, quota) : `Result.err(Failure)`.
- Bug (invariant violé) : exception, qui remonte jusqu'au gestionnaire global.

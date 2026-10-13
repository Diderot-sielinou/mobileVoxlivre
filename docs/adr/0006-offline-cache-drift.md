# 0006. Cache hors ligne en drift, une base par fonctionnalité

- Statut : accepted
- Date : 2026-10-13

## Contexte

Hors ligne d'abord (AGENTS.md) : la bibliothèque doit s'afficher sans
réseau, et viendront ensuite les positions de lecture, les marque-pages et
les téléchargements (écrits localement, synchronisés « le plus récent
gagne »). La décision D7 retient drift (SQLite). Le backend renvoie la
bibliothèque par pages (`GET /v1/library`, ADR-0015 du backend), triée par
date d'import ; un compte n'a que quelques dizaines de livres. La data est
chère et le réseau lent.

## Décision

- **Une base drift par fonctionnalité** (`library.sqlite`, puis d'autres),
  déclarée dans son `infrastructure/`. Une base commune dans `shared/`
  devrait connaître les tables de toutes les fonctionnalités, ce que la
  règle des dépendances interdit (ADR-0001) ; chaque fonctionnalité garde
  ses migrations.
- **L'écran lit toujours le cache** (un flux) ; le réseau ne fait que le
  rafraîchir. Un rafraîchissement lit toutes les pages (`limit=50`) puis
  **remplace** le cache en une transaction : un livre supprimé ailleurs
  disparaît. Le JSON de l'API est gardé tel quel (une ligne par livre) et
  décodé par le même code que la réponse réseau.
- **Quand rafraîchir** : à l'ouverture de l'onglet si le dernier
  rafraîchissement date de plus de 2 min, au geste « tirer pour
  rafraîchir », après la connexion ; toutes les 15 s tant qu'un livre est
  en préparation **et** que l'onglet est visible. Jamais en tâche de fond.
- **Confidentialité** : le cache est effacé à la fermeture de la session
  (déconnexion ou session refusée). `app/` relie la session au nettoyage :
  une fonctionnalité n'importe pas une autre.
- **États** : sans cache, squelettes pendant le chargement ; avec cache et
  sans réseau, les livres restent affichés avec un bandeau « Hors ligne »
  et l'heure de la dernière mise à jour.

## Conséquences

- Dépendances : `drift`, `drift_flutter` (SQLite embarqué), `drift_dev`
  (génération). Les tests utilisent une base en mémoire.
- Le tri par activité et les filtres se font sur l'appareil.
- Un compte très volumineux demanderait une synchronisation incrémentale
  (nouvelle ADR).

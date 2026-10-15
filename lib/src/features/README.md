# Fonctionnalités

Une fonctionnalité = un dossier, quatre couches (ADR-0001, recette :
`docs/code-engineering/hexagonal-guide.md`). Chaque dossier est créé avec
son premier écran, jamais vide « au cas où ».

| Fonctionnalité | Module backend | Écrans (maquettes Stitch) |
|---|---|---|
| `auth` | `identity` (OTP téléphone / e-mail) | splash, onboarding, connexion, code |
| `library` | `library` + `document` (ADR-0007) | bibliothèque, états, import, envoi, fiche, vérification du texte, table des matières |
| `conversion` | `conversion` | choix de la voix, coût, conversion en cours |
| `player` | `conversion` (manifeste, WebVTT) + `library` (position, marque-pages) | lecteur, feuilles, livre terminé |
| `billing` | `billing`, `payment` | unités & offres, paiement Mobile Money, historique |
| `account` | `identity` (suppression, ADR-0023) | profil, stockage, suppression du compte |
| `stats` | — (calculées sur l'appareil) | statistiques |

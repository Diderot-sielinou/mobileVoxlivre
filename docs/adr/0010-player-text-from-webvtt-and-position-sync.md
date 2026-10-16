# 0010. Lecteur : texte tiré du WebVTT, audio par parties, position « le plus récent gagne »

- Statut : accepted
- Date : 2026-10-15

## Contexte

Une conversion produit des **parties** (ADR-0011 du backend) : la 1ʳᵉ ≈ 2 min
(aperçu), puis ≈ 10 min ; chacune a un MP3 et un WebVTT **au mot** (un
repère par mot, identifiant = index global du mot, instants relatifs à la
partie). `GET /v1/conversions/:id/manifest` les décrit, avec des URL signées
valables 1 h, **dès la première partie** (`complete: false`). La position de
lecture se lit et s'écrit par `GET/PUT /v1/conversions/:id/position`
(`wordIndex`, `audioMs`, `recordedAt` de l'appareil ; le serveur garde la
plus récente, `applied: false` sinon). Hors ligne d'abord (AGENTS.md).

## Décision

- Fonctionnalité `features/player/`, ouverte par la route
  (`…/conversions/:conversionId/listen?title=…`, comme l'ADR-0008).
- **Le texte affiché vient des repères WebVTT**, pas de l'API des pages :
  c'est exactement le texte lu, aligné mot pour mot sur l'audio, même si le
  document a été corrigé depuis. Pages tirées de `pageStarts` du manifeste.
- **Audio** : `just_audio` (parties enchaînées sans coupure, vitesse
  0,5×–2×) et `just_audio_background` (notification, écran verrouillé,
  lecture écran éteint ; il s'appuie sur `audio_service`, D13). Derrière un
  port `AudioEngine` : changer de moteur = un nouvel adaptateur.
- Instant **absolu** dans le livre = début de la partie + instant dans la
  partie ; le mot courant est trouvé par recherche dichotomique.
- **Aperçu** : une conversion en cours se lit déjà ; le manifeste est relu
  toutes les 30 s et les parties prêtes s'ajoutent à la file. Le manifeste
  est aussi relu avant l'expiration de ses URL.
- **Position** : écrite en local (drift, `player.sqlite`) toutes les 5 s et
  à chaque pause, puis envoyée ; à l'ouverture, **la plus récente gagne**
  entre locale et serveur (instant de l'appareil). Effacée à la déconnexion.
- **Fin du livre** : `just_audio` reste « en lecture » à l'état terminé ;
  le lecteur se met donc en pause lui-même (une seule sauvegarde, à la
  fin), et « Lecture » reprend alors du début.
- Le lecteur s'ouvre **plein écran**, au-dessus de la barre d'onglets.
- Manifeste de version inconnue : refusé (« mettez l'application à jour »).

## Conséquences

- Nouvelles dépendances : `just_audio`, `just_audio_background` ; Android :
  service au premier plan `mediaPlayback`, `MainActivity` hérite de
  `AudioServiceActivity`.
- Le téléchargement pour l'écoute hors ligne (15b) réutilisera le même
  manifeste et vérifiera les SHA-256.
- Limite connue : en fin de livre, « Lecture » depuis la notification ne
  relance pas le livre (seul le bouton de l'application le fait) — à
  reprendre avec les compléments du lecteur (15c).

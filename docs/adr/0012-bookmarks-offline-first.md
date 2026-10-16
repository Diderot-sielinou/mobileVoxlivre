# 0012. Marque-pages : créés sur l'appareil, envoyés ensuite, fusionnés un par un

- Statut : accepted
- Date : 2026-10-16

## Contexte

Le backend (ADR-0028 du backend) range les marque-pages **par document**,
ancrés au texte : page, index du mot dans la page, extrait, note (≤ 2 000
caractères). L'identifiant (UUID) est créé par l'appareil ; `PUT` crée ou
met à jour la note ; `DELETE …?deletedAt=` laisse une trace ; « le plus
récent gagne » s'applique **marque-page par marque-page** selon l'instant de
l'appareil. Un marque-page dont le texte a changé revient avec
`needsReview: true` ; il n'est jamais supprimé pour cela. AGENTS.md : tout
s'écrit d'abord sur l'appareil, puis se synchronise.

## Décision

- **Dans `features/player/`** : seul le lecteur s'en sert, et il a le
  manifeste (`pageStarts`) qui relie l'ancrage au mot de la conversion.
  Port `BookmarkStore` (appareil), méthodes ajoutées à `PlayerGateway`,
  cas d'usage `AddBookmark`, `EditBookmark`, `DeleteBookmark`,
  `SyncBookmarks`.
- **Sur l'appareil d'abord** : table `bookmarks` de `player.sqlite` (v3).
  Chaque marque-page a son identifiant UUID v4 (créé sur l'appareil),
  l'ancrage, l'extrait, la note, `updatedAt`, `deletedAt` et `pending`
  (« à envoyer »). L'extrait (6 mots à partir de l'ancrage) est calculé sur
  l'appareil ; celui du serveur le remplace à la synchronisation.
- **Suppression** : la ligne reste comme trace (`deletedAt`, `pending`)
  jusqu'au `DELETE` réussi, puis elle part.
- **Synchronisation** (à l'ouverture d'un livre, au démarrage, comme les
  positions, ADR-0011) : 1) envoi des lignes « à envoyer » (`PUT` ou
  `DELETE`), la réponse du `PUT` fait foi (une suppression plus récente
  ailleurs retire la ligne) ; 2) `GET` du document ouvert : une ligne
  encore « à envoyer » est gardée ; les autres prennent la valeur du
  serveur ; une ligne absente du serveur (supprimée ailleurs) part. Réseau
  absent : arrêt, rien n'est perdu.
- **Refus définitif** (422, 409 sauf réseau/429/5xx) : la ligne n'est plus
  « à envoyer » et la fusion suivante l'aligne sur le serveur. L'interface
  évite ces cas : note limitée à 2 000 caractères, ancrage tiré du
  manifeste, 500 marque-pages au plus par document.
- **Placement dans le lecteur** : index global = `pageStarts[page] +
  wordIndex` ; un marque-page dont la partie n'est pas encore prête
  (aperçu) s'affiche sans minutage et ne se rejoint pas.
- **Effacés à la déconnexion**, comme les positions.

## Conséquences

- Dépendance directe : `uuid` (déjà présente indirectement).
- Pas de synchronisation incrémentale (`since`, hors périmètre du
  backend) : un `GET` par livre ouvert.
- Les « thématiques rapides » et l'extrait « ▶ 15 s » de la maquette sont
  retirés (validé par le porteur le 2026-10-16) : aucune donnée côté
  backend.

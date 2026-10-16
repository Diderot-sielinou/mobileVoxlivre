# 0011. Livres hors ligne : téléchargement vérifié, positions à envoyer

- Statut : accepted
- Date : 2026-10-16

## Contexte

Le lecteur (ADR-0010) lit en ligne. AGENTS.md exige qu'un livre téléchargé
se lise **sans réseau** et que la position s'écrive localement puis se
synchronise. Le manifeste donne, pour chaque fichier d'une partie (MP3,
WebVTT), sa taille et son **SHA-256** ; ses URL signées valent 1 h. Le
serveur accepte une position envoyée en retard : la plus récente selon
`recordedAt` (instant de l'appareil) gagne. Réseau instable, data chère :
rien ne se télécharge sans que l'utilisateur le demande.

## Décision

- **Dans `features/player/`** (le manifeste y est déjà) : port `BookFiles`
  (fichiers d'un livre sur l'appareil), cas d'usage `DownloadBook`,
  `RemoveDownload`, `ClearDownloads`, `FlushPositions`.
- **Seulement un livre entièrement converti**, à la demande. Fichiers dans
  le dossier de l'app : `books/<conversionId>/part-<i>.mp3|.vtt` ; le
  manifeste (sans URL) et les parties vérifiées dans `player.sqlite` (v2).
- **Vérification** : SHA-256 de chaque fichier comparé au manifeste ; écart
  = fichier jeté, partie retéléchargée. Une partie n'est notée « vérifiée »
  qu'avec ses deux fichiers justes.
- **Reprise** : les parties vérifiées restent ; seules les manquantes
  repartent (même idée que l'ADR-0009). URL expirées (403) : le manifeste
  est relu une fois et le téléchargement reprend. Annuler garde ce qui est
  vérifié.
- **Lecture** : livre téléchargé = manifeste, texte et audio lus sur
  l'appareil (`file://`), aucun appel réseau nécessaire ; sinon, en ligne
  comme l'ADR-0010.
- **Positions** : écrites localement **« à envoyer »**, marquées envoyées
  après un `PUT` réussi ; les restantes partent à l'ouverture d'un livre et
  au démarrage de la session.
- **Effacement** : l'audio d'un livre se supprime de la fiche (menu ⋮,
  confirmation) ; il est aussi effacé à la suppression du document et à la
  déconnexion.
- **Entre fonctionnalités** : la bibliothèque n'importe pas le lecteur. Le
  routeur (`app/`) lui passe la carte « hors ligne » de la fiche, l'ensemble
  des livres téléchargés et les actions (comme `onListen`, ADR-0008).

### Placement (UX)

- Fiche : « Écouter » reste **l'unique bouton principal**, en bas (zone du
  pouce). Le téléchargement est une **carte** dans le contenu, sous la
  ligne de conversion : le texte sur toute la largeur, puis une rangée de
  48 dp (barre + bouton secondaire) — rien ne s'écrase sur un écran de
  360 dp, et la carte garde sa taille jusqu'à la fin : « Écouter sans
  connexion · 12,4 Mo à télécharger » + « Télécharger » → « Partie 3 sur 9
  · 4,1 Mo sur 12,4 Mo » + « Annuler » → « Connexion perdue » +
  « Reprendre » → « Disponible hors ligne » (icône + texte, sans rangée).
- Bibliothèque : badge icône + « Hors ligne » sur la carte d'un livre
  téléchargé (jamais la couleur seule). Réseau absent (échec du
  rafraîchissement) : bandeau « Hors ligne — vos livres téléchargés restent
  disponibles », annoncé poliment ; livres non téléchargés atténués, non
  cliquables, « Nécessite une connexion ».

## Conséquences

- Dépendance directe : `crypto` (SHA-256), déjà présente indirectement.
- Reporté au Profil (fonctionnalité `account`) : écran « Stockage hors
  ligne » et réglage « Seulement en Wi-Fi » (détection du type de réseau).
- La place prise est visible (taille sur la carte) ; aucun plafond pour
  l'instant.

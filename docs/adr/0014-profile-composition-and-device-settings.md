# 0014. Profil : écran composé par le routeur, réglages de l'appareil partagés

- Statut : accepted
- Date : 2026-10-16

## Contexte

L'onglet Profil rassemble des morceaux de plusieurs fonctionnalités :
l'identité (auth), le solde et l'historique des unités (payment), le
stockage hors ligne (player), la voix par défaut (conversion), la vitesse
(player). Une fonctionnalité n'importe pas l'intérieur d'une autre
(ADR-0001). Le backend n'a **pas** de préférences de compte. ADR-0011 a
reporté au Profil l'écran de stockage et « seulement en Wi-Fi ». Les
adresses (pages légales, contact) ne s'écrivent pas en dur (AGENTS.md).

## Décision

- **`features/account/`** porte l'écran Profil : une mise en page à
  emplacements (en-tête, carte des unités, réglages de lecture, stockage)
  plus ce qui lui est propre (aide, pages légales, version, déconnexion).
  **Le routeur** (`app/`) remplit les emplacements avec les widgets publics
  des autres fonctionnalités (comme `OfflineCard`, ADR-0011) et leur donne
  les recherches dont ils ont besoin (titre d'un livre par conversion, lu
  dans la bibliothèque).
- **Écrans rattachés** : historique des unités dans `payment`
  (`GET /v1/billing/wallet/entries`, curseur), stockage hors ligne dans
  `player`. Routes sous `/profile`.
- **Réglages de l'appareil** dans `shared/settings/` : port `DeviceSettings`
  (voix par défaut, vitesse, « seulement en Wi-Fi », activé par défaut),
  adaptateur `shared_preferences`. Ce sont des préférences de l'appareil, pas
  du compte : ils ne suivent pas l'utilisateur sur un autre téléphone, et
  restent après la déconnexion (aucune donnée personnelle).
- **Réseau** dans `shared/network/` : port `NetworkKind` (Wi-Fi, mobile,
  aucun) sur `connectivity_plus`. « Seulement en Wi-Fi » ne bloque pas : en
  données mobiles, « Télécharger » demande confirmation, avec la taille.
- **Configuration** : `SITE_URL` (pages `/conditions`, `/confidentialite`)
  et `SUPPORT_EMAIL`, facultatifs ; absents, les liens ne s'affichent pas.
  Ouverts par `url_launcher` ; version de l'APK par `package_info_plus`.
- **Suppression du compte** : étape suivante (17b), ADR à part si besoin.

## Conséquences

- Dépendances : `connectivity_plus`, `url_launcher`, `package_info_plus`
  (validé par le porteur le 2026-10-16) ; `<queries>` Android pour
  `https` et `mailto`.
- Les liens légaux de l'écran de connexion deviennent cliquables par la
  même configuration.
- Pas de réglage « Notifications » ni d'aide WhatsApp : aucune source.

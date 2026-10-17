# 0015. Connexion Google par ID token, clé de signature de version

- Statut : accepted
- Date : 2026-10-17

## Contexte

La première version doit être essayée par de vrais utilisateurs, avec un
APK envoyé directement (WhatsApp, lien). Aucun code ne leur arrive : SES
est en bac à sable, le SMS Orange n'est pas ouvert. Le backend accepte
désormais un ID token Google (ADR-0030 du backend) et crédite chaque
nouveau compte de 220 000 unités (offre `welcome`, hors catalogue).

Google n'accepte un ID token que pour une app connue de lui : nom du
paquet **et** empreinte SHA-1 de la clé qui signe l'APK. Jusqu'ici la
version était signée avec la clé de débogage de la machine.

## Décision

1. **Port `GoogleAccount`** (domaine `auth`) : rend un ID token, ou un
   échec `GOOGLE_SIGN_IN_CANCELLED` / `GOOGLE_SIGN_IN_UNAVAILABLE` ; oublie
   le compte choisi. Adaptateur `SdkGoogleAccount` sur `google_sign_in` 7
   (Credential Manager d'Android), avec le client OAuth **Web** en
   `serverClientId` : c'est l'audience que le backend vérifie. Les clients
   OAuth Android (paquet + SHA-1) ne servent qu'à Google, l'app ne les
   connaît pas.
2. **Cas d'usage `SignInWithGoogle`** : choix du compte →
   `POST /api/auth/sign-in/social` `{provider: google, idToken: {token}}`
   → même jeton signé `set-auth-token` que pour un code (ADR-0005) →
   compte chargé. Un jeton refusé fait oublier le compte (le prochain essai
   redemande lequel) ; fermer le choix du compte n'affiche rien. La
   déconnexion oublie aussi le compte Google.
3. **Configuration** : `GOOGLE_SERVER_CLIENT_ID` dans
   `config/<env>.json` (identifiant public, pas un secret) ; absent, le
   bouton Google n'apparaît pas. `auth` ne lit pas `app/` (ADR-0001) : le
   bootstrap fournit la valeur par `googleServerClientIdProvider`.
4. **Écran de connexion** : « Continuer avec Google » en premier, avec le
   logo officiel (`assets/images/google_g.png`, téléchargé chez Google), et
   « Recommandé : la réception d'un code par SMS ou par e-mail n'est pas
   encore ouverte à tous ». Téléphone et e-mail restent proposés en
   dessous. Le bandeau d'erreur est placé juste au-dessus du choix du code,
   près des actions, pour rester visible sur un petit écran.
5. **Clé de version** : un keystore PKCS12 (RSA 2048, 10 000 jours) **hors
   du dépôt** (`~/.voxlivre/`), décrit par `android/key.properties`
   (ignoré par git). `build.gradle.kts` signe la version avec elle si le
   fichier existe, sinon avec la clé de débogage (CI, autre machine). Ses
   SHA-1 et celui de la clé de débogage sont déclarés chez Google.
6. **Historique des unités** : l'achat `welcome` s'affiche « Crédits
   offerts ».

## Conséquences

- Les testeurs se connectent sans SMS ni e-mail ; Google Play Services est
  requis (présent sur les téléphones visés).
- **La clé de version ne doit jamais être perdue** : sans elle, un APK mis
  à jour ne s'installe plus par-dessus l'ancien (désinstaller efface les
  livres téléchargés) et la connexion Google cesse de marcher. Le porteur
  en garde une copie hors de la machine.
- Une publication sur le Play Store ajoutera la clé de signature de Google
  Play : une empreinte SHA-1 de plus à déclarer, aucun code à changer.
- L'APK de la CI (clé de débogage d'une autre machine) n'a pas Google.

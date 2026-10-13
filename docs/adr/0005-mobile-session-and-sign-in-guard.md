# 0005. Session mobile, garde de connexion et premier lancement

- Statut : accepted
- Date : 2026-10-13

## Contexte

Le backend authentifie par code à usage unique (better-auth, ADR-0004 du
backend) : code à 6 chiffres, 5 min, 3 essais, 5 demandes / 10 min / IP,
mobiles camerounais seulement. Après validation, le jeton de session
**signé** arrive dans l'en-tête `set-auth-token` (celui du corps n'est pas
accepté : `requireSignature`), à renvoyer en `Authorization: Bearer`. La
session dure 30 jours. Les erreurs de better-auth ne sont pas des Problem
Details mais `{ "message", "code" }`. L'app doit fonctionner hors ligne :
un livre téléchargé se lit sans réseau.

## Décision

- **Jeton** : dans `flutter_secure_storage` (Keystore Android), seule donnée
  stockée. Lu **une fois** avant le premier écran (le splash natif reste
  affiché), puis gardé en mémoire dans `AuthSession` (`features/auth/application`).
- **`ApiClient`** (ADR-0004) reçoit une `AuthTokenSource`
  (`shared/http/`) : il ajoute le bearer quand un jeton existe et la
  prévient d'un **401 sur une requête qui portait un jeton**. L'adaptateur
  est fourni par auth et branché par `app/` : `shared` ne connaît pas auth.
  Le décodeur reçoit aussi les en-têtes de la réponse (`set-auth-token`) ;
  `message` sert de repli à `detail` (format better-auth).
- **Démarrage hors ligne d'abord** : avec un jeton, l'app ouvre
  directement la Bibliothèque et lit `/v1/me` en arrière-plan. Un 401
  déconnecte (jeton effacé) ; une coupure réseau **garde connecté**.
- **Déconnexion** : `POST /api/auth/sign-out` sans attendre la réponse, puis
  effacement local **toujours** (même hors ligne).
- **Garde go_router** (`redirect`, rafraîchie à chaque changement d'état) :
  premier lancement sans session → onboarding ; sans session → connexion ;
  avec session sur la connexion ou l'onboarding → Bibliothèque.
- **Onboarding vu** : un booléen dans `shared_preferences` (pas une donnée
  sensible), lu avant le premier écran comme le jeton.
- Validation locale du numéro (`6` + 8 chiffres, `+237` ajouté) et de
  l'adresse avant tout appel : pas de requête vouée au refus.
- Saisie du code : un seul champ affiché en 6 cases, clavier du système,
  collage et `AutofillHints.oneTimeCode` (WCAG 2.2 « authentification
  accessible »), validation au 6ᵉ chiffre.

## Conséquences

- Les fonctionnalités appellent l'API sans s'occuper du jeton.
- Une session expirée ou supprimée ailleurs ramène à la connexion au
  premier appel refusé, sans écran d'erreur.
- Hors périmètre : connexion Google (absente du backend), lecture
  automatique du SMS (SMS Retriever : hash de l'app à ajouter au SMS côté
  backend).

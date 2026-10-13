# 0004. Client HTTP et erreurs d'API

- Statut : accepted
- Date : 2026-10-13

## Contexte

Toutes les fonctionnalités (auth, bibliothèque, import, lecteur…) appellent
`voxlivre-api`. Le backend renvoie ses erreurs en Problem Details
(RFC 7807, `application/problem+json`) : `status`, `detail`, `code` stable
pour une erreur métier (absent pour une erreur de validation Nest),
`details`, `requestId`. Il reprend l'en-tête `x-request-id` envoyé par le
client, sinon il en génère un. Réseau visé : lent, coupé souvent, data chère.

## Décision

- **Un seul client** : `ApiClient` dans `shared/http/`, au-dessus de dio.
  `get` / `post` / `patch` / `delete` renvoient
  `Future<Result<T, ApiFailure>>` avec un décodeur `T Function(Object? json)`.
  Aucune exception ne sort du client ; dio n'est importé que dans
  `shared/http/`.
- **`ApiFailure`** (sous-classe de `Failure`) : `status`, `code`, `details`,
  `requestId`. Le `code` est toujours présent :
  - celui du Problem Details quand le backend en donne un ;
  - sinon déduit du statut, avec le vocabulaire du backend (`error-status.ts`) :
    400 `BAD_REQUEST`, 401 `UNAUTHORIZED`,
    403 `FORBIDDEN`, 404 `NOT_FOUND`, 409 `CONFLICT`, 413
    `PAYLOAD_TOO_LARGE`, 429 `RATE_LIMITED`, 5xx `SERVER_ERROR`, autre
    `HTTP_ERROR` ;
  - sans réponse : `NETWORK_UNAVAILABLE`, `TIMEOUT`, `CANCELLED` ;
    réponse illisible : `UNEXPECTED_RESPONSE`.
- **`x-request-id`** : UUID v4 généré par le client pour chaque requête
  (`Random.secure`), repris dans l'`ApiFailure` et le journal.
- **Délais** : connexion 15 s, réception 30 s, envoi 60 s. **Aucun nouvel
  essai automatique** : rejouer un `POST` peut doubler un débit ; chaque
  fonctionnalité décidera de ses nouveaux essais.
- **Journal** : paquet `logging`, relié à `debugPrint` en debug (visible dans
  le terminal de `flutter run`, `dart:developer` ne l'est pas), muet en
  release. Une ligne par requête : méthode, chemin **sans paramètres**,
  statut ou code, durée, `requestId`. Jamais de corps ni d'en-tête.
- Le jeton de session (bearer) et la réaction au 401 arrivent avec l'auth.
- L'environnement `dev` vise l'API de production : un ajustement du backend
  se fait en local, se déploie, puis se vérifie depuis le téléphone.

## Conséquences

- Les adaptateurs `infrastructure/` d'une fonctionnalité reçoivent un
  `ApiClient` et n'écrivent que le décodage de leurs réponses.
- L'interface choisit son message par `code` ; le `requestId` peut être
  montré au support.
- Tester un adaptateur : un faux `HttpClientAdapter` dio, sans réseau.

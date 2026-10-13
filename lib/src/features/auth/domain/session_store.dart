/// Stockage sûr du jeton de session, seule donnée gardée (ADR-0005).
abstract interface class SessionStore {
  /// Le jeton enregistré, ou `null`.
  Future<String?> read();

  /// Enregistre [token] à la place du précédent.
  Future<void> write(String token);

  /// Efface le jeton.
  Future<void> clear();
}

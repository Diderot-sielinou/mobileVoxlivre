import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:voxlivre/src/features/auth/domain/session_store.dart';

/// [SessionStore] dans le Keystore Android (`flutter_secure_storage`) : le
/// jeton n'est jamais ailleurs (AGENTS.md).
final class SecureSessionStore implements SessionStore {
  const SecureSessionStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const _key = 'session_token';

  /// Un Keystore illisible (sauvegarde restaurée sur un autre téléphone,
  /// clé invalidée) n'empêche pas de démarrer : la session est oubliée et
  /// l'utilisateur se reconnecte.
  @override
  Future<String?> read() async {
    try {
      return await _storage.read(key: _key);
    } on PlatformException {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } on PlatformException {
      // Rien à effacer de lisible : la session est déjà perdue.
    }
  }
}

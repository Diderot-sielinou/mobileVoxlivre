import 'dart:async';

import 'package:meta/meta.dart';
import 'package:voxlivre/src/features/auth/domain/current_user.dart';
import 'package:voxlivre/src/features/auth/domain/session_store.dart';

/// État de la session.
@immutable
sealed class SessionState {
  const SessionState();
}

/// Aucune session : connexion requise.
final class SignedOut extends SessionState {
  const SignedOut();
}

/// Session ouverte ; [user] est `null` tant que `/v1/me` n'a pas répondu
/// (démarrage hors ligne).
final class SignedIn extends SessionState {
  const SignedIn(this.token, [this.user]);

  final String token;
  final CurrentUser? user;
}

/// La session de l'app, en mémoire, recopiée dans le [SessionStore]
/// (ADR-0005). Seule source de vérité : le routeur et le client HTTP la
/// suivent.
final class AuthSession {
  /// Session restaurée à partir du jeton lu au démarrage ([token]).
  AuthSession(this._store, {String? token})
    : _state = token == null ? const SignedOut() : SignedIn(token);

  final SessionStore _store;
  final _changes = StreamController<SessionState>.broadcast();
  SessionState _state;

  /// État courant.
  SessionState get state => _state;

  /// Jeton courant, `null` sans session.
  String? get token => switch (_state) {
    SignedIn(:final token) => token,
    SignedOut() => null,
  };

  /// Chaque changement d'état.
  Stream<SessionState> get changes => _changes.stream;

  /// Ouvre la session avec [token] et l'enregistre.
  Future<void> open(String token) async {
    await _store.write(token);
    _set(SignedIn(token));
  }

  /// Complète la session ouverte avec le compte [user].
  void attachUser(CurrentUser user) {
    if (_state case SignedIn(:final token)) _set(SignedIn(token, user));
  }

  /// Ferme la session et efface le jeton.
  Future<void> close() async {
    if (_state is SignedOut) return;
    _set(const SignedOut());
    await _store.clear();
  }

  void _set(SessionState next) {
    _state = next;
    _changes.add(next);
  }
}

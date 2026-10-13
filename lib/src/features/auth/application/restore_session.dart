import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/domain/auth_gateway.dart';

/// Au démarrage, vérifie la session restaurée en arrière-plan (ADR-0005) :
/// un refus la ferme, une coupure réseau la garde (hors ligne d'abord).
final class RestoreSession {
  const RestoreSession(this._gateway, this._session);

  final AuthGateway _gateway;
  final AuthSession _session;

  Future<void> call() async {
    if (_session.state is SignedOut) return;
    switch (await _gateway.currentUser()) {
      case Ok(value: final user):
        _session.attachUser(user);
      case Err(:final error) when error.code == 'UNAUTHORIZED':
        await _session.close();
      case Err():
        // Hors ligne ou serveur indisponible : on reste connecté.
        break;
    }
  }
}

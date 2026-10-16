import 'dart:async';

import 'package:voxlivre/src/features/auth/application/auth_session.dart';

/// Fin de session (déconnexion ou jeton refusé) : les données du compte
/// quittent le téléphone (ADR-0006) — bibliothèque, positions de lecture…
/// C'est `app/` qui relie les fonctionnalités : auth ne les connaît pas.
StreamSubscription<SessionState> clearAccountDataOnSignOut(
  AuthSession session,
  List<Future<void> Function()> clears,
) => session.changes.listen((state) {
  if (state is SignedOut) {
    for (final clear in clears) {
      unawaited(clear());
    }
  }
});

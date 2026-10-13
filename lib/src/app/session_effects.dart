import 'dart:async';

import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/library/application/clear_library.dart';

/// Fin de session (déconnexion ou jeton refusé) : les données du compte
/// quittent le téléphone (ADR-0006). C'est `app/` qui relie les
/// fonctionnalités : auth ne connaît pas la bibliothèque.
StreamSubscription<SessionState> clearAccountDataOnSignOut(
  AuthSession session,
  ClearLibrary clearLibrary,
) => session.changes.listen((state) {
  if (state is SignedOut) unawaited(clearLibrary());
});

import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/library_snapshot.dart';

/// La bibliothèque, hors ligne d'abord (ADR-0006) : l'écran lit le cache,
/// le réseau le rafraîchit.
abstract interface class LibraryRepository {
  /// Le cache, puis chacune de ses mises à jour.
  Stream<LibrarySnapshot> watch();

  /// Instant du dernier rafraîchissement réussi, `null` s'il n'y en a pas.
  Future<DateTime?> lastRefresh();

  /// Relit toute la bibliothèque sur le réseau et remplace le cache.
  Future<Result<void, Failure>> refresh();

  /// Vide le cache (fin de session).
  Future<void> clear();
}

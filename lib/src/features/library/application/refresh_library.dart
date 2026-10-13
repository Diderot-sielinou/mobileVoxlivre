import 'package:voxlivre/src/core/clock.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/library_repository.dart';

/// Rafraîchit la bibliothèque, au plus une fois toutes les [freshness] sauf
/// demande explicite (geste « tirer pour rafraîchir ») : la data est chère
/// (ADR-0006).
final class RefreshLibrary {
  const RefreshLibrary(this._repository, this._clock);

  final LibraryRepository _repository;
  final Clock _clock;

  /// Âge maximal du cache avant un rafraîchissement automatique.
  static const freshness = Duration(minutes: 2);

  Future<Result<void, Failure>> call({bool force = false}) async {
    if (!force) {
      final last = await _repository.lastRefresh();
      if (last != null && _clock.now().difference(last) < freshness) {
        return const Result.ok(null);
      }
    }
    return _repository.refresh();
  }
}

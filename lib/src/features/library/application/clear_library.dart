import 'package:voxlivre/src/features/library/domain/library_repository.dart';

/// Vide la bibliothèque locale à la fin d'une session (ADR-0006) : un
/// téléphone partagé ne montre pas les livres du compte précédent.
final class ClearLibrary {
  const ClearLibrary(this._repository);

  final LibraryRepository _repository;

  Future<void> call() => _repository.clear();
}

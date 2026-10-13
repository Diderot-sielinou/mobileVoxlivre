import 'package:voxlivre/src/features/library/domain/library_repository.dart';
import 'package:voxlivre/src/features/library/domain/library_snapshot.dart';

/// La bibliothèque telle qu'en cache, puis à chaque mise à jour.
final class WatchLibrary {
  const WatchLibrary(this._repository);

  final LibraryRepository _repository;

  Stream<LibrarySnapshot> call() => _repository.watch();
}

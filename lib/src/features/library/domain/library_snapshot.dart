import 'package:meta/meta.dart';
import 'package:voxlivre/src/features/library/domain/library_item.dart';

/// Contenu du cache : les livres et l'instant de leur dernière mise à jour.
@immutable
final class LibrarySnapshot {
  const LibrarySnapshot({required this.items, this.refreshedAt});

  /// Cache vide, jamais rempli.
  static const empty = LibrarySnapshot(items: []);

  /// Livres, du plus récemment importé au plus ancien.
  final List<LibraryItem> items;

  /// `null` tant que le réseau n'a jamais répondu.
  final DateTime? refreshedAt;

  /// Le cache a déjà été rempli au moins une fois.
  bool get loaded => refreshedAt != null;
}

import 'package:voxlivre/src/features/library/domain/library_item.dart';

/// Filtres de la bibliothèque (puces de l'écran).
enum LibraryFilter {
  all,
  inProgress,
  ready,
  finished;

  bool matches(LibraryItem item) => switch (this) {
    all => true,
    inProgress => item.status == LibraryStatus.inProgress,
    ready => item.status == LibraryStatus.ready,
    finished => item.status == LibraryStatus.finished,
  };
}

/// Règles de rangement de la bibliothèque, sur l'appareil (ADR-0006).
abstract final class LibraryShelf {
  /// Livre à reprendre : celui « à reprendre » écouté le plus récemment.
  static LibraryItem? resume(List<LibraryItem> items) {
    LibraryItem? best;
    for (final item in items) {
      final at = item.position?.recordedAt;
      if (item.status != LibraryStatus.inProgress || at == null) continue;
      if (best == null || at.isAfter(best.position!.recordedAt)) best = item;
    }
    return best;
  }

  /// Un livre se prépare : l'écran se rafraîchit tant qu'il est visible.
  static bool hasWorkInProgress(List<LibraryItem> items) =>
      items.any((i) => i.status == LibraryStatus.processing);

  /// Nombre de livres par filtre.
  static Map<LibraryFilter, int> counts(List<LibraryItem> items) => {
    for (final filter in LibraryFilter.values)
      filter: items.where(filter.matches).length,
  };
}

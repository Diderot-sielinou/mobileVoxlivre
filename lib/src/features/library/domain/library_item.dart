import 'package:freezed_annotation/freezed_annotation.dart';

part 'library_item.freezed.dart';

/// Statut d'un livre, **calculé par le backend** (ADR-0015 du backend) :
/// l'app l'affiche, elle ne le recalcule pas.
enum LibraryStatus {
  /// Extraction du texte ou conversion en cours.
  processing,

  /// Extraction ou conversion échouée.
  failed,

  /// Texte prêt, aucune conversion lancée.
  notConverted,

  /// Écoutable, jamais commencé.
  ready,

  /// Écoute commencée : « à reprendre ».
  inProgress,

  /// Moins de 2 % des mots restants.
  finished,

  /// Valeur inconnue (backend plus récent que l'app) : affichée sans action.
  unknown;

  /// Lit la valeur du backend (`not_converted`, `in_progress`…).
  static LibraryStatus fromWire(String value) => switch (value) {
    'processing' => processing,
    'failed' => failed,
    'not_converted' => notConverted,
    'ready' => ready,
    'in_progress' => inProgress,
    'finished' => finished,
    _ => unknown,
  };
}

/// La conversion retenue d'un livre (la plus récente non échouée).
@freezed
abstract class ConversionSummary with _$ConversionSummary {
  const factory ConversionSummary({
    required String id,
    required String status,
    required int partsReady,
    required Duration playable,
    int? partCount,
    String? failureReason,
  }) = _ConversionSummary;
}

/// Dernier endroit écouté (ADR-0015 du backend).
@freezed
abstract class ReadingPoint with _$ReadingPoint {
  const factory ReadingPoint({
    required int wordIndex,
    required Duration audio,
    required DateTime recordedAt,
  }) = _ReadingPoint;
}

/// Un livre de la bibliothèque.
@freezed
abstract class LibraryItem with _$LibraryItem {
  const factory LibraryItem({
    required String documentId,
    required String title,
    required LibraryStatus status,
    required DateTime importedAt,
    int? pageCount,
    int? charCount,

    /// Raison stable d'un échec d'extraction (`unreadable`, `ocr_no_text`…).
    String? extractionError,

    /// 0 à 100, seulement quand la conversion est complète.
    int? progressPercent,
    ConversionSummary? conversion,
    ReadingPoint? position,
  }) = _LibraryItem;

  const LibraryItem._();

  /// Durée d'écoute restante, quand elle se calcule.
  Duration? get remaining {
    final playable = conversion?.playable;
    final percent = progressPercent;
    if (playable == null || playable == Duration.zero) return null;
    if (percent == null) return playable;
    return playable * ((100 - percent.clamp(0, 100)) / 100);
  }
}

import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_sheet.freezed.dart';

/// Étape du texte d'un document (`GET /v1/documents/:id`).
enum DocumentStage {
  /// Fichier pas encore reçu.
  awaitingUpload,

  /// Reçu, extraction en file d'attente.
  uploaded,

  /// Extraction (ou reconnaissance d'un scan) en cours.
  extracting,

  /// Texte prêt, consultable.
  textReady,

  /// Extraction impossible (`extractionError` dit pourquoi).
  failed,

  /// Valeur inconnue (backend plus récent que l'app).
  unknown;

  static DocumentStage fromWire(String value) => switch (value) {
    'awaiting_upload' => awaitingUpload,
    'uploaded' => uploaded,
    'extracting' => extracting,
    'text_ready' => textReady,
    'extraction_failed' => failed,
    _ => unknown,
  };

  /// Le texte n'est pas encore là.
  bool get working =>
      this == awaitingUpload || this == uploaded || this == extracting;
}

/// D'où vient le texte : la couche texte du PDF, ou la reconnaissance d'un
/// scan (ADR-0024 du backend).
enum ExtractionMethod { native, ocr }

/// Une entrée de la table des matières (ADR-0027 du backend).
@freezed
abstract class OutlineEntry with _$OutlineEntry {
  const factory OutlineEntry({
    required String title,
    required int level,
    required int pageNumber,
  }) = _OutlineEntry;
}

/// La fiche d'un document : son texte et sa table des matières.
@freezed
abstract class DocumentSheet with _$DocumentSheet {
  const factory DocumentSheet({
    required String id,
    required String title,
    required DocumentStage stage,
    int? pageCount,
    int? charCount,
    ExtractionMethod? method,
    String? extractionError,

    /// Pendant la reconnaissance d'un scan : pages faites / total.
    ({int done, int total})? ocrProgress,

    /// Confiance faible sur au moins une page : relecture avant conversion.
    @Default(false) bool reviewRequired,
    DateTime? reviewedAt,
    @Default([]) List<OutlineEntry> outline,
  }) = _DocumentSheet;

  const DocumentSheet._();

  /// La relecture est imposée et pas encore faite (RF-06).
  bool get reviewPending => reviewRequired && reviewedAt == null;
}

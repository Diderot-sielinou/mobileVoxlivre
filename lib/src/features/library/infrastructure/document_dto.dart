import 'package:json_annotation/json_annotation.dart';
import 'package:voxlivre/src/features/library/domain/document_sheet.dart';

part 'document_dto.g.dart';

/// `GET /v1/documents/:id` (`DocumentResponseDto` du backend) ; seuls les
/// champs utiles à la fiche sont lus.
@JsonSerializable(createToJson: false)
final class DocumentDto {
  const DocumentDto({
    required this.id,
    required this.title,
    required this.status,
    this.pageCount,
    this.charCount,
    this.extractionError,
    this.extractionMethod,
    this.ocrProgress,
    this.reviewRequired = false,
    this.reviewedAt,
  });

  factory DocumentDto.fromJson(Map<String, Object?> json) =>
      _$DocumentDtoFromJson(json);

  final String id;
  final String title;
  final String status;
  final int? pageCount;
  final int? charCount;
  final String? extractionError;
  final String? extractionMethod;
  final OcrProgressDto? ocrProgress;
  final bool reviewRequired;
  final DateTime? reviewedAt;

  DocumentSheet toDomain(List<OutlineEntry> outline) => DocumentSheet(
    id: id,
    title: title,
    stage: DocumentStage.fromWire(status),
    pageCount: pageCount,
    charCount: charCount,
    method: switch (extractionMethod) {
      'native' => ExtractionMethod.native,
      'ocr' => ExtractionMethod.ocr,
      _ => null,
    },
    extractionError: extractionError,
    ocrProgress: switch (ocrProgress) {
      final p? => (done: p.done, total: p.total),
      null => null,
    },
    reviewRequired: reviewRequired,
    reviewedAt: reviewedAt?.toUtc(),
    outline: outline,
  );
}

@JsonSerializable(createToJson: false)
final class OcrProgressDto {
  const OcrProgressDto({required this.done, required this.total});

  factory OcrProgressDto.fromJson(Map<String, Object?> json) =>
      _$OcrProgressDtoFromJson(json);

  final int done;
  final int total;
}

/// `GET /v1/documents/:id/outline`, une entrée.
@JsonSerializable(createToJson: false)
final class OutlineEntryDto {
  const OutlineEntryDto({
    required this.title,
    required this.level,
    required this.pageNumber,
  });

  factory OutlineEntryDto.fromJson(Map<String, Object?> json) =>
      _$OutlineEntryDtoFromJson(json);

  final String title;
  final int level;
  final int pageNumber;

  OutlineEntry toDomain() =>
      OutlineEntry(title: title, level: level, pageNumber: pageNumber);
}

import 'package:json_annotation/json_annotation.dart';
import 'package:voxlivre/src/features/library/domain/document_page.dart';

part 'document_page_dto.g.dart';

/// Une page de `GET /v1/documents/:id/pages` (`DocumentPageTextDto` du
/// backend).
@JsonSerializable(createToJson: false)
final class DocumentPageDto {
  const DocumentPageDto({
    required this.pageNumber,
    required this.text,
    this.setAside = const [],
    this.confidence,
  });

  factory DocumentPageDto.fromJson(Map<String, Object?> json) =>
      _$DocumentPageDtoFromJson(json);

  final int pageNumber;
  final String text;
  final List<SetAsideLineDto> setAside;
  final double? confidence;

  DocumentPage toDomain() => DocumentPage(
    pageNumber: pageNumber,
    text: text,
    setAside: [for (final line in setAside) line.toDomain()],
    confidence: confidence,
  );
}

@JsonSerializable(createToJson: false)
final class SetAsideLineDto {
  const SetAsideLineDto({required this.text, required this.reason});

  factory SetAsideLineDto.fromJson(Map<String, Object?> json) =>
      _$SetAsideLineDtoFromJson(json);

  final String text;
  final String reason;

  SetAsideLine toDomain() =>
      SetAsideLine(text, SetAsideReason.fromWire(reason));
}

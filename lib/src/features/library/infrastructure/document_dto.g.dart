// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentDto _$DocumentDtoFromJson(Map<String, dynamic> json) => DocumentDto(
  id: json['id'] as String,
  title: json['title'] as String,
  status: json['status'] as String,
  pageCount: (json['pageCount'] as num?)?.toInt(),
  charCount: (json['charCount'] as num?)?.toInt(),
  extractionError: json['extractionError'] as String?,
  extractionMethod: json['extractionMethod'] as String?,
  ocrProgress: json['ocrProgress'] == null
      ? null
      : OcrProgressDto.fromJson(json['ocrProgress'] as Map<String, dynamic>),
  reviewRequired: json['reviewRequired'] as bool? ?? false,
  reviewedAt: json['reviewedAt'] == null
      ? null
      : DateTime.parse(json['reviewedAt'] as String),
);

OcrProgressDto _$OcrProgressDtoFromJson(Map<String, dynamic> json) =>
    OcrProgressDto(
      done: (json['done'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

OutlineEntryDto _$OutlineEntryDtoFromJson(Map<String, dynamic> json) =>
    OutlineEntryDto(
      title: json['title'] as String,
      level: (json['level'] as num).toInt(),
      pageNumber: (json['pageNumber'] as num).toInt(),
    );

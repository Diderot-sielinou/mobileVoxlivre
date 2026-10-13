// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LibraryItemDto _$LibraryItemDtoFromJson(Map<String, dynamic> json) =>
    LibraryItemDto(
      status: json['status'] as String,
      document: LibraryDocumentDto.fromJson(
        json['document'] as Map<String, dynamic>,
      ),
      progressPercent: (json['progressPercent'] as num?)?.toInt(),
      conversion: json['conversion'] == null
          ? null
          : LibraryConversionDto.fromJson(
              json['conversion'] as Map<String, dynamic>,
            ),
      position: json['position'] == null
          ? null
          : ReadingPositionDto.fromJson(
              json['position'] as Map<String, dynamic>,
            ),
    );

LibraryDocumentDto _$LibraryDocumentDtoFromJson(Map<String, dynamic> json) =>
    LibraryDocumentDto(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      pageCount: (json['pageCount'] as num?)?.toInt(),
      charCount: (json['charCount'] as num?)?.toInt(),
      extractionError: json['extractionError'] as String?,
    );

LibraryConversionDto _$LibraryConversionDtoFromJson(
  Map<String, dynamic> json,
) => LibraryConversionDto(
  id: json['id'] as String,
  status: json['status'] as String,
  partsReady: (json['partsReady'] as num).toInt(),
  playableDurationMs: (json['playableDurationMs'] as num).toInt(),
  partCount: (json['partCount'] as num?)?.toInt(),
  failureReason: json['failureReason'] as String?,
);

ReadingPositionDto _$ReadingPositionDtoFromJson(Map<String, dynamic> json) =>
    ReadingPositionDto(
      wordIndex: (json['wordIndex'] as num).toInt(),
      audioMs: (json['audioMs'] as num).toInt(),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
    );

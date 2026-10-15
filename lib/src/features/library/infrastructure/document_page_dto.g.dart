// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_page_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentPageDto _$DocumentPageDtoFromJson(Map<String, dynamic> json) =>
    DocumentPageDto(
      pageNumber: (json['pageNumber'] as num).toInt(),
      text: json['text'] as String,
      setAside:
          (json['setAside'] as List<dynamic>?)
              ?.map((e) => SetAsideLineDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      confidence: (json['confidence'] as num?)?.toDouble(),
    );

SetAsideLineDto _$SetAsideLineDtoFromJson(Map<String, dynamic> json) =>
    SetAsideLineDto(
      text: json['text'] as String,
      reason: json['reason'] as String,
    );

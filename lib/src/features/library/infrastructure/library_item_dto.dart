import 'package:json_annotation/json_annotation.dart';
import 'package:voxlivre/src/features/library/domain/library_item.dart';

part 'library_item_dto.g.dart';

/// Un élément de `GET /v1/library` (`LibraryItemDto` du backend). Le cache
/// garde ce JSON tel quel et le relit par ce même code (ADR-0006).
@JsonSerializable(createToJson: false)
final class LibraryItemDto {
  const LibraryItemDto({
    required this.status,
    required this.document,
    this.progressPercent,
    this.conversion,
    this.position,
  });

  factory LibraryItemDto.fromJson(Map<String, Object?> json) =>
      _$LibraryItemDtoFromJson(json);

  final String status;
  final int? progressPercent;
  final LibraryDocumentDto document;
  final LibraryConversionDto? conversion;
  final ReadingPositionDto? position;

  LibraryItem toDomain() => LibraryItem(
    documentId: document.id,
    title: document.title,
    status: LibraryStatus.fromWire(status),
    importedAt: document.createdAt,
    pageCount: document.pageCount,
    charCount: document.charCount,
    extractionError: document.extractionError,
    progressPercent: progressPercent,
    conversion: conversion?.toDomain(),
    position: position?.toDomain(),
  );
}

@JsonSerializable(createToJson: false)
final class LibraryDocumentDto {
  const LibraryDocumentDto({
    required this.id,
    required this.title,
    required this.createdAt,
    this.pageCount,
    this.charCount,
    this.extractionError,
  });

  factory LibraryDocumentDto.fromJson(Map<String, Object?> json) =>
      _$LibraryDocumentDtoFromJson(json);

  final String id;
  final String title;
  final DateTime createdAt;
  final int? pageCount;
  final int? charCount;
  final String? extractionError;
}

@JsonSerializable(createToJson: false)
final class LibraryConversionDto {
  const LibraryConversionDto({
    required this.id,
    required this.status,
    required this.partsReady,
    required this.playableDurationMs,
    this.partCount,
    this.failureReason,
  });

  factory LibraryConversionDto.fromJson(Map<String, Object?> json) =>
      _$LibraryConversionDtoFromJson(json);

  final String id;
  final String status;
  final int partsReady;
  final int playableDurationMs;
  final int? partCount;
  final String? failureReason;

  ConversionSummary toDomain() => ConversionSummary(
    id: id,
    status: status,
    partsReady: partsReady,
    partCount: partCount,
    playable: Duration(milliseconds: playableDurationMs),
    failureReason: failureReason,
  );
}

@JsonSerializable(createToJson: false)
final class ReadingPositionDto {
  const ReadingPositionDto({
    required this.wordIndex,
    required this.audioMs,
    required this.recordedAt,
  });

  factory ReadingPositionDto.fromJson(Map<String, Object?> json) =>
      _$ReadingPositionDtoFromJson(json);

  final int wordIndex;
  final int audioMs;
  final DateTime recordedAt;

  ReadingPoint toDomain() => ReadingPoint(
    wordIndex: wordIndex,
    audio: Duration(milliseconds: audioMs),
    recordedAt: recordedAt,
  );
}

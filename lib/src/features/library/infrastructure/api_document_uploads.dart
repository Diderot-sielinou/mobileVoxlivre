import 'dart:io';

import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_import.dart';
import 'package:voxlivre/src/shared/http/api_client.dart';
import 'package:voxlivre/src/shared/http/signed_upload.dart';

/// [DocumentUploads] : `voxlivre-api` pour créer et confirmer, envoi direct
/// vers le stockage entre les deux (ADR-0007).
final class ApiDocumentUploads implements DocumentUploads {
  const ApiDocumentUploads(this._api, this._storage);

  final ApiClient _api;
  final SignedUpload _storage;

  @override
  Future<Result<UploadTicket, Failure>> request({
    required String title,
    required int sizeBytes,
  }) => _api.post(
    '/v1/documents',
    // Toujours proposé ; le backend choisit (ADR-0009).
    body: {
      'title': title,
      'sizeBytes': sizeBytes,
      'rightsAttested': true,
      'multipart': true,
    },
    decode: (r) {
      final json = r.json! as Map<String, Object?>;
      final document = json['document']! as Map<String, Object?>;
      final id = document['id']! as String;
      if (json['multipart'] case final Map<String, Object?> plan) {
        return UploadTicket(
          documentId: id,
          partSize: plan['partSize']! as int,
          partCount: plan['partCount']! as int,
        );
      }
      final upload = json['upload']! as Map<String, Object?>;
      return UploadTicket(
        documentId: id,
        url: Uri.parse(upload['url']! as String),
        headers: _headers(upload['headers']),
      );
    },
  );

  @override
  Future<Result<PartsTicket, Failure>> prepareParts(
    String documentId, {
    required int partSize,
    required int fileSize,
  }) => _api.post(
    '/v1/documents/$documentId/upload-parts',
    decode: (r) {
      final json = r.json! as Map<String, Object?>;
      return PartsTicket(
        received: (json['receivedParts']! as List<Object?>).cast<int>(),
        missing: [
          for (final p
              in (json['parts']! as List<Object?>).cast<Map<String, Object?>>())
            UploadPart(
              partNumber: p['partNumber']! as int,
              url: Uri.parse(p['url']! as String),
              headers: _headers(p['headers']),
              offset: PartPlan.offsetOf(p['partNumber']! as int, partSize),
              length: PartPlan.lengthOf(
                p['partNumber']! as int,
                partSize,
                fileSize,
              ),
            ),
        ],
      );
    },
  );

  @override
  Future<Result<void, Failure>> sendPart(
    UploadPart part,
    PickedPdf file, {
    void Function(int sent)? onProgress,
    Future<void>? cancel,
  }) => _storage.put(
    part.url,
    headers: _withoutLength(part.headers),
    body: File(file.path).openRead(part.offset, part.offset + part.length),
    length: part.length,
    onProgress: onProgress,
    cancel: cancel,
  );

  static Map<String, String> _headers(Object? json) => {
    for (final e in (json! as Map<String, Object?>).entries)
      e.key: e.value! as String,
  };

  /// Le `content-length` signé fait foi ; dio le pose lui-même.
  static Map<String, String> _withoutLength(Map<String, String> headers) => {
    for (final e in headers.entries)
      if (e.key.toLowerCase() != 'content-length') e.key: e.value,
  };

  @override
  Future<Result<void, Failure>> send(
    UploadTicket ticket,
    PickedPdf file, {
    void Function(int sent)? onProgress,
    Future<void>? cancel,
  }) => _storage.put(
    ticket.url!,
    headers: _withoutLength(ticket.headers),
    body: File(file.path).openRead(),
    length: file.sizeBytes,
    onProgress: onProgress,
    cancel: cancel,
  );

  @override
  Future<Result<void, Failure>> confirm(String documentId) => _api.post(
    '/v1/documents/$documentId/upload-confirmation',
    decode: (_) {},
  );
}

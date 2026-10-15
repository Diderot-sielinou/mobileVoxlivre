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
    body: {'title': title, 'sizeBytes': sizeBytes, 'rightsAttested': true},
    decode: (r) {
      final json = r.json! as Map<String, Object?>;
      final document = json['document']! as Map<String, Object?>;
      final upload = json['upload']! as Map<String, Object?>;
      return UploadTicket(
        documentId: document['id']! as String,
        url: Uri.parse(upload['url']! as String),
        headers: {
          for (final e in (upload['headers']! as Map<String, Object?>).entries)
            e.key: e.value! as String,
        },
      );
    },
  );

  @override
  Future<Result<void, Failure>> send(
    UploadTicket ticket,
    PickedPdf file, {
    void Function(int sent)? onProgress,
    Future<void>? cancel,
  }) => _storage.put(
    ticket.url,
    // Le `content-length` signé fait foi ; dio le pose lui-même.
    headers: {
      for (final e in ticket.headers.entries)
        if (e.key.toLowerCase() != 'content-length') e.key: e.value,
    },
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

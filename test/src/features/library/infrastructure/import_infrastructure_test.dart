import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_import.dart';
import 'package:voxlivre/src/features/library/infrastructure/api_document_uploads.dart';
import 'package:voxlivre/src/shared/http/signed_upload.dart';

import '../../../../helpers/fake_http.dart';

/// Réponse de `POST /v1/documents`.
final Map<String, Object?> wireUpload = {
  'document': {
    'id': 'doc-1',
    'title': 'Droit civil',
    'status': 'awaiting_upload',
  },
  'upload': {
    'url': 'https://stockage.test/bucket/doc-1.pdf?X-Amz-Signature=abc',
    'method': 'PUT',
    'headers': {'content-type': 'application/pdf', 'content-length': '9'},
    'expiresAt': '2026-10-15T12:15:00.000Z',
  },
};

String? codeOf(Result<Object?, Failure> result) => switch (result) {
  Ok() => null,
  Err(:final error) => error.code,
};

void main() {
  late Directory dir;
  late PickedPdf file;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('voxlivre-pdf');
    final f = File('${dir.path}/cours.pdf');
    await f.writeAsString('%PDF-1.7');
    file = PickedPdf(
      name: 'cours.pdf',
      path: f.path,
      sizeBytes: await f.length(),
      isPdf: true,
    );
  });
  tearDown(() => dir.delete(recursive: true));

  SignedUpload storageOn(FakeHttp http) =>
      SignedUpload(Dio()..httpClientAdapter = http);

  test('créer, envoyer au stockage, confirmer', () async {
    final api = FakeHttp(
      (r) => r.path == '/v1/documents'
          ? reply(201, wireUpload)
          : reply(200, {'id': 'doc-1', 'status': 'uploaded'}),
    );
    final storage = FakeHttp((_) => reply(200));
    final uploads = ApiDocumentUploads(api.client(), storageOn(storage));

    final ticket = switch (await uploads.request(
      title: 'Droit civil',
      sizeBytes: 8,
    )) {
      Ok(:final value) => value,
      Err() => fail('création refusée'),
    };
    expect(api.requests.single.data, {
      'title': 'Droit civil',
      'sizeBytes': 8,
      'rightsAttested': true,
    });
    expect(ticket.documentId, 'doc-1');
    expect(ticket.url.host, 'stockage.test');

    final sent = <int>[];
    expect(
      (await uploads.send(ticket, file, onProgress: sent.add)).isOk,
      isTrue,
    );
    final put = storage.requests.single;
    expect(put.method, 'PUT');
    expect(put.uri.toString(), startsWith('https://stockage.test/bucket'));
    expect(put.headers['content-type'], 'application/pdf');
    expect(put.headers['content-length'], '8');
    expect(
      put.headers.keys.map((k) => k.toLowerCase()),
      isNot(contains('authorization')),
      reason: 'le jeton ne part jamais vers le stockage',
    );
    expect(String.fromCharCodes(storage.streamed.single), '%PDF-1.7');
    expect(sent.last, 8);

    expect((await uploads.confirm('doc-1')).isOk, isTrue);
    expect(api.requests.last.path, '/v1/documents/doc-1/upload-confirmation');
    expect(api.requests.last.method, 'POST');
  });

  group('SignedUpload', () {
    Future<String?> put(FakeHttp http, {Future<void>? cancel}) async => codeOf(
      await storageOn(http).put(
        Uri.parse('https://stockage.test/x'),
        headers: const {'content-type': 'application/pdf'},
        body: File(file.path).openRead(),
        length: file.sizeBytes,
        cancel: cancel,
      ),
    );

    test('le client de l’app se construit sans adresse ni jeton', () {
      expect(SignedUpload.create(), isA<SignedUpload>());
    });

    test('statut du stockage → code', () async {
      expect(await put(FakeHttp((_) => reply(403))), 'FORBIDDEN');
      expect(await put(FakeHttp((_) => reply(503))), 'SERVER_ERROR');
    });

    test('réseau absent, délai, annulation', () async {
      expect(
        await put(
          FakeHttp(
            (r) => throw DioException.connectionError(
              requestOptions: r,
              reason: 'hors ligne',
            ),
          ),
        ),
        'NETWORK_UNAVAILABLE',
      );
      expect(
        await put(
          FakeHttp(
            (r) => throw DioException.sendTimeout(
              timeout: Duration.zero,
              requestOptions: r,
            ),
          ),
        ),
        'TIMEOUT',
      );
      expect(
        await put(FakeHttp((_) => reply(200)), cancel: Future.value()),
        'CANCELLED',
      );
    });
  });
}

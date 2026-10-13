import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/shared/http/api_client.dart';
import 'package:voxlivre/src/shared/http/api_failure.dart';

/// Faux réseau : répond par [respond] et garde la dernière requête.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final Future<ResponseBody> Function(RequestOptions options) respond;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    last = options;
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

const Map<String, List<String>> _json = {
  Headers.contentTypeHeader: ['application/json'],
};

ResponseBody _body(String body, int status) =>
    ResponseBody.fromString(body, status, headers: _json);

({ApiClient client, _FakeAdapter adapter}) _client(
  Future<ResponseBody> Function(RequestOptions options) respond,
) {
  final adapter = _FakeAdapter(respond);
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
    ..httpClientAdapter = adapter;
  return (
    client: ApiClient(dio, requestId: () => 'req-1'),
    adapter: adapter,
  );
}

ApiFailure _failure<T>(Result<T, ApiFailure> result) => switch (result) {
  Ok() => fail('échec attendu, succès reçu'),
  Err(:final error) => error,
};

Map<String, Object?> _map(Object? json) => json! as Map<String, Object?>;

void main() {
  group('succès', () {
    test('GET décode le JSON et envoie x-request-id', () async {
      final (:client, :adapter) = _client(
        (_) async => _body('{"status":"ok"}', 200),
      );

      final result = await client.get(
        '/health',
        decode: (json) => _map(json)['status']! as String,
        query: {'page': 2},
      );

      expect(result, const Result<String, ApiFailure>.ok('ok'));
      final request = adapter.last!;
      expect(request.method, 'GET');
      expect(request.uri.toString(), 'https://api.test/health?page=2');
      expect(request.headers['x-request-id'], 'req-1');
    });

    test('POST et PATCH envoient le corps, DELETE sans corps', () async {
      final (:client, :adapter) = _client((_) async => _body('{}', 200));

      await client.post('/a', body: {'x': 1}, decode: (_) => null);
      expect(adapter.last!.method, 'POST');
      expect(adapter.last!.data, {'x': 1});

      await client.patch('/a', body: {'x': 2}, decode: (_) => null);
      expect(adapter.last!.method, 'PATCH');
      expect(adapter.last!.data, {'x': 2});

      await client.delete('/a', decode: (_) => null);
      expect(adapter.last!.method, 'DELETE');
      expect(adapter.last!.data, isNull);
    });

    test('un corps vide (204) est décodé comme null', () async {
      final (:client, adapter: _) = _client(
        (_) async => ResponseBody.fromString('', 204),
      );

      final result = await client.delete('/a', decode: (json) => json);

      expect(result, const Result<Object?, ApiFailure>.ok(null));
    });
  });

  group('Problem Details', () {
    test('le code du backend est repris, avec détails et statut', () async {
      final (:client, adapter: _) = _client(
        (_) async => _body(
          jsonEncode({
            'type': 'about:blank',
            'title': 'Payment Required',
            'status': 402,
            'detail': 'Quota exceeded',
            'code': 'QUOTA_EXCEEDED',
            'details': {'missing': 120},
            'requestId': 'req-1',
          }),
          402,
        ),
      );

      final failure = _failure(await client.get('/a', decode: (j) => j));

      expect(failure.code, 'QUOTA_EXCEEDED');
      expect(failure.status, 402);
      expect(failure.details, {'missing': 120});
      expect(failure.message, 'Quota exceeded');
      expect(failure.requestId, 'req-1');
    });

    test('sans code, le code vient du statut', () async {
      final (:client, adapter: _) = _client(
        (_) async => _body('{"status":401,"detail":"Unauthorized"}', 401),
      );

      final failure = _failure(await client.get('/v1/me', decode: (j) => j));

      expect(failure.code, 'UNAUTHORIZED');
      expect(failure.details, isEmpty);
    });

    test("une page HTML d'un proxy garde le code du statut", () async {
      final (:client, adapter: _) = _client(
        (_) async => ResponseBody.fromString('<html>Bad Gateway</html>', 502),
      );

      final failure = _failure(await client.get('/a', decode: (j) => j));

      expect(failure.code, 'SERVER_ERROR');
      expect(failure.status, 502);
      expect(failure.message, isEmpty);
    });

    test('codeForStatus couvre les statuts usuels', () {
      expect(
        {
          for (final s in [400, 401, 403, 404, 409, 413, 429, 500, 503, 418])
            s: ApiFailure.codeForStatus(s),
        },
        {
          400: 'BAD_REQUEST',
          401: 'UNAUTHORIZED',
          403: 'FORBIDDEN',
          404: 'NOT_FOUND',
          409: 'CONFLICT',
          413: 'PAYLOAD_TOO_LARGE',
          429: 'RATE_LIMITED',
          500: 'SERVER_ERROR',
          503: 'SERVER_ERROR',
          418: 'HTTP_ERROR',
        },
      );
    });
  });

  group('réponse inattendue', () {
    test('un succès au corps non JSON', () async {
      final (:client, adapter: _) = _client(
        (_) async => ResponseBody.fromString('<html></html>', 200),
      );

      final failure = _failure(await client.get('/a', decode: (j) => j));

      expect(failure.code, ApiFailure.unexpectedResponse);
      expect(failure.status, 200);
    });

    test('une forme qui ne colle pas au décodeur', () async {
      final (:client, adapter: _) = _client((_) async => _body('[1, 2]', 200));

      final failure = _failure(
        await client.get('/a', decode: (json) => _map(json)['id']! as String),
      );

      expect(failure.code, ApiFailure.unexpectedResponse);
    });
  });

  group('sans réponse', () {
    Future<ApiFailure> failWith(DioExceptionType type) async {
      final (:client, adapter: _) = _client(
        (options) => Future.error(
          DioException(requestOptions: options, type: type),
        ),
      );
      return _failure(await client.get('/a', decode: (j) => j));
    }

    test('les délais dépassés donnent TIMEOUT', () async {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect((await failWith(type)).code, ApiFailure.timeout);
      }
    });

    test('une coupure donne NETWORK_UNAVAILABLE, sans statut', () async {
      final failure = await failWith(DioExceptionType.connectionError);

      expect(failure.code, ApiFailure.networkUnavailable);
      expect(failure.status, isNull);
      expect(failure.requestId, 'req-1');
    });

    test('une annulation donne CANCELLED', () async {
      expect(
        (await failWith(DioExceptionType.cancel)).code,
        ApiFailure.cancelled,
      );
    });
  });

  test('le journal ne contient ni paramètres ni corps', () async {
    final (:client, adapter: _) = _client(
      (_) async => _body('{"secret":"corps"}', 200),
    );
    final lines = <String>[];
    final subscription = Logger('http').onRecord.listen(
      (r) => lines.add(r.message),
    );
    addTearDown(subscription.cancel);

    await client.post(
      '/v1/auth',
      body: {'phone': '+237600000000'},
      decode: (j) => j,
    );
    await client.get('/v1/x', query: {'email': 'a@b.c'}, decode: (j) => j);

    expect(lines, hasLength(2));
    expect(lines.first, startsWith('POST /v1/auth → ok ('));
    expect(lines.first, endsWith('[req-1]'));
    expect(lines.last, startsWith('GET /v1/x → ok ('));
    for (final line in lines) {
      expect(line, isNot(contains('+237')));
      expect(line, isNot(contains('a@b.c')));
      expect(line, isNot(contains('corps')));
    }
  });

  test('ApiFailure.toString ne montre que code, statut et requestId', () {
    const failure = ApiFailure(
      'NOT_FOUND',
      requestId: 'req-1',
      status: 404,
      message: 'Document 42 introuvable',
    );

    expect(failure.toString(), 'ApiFailure(NOT_FOUND, status: 404, req-1)');
  });
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:voxlivre/src/shared/http/api_client.dart';
import 'package:voxlivre/src/shared/http/auth_token_source.dart';

/// Réponse scriptée : statut, corps JSON, en-têtes.
typedef FakeReply = ({int status, Object? body, Map<String, String> headers});

FakeReply reply(
  int status, [
  Object? body,
  Map<String, String> headers = const {},
]) => (status: status, body: body, headers: headers);

/// Faux réseau : répond par [respond], garde chaque requête.
final class FakeHttp implements HttpClientAdapter {
  FakeHttp(this.respond);

  FakeReply Function(RequestOptions request) respond;
  final requests = <RequestOptions>[];

  /// Corps envoyés en flux (un `PUT` de fichier), dans l'ordre.
  final streamed = <List<int>>[];

  /// Client de l'app au-dessus de ce faux réseau.
  ApiClient client({AuthTokenSource? tokens}) => ApiClient(
    Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = this,
    tokens: tokens,
    requestId: () => 'req-test',
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) {
      streamed.add([await for (final chunk in requestStream) ...chunk]);
    }
    final r = respond(options);
    return ResponseBody.fromString(
      r.body == null ? '' : jsonEncode(r.body),
      r.status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        for (final e in r.headers.entries) e.key: [e.value],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

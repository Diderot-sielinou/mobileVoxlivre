import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/shared/http/api_failure.dart';
import 'package:voxlivre/src/shared/http/api_response.dart';
import 'package:voxlivre/src/shared/http/auth_token_source.dart';
import 'package:voxlivre/src/shared/http/request_id.dart';

/// Transforme une réponse réussie en valeur ; peut lever une erreur de type
/// si la forme n'est pas celle attendue (→ [ApiFailure.unexpectedResponse]).
typedef Decode<T> = T Function(ApiResponse response);

/// Seul point d'accès à `voxlivre-api` (ADR-0004).
///
/// Chaque appel renvoie un [Result] : aucune exception n'en sort, et dio
/// n'est connu que de `shared/http/`. Chaque requête porte un `x-request-id`
/// neuf, repris dans l'[ApiFailure] et dans le journal ; avec une session,
/// elle porte aussi le jeton de [AuthTokenSource] (ADR-0005).
final class ApiClient {
  /// Client au-dessus de `dio` ; [requestId] est remplaçable pour les tests.
  ApiClient(this._dio, {AuthTokenSource? tokens, String Function()? requestId})
    : _tokens = tokens,
      _requestId = requestId ?? newRequestId;

  /// Client de l'app pour l'API située à [baseUrl].
  factory ApiClient.create({
    required Uri baseUrl,
    AuthTokenSource? tokens,
  }) => ApiClient(
    Dio(
      BaseOptions(
        baseUrl: baseUrl.toString(),
        // Réseau lent mais il faut répondre vite ; pas de nouvel essai
        // automatique : rejouer un POST peut doubler un débit.
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 60),
        headers: {'accept': 'application/json'},
      ),
    ),
    tokens: tokens,
  );

  final Dio _dio;
  final AuthTokenSource? _tokens;
  final String Function() _requestId;
  static final _log = Logger('http');

  /// `GET` de [path] (ex. `/v1/me`).
  Future<Result<T, ApiFailure>> get<T>(
    String path, {
    required Decode<T> decode,
    Map<String, Object?>? query,
  }) => _send('GET', path, decode, query: query);

  /// `POST` de [body] (encodé en JSON) vers [path].
  Future<Result<T, ApiFailure>> post<T>(
    String path, {
    required Decode<T> decode,
    Object? body,
  }) => _send('POST', path, decode, body: body);

  /// `PATCH` de [body] (encodé en JSON) vers [path].
  Future<Result<T, ApiFailure>> patch<T>(
    String path, {
    required Decode<T> decode,
    Object? body,
  }) => _send('PATCH', path, decode, body: body);

  /// `DELETE` de [path].
  Future<Result<T, ApiFailure>> delete<T>(
    String path, {
    required Decode<T> decode,
  }) => _send('DELETE', path, decode);

  Future<Result<T, ApiFailure>> _send<T>(
    String method,
    String path,
    Decode<T> decode, {
    Object? body,
    Map<String, Object?>? query,
  }) async {
    final requestId = _requestId();
    final watch = Stopwatch()..start();
    final result = await _attempt(method, path, decode, requestId, body, query);
    // Chemin sans paramètres, jamais de corps ni d'en-tête : aucune donnée
    // personnelle dans les journaux.
    final outcome = switch (result) {
      Ok() => 'ok',
      Err(:final error) => '${error.status ?? '-'} ${error.code}',
    };
    _log.info(
      '$method $path → $outcome (${watch.elapsedMilliseconds} ms) '
      '[$requestId]',
    );
    return result;
  }

  Future<Result<T, ApiFailure>> _attempt<T>(
    String method,
    String path,
    Decode<T> decode,
    String requestId,
    Object? body,
    Map<String, Object?>? query,
  ) async {
    final token = _tokens?.token;
    try {
      final response = await _dio.request<String>(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {
            'x-request-id': requestId,
            if (token != null) 'authorization': 'Bearer $token',
          },
          // Le corps est lu en texte puis décodé ici : un corps non JSON
          // devient un échec, jamais une exception.
          responseType: ResponseType.plain,
          // Les statuts d'erreur sont traités ici (Problem Details).
          validateStatus: (_) => true,
        ),
      );
      // Jeton refusé : session expirée ou supprimée ailleurs. Sans jeton, un
      // 401 n'est qu'une réponse (connexion requise).
      if (response.statusCode == 401 && token != null) {
        _tokens?.onUnauthorized();
      }
      return _read(response, decode, requestId);
    } on DioException catch (e) {
      return Result.err(_withoutResponse(e, requestId));
    }
  }

  Result<T, ApiFailure> _read<T>(
    Response<String> response,
    Decode<T> decode,
    String requestId,
  ) {
    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      return Result.err(_problem(status, response.data, requestId));
    }
    try {
      return Result.ok(
        decode(ApiResponse(_parse(response.data), response.headers.map)),
      );
      // Corps non JSON (FormatException) ou forme qui ne colle pas au
      // décodeur (erreur de type) : réponse inattendue, pas un plantage.
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      return Result.err(
        ApiFailure(
          ApiFailure.unexpectedResponse,
          requestId: requestId,
          status: status,
          message: 'réponse illisible : ${e.runtimeType}',
        ),
      );
    }
  }

  /// `null` pour un corps vide (204…), sinon le JSON décodé.
  static Object? _parse(String? body) =>
      body == null || body.isEmpty ? null : jsonDecode(body);

  /// Problem Details (RFC 7807) → [ApiFailure] ; un corps qui n'en est pas
  /// un (page HTML d'un proxy) garde le code déduit du statut. Les routes
  /// better-auth répondent `{ message, code }` : `message` remplace `detail`.
  static ApiFailure _problem(int status, String? body, String requestId) {
    Object? json;
    try {
      json = _parse(body);
    } on FormatException {
      json = null;
    }
    final problem = json is Map<String, Object?>
        ? json
        : const <String, Object?>{};
    final code = problem['code'];
    final detail = problem['detail'] ?? problem['message'];
    final details = problem['details'];
    return ApiFailure(
      code is String && code.isNotEmpty
          ? code
          : ApiFailure.codeForStatus(status),
      requestId: requestId,
      status: status,
      message: detail is String ? detail : '',
      details: details is Map<String, Object?> ? details : const {},
    );
  }

  /// Échec sans réponse exploitable : réseau, délai, annulation.
  static ApiFailure _withoutResponse(DioException e, String requestId) {
    final code = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => ApiFailure.timeout,
      DioExceptionType.cancel => ApiFailure.cancelled,
      DioExceptionType.badCertificate ||
      DioExceptionType.badResponse ||
      DioExceptionType.connectionError ||
      DioExceptionType.unknown => ApiFailure.networkUnavailable,
    };
    return ApiFailure(code, requestId: requestId, message: e.type.name);
  }
}

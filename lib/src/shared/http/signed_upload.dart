import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/shared/http/api_failure.dart';

/// Envoi d'un fichier vers une URL signée du stockage objet (ADR-0007).
///
/// Un `dio` à part : ni adresse de base ni jeton de session (l'URL signée
/// est la seule autorisation, le jeton ne part jamais vers le stockage).
/// Aucune exception n'en sort ; l'URL (qui porte la signature) n'est jamais
/// journalisée.
final class SignedUpload {
  SignedUpload(this._dio);

  factory SignedUpload.create() => SignedUpload(
    Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        // Délai sans progression, pas durée totale : un gros PDF sur un
        // réseau lent prend plusieurs minutes.
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    ),
  );

  final Dio _dio;
  static final _log = Logger('http');

  /// `PUT` de [body] ([length] octets) vers [url], avec exactement
  /// [headers] (signés). [onProgress] reçoit les octets envoyés ; [cancel]
  /// arrête l'envoi (`CANCELLED`).
  Future<Result<void, ApiFailure>> put(
    Uri url, {
    required Map<String, String> headers,
    required Stream<List<int>> body,
    required int length,
    void Function(int sent)? onProgress,
    Future<void>? cancel,
  }) async {
    final token = CancelToken();
    cancel?.whenComplete(token.cancel).ignore();
    final watch = Stopwatch()..start();
    final result = await _attempt(
      url,
      headers,
      body,
      length,
      onProgress,
      token,
    );
    final outcome = switch (result) {
      Ok() => 'ok',
      Err(:final error) => '${error.status ?? '-'} ${error.code}',
    };
    _log.info(
      'PUT stockage ($length o) → $outcome (${watch.elapsedMilliseconds} ms)',
    );
    return result;
  }

  Future<Result<void, ApiFailure>> _attempt(
    Uri url,
    Map<String, String> headers,
    Stream<List<int>> body,
    int length,
    void Function(int sent)? onProgress,
    CancelToken token,
  ) async {
    try {
      final response = await _dio.putUri<void>(
        url,
        data: body,
        cancelToken: token,
        onSendProgress: onProgress == null
            ? null
            : (sent, _) => onProgress(sent),
        options: Options(
          headers: {...headers, Headers.contentLengthHeader: '$length'},
          // Le stockage répond en XML : seul le statut compte.
          responseType: ResponseType.plain,
          validateStatus: (_) => true,
        ),
      );
      final status = response.statusCode ?? 0;
      if (status >= 200 && status < 300) return const Result.ok(null);
      return Result.err(
        ApiFailure(
          ApiFailure.codeForStatus(status),
          requestId: '-',
          status: status,
        ),
      );
    } on DioException catch (e) {
      final code = switch (e.type) {
        DioExceptionType.cancel => ApiFailure.cancelled,
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.transformTimeout => ApiFailure.timeout,
        _ => ApiFailure.networkUnavailable,
      };
      return Result.err(
        ApiFailure(code, requestId: '-', message: e.type.name),
      );
    }
  }
}

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/shared/http/api_failure.dart';

/// Lecture d'un fichier par URL signée du stockage (WebVTT, ADR-0010) : un
/// `dio` sans adresse de base ni jeton, comme `SignedUpload`. L'URL (qui
/// porte la signature) n'est jamais journalisée.
final class SignedDownload {
  SignedDownload(this._dio);

  factory SignedDownload.create() => SignedDownload(
    Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
      ),
    ),
  );

  final Dio _dio;
  static final _log = Logger('http');

  /// Le contenu texte de [url].
  Future<Result<String, ApiFailure>> text(Uri url) async {
    final watch = Stopwatch()..start();
    final Result<String, ApiFailure> result;
    try {
      final response = await _dio.getUri<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (_) => true,
        ),
      );
      final status = response.statusCode ?? 0;
      result = status >= 200 && status < 300
          ? Result.ok(response.data ?? '')
          : Result.err(
              ApiFailure(
                ApiFailure.codeForStatus(status),
                requestId: '-',
                status: status,
              ),
            );
    } on DioException catch (e) {
      final code = switch (e.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => ApiFailure.timeout,
        DioExceptionType.cancel => ApiFailure.cancelled,
        _ => ApiFailure.networkUnavailable,
      };
      return Result.err(ApiFailure(code, requestId: '-', message: e.type.name));
    }
    final outcome = switch (result) {
      Ok() => 'ok',
      Err(:final error) => '${error.status ?? '-'} ${error.code}',
    };
    _log.info('GET stockage → $outcome (${watch.elapsedMilliseconds} ms)');
    return result;
  }
}

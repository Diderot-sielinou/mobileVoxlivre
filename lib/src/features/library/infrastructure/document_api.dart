import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/shared/http/api_client.dart';

/// Routes d'un document : JSON brut (le cache le garde tel quel, ADR-0006).
final class DocumentApi {
  const DocumentApi(this._api);

  final ApiClient _api;

  Future<Result<Map<String, Object?>, Failure>> fetch(String id) =>
      _api.get('/v1/documents/$id', decode: (r) => _object(r.json));

  /// Table des matières ; vide avant le texte (409 `DOCUMENT_TEXT_NOT_READY`).
  Future<Result<List<Object?>, Failure>> outline(String id) async {
    final result = await _api.get(
      '/v1/documents/$id/outline',
      decode: (r) =>
          (r.json! as Map<String, Object?>)['items']! as List<Object?>,
    );
    return switch (result) {
      Err(:final error) when error.code == 'DOCUMENT_TEXT_NOT_READY' =>
        const Result.ok([]),
      _ => result,
    };
  }

  Future<Result<Map<String, Object?>, Failure>> rename(
    String id,
    String title,
  ) => _api.patch(
    '/v1/documents/$id',
    body: {'title': title},
    decode: (r) => _object(r.json),
  );

  Future<Result<void, Failure>> delete(String id) =>
      _api.delete('/v1/documents/$id', decode: (_) {});

  static Map<String, Object?> _object(Object? json) =>
      json! as Map<String, Object?>;
}

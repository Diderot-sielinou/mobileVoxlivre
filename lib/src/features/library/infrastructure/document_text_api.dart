import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/shared/http/api_client.dart';

/// Routes du texte d'un document (RF-06) : JSON brut, gardé tel quel par
/// le cache (ADR-0006).
final class DocumentTextApi {
  const DocumentTextApi(this._api);

  final ApiClient _api;

  /// Garde-fou : 100 lots de 50 pages.
  static const maxBatches = 100;

  /// Toutes les pages, lot par lot.
  Future<Result<List<Map<String, Object?>>, Failure>> pages(String id) async {
    final pages = <Map<String, Object?>>[];
    String? cursor;
    for (var batch = 0; batch < maxBatches; batch++) {
      final result = await _api.get(
        '/v1/documents/$id/pages',
        query: {'limit': 50, 'cursor': ?cursor},
        decode: (r) => r.json! as Map<String, Object?>,
      );
      switch (result) {
        case Err(:final error):
          return Result.err(error);
        case Ok(value: final json):
          pages.addAll(
            (json['items']! as List<Object?>).cast<Map<String, Object?>>(),
          );
          cursor = json['nextCursor'] as String?;
          if (cursor == null) return Result.ok(pages);
      }
    }
    return Result.ok(pages);
  }

  Future<Result<Map<String, Object?>, Failure>> savePage(
    String id,
    int pageNumber,
    String text,
  ) => _api.put(
    '/v1/documents/$id/pages/$pageNumber',
    body: {'text': text},
    decode: (r) => r.json! as Map<String, Object?>,
  );

  Future<Result<Map<String, Object?>, Failure>> review(String id) => _api.post(
    '/v1/documents/$id/review',
    decode: (r) => r.json! as Map<String, Object?>,
  );
}

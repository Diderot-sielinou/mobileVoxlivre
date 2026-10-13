import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/shared/http/api_client.dart';

/// `GET /v1/library`, toutes les pages : le JSON brut de chaque livre (le
/// cache le garde tel quel, ADR-0006).
final class LibraryApi {
  const LibraryApi(this._api);

  final ApiClient _api;

  /// Taille de page maximale acceptée par le backend.
  static const pageSize = 50;

  /// Garde-fou : jamais plus de 40 pages (2 000 livres) par rafraîchissement.
  static const maxPages = 40;

  Future<Result<List<Map<String, Object?>>, Failure>> fetchAll() async {
    final items = <Map<String, Object?>>[];
    String? cursor;
    for (var page = 0; page < maxPages; page++) {
      final result = await _api.get(
        '/v1/library',
        query: {'limit': pageSize, 'cursor': ?cursor},
        decode: (r) {
          final body = r.json! as Map<String, Object?>;
          return (
            items: (body['items']! as List<Object?>)
                .cast<Map<String, Object?>>(),
            next: body['nextCursor'] as String?,
          );
        },
      );
      switch (result) {
        case Err(:final error):
          return Result.err(error);
        case Ok(:final value):
          items.addAll(value.items);
          cursor = value.next;
      }
      if (cursor == null) break;
    }
    return Result.ok(items);
  }
}

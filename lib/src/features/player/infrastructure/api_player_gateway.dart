import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/domain/bookmark.dart';
import 'package:voxlivre/src/features/player/domain/manifest.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';
import 'package:voxlivre/src/features/player/domain/reading_position.dart';
import 'package:voxlivre/src/features/player/infrastructure/manifest_json.dart';
import 'package:voxlivre/src/shared/http/api_client.dart';
import 'package:voxlivre/src/shared/http/api_failure.dart';
import 'package:voxlivre/src/shared/http/signed_download.dart';

typedef _Json = Map<String, Object?>;

/// Manifeste de version inconnue : l'app doit être mise à jour.
final class UnsupportedManifest extends Failure {
  const UnsupportedManifest() : super('UNSUPPORTED_MANIFEST');
}

/// [PlayerGateway] : `voxlivre-api`, et le stockage pour les WebVTT.
final class ApiPlayerGateway implements PlayerGateway {
  const ApiPlayerGateway(this._api, this._storage);

  final ApiClient _api;
  final SignedDownload _storage;

  @override
  Future<Result<Manifest, Failure>> manifest(String conversionId) async {
    final result = await _api.get(
      '/v1/conversions/$conversionId/manifest',
      decode: (r) => r.json! as _Json,
    );
    switch (result) {
      case Err(:final error):
        return Result.err(error);
      case Ok(value: final json):
        if (json['version'] != Manifest.supportedVersion) {
          return const Result.err(UnsupportedManifest());
        }
        try {
          return Result.ok(manifestFromJson(json));
          // Version connue mais forme inattendue : même réponse.
          // ignore: avoid_catches_without_on_clauses
        } catch (_) {
          return const Result.err(UnsupportedManifest());
        }
    }
  }

  @override
  Future<Result<String, Failure>> vtt(Uri url) => _storage.text(url);

  @override
  Future<Result<void, Failure>> download(
    Uri url,
    String path, {
    void Function(int received)? onBytes,
    Future<void>? cancel,
  }) => _storage.toFile(url, path, onProgress: onBytes, cancel: cancel);

  @override
  Future<Result<ReadingPosition?, Failure>> position(
    String conversionId,
  ) async {
    final result = await _api.get(
      '/v1/conversions/$conversionId/position',
      decode: (r) => _position(r.json! as _Json),
    );
    return switch (result) {
      // Lecture jamais commencée.
      Err(:final error) when error.code == 'READING_POSITION_NOT_FOUND' =>
        const Result.ok(null),
      Err(:final error) => Result.err(error),
      Ok(:final value) => Result.ok(value),
    };
  }

  @override
  Future<Result<void, Failure>> savePosition(
    String conversionId,
    ReadingPosition position,
  ) => _api.put(
    '/v1/conversions/$conversionId/position',
    body: {
      'wordIndex': position.wordIndex,
      'audioMs': position.audioMs,
      'recordedAt': position.recordedAt.toUtc().toIso8601String(),
    },
    decode: (_) {},
  );

  @override
  Future<Result<List<Bookmark>, Failure>> bookmarks(String documentId) =>
      _api.get(
        '/v1/documents/$documentId/bookmarks',
        decode: (r) => [
          for (final item
              in ((r.json! as _Json)['items']! as List<Object?>).cast<_Json>())
            _bookmark(documentId, item),
        ],
      );

  @override
  Future<Result<Bookmark, Failure>> putBookmark(Bookmark bookmark) async =>
      _rejectable(
        await _api.put(
          '/v1/documents/${bookmark.documentId}/bookmarks/${bookmark.id}',
          body: {
            'pageNumber': bookmark.pageNumber,
            'wordIndex': bookmark.wordIndex,
            'note': bookmark.note,
            'updatedAt': bookmark.updatedAt.toUtc().toIso8601String(),
          },
          decode: (r) => _bookmark(bookmark.documentId, r.json! as _Json),
        ),
      );

  @override
  Future<Result<void, Failure>> deleteBookmark(Bookmark bookmark) async =>
      _rejectable(
        await _api.delete(
          '/v1/documents/${bookmark.documentId}/bookmarks/${bookmark.id}',
          query: {
            'deletedAt': (bookmark.deletedAt ?? bookmark.updatedAt)
                .toUtc()
                .toIso8601String(),
          },
          decode: (_) {},
        ),
      );

  /// 400, 404, 409, 422 : le serveur ne changera pas d'avis (ADR-0012).
  static Result<T, Failure> _rejectable<T>(Result<T, ApiFailure> result) =>
      switch (result) {
        Err(:final error)
            when const {
              400,
              404,
              409,
              422,
            }.contains(error.status) =>
          Result.err(BookmarkRejected(error.code)),
        Err(:final error) => Result.err(error),
        Ok(:final value) => Result.ok(value),
      };

  static Bookmark _bookmark(String documentId, _Json json) {
    DateTime at(String key) => DateTime.parse(json[key]! as String).toUtc();
    final deletedAt = json['deletedAt'] as String?;
    return Bookmark(
      id: json['id']! as String,
      documentId: documentId,
      pageNumber: json['pageNumber']! as int,
      wordIndex: json['wordIndex']! as int,
      excerpt: json['excerpt']! as String,
      note: json['note']! as String,
      needsReview: json['needsReview'] as bool? ?? false,
      createdAt: at('createdAt'),
      updatedAt: at('updatedAt'),
      deletedAt: deletedAt == null ? null : DateTime.parse(deletedAt).toUtc(),
    );
  }

  static ReadingPosition _position(_Json json) => ReadingPosition(
    wordIndex: json['wordIndex']! as int,
    audioMs: json['audioMs']! as int,
    recordedAt: DateTime.parse(json['recordedAt']! as String).toUtc(),
  );
}

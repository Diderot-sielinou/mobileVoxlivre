import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/domain/manifest.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';
import 'package:voxlivre/src/features/player/domain/reading_position.dart';
import 'package:voxlivre/src/shared/http/api_client.dart';
import 'package:voxlivre/src/shared/http/signed_download.dart';

typedef _Json = Map<String, Object?>;

/// Manifeste de version inconnue : l'app doit être mise à jour.
final class UnsupportedManifest extends Failure {
  const UnsupportedManifest() : super('UNSUPPORTED_MANIFEST');
}

/// Forme inattendue du manifeste.
final class _BadManifest implements Exception {}

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
          return Result.ok(_manifest(json));
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

  static ReadingPosition _position(_Json json) => ReadingPosition(
    wordIndex: json['wordIndex']! as int,
    audioMs: json['audioMs']! as int,
    recordedAt: DateTime.parse(json['recordedAt']! as String).toUtc(),
  );

  static Manifest _manifest(_Json json) => Manifest(
    conversionId: json['conversionId']! as String,
    documentId: json['documentId']! as String,
    complete: json['complete']! as bool,
    partCount: json['partCount']! as int,
    durationMs: json['durationMs'] as int?,
    urlsExpireAt: DateTime.parse(json['urlsExpireAt']! as String).toUtc(),
    parts: [
      for (final p in (json['parts']! as List<Object?>).cast<_Json>())
        ManifestPart(
          index: p['index']! as int,
          ready: p['status'] == 'ready',
          firstWordIndex: p['firstWordIndex']! as int,
          startMs: p['startMs'] as int?,
          durationMs: p['durationMs'] as int?,
          wordCount: p['wordCount'] as int?,
          pageStarts: [
            for (final s
                in ((p['pageStarts'] as List<Object?>?) ?? const [])
                    .cast<_Json>())
              (page: s['page']! as int, wordIndex: s['wordIndex']! as int),
          ],
          audio: _file(p['audio']),
          vtt: _file(p['vtt']),
        ),
    ],
  );

  static ManifestFile? _file(Object? json) {
    if (json == null) return null;
    if (json is! _Json) throw _BadManifest();
    final url = json['url'] as String?;
    return ManifestFile(
      url: url == null ? null : Uri.parse(url),
      bytes: json['bytes']! as int,
      sha256: json['sha256']! as String,
    );
  }
}

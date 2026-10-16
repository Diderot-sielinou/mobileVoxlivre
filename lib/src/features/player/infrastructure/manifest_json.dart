import 'package:voxlivre/src/features/player/domain/manifest.dart';

typedef ManifestJson = Map<String, Object?>;

/// Forme inattendue du manifeste.
final class BadManifest implements Exception {}

/// Le manifeste au format de l'API (`version: 1`), lu par la passerelle et
/// par l'enregistrement des livres hors ligne (ADR-0011).
Manifest manifestFromJson(ManifestJson json) => Manifest(
  conversionId: json['conversionId']! as String,
  documentId: json['documentId']! as String,
  complete: json['complete']! as bool,
  partCount: json['partCount']! as int,
  durationMs: json['durationMs'] as int?,
  urlsExpireAt: DateTime.parse(json['urlsExpireAt']! as String).toUtc(),
  parts: [
    for (final p in (json['parts']! as List<Object?>).cast<ManifestJson>())
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
                  .cast<ManifestJson>())
            (page: s['page']! as int, wordIndex: s['wordIndex']! as int),
        ],
        audio: _file(p['audio']),
        vtt: _file(p['vtt']),
      ),
  ],
);

ManifestFile? _file(Object? json) {
  if (json == null) return null;
  if (json is! ManifestJson) throw BadManifest();
  final url = json['url'] as String?;
  return ManifestFile(
    url: url == null ? null : Uri.parse(url),
    bytes: json['bytes']! as int,
    sha256: json['sha256']! as String,
  );
}

/// Le manifeste au format de l'API, **sans URL** (elles expirent) : ce qui
/// est gardé pour un livre téléchargé.
ManifestJson manifestToJson(Manifest manifest) => {
  'version': Manifest.supportedVersion,
  'conversionId': manifest.conversionId,
  'documentId': manifest.documentId,
  'complete': manifest.complete,
  'partCount': manifest.partCount,
  'durationMs': manifest.durationMs,
  'urlsExpireAt': manifest.urlsExpireAt.toUtc().toIso8601String(),
  'parts': [
    for (final p in manifest.parts)
      {
        'index': p.index,
        'status': p.ready ? 'ready' : 'pending',
        'firstWordIndex': p.firstWordIndex,
        'startMs': p.startMs,
        'durationMs': p.durationMs,
        'wordCount': p.wordCount,
        'pageStarts': [
          for (final s in p.pageStarts)
            {'page': s.page, 'wordIndex': s.wordIndex},
        ],
        'audio': _fileJson(p.audio),
        'vtt': _fileJson(p.vtt),
      },
  ],
};

ManifestJson? _fileJson(ManifestFile? file) =>
    file == null ? null : {'bytes': file.bytes, 'sha256': file.sha256};

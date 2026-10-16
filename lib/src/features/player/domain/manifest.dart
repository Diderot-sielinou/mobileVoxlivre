/// Fichier d'une partie (MP3 ou WebVTT) : URL signée, taille, empreinte.
final class ManifestFile {
  const ManifestFile({
    required this.url,
    required this.bytes,
    required this.sha256,
  });

  final Uri? url;
  final int bytes;
  final String sha256;
}

/// Une partie de la conversion (ADR-0011 du backend). La 1ʳᵉ est l'aperçu.
final class ManifestPart {
  const ManifestPart({
    required this.index,
    required this.ready,
    required this.firstWordIndex,
    this.startMs,
    this.durationMs,
    this.wordCount,
    this.pageStarts = const [],
    this.audio,
    this.vtt,
  });

  final int index;
  final bool ready;
  final int firstWordIndex;

  /// Début dans le livre, connu quand les parties précédentes sont prêtes.
  final int? startMs;
  final int? durationMs;
  final int? wordCount;

  /// Pages qui commencent dans cette partie : (page, premier mot).
  final List<({int page, int wordIndex})> pageStarts;
  final ManifestFile? audio;
  final ManifestFile? vtt;

  /// Écoutable : prête, avec son audio, son WebVTT et sa place dans le livre.
  bool get playable =>
      ready && audio?.url != null && vtt?.url != null && startMs != null;
}

/// `GET /v1/conversions/:id/manifest`, `version: 1`.
final class Manifest {
  const Manifest({
    required this.conversionId,
    required this.documentId,
    required this.complete,
    required this.partCount,
    required this.urlsExpireAt,
    required this.parts,
    this.durationMs,
  });

  /// Seule version que l'app sait lire ; une autre = mettre l'app à jour.
  static const supportedVersion = 1;

  final String conversionId;
  final String documentId;

  /// Toutes les parties sont prêtes.
  final bool complete;
  final int partCount;
  final DateTime urlsExpireAt;
  final List<ManifestPart> parts;
  final int? durationMs;

  /// Les parties écoutables, dans l'ordre, sans trou.
  List<ManifestPart> get playableParts {
    final sorted = [...parts]..sort((a, b) => a.index.compareTo(b.index));
    final result = <ManifestPart>[];
    for (final part in sorted) {
      if (!part.playable) break;
      result.add(part);
    }
    return result;
  }
}

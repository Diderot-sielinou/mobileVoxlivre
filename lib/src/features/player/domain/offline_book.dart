import 'package:voxlivre/src/features/player/domain/manifest.dart';

/// Les deux fichiers d'une partie.
enum PartFile { audio, vtt }

/// Un livre (même partiel) sur l'appareil (ADR-0011).
final class StoredBook {
  const StoredBook({
    required this.manifest,
    required this.verified,
    required this.complete,
  });

  /// Manifeste enregistré ; les fichiers des parties vérifiées y ont une
  /// URL `file://`, les autres aucune.
  final Manifest manifest;

  /// Index des parties dont les deux fichiers ont la bonne empreinte.
  final Set<int> verified;

  /// Toutes les parties sont là : le livre se lit sans réseau.
  final bool complete;

  /// Ce qui est déjà sur l'appareil.
  DownloadProgress get progress => DownloadProgress(
    partsDone: verified.length,
    partCount: manifest.parts.length,
    bytesDone: manifest.parts
        .where((p) => verified.contains(p.index))
        .fold(0, (sum, p) => sum + partBytes(p)),
    bytesTotal: manifestBytes(manifest),
  );
}

/// Où en est un téléchargement.
final class DownloadProgress {
  const DownloadProgress({
    required this.partsDone,
    required this.partCount,
    required this.bytesDone,
    required this.bytesTotal,
  });

  final int partsDone;
  final int partCount;
  final int bytesDone;
  final int bytesTotal;

  /// La partie en cours (1 à [partCount]).
  int get currentPart => partsDone < partCount ? partsDone + 1 : partCount;

  /// 0 à 1.
  double get fraction => bytesTotal == 0 ? 0 : bytesDone / bytesTotal;
}

/// Taille des deux fichiers d'une partie.
int partBytes(ManifestPart part) =>
    (part.audio?.bytes ?? 0) + (part.vtt?.bytes ?? 0);

/// Taille totale des fichiers d'un manifeste (audio et WebVTT).
int manifestBytes(Manifest manifest) =>
    manifest.parts.fold(0, (sum, part) => sum + partBytes(part));

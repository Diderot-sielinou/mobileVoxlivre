import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/domain/manifest.dart';
import 'package:voxlivre/src/features/player/domain/reading_position.dart';

/// Ce que le lecteur demande au backend.
abstract interface class PlayerGateway {
  /// Manifeste ; `UNSUPPORTED_MANIFEST` pour une version inconnue.
  Future<Result<Manifest, Failure>> manifest(String conversionId);

  /// Contenu d'un WebVTT (URL signée).
  Future<Result<String, Failure>> vtt(Uri url);

  /// Position enregistrée sur le serveur, ou `null`.
  Future<Result<ReadingPosition?, Failure>> position(String conversionId);

  /// Envoie la position ; le serveur garde la plus récente.
  Future<Result<void, Failure>> savePosition(
    String conversionId,
    ReadingPosition position,
  );
}

/// Positions gardées sur l'appareil (hors ligne d'abord).
abstract interface class PositionStore {
  Future<ReadingPosition?> read(String conversionId);

  Future<void> write(String conversionId, ReadingPosition position);

  /// Fin de session : tout part (ADR-0006).
  Future<void> clear();
}

/// Une partie à jouer : son audio et sa place dans le livre.
final class AudioPart {
  const AudioPart({
    required this.index,
    required this.url,
    required this.startMs,
  });

  final int index;
  final Uri url;
  final int startMs;
}

/// Le moteur audio (ADR-0010) : parties enchaînées, instants **absolus**.
abstract interface class AudioEngine {
  /// Charge [parts] et se place à [startMs] (sans jouer).
  Future<void> load(
    List<AudioPart> parts, {
    required int startMs,
    required String title,
  });

  /// Ajoute des parties devenues prêtes (aperçu), à la fin.
  Future<void> append(List<AudioPart> parts);

  Future<void> play();

  Future<void> pause();

  Future<void> seek(int ms);

  Future<void> setSpeed(double speed);

  /// Instant absolu, émis pendant la lecture.
  Stream<int> get positions;

  Stream<bool> get playingChanges;

  /// Fin de la dernière partie chargée.
  Stream<void> get completed;

  Future<void> dispose();
}

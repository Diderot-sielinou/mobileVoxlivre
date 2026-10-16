import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/domain/bookmark.dart';
import 'package:voxlivre/src/features/player/domain/manifest.dart';
import 'package:voxlivre/src/features/player/domain/offline_book.dart';
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

  /// Écrit le fichier d'une URL signée dans [path] (ADR-0011). [onBytes]
  /// reçoit les octets reçus ; [cancel] interrompt (`CANCELLED`).
  Future<Result<void, Failure>> download(
    Uri url,
    String path, {
    void Function(int received)? onBytes,
    Future<void>? cancel,
  });

  /// Marque-pages actifs du document, ancrage vérifié (ADR-0012).
  Future<Result<List<Bookmark>, Failure>> bookmarks(String documentId);

  /// Crée ou met à jour ; rend l'état retenu par le serveur (`deletedAt`
  /// renseigné si une suppression plus récente l'emporte). Refus définitif :
  /// `BookmarkRejected`.
  Future<Result<Bookmark, Failure>> putBookmark(Bookmark bookmark);

  /// Envoie la suppression (`deletedAt`). Refus définitif : `BookmarkRejected`.
  Future<Result<void, Failure>> deleteBookmark(Bookmark bookmark);
}

/// Positions gardées sur l'appareil (hors ligne d'abord).
abstract interface class PositionStore {
  Future<ReadingPosition?> read(String conversionId);

  /// Écrit la position, « à envoyer » au serveur (ADR-0011).
  Future<void> write(String conversionId, ReadingPosition position);

  /// Le serveur l'a reçue : plus à envoyer (si c'est toujours la même).
  Future<void> markSent(String conversionId, DateTime recordedAt);

  /// Positions pas encore reçues par le serveur.
  Future<Map<String, ReadingPosition>> pending();

  /// Fin de session : tout part (ADR-0006).
  Future<void> clear();
}

/// Les marque-pages sur l'appareil (ADR-0012), traces de suppression
/// comprises.
abstract interface class BookmarkStore {
  /// Marque-pages actifs du document, à chaque changement.
  Stream<List<Bookmark>> watch(String documentId);

  /// Tous ceux du document, traces comprises.
  Future<List<Bookmark>> all(String documentId);

  /// Ceux à envoyer, tous documents.
  Future<List<Bookmark>> pending();

  /// Crée ou remplace.
  Future<void> save(Bookmark bookmark);

  Future<void> remove(String id);

  /// Fin de session : tout part.
  Future<void> clear();
}

/// Identifiants créés sur l'appareil (UUID v4).
abstract interface class IdGenerator {
  String newId();
}

/// Les livres sur l'appareil (ADR-0011) : fichiers et manifeste.
abstract interface class BookFiles {
  /// Le livre enregistré, même partiel, ou `null`.
  Future<StoredBook?> read(String conversionId);

  /// Enregistre [manifest] (sans ses URL) ; les parties vérifiées restent.
  Future<void> save(String conversionId, Manifest manifest);

  /// Où écrire un fichier d'une partie.
  Future<String> pathOf(String conversionId, int index, PartFile file);

  /// Le fichier [path] a-t-il l'empreinte SHA-256 [sha256] ?
  Future<bool> matches(String path, String sha256);

  Future<void> deleteFile(String path);

  Future<String> readText(String path);

  Future<void> markVerified(String conversionId, int index);

  Future<void> markComplete(String conversionId);

  /// Efface les fichiers et l'enregistrement d'un livre.
  Future<void> remove(String conversionId);

  /// Fin de session : tous les livres partent.
  Future<void> clear();

  /// Les livres complets, à chaque changement.
  Stream<Set<String>> watchComplete();
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

import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';

/// Un PDF choisi sur l'appareil : une copie locale lisible en [path]
/// (ADR-0007).
final class PickedPdf {
  const PickedPdf({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.isPdf,
  });

  /// Nom du fichier, avec son extension.
  final String name;
  final String path;
  final int sizeBytes;

  /// Le contenu commence par la signature `%PDF-`.
  final bool isPdf;
}

/// Où l'app trouve les PDF de l'utilisateur.
abstract interface class PdfSource {
  /// Le sélecteur du système ; `null` si l'utilisateur renonce.
  Future<PickedPdf?> pick();

  /// Efface la copie locale de [file] (document personnel).
  Future<void> discard(PickedPdf file);
}

/// Autorisation d'envoi rendue par `POST /v1/documents` : un seul `PUT`
/// signé, ou un envoi par morceaux (ADR-0009).
final class UploadTicket {
  const UploadTicket({
    required this.documentId,
    this.url,
    this.headers = const {},
    this.partSize,
    this.partCount,
  });

  final String documentId;

  /// URL `PUT` signée (un seul envoi), à appeler telle quelle.
  final Uri? url;

  /// En-têtes signés, à envoyer tels quels.
  final Map<String, String> headers;

  /// Envoi par morceaux : taille d'un morceau (le dernier : le reste).
  final int? partSize;
  final int? partCount;

  bool get byParts => partSize != null;
}

/// Un morceau à envoyer : son URL signée et sa place dans le fichier.
final class UploadPart {
  const UploadPart({
    required this.partNumber,
    required this.url,
    required this.headers,
    required this.offset,
    required this.length,
  });

  final int partNumber;
  final Uri url;
  final Map<String, String> headers;

  /// Premier octet du morceau dans le fichier, et sa taille.
  final int offset;
  final int length;
}

/// Réponse de `upload-parts` : ce que le stockage a déjà, ce qui manque.
final class PartsTicket {
  const PartsTicket({required this.received, required this.missing});

  /// Numéros des morceaux déjà reçus.
  final List<int> received;
  final List<UploadPart> missing;
}

/// Morceaux d'un fichier : numéro → (début, taille).
abstract final class PartPlan {
  static int offsetOf(int partNumber, int partSize) =>
      (partNumber - 1) * partSize;

  static int lengthOf(int partNumber, int partSize, int fileSize) {
    final rest = fileSize - offsetOf(partNumber, partSize);
    return rest < partSize ? rest : partSize;
  }
}

/// Les trois appels de l'import (ADR-0007 du backend).
abstract interface class DocumentUploads {
  /// Crée le document (`awaiting_upload`) et obtient l'URL d'envoi, ou le
  /// plan des morceaux (le backend choisit, ADR-0009).
  Future<Result<UploadTicket, Failure>> request({
    required String title,
    required int sizeBytes,
  });

  /// Morceaux reçus et URL des manquants (démarrer ou reprendre).
  Future<Result<PartsTicket, Failure>> prepareParts(
    String documentId, {
    required int partSize,
    required int fileSize,
  });

  /// Envoie un morceau de [file].
  Future<Result<void, Failure>> sendPart(
    UploadPart part,
    PickedPdf file, {
    void Function(int sent)? onProgress,
    Future<void>? cancel,
  });

  /// Envoie [file] vers [ticket] ; [onProgress] reçoit les octets envoyés,
  /// [cancel] arrête l'envoi (`CANCELLED`).
  Future<Result<void, Failure>> send(
    UploadTicket ticket,
    PickedPdf file, {
    void Function(int sent)? onProgress,
    Future<void>? cancel,
  });

  /// Le fichier est arrivé : le backend le vérifie et lance l'extraction.
  Future<Result<void, Failure>> confirm(String documentId);
}

/// Import refusé avant tout appel.
final class ImportRefused extends Failure {
  const ImportRefused(super.code);

  static const tooLarge = 'FILE_TOO_LARGE';
  static const empty = 'FILE_EMPTY';
  static const notPdf = 'NOT_A_PDF';
  static const rightsNotAttested = 'RIGHTS_NOT_ATTESTED';
}

/// Où en est l'import.
enum ImportStage { requesting, sending, confirming }

/// Avancement de l'import, pour l'écran.
final class ImportProgress {
  const ImportProgress(
    this.stage, {
    this.sent = 0,
    this.total = 0,
    this.attempt = 1,
    this.resumable = false,
  });

  final ImportStage stage;
  final int sent;
  final int total;

  /// Essai d'envoi en cours (1 au premier, plus après une coupure).
  final int attempt;

  /// Envoi par morceaux : une reprise repart où elle s'était arrêtée.
  final bool resumable;
}

/// Règles de l'import, comme le backend.
abstract final class ImportRules {
  /// `DOCUMENT_MAX_SIZE_BYTES` du backend : 50 Mo.
  static const int maxSizeBytes = 50 * 1024 * 1024;

  /// Titre proposé : le nom du fichier sans `.pdf`, `_` en espaces.
  static String titleFromFileName(String name) => name
      .replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '')
      .replaceAll(RegExp('[_]+'), ' ')
      .trim();

  /// Refus local de [file], ou `null` s'il peut partir.
  static ImportRefused? check(PickedPdf file, {required bool rightsAttested}) {
    if (!rightsAttested) {
      return const ImportRefused(ImportRefused.rightsNotAttested);
    }
    if (file.sizeBytes <= 0) return const ImportRefused(ImportRefused.empty);
    if (file.sizeBytes > maxSizeBytes) {
      return const ImportRefused(ImportRefused.tooLarge);
    }
    if (!file.isPdf) return const ImportRefused(ImportRefused.notPdf);
    return null;
  }
}

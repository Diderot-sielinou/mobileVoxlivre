import 'dart:async';

import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_import.dart';
import 'package:voxlivre/src/features/library/domain/document_title.dart';

/// Attente entre deux essais ; remplaçable dans les tests.
typedef Wait = Future<void> Function(Duration delay);

/// Importe un PDF (ADR-0007) : contrôles locaux, création du document,
/// envoi direct (relancé en entier après une coupure, nouvelle URL si
/// elle a expiré), confirmation. Rend l'identifiant du document ; la copie
/// locale est effacée une fois le fichier confirmé.
final class ImportDocument {
  ImportDocument(this._uploads, this._source, {Wait? wait})
    : _wait = wait ?? Future<void>.delayed;

  final DocumentUploads _uploads;
  final PdfSource _source;
  final Wait _wait;

  /// Pauses avant chaque nouvel essai après une coupure réseau.
  static const retryDelays = [
    Duration(seconds: 3),
    Duration(seconds: 8),
    Duration(seconds: 15),
  ];

  static const _network = {'NETWORK_UNAVAILABLE', 'TIMEOUT'};
  static const _cancelled = 'CANCELLED';

  /// URL signée refusée par le stockage (expirée).
  static const _expired = 'FORBIDDEN';

  /// Plus d'envoi par morceaux en cours (déjà assemblé).
  static const _conflict = 'DOCUMENT_UPLOAD_CONFLICT';

  Future<Result<String, Failure>> call({
    required PickedPdf file,
    required String title,
    required bool rightsAttested,
    void Function(ImportProgress progress)? onProgress,
    Future<void>? cancel,
  }) async {
    if (ImportRules.check(file, rightsAttested: rightsAttested)
        case final refused?) {
      return Result.err(refused);
    }
    final String validTitle;
    switch (DocumentTitle.parse(title)) {
      case Err(:final error):
        return Result.err(error);
      case Ok(:final value):
        validTitle = value;
    }

    var cancelled = false;
    cancel?.whenComplete(() => cancelled = true).ignore();
    final total = file.sizeBytes;

    Future<Result<UploadTicket, Failure>> request() {
      onProgress?.call(ImportProgress(ImportStage.requesting, total: total));
      return _uploads.request(title: validTitle, sizeBytes: total);
    }

    var ticketResult = await request();
    var attempt = 1;
    while (true) {
      final UploadTicket ticket;
      switch (ticketResult) {
        case Err(:final error):
          return Result.err(error);
        case Ok(:final value):
          ticket = value;
      }
      if (cancelled) return const Result.err(_Cancelled());
      if (ticket.byParts) {
        return _sendByParts(
          ticket,
          file,
          onProgress: onProgress,
          cancel: cancel,
          isCancelled: () => cancelled,
        );
      }

      final current = attempt;
      onProgress?.call(
        ImportProgress(ImportStage.sending, total: total, attempt: current),
      );
      final sent = await _uploads.send(
        ticket,
        file,
        cancel: cancel,
        onProgress: (bytes) => onProgress?.call(
          ImportProgress(
            ImportStage.sending,
            sent: bytes,
            total: total,
            attempt: current,
          ),
        ),
      );
      switch (sent) {
        case Ok():
          return _confirm(ticket.documentId, file, total, onProgress);
        case Err(:final error) when error.code == _cancelled || cancelled:
          return const Result.err(_Cancelled());
        case Err(:final error)
            when (_network.contains(error.code) || error.code == _expired) &&
                attempt <= retryDelays.length:
          await _pause(retryDelays[attempt - 1], cancel);
          if (cancelled) return const Result.err(_Cancelled());
          attempt++;
          // URL expirée : nouveau document (l'ancien est purgé côté
          // backend). Sinon la même URL resert.
          if (error.code == _expired) ticketResult = await request();
        case Err(:final error):
          return Result.err(error);
      }
    }
  }

  /// Envoi par morceaux (ADR-0009) : on demande ce qui manque, on l'envoie
  /// ; après une coupure, on redemande — seuls les morceaux absents
  /// repartent. Trois échecs d'affilée sans progrès arrêtent l'import.
  Future<Result<String, Failure>> _sendByParts(
    UploadTicket ticket,
    PickedPdf file, {
    required bool Function() isCancelled,
    void Function(ImportProgress progress)? onProgress,
    Future<void>? cancel,
  }) async {
    final total = file.sizeBytes;
    final partSize = ticket.partSize!;
    var failures = 0;
    var attempt = 1;
    // Octets déjà reçus par le stockage, dernière valeur connue.
    var known = 0;

    // Une coupure (ou une URL expirée) : la coupure est annoncée tout de
    // suite (octets déjà reçus, essai suivant), pause, puis reprise ;
    // `false` si les relances sont épuisées ou l'import annulé.
    Future<bool> resume(int received) async {
      if (failures >= retryDelays.length) return false;
      onProgress?.call(
        ImportProgress(
          ImportStage.sending,
          sent: received,
          total: total,
          attempt: attempt + 1,
          resumable: true,
        ),
      );
      await _pause(retryDelays[failures], cancel);
      failures++;
      attempt++;
      return !isCancelled();
    }

    while (true) {
      if (isCancelled()) return const Result.err(_Cancelled());
      final prepared = await _uploads.prepareParts(
        ticket.documentId,
        partSize: partSize,
        fileSize: total,
      );
      final PartsTicket parts;
      switch (prepared) {
        case Err(:final error) when _network.contains(error.code):
          if (await resume(known)) continue;
          return isCancelled()
              ? const Result.err(_Cancelled())
              : Result.err(error);
        // Plus d'envoi en cours : déjà assemblé, il ne reste qu'à confirmer.
        case Err(:final error) when error.code == _conflict:
          return _confirm(ticket.documentId, file, total, onProgress);
        case Err(:final error):
          return Result.err(error);
        case Ok(:final value):
          parts = value;
      }
      if (parts.missing.isEmpty) {
        return _confirm(ticket.documentId, file, total, onProgress);
      }

      var done = parts.received.fold<int>(
        0,
        (sum, n) => sum + PartPlan.lengthOf(n, partSize, total),
      );
      known = done;
      var cut = false;
      for (final part in parts.missing) {
        final base = done;
        final current = attempt;
        onProgress?.call(
          ImportProgress(
            ImportStage.sending,
            sent: base,
            total: total,
            attempt: current,
            resumable: true,
          ),
        );
        final sent = await _uploads.sendPart(
          part,
          file,
          cancel: cancel,
          onProgress: (bytes) => onProgress?.call(
            ImportProgress(
              ImportStage.sending,
              sent: base + bytes,
              total: total,
              attempt: current,
              resumable: true,
            ),
          ),
        );
        switch (sent) {
          case Ok():
            done += part.length;
            known = done;
            failures = 0;
          case Err(:final error) when error.code == _cancelled || isCancelled():
            return const Result.err(_Cancelled());
          case Err(:final error)
              when _network.contains(error.code) || error.code == _expired:
            cut = true;
          case Err(:final error):
            return Result.err(error);
        }
        if (cut) break;
      }
      // Tout est parti : pas besoin de redemander, on confirme.
      if (!cut) return _confirm(ticket.documentId, file, total, onProgress);
      if (!await resume(done)) {
        return isCancelled()
            ? const Result.err(_Cancelled())
            : const Result.err(_NetworkLost());
      }
    }
  }

  Future<Result<String, Failure>> _confirm(
    String documentId,
    PickedPdf file,
    int total,
    void Function(ImportProgress progress)? onProgress,
  ) async {
    onProgress?.call(
      ImportProgress(ImportStage.confirming, sent: total, total: total),
    );
    var confirmed = await _uploads.confirm(documentId);
    // Confirmer deux fois est sans risque : un essai de plus après une
    // coupure.
    if (confirmed case Err(:final error) when _network.contains(error.code)) {
      await _wait(retryDelays.first);
      confirmed = await _uploads.confirm(documentId);
    }
    switch (confirmed) {
      case Err(:final error):
        return Result.err(error);
      case Ok():
        await _source.discard(file);
        return Result.ok(documentId);
    }
  }

  /// [delay], écourté par [cancel].
  Future<void> _pause(Duration delay, Future<void>? cancel) => Future.any([
    _wait(delay),
    ?cancel,
  ]);
}

final class _Cancelled extends Failure {
  const _Cancelled() : super('CANCELLED');
}

/// Relances épuisées pendant un envoi par morceaux.
final class _NetworkLost extends Failure {
  const _NetworkLost() : super('NETWORK_UNAVAILABLE');
}

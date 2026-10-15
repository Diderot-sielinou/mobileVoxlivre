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

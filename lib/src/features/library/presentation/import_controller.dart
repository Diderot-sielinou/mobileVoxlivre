import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/document_import.dart';
import 'package:voxlivre/src/features/library/library_providers.dart';

/// Étape de l'écran Importer.
enum ImportPhase { idle, picked, working, failed, done }

/// État de l'écran Importer.
@immutable
final class ImportViewState {
  const ImportViewState({
    this.phase = ImportPhase.idle,
    this.file,
    this.progress,
    this.bytesPerSecond,
    this.errorCode,
    this.errorReason,
    this.documentId,
  });

  final ImportPhase phase;
  final PickedPdf? file;
  final ImportProgress? progress;

  /// Débit mesuré sur l'essai en cours.
  final double? bytesPerSecond;

  /// Code du dernier échec, et sa raison (`details.reason`) s'il y en a une.
  final String? errorCode;
  final String? errorReason;

  /// Document importé (phase [ImportPhase.done]).
  final String? documentId;
}

/// Écran Importer : choisir, envoyer, annuler. Aucune règle métier ici
/// (cas d'usage `PickPdf`, `ImportDocument`).
final class ImportController extends Notifier<ImportViewState> {
  Completer<void>? _cancel;
  final _watch = Stopwatch();
  int _attempt = 0;

  /// Fichier choisi pas encore confirmé : sa copie est à effacer si l'on
  /// part.
  PickedPdf? _pending;

  @override
  ImportViewState build() {
    // Lu ici : un `ref.read` est interdit pendant la libération.
    final pickPdf = ref.read(pickPdfProvider);
    ref.onDispose(() {
      if (_cancel case final c? when !c.isCompleted) c.complete();
      if (_pending case final file?) unawaited(pickPdf.discard(file));
    });
    return const ImportViewState();
  }

  /// Ouvre le sélecteur ; un nouveau choix remplace (et efface) l'ancien.
  Future<void> pick() async {
    final picked = await ref.read(pickPdfProvider)();
    if (!ref.mounted || picked == null) return;
    if (state.file case final previous?) {
      unawaited(ref.read(pickPdfProvider).discard(previous));
    }
    _pending = picked;
    state = ImportViewState(phase: ImportPhase.picked, file: picked);
  }

  Future<void> start({required String title, required bool attested}) async {
    final file = state.file;
    if (file == null || state.phase == ImportPhase.working) return;
    final cancel = _cancel = Completer<void>();
    _attempt = 0;
    state = ImportViewState(phase: ImportPhase.working, file: file);

    final result = await ref.read(importDocumentProvider)(
      file: file,
      title: title,
      rightsAttested: attested,
      cancel: cancel.future,
      onProgress: (progress) {
        if (!ref.mounted) return;
        if (progress.attempt != _attempt) {
          _attempt = progress.attempt;
          _watch
            ..reset()
            ..start();
        }
        final seconds = _watch.elapsedMilliseconds / 1000;
        state = ImportViewState(
          phase: ImportPhase.working,
          file: file,
          progress: progress,
          bytesPerSecond: seconds >= 1 && progress.sent > 0
              ? progress.sent / seconds
              : null,
        );
      },
    );
    _watch.stop();
    if (!ref.mounted) return;
    switch (result) {
      case Ok(value: final id):
        _pending = null;
        state = ImportViewState(phase: ImportPhase.done, documentId: id);
        unawaited(ref.read(refreshLibraryProvider)(force: true));
      case Err(:final error) when error.code == 'CANCELLED':
        state = ImportViewState(phase: ImportPhase.picked, file: file);
      case Err(:final error):
        final reason = error.details['reason'];
        state = ImportViewState(
          phase: ImportPhase.failed,
          file: file,
          errorCode: error.code,
          errorReason: reason is String ? reason : null,
        );
    }
  }

  /// Arrête l'envoi en cours ; le fichier reste choisi.
  void cancel() {
    if (_cancel case final c? when !c.isCompleted) c.complete();
  }

  /// Retour à l'écran de choix (après un import réussi, ou abandon).
  void reset() {
    if (_pending case final file?) {
      unawaited(ref.read(pickPdfProvider).discard(file));
    }
    _pending = null;
    state = const ImportViewState();
  }
}

/// Libéré quand l'écran disparaît (déconnexion) : la copie du PDF part
/// avec.
// Type de fournisseur non exporté par flutter_riverpod 3 : il est inféré.
// ignore: specify_nonobvious_property_types
final importControllerProvider =
    NotifierProvider.autoDispose<ImportController, ImportViewState>(
      ImportController.new,
    );

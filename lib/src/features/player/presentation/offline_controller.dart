import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/player/domain/offline_book.dart';
import 'package:voxlivre/src/features/player/player_providers.dart';

/// Étape du téléchargement d'un livre (ADR-0011).
enum OfflineStage { checking, available, downloading, interrupted, downloaded }

/// État de la carte « Écouter sans connexion ».
@immutable
final class OfflineViewState {
  const OfflineViewState({
    this.stage = OfflineStage.checking,
    this.totalBytes,
    this.progress,
    this.errorCode,
  });

  final OfflineStage stage;

  /// Taille du livre, quand le manifeste a pu être lu.
  final int? totalBytes;
  final DownloadProgress? progress;

  /// Raison d'une interruption ; `null` si l'utilisateur a annulé.
  final String? errorCode;
}

/// Le téléchargement d'une conversion. Reste en vie pendant qu'il tourne,
/// même si l'on quitte la fiche.
final class OfflineController extends Notifier<OfflineViewState> {
  OfflineController(this.conversionId);

  final String conversionId;
  Completer<void>? _cancel;

  @override
  OfflineViewState build() {
    // Audio retiré ailleurs (menu de la fiche, suppression du document) :
    // la carte repropose le téléchargement.
    ref.listen(downloadedBooksProvider, (_, next) {
      final books = next.value;
      if (books != null &&
          !books.contains(conversionId) &&
          state.stage == OfflineStage.downloaded) {
        state = OfflineViewState(
          stage: OfflineStage.available,
          totalBytes: state.totalBytes,
        );
      }
    });
    unawaited(Future.microtask(_check));
    return const OfflineViewState();
  }

  Future<void> _check() async {
    final stored = await ref.read(bookFilesProvider).read(conversionId);
    if (!ref.mounted || state.stage != OfflineStage.checking) return;
    if (stored != null && stored.complete) {
      state = OfflineViewState(
        stage: OfflineStage.downloaded,
        totalBytes: manifestBytes(stored.manifest),
      );
      return;
    }
    if (stored != null && stored.verified.isNotEmpty) {
      // Un téléchargement commencé : on propose de reprendre.
      state = OfflineViewState(
        stage: OfflineStage.interrupted,
        totalBytes: manifestBytes(stored.manifest),
        progress: stored.progress,
      );
      return;
    }
    final manifest = await ref
        .read(playerGatewayProvider)
        .manifest(conversionId);
    if (!ref.mounted || state.stage != OfflineStage.checking) return;
    state = OfflineViewState(
      stage: OfflineStage.available,
      totalBytes: switch (manifest) {
        Ok(:final value) => manifestBytes(value),
        Err() => null,
      },
    );
  }

  /// Télécharge (ou reprend) le livre.
  Future<void> download() async {
    if (state.stage == OfflineStage.downloading) return;
    final keep = ref.keepAlive();
    final cancel = _cancel = Completer<void>();
    state = OfflineViewState(
      stage: OfflineStage.downloading,
      totalBytes: state.totalBytes,
      progress: state.progress,
    );
    var lastPercent = -1;
    final result = await ref
        .read(downloadBookProvider)
        .call(
          conversionId,
          cancel: cancel.future,
          onProgress: (progress) {
            // Un nouvel état par point de pourcentage ou partie finie.
            final percent = (progress.fraction * 100).floor();
            if (percent == lastPercent &&
                progress.partsDone == state.progress?.partsDone) {
              return;
            }
            lastPercent = percent;
            if (ref.mounted) {
              state = OfflineViewState(
                stage: OfflineStage.downloading,
                totalBytes: progress.bytesTotal,
                progress: progress,
              );
            }
          },
        );
    _cancel = null;
    if (ref.mounted) {
      state = switch (result) {
        Ok() => OfflineViewState(
          stage: OfflineStage.downloaded,
          totalBytes: state.totalBytes,
        ),
        Err(:final error) => OfflineViewState(
          stage: OfflineStage.interrupted,
          totalBytes: state.totalBytes,
          progress: state.progress,
          errorCode: error.code == 'CANCELLED' ? null : error.code,
        ),
      };
    }
    keep.close();
  }

  /// Arrête ; les parties vérifiées restent.
  void cancel() {
    final cancel = _cancel;
    if (cancel != null && !cancel.isCompleted) cancel.complete();
  }
}

// Type de famille non exporté par flutter_riverpod 3 : il est inféré.
// ignore: specify_nonobvious_property_types
final offlineControllerProvider = NotifierProvider.autoDispose
    .family<OfflineController, OfflineViewState, String>(OfflineController.new);

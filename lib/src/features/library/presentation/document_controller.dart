import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/library_providers.dart';

/// État de la fiche (le contenu vient du cache, `documentSheetProvider`).
@immutable
final class DocumentViewState {
  const DocumentViewState({this.refreshing = false, this.errorCode});

  final bool refreshing;

  /// Code du dernier rafraîchissement raté.
  final String? errorCode;
}

/// Fiche d'un document : rafraîchir, renommer, supprimer. Aucune règle
/// métier ici (cas d'usage).
final class DocumentController extends Notifier<DocumentViewState> {
  DocumentController(this.documentId);

  final String documentId;

  @override
  DocumentViewState build() => const DocumentViewState();

  Future<void> refresh() async {
    if (state.refreshing) return;
    state = DocumentViewState(refreshing: true, errorCode: state.errorCode);
    final result = await ref.read(refreshDocumentProvider)(documentId);
    if (!ref.mounted) return;
    state = DocumentViewState(
      errorCode: switch (result) {
        Ok() => null,
        Err(:final error) => error.code,
      },
    );
  }

  /// `null` si renommé, sinon le code de l'échec.
  Future<String?> rename(String title) async {
    final result = await ref.read(renameDocumentProvider)(documentId, title);
    return switch (result) {
      Ok() => null,
      Err(:final error) => error.code,
    };
  }

  /// `null` si supprimé, sinon le code de l'échec.
  Future<String?> delete() async {
    final result = await ref.read(deleteDocumentProvider)(documentId);
    return switch (result) {
      Ok() => null,
      Err(:final error) => error.code,
    };
  }
}

// Type de famille non exporté par flutter_riverpod 3 : il est inféré.
// ignore: specify_nonobvious_property_types
final documentControllerProvider = NotifierProvider.autoDispose
    .family<DocumentController, DocumentViewState, String>(
      DocumentController.new,
    );

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/domain/library_shelf.dart';
import 'package:voxlivre/src/features/library/library_providers.dart';

/// État de l'écran (le contenu vient du cache, `librarySnapshotProvider`).
@immutable
final class LibraryViewState {
  const LibraryViewState({
    this.filter = LibraryFilter.all,
    this.refreshing = false,
    this.errorCode,
  });

  final LibraryFilter filter;
  final bool refreshing;

  /// Code du dernier rafraîchissement raté, effacé au suivant qui réussit.
  final String? errorCode;

  LibraryViewState copyWith({
    LibraryFilter? filter,
    bool? refreshing,
    String? Function()? errorCode,
  }) => LibraryViewState(
    filter: filter ?? this.filter,
    refreshing: refreshing ?? this.refreshing,
    errorCode: errorCode != null ? errorCode() : this.errorCode,
  );
}

final class LibraryController extends Notifier<LibraryViewState> {
  @override
  LibraryViewState build() => const LibraryViewState();

  void select(LibraryFilter filter) => state = state.copyWith(filter: filter);

  /// Rafraîchit le cache ; [force] ignore l'âge du cache (geste de
  /// l'utilisateur, livre en préparation).
  Future<void> refresh({bool force = false}) async {
    if (state.refreshing) return;
    state = state.copyWith(refreshing: true);
    final result = await ref.read(refreshLibraryProvider)(force: force);
    if (!ref.mounted) return;
    state = state.copyWith(
      refreshing: false,
      errorCode: () => switch (result) {
        Ok() => null,
        Err(:final error) => error.code,
      },
    );
  }
}

final libraryControllerProvider =
    NotifierProvider<LibraryController, LibraryViewState>(
      LibraryController.new,
    );

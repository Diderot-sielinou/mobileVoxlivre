import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/library/library_providers.dart';

/// État de l'écran de vérification (le texte vient du cache,
/// `documentPagesProvider`).
@immutable
final class ReviewViewState {
  const ReviewViewState({
    this.onlyToReview = true,
    this.pageNumber,
    this.refreshing = false,
    this.errorCode,
  });

  /// Filtre « À vérifier » (sinon « Toutes »).
  final bool onlyToReview;

  /// Page affichée ; `null` : la première du filtre.
  final int? pageNumber;
  final bool refreshing;

  /// Code du dernier rafraîchissement raté.
  final String? errorCode;

  ReviewViewState copyWith({
    bool? onlyToReview,
    int? pageNumber,
    bool? refreshing,
    String? errorCode,
    bool clearError = false,
  }) => ReviewViewState(
    onlyToReview: onlyToReview ?? this.onlyToReview,
    pageNumber: pageNumber ?? this.pageNumber,
    refreshing: refreshing ?? this.refreshing,
    errorCode: clearError ? null : errorCode ?? this.errorCode,
  );
}

/// Vérification du texte (RF-06) : relire, corriger une page, déclarer la
/// relecture faite. Aucune règle métier ici (cas d'usage).
final class ReviewController extends Notifier<ReviewViewState> {
  ReviewController(this.documentId);

  final String documentId;

  @override
  ReviewViewState build() => const ReviewViewState();

  Future<void> refresh() async {
    if (state.refreshing) return;
    state = state.copyWith(refreshing: true);
    final result = await ref.read(refreshDocumentPagesProvider)(documentId);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => state.copyWith(refreshing: false, clearError: true),
      Err(:final error) => state.copyWith(
        refreshing: false,
        errorCode: error.code,
      ),
    };
  }

  void showOnlyToReview({required bool value}) => state = ReviewViewState(
    onlyToReview: value,
    refreshing: state.refreshing,
    errorCode: state.errorCode,
  );

  void select(int pageNumber) => state = state.copyWith(pageNumber: pageNumber);

  /// `null` si enregistrée, sinon le code de l'échec.
  Future<String?> save(int pageNumber, String text) async {
    final result = await ref.read(saveDocumentPageProvider)(
      documentId,
      pageNumber,
      text,
    );
    if (result is Ok) {
      // Le nombre de caractères (base du coût) a changé : la fiche suit.
      unawaited(ref.read(refreshDocumentProvider)(documentId));
    }
    return switch (result) {
      Ok() => null,
      Err(:final error) => error.code,
    };
  }

  /// `null` si la relecture est enregistrée, sinon le code de l'échec.
  Future<String?> markReviewed() async {
    final result = await ref.read(markDocumentReviewedProvider)(documentId);
    return switch (result) {
      Ok() => null,
      Err(:final error) => error.code,
    };
  }
}

// Type de famille non exporté par flutter_riverpod 3 : il est inféré.
// ignore: specify_nonobvious_property_types
final reviewControllerProvider = NotifierProvider.autoDispose
    .family<ReviewController, ReviewViewState, String>(ReviewController.new);

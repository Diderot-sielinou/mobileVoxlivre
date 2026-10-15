import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/conversion/application/load_conversion_options.dart';
import 'package:voxlivre/src/features/conversion/conversion_providers.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion_options.dart';
import 'package:voxlivre/src/features/conversion/domain/voice.dart';

/// Unités manquantes selon le backend (402 `QUOTA_EXCEEDED`).
@immutable
final class QuotaShortfall {
  const QuotaShortfall({required this.requested, required this.usable});

  final int requested;
  final int usable;

  int get missing => requested > usable ? requested - usable : 0;
}

/// État de l'écran « Choisir la voix ».
@immutable
final class ConvertViewState {
  const ConvertViewState({
    this.loading = false,
    this.options,
    this.voiceId,
    this.starting = false,
    this.errorCode,
    this.quota,
    this.conversionId,
  });

  final bool loading;
  final ConversionOptions? options;
  final String? voiceId;
  final bool starting;

  /// Dernier échec (chargement ou lancement).
  final String? errorCode;

  /// Refus du backend faute d'unités, pour la voix choisie.
  final QuotaShortfall? quota;

  /// Conversion lancée : l'écran passe au suivi.
  final String? conversionId;

  Voice? get voice => options?.voices.where((v) => v.id == voiceId).firstOrNull;

  ConvertViewState copyWith({
    bool? loading,
    ConversionOptions? options,
    String? voiceId,
    bool? starting,
    String? errorCode,
    QuotaShortfall? quota,
    String? conversionId,
    bool clearError = false,
  }) => ConvertViewState(
    loading: loading ?? this.loading,
    options: options ?? this.options,
    voiceId: voiceId ?? this.voiceId,
    starting: starting ?? this.starting,
    errorCode: clearError ? null : errorCode ?? this.errorCode,
    quota: clearError ? null : quota ?? this.quota,
    conversionId: conversionId ?? this.conversionId,
  );
}

/// Choix de la voix et lancement (ADR-0008). Aucune règle métier ici.
final class ConvertController extends Notifier<ConvertViewState> {
  ConvertController(this.documentId);

  final String documentId;

  @override
  ConvertViewState build() => const ConvertViewState();

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    final result = await ref.read(loadConversionOptionsProvider)();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(value: final options) => state.copyWith(
        loading: false,
        options: options,
        voiceId: state.voiceId ?? suggestedVoice(options.voices)?.id,
      ),
      Err(:final error) => state.copyWith(
        loading: false,
        errorCode: error.code,
      ),
    };
  }

  void choose(String voiceId) =>
      state = state.copyWith(voiceId: voiceId, clearError: true);

  Future<void> start() async {
    final voiceId = state.voiceId;
    if (voiceId == null || state.starting) return;
    state = state.copyWith(starting: true, clearError: true);
    final result = await ref.read(startConversionProvider)(
      documentId,
      voiceId,
    );
    if (!ref.mounted) return;
    switch (result) {
      case Ok(value: final conversion):
        state = state.copyWith(starting: false, conversionId: conversion.id);
      case Err(:final error):
        final requested = error.details['requested'];
        final usable = error.details['usable'];
        state = state.copyWith(
          starting: false,
          errorCode: error.code,
          quota: requested is int && usable is int
              ? QuotaShortfall(requested: requested, usable: usable)
              : null,
        );
    }
  }
}

// Type de famille non exporté par flutter_riverpod 3 : il est inféré.
// ignore: specify_nonobvious_property_types
final convertControllerProvider = NotifierProvider.autoDispose
    .family<ConvertController, ConvertViewState, String>(
      ConvertController.new,
    );

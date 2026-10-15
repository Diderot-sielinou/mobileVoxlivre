import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/conversion/conversion_providers.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion.dart';

/// État du suivi.
@immutable
final class ConversionViewState {
  const ConversionViewState({this.conversion, this.errorCode});

  final Conversion? conversion;

  /// Dernière relecture ratée (la dernière conversion connue reste).
  final String? errorCode;
}

/// Suit une conversion. Aucune règle métier ici.
final class ConversionController extends Notifier<ConversionViewState> {
  ConversionController(this.conversionId);

  final String conversionId;

  @override
  ConversionViewState build() => const ConversionViewState();

  Future<void> refresh() async {
    final result = await ref.read(fetchConversionProvider)(conversionId);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(value: final conversion) => ConversionViewState(
        conversion: conversion,
      ),
      Err(:final error) => ConversionViewState(
        conversion: state.conversion,
        errorCode: error.code,
      ),
    };
  }
}

// Type de famille non exporté par flutter_riverpod 3 : il est inféré.
// ignore: specify_nonobvious_property_types
final conversionControllerProvider = NotifierProvider.autoDispose
    .family<ConversionController, ConversionViewState, String>(
      ConversionController.new,
    );

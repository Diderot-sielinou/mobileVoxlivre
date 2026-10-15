import 'package:voxlivre/src/features/conversion/domain/units_account.dart';
import 'package:voxlivre/src/features/conversion/domain/voice.dart';

/// De quoi choisir une voix : les voix et le solde.
final class ConversionOptions {
  const ConversionOptions({required this.voices, required this.account});

  final List<Voice> voices;
  final UnitsAccount account;
}

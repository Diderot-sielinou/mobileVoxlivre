import 'package:voxlivre/src/features/conversion/domain/voice.dart';

/// Les unités du compte, par source (ADR-0019 du backend) : le palier
/// gratuit ne finance que les voix standard.
final class UnitsAccount {
  const UnitsAccount({
    required this.freeRemaining,
    required this.passRemaining,
    required this.credits,
    required this.maxCharsPerConversion,
    required this.standardWeight,
    required this.naturalWeight,
  });

  final int freeRemaining;
  final int passRemaining;
  final int credits;

  /// Plafond de caractères d'une conversion (au-delà : 422).
  final int maxCharsPerConversion;
  final int standardWeight;
  final int naturalWeight;

  /// Coût en unités de [chars] caractères lus par une voix de [tier].
  int costFor(int chars, VoiceTier tier) =>
      chars * (tier == VoiceTier.natural ? naturalWeight : standardWeight);

  /// Unités qui peuvent financer une voix de [tier].
  int usableFor(VoiceTier tier) =>
      (tier == VoiceTier.standard ? freeRemaining : 0) +
      passRemaining +
      credits;

  /// Unités manquantes (0 si le solde suffit).
  int shortfall(int chars, VoiceTier tier) {
    final missing = costFor(chars, tier) - usableFor(tier);
    return missing > 0 ? missing : 0;
  }

  bool tooLong(int chars) => chars > maxCharsPerConversion;
}

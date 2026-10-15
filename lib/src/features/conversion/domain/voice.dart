/// Gamme d'une voix : le poids de son coût en unités (ADR-0019 du backend).
enum VoiceTier {
  standard,
  natural;

  static VoiceTier fromWire(String value) =>
      value == 'natural' ? natural : standard;
}

/// Une voix de synthèse (`GET /v1/voices`).
final class Voice {
  const Voice({
    required this.id,
    required this.label,
    required this.tier,
    this.female = true,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final VoiceTier tier;
  final bool female;
  final bool isDefault;
}

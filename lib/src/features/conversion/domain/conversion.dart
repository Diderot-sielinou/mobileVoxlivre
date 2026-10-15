/// Étape d'une conversion (`GET /v1/conversions/:id`).
enum ConversionStage {
  queued,
  preparing,
  synthesizing,
  synthesized,
  ready,
  failed,
  unknown;

  static ConversionStage fromWire(String value) => switch (value) {
    'queued' => queued,
    'preparing' => preparing,
    'synthesizing' => synthesizing,
    'synthesized' => synthesized,
    'ready' => ready,
    'failed' => failed,
    _ => unknown,
  };

  /// Encore en cours : on continue de suivre.
  bool get working =>
      this == queued ||
      this == preparing ||
      this == synthesizing ||
      this == synthesized;
}

/// Une conversion d'un texte en audio.
final class Conversion {
  const Conversion({
    required this.id,
    required this.documentId,
    required this.voiceId,
    required this.stage,
    this.segmentsDone = 0,
    this.segmentCount,
    this.partsReady = 0,
    this.partCount,
    this.failureReason,
  });

  final String id;
  final String documentId;
  final String voiceId;
  final ConversionStage stage;
  final int segmentsDone;
  final int? segmentCount;
  final int partsReady;
  final int? partCount;

  /// Raison stable quand [stage] vaut `failed`.
  final String? failureReason;

  /// Avancement de la synthèse, de 0 à 1 (`null` tant qu'inconnu).
  double? get synthesisRatio {
    final total = segmentCount;
    if (total == null || total == 0) return null;
    return (segmentsDone / total).clamp(0, 1).toDouble();
  }

  /// Étape affichée, de 1 à 4 : préparation, synthèse, assemblage, prêt.
  int get step => switch (stage) {
    ConversionStage.queued || ConversionStage.preparing => 1,
    ConversionStage.synthesizing => 2,
    ConversionStage.synthesized => 3,
    ConversionStage.ready => 4,
    ConversionStage.failed || ConversionStage.unknown => 0,
  };
}

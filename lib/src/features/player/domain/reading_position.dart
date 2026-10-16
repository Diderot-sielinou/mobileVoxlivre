/// Où l'on en est d'une conversion (ADR-0015 du backend) : mot, instant,
/// et l'heure de l'appareil qui départage deux positions.
final class ReadingPosition {
  const ReadingPosition({
    required this.wordIndex,
    required this.audioMs,
    required this.recordedAt,
  });

  final int wordIndex;
  final int audioMs;
  final DateTime recordedAt;

  /// « Le plus récent gagne » (AGENTS.md) ; `null` si aucune des deux.
  static ReadingPosition? latest(ReadingPosition? a, ReadingPosition? b) {
    if (a == null) return b;
    if (b == null) return a;
    return b.recordedAt.isAfter(a.recordedAt) ? b : a;
  }
}

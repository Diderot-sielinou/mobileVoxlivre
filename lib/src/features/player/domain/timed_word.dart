/// Un mot du livre et son instant **absolu** dans l'audio (ADR-0010).
final class TimedWord {
  const TimedWord({
    required this.index,
    required this.text,
    required this.startMs,
    required this.endMs,
  });

  /// Index global du mot (identifiant du repère WebVTT).
  final int index;
  final String text;
  final int startMs;
  final int endMs;
}

/// Source de l'heure courante, injectée (calque du `ClockPort` du backend) :
/// les règles qui dépendent du temps (synchronisation « le plus récent
/// gagne », expiration d'un code) se testent avec une horloge fixe.
abstract interface class Clock {
  /// L'instant présent, en UTC.
  DateTime now();
}

/// Horloge réelle du téléphone.
final class SystemClock implements Clock {
  /// Horloge réelle.
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}

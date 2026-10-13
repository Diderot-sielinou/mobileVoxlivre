/// Mémoire du premier lancement : l'onboarding n'est montré qu'une fois
/// (ADR-0005).
abstract interface class OnboardingStore {
  /// `true` une fois l'onboarding terminé ou passé.
  bool get completed;

  /// Retient que l'onboarding a été vu.
  Future<void> complete();
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/onboarding/domain/onboarding_store.dart';

/// Composition de l'onboarding (ADR-0002).

/// Mémoire du premier lancement, ouverte au démarrage (ADR-0005).
final onboardingStoreProvider = Provider<OnboardingStore>(
  (ref) => throw UnimplementedError(
    'onboardingStoreProvider est fourni au démarrage',
  ),
);

import 'package:shared_preferences/shared_preferences.dart';
import 'package:voxlivre/src/features/onboarding/domain/onboarding_store.dart';

/// [OnboardingStore] dans `shared_preferences` : un simple booléen, pas une
/// donnée sensible. Lu au démarrage, avant le premier écran.
final class PrefsOnboardingStore implements OnboardingStore {
  PrefsOnboardingStore._(this._prefs);

  /// Ouvre le stockage (lecture unique, ensuite en mémoire).
  static Future<PrefsOnboardingStore> open() async => PrefsOnboardingStore._(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(
        allowList: {_key},
      ),
    ),
  );

  final SharedPreferencesWithCache _prefs;

  static const _key = 'onboarding_completed';

  @override
  bool get completed => _prefs.getBool(_key) ?? false;

  @override
  Future<void> complete() => _prefs.setBool(_key, true);
}

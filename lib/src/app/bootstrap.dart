import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:voxlivre/src/app/app_config.dart';
import 'package:voxlivre/src/app/session_effects.dart';
import 'package:voxlivre/src/app/voxlivre_app.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/auth_providers.dart';
import 'package:voxlivre/src/features/auth/infrastructure/secure_session_store.dart';
import 'package:voxlivre/src/features/auth/infrastructure/session_token_source.dart';
import 'package:voxlivre/src/features/library/library_providers.dart';
import 'package:voxlivre/src/features/onboarding/infrastructure/prefs_onboarding_store.dart';
import 'package:voxlivre/src/features/onboarding/onboarding_providers.dart';
import 'package:voxlivre/src/features/payment/payment_providers.dart';
import 'package:voxlivre/src/features/player/player_providers.dart';
import 'package:voxlivre/src/shared/http/api_client.dart';
import 'package:voxlivre/src/shared/http/http_providers.dart';
import 'package:voxlivre/src/shared/logging/app_logging.dart';

/// Démarrage : valide la configuration, lit le jeton de session et la
/// mémoire du premier lancement (le splash natif reste affiché pendant ce
/// temps), puis lance l'app. La session est
/// vérifiée auprès du backend **après** le premier écran (ADR-0005).
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Lecteur en arrière-plan : notification et écran verrouillé (ADR-0010).
  await JustAudioBackground.init(
    androidNotificationChannelId: 'store.voxlivre.app.audio',
    androidNotificationChannelName: 'Lecture',
    androidNotificationOngoing: true,
  );
  // Journaux en debug seulement : rien ne sort d'un téléphone en release.
  configureLogging(enabled: kDebugMode);
  final config = switch (AppConfig.fromEnvironment()) {
    Ok(:final value) => value,
    // Erreur de construction, pas d'utilisation : on échoue tout de suite,
    // avec le message qui dit quoi corriger (ADR-0003).
    Err(:final error) => throw StateError(error.message),
  };

  const store = SecureSessionStore();
  final (token, onboarding) = await (
    store.read(),
    PrefsOnboardingStore.open(),
  ).wait;
  final session = AuthSession(store, token: token);
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      authSessionProvider.overrideWithValue(session),
      onboardingStoreProvider.overrideWithValue(onboarding),
      apiClientProvider.overrideWithValue(
        ApiClient.create(
          baseUrl: config.apiBaseUrl,
          tokens: SessionTokenSource(session),
        ),
      ),
    ],
  );
  clearAccountDataOnSignOut(session, [
    container.read(clearLibraryProvider).call,
    container.read(clearPositionsProvider).call,
    container.read(clearDownloadsProvider).call,
    container.read(clearBookmarksProvider).call,
    container.read(clearPaymentMemoryProvider).call,
  ]);
  unawaited(container.read(restoreSessionProvider)());
  // Écrits hors ligne lors d'une session précédente (ADR-0011, ADR-0012).
  if (session.state is SignedIn) {
    unawaited(container.read(flushPositionsProvider)());
    // Marque-pages posés ou supprimés sans réseau (ADR-0012).
    unawaited(container.read(syncBookmarksProvider)());
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const VoxlivreApp(),
    ),
  );
}

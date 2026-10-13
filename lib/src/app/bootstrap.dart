import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/app/app_config.dart';
import 'package:voxlivre/src/app/voxlivre_app.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/shared/http/api_client.dart';
import 'package:voxlivre/src/shared/http/http_providers.dart';
import 'package:voxlivre/src/shared/logging/app_logging.dart';

/// Démarrage : valide la configuration, puis lance l'app avec ses providers
/// racine. Pas de gros travail ici (premier écran rapide) : les connexions
/// (API, base locale) s'ouvrent à la première utilisation.
void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  // Journaux en debug seulement : rien ne sort d'un téléphone en release.
  configureLogging(enabled: kDebugMode);
  final config = switch (AppConfig.fromEnvironment()) {
    Ok(:final value) => value,
    // Erreur de construction, pas d'utilisation : on échoue tout de suite,
    // avec le message qui dit quoi corriger (ADR-0003).
    Err(:final error) => throw StateError(error.message),
  };
  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        // Construire dio n'ouvre aucune connexion : le premier écran reste
        // rapide.
        apiClientProvider.overrideWithValue(
          ApiClient.create(baseUrl: config.apiBaseUrl),
        ),
      ],
      child: const VoxlivreApp(),
    ),
  );
}

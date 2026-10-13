import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/app/app_config.dart';
import 'package:voxlivre/src/app/voxlivre_app.dart';
import 'package:voxlivre/src/core/result.dart';

/// Démarrage : valide la configuration, puis lance l'app avec ses providers
/// racine. Pas de gros travail ici (premier écran rapide) : les connexions
/// (API, base locale) s'ouvrent à la première utilisation.
void bootstrap() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = switch (AppConfig.fromEnvironment()) {
    Ok(:final value) => value,
    // Erreur de construction, pas d'utilisation : on échoue tout de suite,
    // avec le message qui dit quoi corriger (ADR-0003).
    Err(:final error) => throw StateError(error.message),
  };
  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const VoxlivreApp(),
    ),
  );
}

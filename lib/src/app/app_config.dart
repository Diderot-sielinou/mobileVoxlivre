import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';

/// Environnements connus (ADR-0003).
enum AppEnv { dev, prod }

/// Configuration invalide : l'app refuse de démarrer.
final class InvalidConfigFailure extends Failure {
  const InvalidConfigFailure(String message)
    : super('INVALID_CONFIG', message: message);
}

/// Configuration lue une fois au démarrage, depuis
/// `--dart-define-from-file=config/<env>.json` (ADR-0003).
final class AppConfig {
  const AppConfig._({required this.env, required this.apiBaseUrl});

  final AppEnv env;

  /// Racine de l'API, sans `/` final.
  final Uri apiBaseUrl;

  /// Valeurs compilées dans l'app par `--dart-define-from-file`.
  static Result<AppConfig, InvalidConfigFailure> fromEnvironment() => parse(
    env: const String.fromEnvironment('APP_ENV'),
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
  );

  /// Valide des valeurs brutes ; séparé de [fromEnvironment] pour les tests.
  static Result<AppConfig, InvalidConfigFailure> parse({
    required String env,
    required String apiBaseUrl,
  }) {
    final knownEnv = AppEnv.values.where((e) => e.name == env).firstOrNull;
    if (knownEnv == null) {
      final names = AppEnv.values.map((e) => e.name).join(' ou ');
      return Result.err(
        InvalidConfigFailure(
          'APP_ENV doit valoir $names (reçu : "$env"). Lancez avec '
          '--dart-define-from-file=config/<env>.json',
        ),
      );
    }
    final url = Uri.tryParse(apiBaseUrl);
    if (url == null ||
        !url.hasAuthority ||
        (!url.isScheme('http') && !url.isScheme('https'))) {
      return Result.err(
        InvalidConfigFailure(
          'API_BASE_URL doit être une URL http(s) absolue '
          '(reçu : "$apiBaseUrl")',
        ),
      );
    }
    // En production, le jeton de session ne circule jamais en clair.
    if (knownEnv == AppEnv.prod && !url.isScheme('https')) {
      return const Result.err(
        InvalidConfigFailure('API_BASE_URL doit être en https en production'),
      );
    }
    final path = url.path.endsWith('/')
        ? url.path.substring(0, url.path.length - 1)
        : url.path;
    return Result.ok(
      AppConfig._(
        env: knownEnv,
        apiBaseUrl: url.replace(path: path),
      ),
    );
  }
}

/// Fourni par le bootstrap (`ProviderScope.overrides`) une fois validé.
final appConfigProvider = Provider<AppConfig>(
  (ref) =>
      throw UnimplementedError('appConfigProvider est fourni au démarrage'),
);

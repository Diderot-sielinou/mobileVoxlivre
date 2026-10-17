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
  const AppConfig._({
    required this.env,
    required this.apiBaseUrl,
    this.siteUrl,
    this.supportEmail,
    this.googleServerClientId,
  });

  final AppEnv env;

  /// Racine de l'API, sans `/` final.
  final Uri apiBaseUrl;

  /// Site public (pages légales), facultatif (ADR-0014).
  final Uri? siteUrl;

  /// Adresse de l'aide, facultative.
  final String? supportEmail;

  /// Client OAuth **Web** de Google, audience des ID tokens envoyés au
  /// backend (ADR-0015) ; absent : pas de connexion Google.
  final String? googleServerClientId;

  /// Conditions d'utilisation, si le site est configuré.
  Uri? get termsUrl => siteUrl?.resolve('conditions');

  /// Politique de confidentialité, si le site est configuré.
  Uri? get privacyUrl => siteUrl?.resolve('confidentialite');

  /// Valeurs compilées dans l'app par `--dart-define-from-file`.
  static Result<AppConfig, InvalidConfigFailure> fromEnvironment() => parse(
    env: const String.fromEnvironment('APP_ENV'),
    apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
    siteUrl: const String.fromEnvironment('SITE_URL'),
    supportEmail: const String.fromEnvironment('SUPPORT_EMAIL'),
    googleServerClientId: const String.fromEnvironment(
      'GOOGLE_SERVER_CLIENT_ID',
    ),
  );

  /// Valide des valeurs brutes ; séparé de [fromEnvironment] pour les tests.
  static Result<AppConfig, InvalidConfigFailure> parse({
    required String env,
    required String apiBaseUrl,
    String? siteUrl,
    String? supportEmail,
    String? googleServerClientId,
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
    // Site et contact : facultatifs, mais justes s'ils sont donnés.
    Uri? site;
    if (siteUrl != null && siteUrl.isNotEmpty) {
      site = Uri.tryParse(siteUrl);
      if (site == null || !site.isScheme('https') || !site.hasAuthority) {
        return Result.err(
          InvalidConfigFailure(
            'SITE_URL doit être une URL https (reçu : "$siteUrl")',
          ),
        );
      }
      // `resolve('conditions')` doit garder le chemin : `/` final.
      if (!site.path.endsWith('/')) site = site.replace(path: '${site.path}/');
    }
    final email = (supportEmail ?? '').trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return Result.err(
        InvalidConfigFailure(
          'SUPPORT_EMAIL doit être une adresse e-mail (reçu : "$supportEmail")',
        ),
      );
    }
    final google = (googleServerClientId ?? '').trim();
    if (google.isNotEmpty &&
        !RegExp(r'^[\w-]+\.apps\.googleusercontent\.com$').hasMatch(google)) {
      return Result.err(
        InvalidConfigFailure(
          'GOOGLE_SERVER_CLIENT_ID doit être un identifiant de client OAuth '
          'Google (reçu : "$googleServerClientId")',
        ),
      );
    }
    final path = url.path.endsWith('/')
        ? url.path.substring(0, url.path.length - 1)
        : url.path;
    return Result.ok(
      AppConfig._(
        env: knownEnv,
        apiBaseUrl: url.replace(path: path),
        siteUrl: site,
        supportEmail: email.isEmpty ? null : email,
        googleServerClientId: google.isEmpty ? null : google,
      ),
    );
  }
}

/// Fourni par le bootstrap (`ProviderScope.overrides`) une fois validé.
final appConfigProvider = Provider<AppConfig>(
  (ref) =>
      throw UnimplementedError('appConfigProvider est fourni au démarrage'),
);

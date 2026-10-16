import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/app/app_config.dart';
import 'package:voxlivre/src/core/result.dart';

void main() {
  AppConfig ok(String env, String url) =>
      switch (AppConfig.parse(env: env, apiBaseUrl: url)) {
        Ok(:final value) => value,
        Err(:final error) => fail(error.message),
      };

  String err(String env, String url) =>
      switch (AppConfig.parse(env: env, apiBaseUrl: url)) {
        Ok() => fail('configuration acceptée à tort'),
        Err(:final error) => error.message,
      };

  test('dev accepte http (émulateur Android)', () {
    final config = ok('dev', 'http://10.0.2.2:8080');
    expect(config.env, AppEnv.dev);
    expect(config.apiBaseUrl.toString(), 'http://10.0.2.2:8080');
  });

  test('retire le / final de l’URL', () {
    expect(
      ok('prod', 'https://api.voxlivre.store/').apiBaseUrl.toString(),
      'https://api.voxlivre.store',
    );
  });

  test('prod refuse http', () {
    expect(err('prod', 'http://api.voxlivre.store'), contains('https'));
  });

  test('environnement absent ou inconnu : message qui dit quoi faire', () {
    expect(err('', 'https://x.test'), contains('--dart-define-from-file'));
    expect(err('staging', 'https://x.test'), contains('staging'));
  });

  test('URL absente, relative ou d’un autre schéma', () {
    for (final url in ['', '/api', 'ftp://x.test', 'api.voxlivre.store']) {
      expect(err('dev', url), contains('API_BASE_URL'), reason: url);
    }
  });

  test('le code d’échec est stable', () {
    final result = AppConfig.parse(env: 'x', apiBaseUrl: '');
    expect(result, isA<Err<AppConfig, InvalidConfigFailure>>());
    expect(
      (result as Err<AppConfig, InvalidConfigFailure>).error.code,
      'INVALID_CONFIG',
    );
  });

  group('site et contact (ADR-0014)', () {
    AppConfig ok({String? site, String? email}) => switch (AppConfig.parse(
      env: 'dev',
      apiBaseUrl: 'https://api.x.test',
      siteUrl: site,
      supportEmail: email,
    )) {
      Ok(:final value) => value,
      Err(:final error) => throw StateError(error.message),
    };

    test('absents : pas de liens', () {
      final config = ok(site: '', email: '');
      expect(config.termsUrl, isNull);
      expect(config.privacyUrl, isNull);
      expect(config.supportEmail, isNull);
    });

    test('pages légales sous le site, avec ou sans / final', () {
      for (final site in [
        'https://voxlivre.store',
        'https://voxlivre.store/',
      ]) {
        final config = ok(site: site, email: ' contact@voxlivre.store ');
        expect(
          config.termsUrl.toString(),
          'https://voxlivre.store/conditions',
        );
        expect(
          config.privacyUrl.toString(),
          'https://voxlivre.store/confidentialite',
        );
        expect(config.supportEmail, 'contact@voxlivre.store');
      }
    });

    test('site en clair ou adresse fausse : refusés', () {
      for (final (site, email, key) in [
        ('http://voxlivre.store', '', 'SITE_URL'),
        ('voxlivre.store', '', 'SITE_URL'),
        ('', 'contact', 'SUPPORT_EMAIL'),
        ('', 'a@b', 'SUPPORT_EMAIL'),
      ]) {
        final result = AppConfig.parse(
          env: 'dev',
          apiBaseUrl: 'https://api.x.test',
          siteUrl: site,
          supportEmail: email,
        );
        expect(
          (result as Err<AppConfig, InvalidConfigFailure>).error.message,
          contains(key),
          reason: '$site $email',
        );
      }
    });
  });
}

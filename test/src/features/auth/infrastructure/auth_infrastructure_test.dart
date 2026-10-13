import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/domain/current_user.dart';
import 'package:voxlivre/src/features/auth/domain/email_address.dart';
import 'package:voxlivre/src/features/auth/domain/phone_number.dart';
import 'package:voxlivre/src/features/auth/domain/sign_in_target.dart';
import 'package:voxlivre/src/features/auth/infrastructure/better_auth_gateway.dart';
import 'package:voxlivre/src/features/auth/infrastructure/secure_session_store.dart';
import 'package:voxlivre/src/features/auth/infrastructure/session_token_source.dart';

import '../../../../helpers/fake_http.dart';
import '../fakes.dart';

void main() {
  final phone = switch (PhoneNumber.parse('699000419')) {
    Ok(:final value) => PhoneTarget(value),
    Err() => throw StateError('numéro de test'),
  };
  final email = switch (EmailAddress.parse('lecteur@mail.com')) {
    Ok(:final value) => EmailTarget(value),
    Err() => throw StateError('adresse de test'),
  };

  group('BetterAuthGateway', () {
    test('demande le code sur la bonne route, selon le moyen', () async {
      final http = FakeHttp((_) => reply(200, {'status': true}));
      final gateway = BetterAuthGateway(http.client());

      await gateway.requestCode(phone);
      await gateway.requestCode(email);

      expect(http.requests.map((r) => r.path), [
        '/api/auth/phone-number/send-otp',
        '/api/auth/email-otp/send-verification-otp',
      ]);
      expect(http.requests.first.data, {'phoneNumber': '+237699000419'});
      expect(http.requests.last.data, {
        'email': 'lecteur@mail.com',
        'type': 'sign-in',
      });
    });

    test('valide le code et rend le jeton signé de l’en-tête', () async {
      final http = FakeHttp(
        (_) => reply(200, {'token': 'brut'}, {'set-auth-token': 'signé'}),
      );
      final gateway = BetterAuthGateway(http.client());

      expect(
        await gateway.verifyCode(phone, '123456'),
        const Result<String, Object>.ok('signé'),
      );
      expect(
        await gateway.verifyCode(email, '654321'),
        const Result<String, Object>.ok('signé'),
      );
      expect(http.requests.first.path, '/api/auth/phone-number/verify');
      expect(http.requests.first.data, {
        'phoneNumber': '+237699000419',
        'code': '123456',
      });
      expect(http.requests.last.path, '/api/auth/sign-in/email-otp');
      expect(http.requests.last.data, {
        'email': 'lecteur@mail.com',
        'otp': '654321',
      });
    });

    test('sans en-tête de jeton, la réponse est inattendue', () async {
      final http = FakeHttp((_) => reply(200, {'token': 'brut'}));

      final result = await BetterAuthGateway(
        http.client(),
      ).verifyCode(email, '123456');

      expect(switch (result) {
        Err(:final error) => error.code,
        Ok() => null,
      }, 'UNEXPECTED_RESPONSE');
    });

    test('un code refusé garde le code du backend', () async {
      final http = FakeHttp(
        (_) => reply(400, {'message': 'Invalid OTP', 'code': 'INVALID_OTP'}),
      );

      final result = await BetterAuthGateway(
        http.client(),
      ).verifyCode(email, '000000');

      expect(switch (result) {
        Err(:final error) => error.code,
        Ok() => null,
      }, 'INVALID_OTP');
    });

    test('lit le compte et ferme la session', () async {
      final http = FakeHttp(
        (r) => r.path == '/v1/me'
            ? reply(200, {
                'id': 'u1',
                'email': null,
                'emailVerified': false,
                'phoneNumber': '+237699000419',
                'phoneNumberVerified': true,
                'role': 'user',
                'name': '+237699000419',
                'createdAt': '2026-10-13T10:00:00.000Z',
              })
            : reply(200, {'success': true}),
      );
      final gateway = BetterAuthGateway(http.client());

      expect(
        await gateway.currentUser(),
        const Result<CurrentUser, Object>.ok(
          CurrentUser(
            id: 'u1',
            phoneNumber: '+237699000419',
            name: '+237699000419',
          ),
        ),
      );
      expect((await gateway.signOut()).isOk, isTrue);
      expect(http.requests.last.path, '/api/auth/sign-out');
      expect(http.requests.last.method, 'POST');
    });
  });

  group('SecureSessionStore', () {
    test('écrit, lit et efface le jeton', () async {
      FlutterSecureStorage.setMockInitialValues({});
      const store = SecureSessionStore();

      expect(await store.read(), isNull);
      await store.write('t1');
      expect(await store.read(), 't1');
      await store.clear();
      expect(await store.read(), isNull);
    });

    test('un Keystore illisible oublie la session sans planter', () async {
      final store = SecureSessionStore(_BrokenStorage());

      expect(await store.read(), isNull);
      await store.clear();
    });
  });

  test('SessionTokenSource lit le jeton et ferme sur refus', () async {
    final session = AuthSession(MemorySessionStore('t'), token: 't');
    final source = SessionTokenSource(session);

    expect(source.token, 't');
    source.onUnauthorized();
    await Future<void>.delayed(Duration.zero);
    expect(session.state, isA<SignedOut>());
    expect(source.token, isNull);
  });
}

/// Keystore dont la clé est perdue : toute lecture échoue.
class _BrokenStorage implements FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => throw PlatformException(code: 'BAD_DECRYPT');

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => throw PlatformException(code: 'BAD_DECRYPT');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

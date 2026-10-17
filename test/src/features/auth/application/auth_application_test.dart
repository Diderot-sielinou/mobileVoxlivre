import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/application/request_code.dart';
import 'package:voxlivre/src/features/auth/application/restore_session.dart';
import 'package:voxlivre/src/features/auth/application/sign_in_with_google.dart';
import 'package:voxlivre/src/features/auth/application/sign_out.dart';
import 'package:voxlivre/src/features/auth/application/verify_code.dart';
import 'package:voxlivre/src/features/auth/domain/current_user.dart';
import 'package:voxlivre/src/features/auth/domain/email_address.dart';
import 'package:voxlivre/src/features/auth/domain/google_account.dart';
import 'package:voxlivre/src/features/auth/domain/sign_in_target.dart';

import '../fakes.dart';

void main() {
  late FakeAuthGateway gateway;
  late FakeGoogleAccount google;
  late MemorySessionStore store;
  final target = switch (EmailAddress.parse('lecteur@mail.com')) {
    Ok(:final value) => EmailTarget(value),
    Err() => throw StateError('adresse de test invalide'),
  };

  setUp(() {
    gateway = FakeAuthGateway();
    google = FakeGoogleAccount();
    store = MemorySessionStore();
  });

  group('AuthSession', () {
    test('démarre selon le jeton lu, ouvre, complète et ferme', () async {
      final session = AuthSession(store);
      final changes = <SessionState>[];
      session.changes.listen(changes.add);

      expect(session.state, isA<SignedOut>());
      expect(session.token, isNull);

      await session.open('t1');
      expect(store.token, 't1');
      expect(session.token, 't1');

      session.attachUser(const CurrentUser(id: 'u1'));
      expect((session.state as SignedIn).user?.id, 'u1');

      await session.close();
      await session.close(); // déjà fermée : sans effet
      expect(store.token, isNull);
      await Future<void>.delayed(Duration.zero);
      expect(changes.map((s) => s.runtimeType), [
        SignedIn,
        SignedIn,
        SignedOut,
      ]);
    });

    test('un compte reçu sans session est ignoré', () {
      AuthSession(store).attachUser(const CurrentUser(id: 'u1'));
      expect(AuthSession(store, token: 't').state, isA<SignedIn>());
    });
  });

  test('RequestCode transmet à la passerelle', () async {
    final result = await RequestCode(gateway)(target);

    expect(result.isOk, isTrue);
    expect(gateway.calls, ['request l•••@mail.com']);
  });

  group('VerifyCode', () {
    test('ouvre la session puis charge le compte', () async {
      final session = AuthSession(store);

      final result = await VerifyCode(gateway, session)(target, '123456');

      expect(result.isOk, isTrue);
      expect(store.token, 'jeton-signé');
      expect((session.state as SignedIn).user?.email, 'lecteur@mail.com');
      expect(gateway.calls, ['verify 123456', 'me']);
    });

    test('un code refusé n’ouvre rien', () async {
      gateway.verifyResult = const Result.err(FakeFailure('INVALID_OTP'));
      final session = AuthSession(store);

      final result = await VerifyCode(gateway, session)(target, '000000');

      expect(result.isErr, isTrue);
      expect(session.state, isA<SignedOut>());
    });

    test('le compte injoignable n’empêche pas d’entrer', () async {
      gateway.userResult = const Result.err(FakeFailure('NETWORK_UNAVAILABLE'));
      final session = AuthSession(store);

      await VerifyCode(gateway, session)(target, '123456');

      expect((session.state as SignedIn).user, isNull);
    });
  });

  group('RestoreSession', () {
    test('sans session, rien n’est appelé', () async {
      await RestoreSession(gateway, AuthSession(store))();
      expect(gateway.calls, isEmpty);
    });

    test('complète la session avec le compte', () async {
      final session = AuthSession(store, token: 't');
      await RestoreSession(gateway, session)();
      expect((session.state as SignedIn).user?.id, 'u1');
    });

    test('un refus ferme la session', () async {
      store.token = 't';
      gateway.userResult = const Result.err(FakeFailure('UNAUTHORIZED'));
      final session = AuthSession(store, token: 't');

      await RestoreSession(gateway, session)();

      expect(session.state, isA<SignedOut>());
      expect(store.token, isNull);
    });

    test('hors ligne, on reste connecté', () async {
      gateway.userResult = const Result.err(FakeFailure('NETWORK_UNAVAILABLE'));
      final session = AuthSession(store, token: 't');

      await RestoreSession(gateway, session)();

      expect(session.state, isA<SignedIn>());
    });
  });

  group('SignInWithGoogle', () {
    test("échange l'ID token, ouvre la session et charge le compte", () async {
      final session = AuthSession(store);

      final result = await SignInWithGoogle(google, gateway, session)();

      expect(result, isA<Ok<void, Object>>());
      expect(gateway.calls, ['google id-token', 'me']);
      expect(store.token, 'jeton-google');
      expect((session.state as SignedIn).user?.id, 'u1');
    });

    test("choix du compte fermé : rien n'est appelé", () async {
      google.idTokenResult = const Result.err(GoogleSignInCancelled());
      final session = AuthSession(store);

      final result = await SignInWithGoogle(google, gateway, session)();

      expect(
        (result as Err<void, Failure>).error,
        isA<GoogleSignInCancelled>(),
      );
      expect(gateway.calls, isEmpty);
      expect(session.state, isA<SignedOut>());
    });

    test('jeton refusé : pas de session, le compte est oublié', () async {
      gateway.googleResult = const Result.err(FakeFailure('INVALID_TOKEN'));
      final session = AuthSession(store);

      final result = await SignInWithGoogle(google, gateway, session)();

      expect((result as Err<void, Failure>).error.code, 'INVALID_TOKEN');
      expect(google.calls, ['choose', 'forget']);
      expect(store.token, isNull);
    });
  });

  test('SignOut prévient le serveur et efface toujours la session', () async {
    store.token = 't';
    final session = AuthSession(store, token: 't');

    await SignOut(gateway, session, google)();

    expect(gateway.calls, ['sign-out']);
    expect(google.calls, ['forget']);
    expect(session.state, isA<SignedOut>());
    expect(store.token, isNull);
  });
}

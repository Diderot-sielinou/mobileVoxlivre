import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/auth/application/auth_session.dart';
import 'package:voxlivre/src/features/auth/domain/current_user.dart';
import 'package:voxlivre/src/features/auth/presentation/code_screen.dart';
import 'package:voxlivre/src/features/auth/presentation/sign_in_screen.dart';
import 'package:voxlivre/src/features/auth/presentation/widgets/code_input.dart';

import '../../../../helpers/app_harness.dart';
import '../fakes.dart';

void main() {
  /// Remplit le champ visible (numéro ou adresse) et demande le code.
  Future<void> requestCode(WidgetTester tester, String input) async {
    await tester.enterText(find.byType(TextField), input);
    await tester.tap(find.text('Recevoir un code'));
    await tester.pumpAndSettle();
  }

  /// Le compte à rebours de l'écran du code tourne : on le quitte avant la
  /// fin du test.
  Future<void> leave(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('sans session, l’app s’ouvre sur la connexion', (tester) async {
    await pumpVoxlivre(tester);

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.text('Bienvenue sur Voxlivre'), findsOneWidget);
    expect(find.text('AUDIO-LECTURE AUGMENTÉE'), findsOneWidget);
    expect(find.text('Cameroun'), findsOneWidget);
    expect(
      find.text('Orange ou MTN, 9 chiffres commençant par 6'),
      findsOneWidget,
    );
  });

  testWidgets('un numéro invalide est refusé sans appel au réseau', (
    tester,
  ) async {
    final h = await pumpVoxlivre(tester);

    await requestCode(tester, '2 33 00 04 19');

    expect(find.textContaining('9 chiffres commençant par 6.'), findsOneWidget);
    expect(h.gateway.calls, isEmpty);
  });

  testWidgets('parcours complet par SMS : code juste → Bibliothèque', (
    tester,
  ) async {
    final h = await pumpVoxlivre(tester);

    await requestCode(tester, '6 99 00 04 19');
    expect(find.byType(CodeScreen), findsOneWidget);
    expect(
      find.textContaining(
        'Code envoyé par SMS au +237 6•• •• •4 19',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.textContaining('5:00', findRichText: true), findsOneWidget);

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();

    expect(h.gateway.calls, [
      'request +237 6•• •• •4 19',
      'verify 123456',
      'me',
    ]);
    expect(h.session.state, isA<SignedIn>());
    expect(h.store.token, 'jeton-signé');
    expect(find.widgetWithText(AppBar, 'Bibliothèque'), findsOneWidget);
  });

  testWidgets('un code faux affiche l’erreur et vide les cases', (
    tester,
  ) async {
    final h = await pumpVoxlivre(tester);
    h.gateway.verifyResult = const Result.err(FakeFailure('INVALID_OTP'));
    await requestCode(tester, '699000419');

    await tester.enterText(find.byType(TextField), '000000');
    await tester.pumpAndSettle();

    expect(find.textContaining('Code incorrect'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, isEmpty);
    expect(h.session.state, isA<SignedOut>());
    await leave(tester);
  });

  /// Décalage horizontal des cases 40 ms après un code refusé.
  Future<double> shakeAfterRejection(
    WidgetTester tester, {
    required bool reduceMotion,
  }) async {
    final h = await pumpVoxlivre(tester, reduceMotion: reduceMotion);
    h.gateway.verifyResult = const Result.err(FakeFailure('OTP_EXPIRED'));
    await requestCode(tester, '699000419');
    await tester.enterText(find.byType(TextField), '111111');
    await tester.pump(); // réponse du faux réseau
    await tester.pump(const Duration(milliseconds: 40));
    final box = find.byType(CodeInput);
    final dx = tester
        .widget<Transform>(
          find.descendant(of: box, matching: find.byType(Transform)).first,
        )
        .transform
        .getTranslation()
        .x;
    expect(find.textContaining('a expiré'), findsOneWidget);
    await leave(tester);
    return dx;
  }

  testWidgets('un code refusé secoue les cases', (tester) async {
    expect(await shakeAfterRejection(tester, reduceMotion: false), isNot(0));
  });

  testWidgets('« réduire les animations » : erreur sans secousse', (
    tester,
  ) async {
    expect(await shakeAfterRejection(tester, reduceMotion: true), 0);
  });

  testWidgets('par e-mail ; trop de demandes → bandeau', (tester) async {
    final h = await pumpVoxlivre(tester);
    await tester.tap(find.text('E-mail'));
    await tester.pumpAndSettle();
    expect(find.text('Adresse e-mail'), findsOneWidget);

    h.gateway.requestResult = const Result.err(FakeFailure('OTP_RATE_LIMITED'));
    await requestCode(tester, 'Lecteur@Mail.com');

    expect(find.textContaining('Trop de demandes'), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    expect(find.byType(CodeScreen), findsNothing);

    h.gateway.requestResult = const Result.ok(null);
    await requestCode(tester, 'Lecteur@Mail.com');
    expect(
      find.textContaining(
        'Code envoyé par e-mail à l•••@mail.com',
        findRichText: true,
      ),
      findsOneWidget,
    );
    await leave(tester);
  });

  testWidgets('renvoi après 30 s, expiration après 5 min', (tester) async {
    final h = await pumpVoxlivre(tester);
    await requestCode(tester, '699000419');

    expect(
      find.textContaining('Renvoyer le code dans', findRichText: true),
      findsOneWidget,
    );
    h.clock.advance(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Renvoyer le code'));
    await tester.pumpAndSettle();
    expect(h.gateway.calls.where((c) => c.startsWith('request')), hasLength(2));

    h.clock.advance(const Duration(minutes: 6));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text('Le code a expiré. Demandez-en un nouveau.'),
      findsOneWidget,
    );
    await leave(tester);
  });

  testWidgets('« Coller le code » remplit et valide', (tester) async {
    final h = await pumpVoxlivre(tester);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => call.method == 'Clipboard.getData'
          ? {'text': 'Votre code Voxlivre : 246 810'}
          : null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await requestCode(tester, '699000419');

    await tester.tap(find.text('Coller le code'));
    await tester.pumpAndSettle();

    expect(h.gateway.calls, contains('verify 246810'));
  });

  testWidgets('« Modifier le numéro » revient à la saisie', (tester) async {
    await pumpVoxlivre(tester);
    await requestCode(tester, '699000419');

    await tester.tap(find.text('Modifier le numéro'));
    await tester.pumpAndSettle();

    expect(find.byType(SignInScreen), findsOneWidget);
    expect(find.byType(CodeScreen), findsNothing);
  });

  testWidgets('connecté : le Profil déconnecte et ramène à la connexion', (
    tester,
  ) async {
    final h = await pumpVoxlivre(tester, token: 'jeton');
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    h.session.attachUser(
      const CurrentUser(id: 'u1', email: 'lecteur@mail.com'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Connecté : lecteur@mail.com'), findsOneWidget);

    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();

    expect(h.gateway.calls, ['sign-out']);
    expect(h.store.token, isNull);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('accessibilité des deux écrans (cibles, libellés, contraste)', (
    tester,
  ) async {
    await pumpVoxlivre(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    await requestCode(tester, '699000419');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await leave(tester);
  });
}

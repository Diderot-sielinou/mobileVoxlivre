import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:voxlivre/src/features/auth/presentation/sign_in_screen.dart';
import 'package:voxlivre/src/features/onboarding/infrastructure/prefs_onboarding_store.dart';
import 'package:voxlivre/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:voxlivre/src/shared/design/vox_colors.dart';

import '../../../helpers/app_harness.dart';

void main() {
  Future<void> tapContinue(WidgetTester tester) async {
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
  }

  testWidgets('premier lancement : trois pages, puis la connexion', (
    tester,
  ) async {
    final h = await pumpVoxlivre(tester, onboarded: false);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('ÉTAPE 1 SUR 3'), findsOneWidget);
    final headerTop = tester.getTopLeft(find.text('ÉTAPE 1 SUR 3')).dy;
    expect(find.text('Importez vos PDF et cours'), findsOneWidget);
    expect(find.bySemanticsLabel('Page 1 sur 3'), findsOneWidget);

    await tapContinue(tester);
    expect(find.text('Écoutez en suivant le texte'), findsOneWidget);
    expect(find.bySemanticsLabel('Page 2 sur 3'), findsOneWidget);

    // Glisser vers la gauche mène aussi à la page suivante.
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Hors ligne, partout'), findsOneWidget);
    expect(find.text('Passer'), findsNothing);
    // Sans « Passer », l'en-tête ne bouge pas (vu sur le téléphone).
    expect(tester.getTopLeft(find.text('ÉTAPE 3 SUR 3')).dy, headerTop);

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(h.onboarding.completed, isTrue);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('« Passer » mène à la connexion et ne revient plus', (
    tester,
  ) async {
    final h = await pumpVoxlivre(tester, onboarded: false);

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(h.onboarding.completed, isTrue);
    expect(find.byType(SignInScreen), findsOneWidget);
  });

  testWidgets('déjà vu, ou déjà connecté : pas d’onboarding', (tester) async {
    await pumpVoxlivre(tester);
    expect(find.byType(OnboardingScreen), findsNothing);

    await pumpVoxlivre(tester, token: 'jeton', onboarded: false);
    expect(find.byType(OnboardingScreen), findsNothing);
  });

  /// Couleur du mot « du » (allumé au départ) puis 700 ms plus tard.
  Future<(Color?, Color?)> highlightOverTime(
    WidgetTester tester, {
    required bool reduceMotion,
  }) async {
    await pumpVoxlivre(tester, onboarded: false, reduceMotion: reduceMotion);
    await tester.tap(find.text('Continuer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    Color? colorOfDu() => tester.widget<Text>(find.text('du')).style?.color;
    final before = colorOfDu();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 200));
    final after = colorOfDu();
    await tester.pumpWidget(const SizedBox());
    return (before, after);
  }

  testWidgets('page 2 : le surlignage avance de mot en mot', (tester) async {
    final (before, after) = await highlightOverTime(
      tester,
      reduceMotion: false,
    );
    expect(before, isNot(after));
  });

  testWidgets('« réduire les animations » : surlignage fixe, pages directes', (
    tester,
  ) async {
    final (before, after) = await highlightOverTime(tester, reduceMotion: true);
    expect(before, after);
    expect(before, VoxColors.dark.onWordHighlight);
  });

  testWidgets('accessibilité de l’onboarding', (tester) async {
    await pumpVoxlivre(tester, onboarded: false);

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });

  test('PrefsOnboardingStore retient que l’onboarding a été vu', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();

    final store = await PrefsOnboardingStore.open();
    expect(store.completed, isFalse);

    await store.complete();
    expect(store.completed, isTrue);
    expect((await PrefsOnboardingStore.open()).completed, isTrue);
  });
}

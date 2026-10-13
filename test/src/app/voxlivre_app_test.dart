import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';

void main() {
  // Session ouverte : l'app s'ouvre sur les onglets.
  Future<void> pumpApp(WidgetTester tester) =>
      pumpVoxlivre(tester, token: 'jeton');

  testWidgets('démarre sur la Bibliothèque, en sombre et en français', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.widgetWithText(AppBar, 'Bibliothèque'), findsOneWidget);
    final context = tester.element(find.byType(Scaffold).last);
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(Localizations.localeOf(context), const Locale('fr'));
  });

  testWidgets('les 4 onglets sont joignables depuis la barre du bas', (
    tester,
  ) async {
    await pumpApp(tester);
    // Libellé court de l'onglet → titre de l'écran.
    const tabs = {
      'Importer': 'Importer',
      'Stats': 'Statistiques',
      'Profil': 'Profil',
      'Livres': 'Bibliothèque',
    };
    for (final MapEntry(key: tab, value: title) in tabs.entries) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, title), findsOneWidget, reason: tab);
    }
  });

  testWidgets('chaque onglet a une zone tactile d’au moins 48 dp', (
    tester,
  ) async {
    await pumpApp(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/app/voxlivre_app.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VoxlivreApp()));
    await tester.pumpAndSettle();
  }

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
    for (final tab in ['Importer', 'Statistiques', 'Profil', 'Bibliothèque']) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(tab),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, tab), findsOneWidget, reason: tab);
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

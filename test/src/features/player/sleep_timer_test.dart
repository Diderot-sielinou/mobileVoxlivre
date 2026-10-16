import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/features/player/presentation/sleep_timer.dart';

import '../../../helpers/app_harness.dart';
import '../library/fakes.dart';
import '../library/presentation/library_screen_test.dart' show tallScreen;

const title = 'Droit des obligations';

void main() {
  Future<Harness> open(WidgetTester tester) async {
    tallScreen(tester);
    final h = await pumpVoxlivre(
      tester,
      token: 'jeton',
      library: FakeLibraryRepository(remote: [book('a', title: title)]),
      documents: FakeDocumentRepository(
        remote: {'a': sheet('a', title: title)},
      ),
    );
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Écouter'));
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> leave(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byType(SleepTimerButton));
    await tester.pumpAndSettle();
  }

  testWidgets('15 min : ne compte que pendant l’écoute', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester);
    await openSheet(tester);
    expect(find.text('Courte sieste'), findsOneWidget);
    expect(find.text('1 h'), findsOneWidget);
    expect(find.text('Fondu du son à la fin'), findsOneWidget);

    await tester.tap(find.text('15 min'));
    await tester.pumpAndSettle();
    expect(find.text('15:00'), findsOneWidget, reason: 'décompte visible');

    await tester.pump(const Duration(seconds: 5));
    expect(find.text('15:00'), findsOneWidget, reason: 'en pause');

    await tester.tap(find.byTooltip('Lecture'));
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('14:57'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Minuterie de sommeil, arrêt dans 15 min'),
      findsOneWidget,
    );
    await leave(tester);
    semantics.dispose();
  });

  testWidgets('à zéro : fondu, pause, volume rétabli', (tester) async {
    final h = await open(tester);
    await openSheet(tester);
    await tester.tap(find.text('15 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Lecture'));

    await tester.pump(const Duration(minutes: 14, seconds: 45));
    expect(h.audio.volume, lessThan(1), reason: 'fondu des 30 dernières s');
    expect(h.audio.volume, greaterThan(0));

    await tester.pump(const Duration(seconds: 20));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Lecture'), findsOneWidget, reason: 'en pause');
    expect(h.audio.volume, 1);
    expect(find.byTooltip('Minuterie de sommeil'), findsOneWidget);
    expect(h.positions.position, isNotNull, reason: 'position enregistrée');
    await leave(tester);
  });

  testWidgets('sans fondu : volume intact ; annuler', (tester) async {
    final h = await open(tester);
    await openSheet(tester);
    await tester.tap(find.text('Fondu du son à la fin'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15 min'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Lecture'));
    await tester.pump(const Duration(minutes: 14, seconds: 50));
    expect(h.audio.volume, 1);

    await openSheet(tester);
    expect(find.text('En cours'), findsOneWidget);
    expect(
      find.textContaining('Arrêt dans', findRichText: true),
      findsOneWidget,
    );
    await tester.tap(find.text('Annuler la minuterie'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 30));
    expect(find.byTooltip('Pause'), findsOneWidget, reason: 'continue');
    await leave(tester);
  });

  testWidgets('fin de la page : arrêt au premier mot de la suivante', (
    tester,
  ) async {
    final h = await open(tester);
    h.audio.emit(1000);
    await tester.pumpAndSettle();
    await openSheet(tester);
    // Page 1 : mots 0 à 3 ; la page 2 commence à 4 s.
    expect(find.text('0:03 restantes'), findsOneWidget);
    await tester.tap(find.text('Fin de la page'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Lecture'));

    h.audio.emit(2500);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byTooltip('Pause'), findsOneWidget);
    h.audio.emit(3300);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byTooltip('Pause'), findsOneWidget, reason: 'encore 0,7 s');
    // Arrêt programmé à l'instant près (0,7 s plus tard).
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Lecture'), findsOneWidget, reason: 'arrêté');
    await leave(tester);
  });

  test('libellés', () {
    expect(sleepClock(const Duration(minutes: 27, seconds: 33)), '27:33');
    expect(sleepClock(const Duration(milliseconds: 200)), '0:01');
    expect(sleepSpoken(const Duration(seconds: 40)), contains('moins'));
    expect(sleepSpoken(const Duration(minutes: 4, seconds: 1)), contains('5'));
  });
}

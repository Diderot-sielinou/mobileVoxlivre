import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/app/splash_gate.dart';
import 'package:voxlivre/src/shared/design/vox_theme.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_logo.dart';

void main() {
  var taps = 0;

  Future<void> pumpGate(WidgetTester tester, {bool reduceMotion = false}) {
    taps = 0;
    return tester.pumpWidget(
      MaterialApp(
        theme: VoxTheme.dark,
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: SplashGate(
            child: Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => taps++,
                  child: const Text('Écran'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('le splash couvre l’app, puis s’efface', (tester) async {
    await pumpGate(tester);

    expect(find.text('Lisez. Écoutez. Vivez le livre.'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Voxlivre')), findsOneWidget);
    await tester.tap(find.text('Écran'), warnIfMissed: false);
    expect(taps, 0, reason: 'le splash absorbe les appuis');

    // Centré sur l'écran (bug vu sur le téléphone : collé à gauche).
    expect(
      tester.getCenter(find.byType(VoxLogo)).dx,
      tester.getCenter(find.byType(Scaffold)).dx,
    );

    await tester.pump(const Duration(milliseconds: 450));
    final midway = tester.widget<VoxLogo>(find.byType(VoxLogo)).progress;
    expect(midway, inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(find.byType(VoxLogo), findsNothing);
    await tester.tap(find.text('Écran'));
    expect(taps, 1);
  });

  testWidgets('« réduire les animations » : pas de splash', (tester) async {
    await pumpGate(tester, reduceMotion: true);

    expect(find.byType(VoxLogo), findsNothing);
    expect(find.text('Écran'), findsOneWidget);
  });

  testWidgets('le logo se dessine, à plat comme déployé', (tester) async {
    for (final progress in [0.0, 1.0]) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: VoxLogo(progress: progress)),
        ),
      );
      expect(find.bySemanticsLabel('Logo Voxlivre'), findsOneWidget);
    }
    expect(
      const VoxLogoPainter().shouldRepaint(
        const VoxLogoPainter(progress: 0.5),
      ),
      isTrue,
    );
  });
}

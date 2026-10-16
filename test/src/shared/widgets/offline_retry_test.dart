import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/shared/widgets/offline_retry.dart';

/// L'app passe en arrière-plan puis revient (transitions permises).
void backgroundThenForeground(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

void main() {
  late int retries;

  Widget app({required bool offline}) => MaterialApp(
    home: OfflineRetry(
      offline: offline,
      onRetry: () async => retries++,
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const Text('Lecteur')),
          ),
          child: const Text('Ouvrir'),
        ),
      ),
    ),
  );

  setUp(() => retries = 0);

  test('codes hors ligne', () {
    expect(isOfflineCode('NETWORK_UNAVAILABLE'), isTrue);
    expect(isOfflineCode('TIMEOUT'), isTrue);
    expect(isOfflineCode('SERVER_ERROR'), isFalse);
    expect(isOfflineCode(null), isFalse);
  });

  testWidgets('hors ligne : un essai toutes les 30 s', (tester) async {
    await tester.pumpWidget(app(offline: true));
    await tester.pump(offlineRetryEvery);
    expect(retries, 1);
    await tester.pump(offlineRetryEvery);
    expect(retries, 2);
  });

  testWidgets('en ligne : aucun essai', (tester) async {
    await tester.pumpWidget(app(offline: false));
    await tester.pump(offlineRetryEvery * 3);
    backgroundThenForeground(tester);
    expect(retries, 0);
  });

  testWidgets('retour sur l’écran : un essai ; caché : aucun', (
    tester,
  ) async {
    await tester.pumpWidget(app(offline: true));
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    // Écran couvert par le lecteur : le minuteur n'essaie pas.
    await tester.pump(offlineRetryEvery);
    expect(retries, 0);

    Navigator.of(tester.element(find.text('Lecteur'))).pop();
    await tester.pumpAndSettle();
    expect(retries, 1);
  });

  testWidgets('retour de l’app au premier plan : un essai', (tester) async {
    await tester.pumpWidget(app(offline: true));
    backgroundThenForeground(tester);
    expect(retries, 1);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/features/library/domain/library_item.dart';
import 'package:voxlivre/src/features/player/domain/reading_position.dart';
import 'package:voxlivre/src/features/player/presentation/player_controller.dart';
import 'package:voxlivre/src/features/player/presentation/player_screen.dart';

import '../../../helpers/app_harness.dart';
import '../library/fakes.dart';
import '../library/presentation/library_screen_test.dart' show tallScreen;
import 'fakes.dart';

const title = 'Droit des obligations';

void main() {
  /// Ouvre la fiche de « a » (livre prêt), puis « Écouter ».
  Future<Harness> open(
    WidgetTester tester, {
    FakePlayerGateway? player,
    MemoryPositionStore? positions,
    bool reduceMotion = false,
  }) async {
    tallScreen(tester);
    final h = await pumpVoxlivre(
      tester,
      token: 'jeton',
      library: FakeLibraryRepository(
        remote: [book('a', title: title)],
      ),
      documents: FakeDocumentRepository(
        remote: {'a': sheet('a', title: title)},
      ),
      player: player,
      positions: positions,
      reduceMotion: reduceMotion,
    );
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Écouter'));
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> leave(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('ouvre le livre : texte par pages, reprise à la position', (
    tester,
  ) async {
    final h = await open(
      tester,
      player: FakePlayerGateway(
        remote: ReadingPosition(
          wordIndex: 5,
          audioMs: 5000,
          recordedAt: DateTime.utc(2026, 10, 16),
        ),
      ),
    );

    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing, reason: 'plein écran');
    expect(h.audio.loads.single.startMs, 5000);
    expect(h.audio.loads.single.parts, hasLength(2));
    expect(find.text('Page 2'), findsNWidgets(2), reason: 'en-tête et page');
    expect(
      find.textContaining('Le droit civil.', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('0:05'), findsOneWidget);
    expect(find.text('−0:03'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('lecture : le mot suit la voix ; pause enregistre', (
    tester,
  ) async {
    final h = await open(tester);

    await tester.tap(find.byTooltip('Lecture'));
    await tester.pump();
    expect(find.byTooltip('Pause'), findsOneWidget);

    h.audio.emit(2500);
    await tester.pumpAndSettle();
    expect(find.text('0:02'), findsOneWidget);

    h.audio.emit(4500);
    await tester.pumpAndSettle();
    expect(find.text('Page 2'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Pause'));
    await tester.pumpAndSettle();
    expect(h.player.saved.last.wordIndex, 4);
    expect(h.positions.position?.audioMs, 4500);

    // Toutes les 5 s pendant la lecture.
    await tester.tap(find.byTooltip('Lecture'));
    await tester.pump();
    final before = h.player.saved.length;
    await tester.pump(positionSaveEvery);
    expect(h.player.saved.length, before + 1);
    await leave(tester);
  });

  testWidgets('−15 s, +15 s, curseur, vitesse', (tester) async {
    final h = await open(tester, reduceMotion: true);
    expect(
      find.bySemanticsLabel('Avancer de 15 secondes'),
      findsOneWidget,
      reason: 'le « 15 » dessiné n’est pas lu',
    );

    await tester.tap(find.byTooltip('Avancer de 15 secondes'));
    await tester.pump();
    expect(h.audio.seeks.last, 8000, reason: 'borné à la durée');
    await tester.tap(find.byTooltip('Reculer de 15 secondes'));
    await tester.pump();
    expect(h.audio.seeks.last, 0);

    await tester.drag(find.byType(Slider), const Offset(200, 0));
    await tester.pump();
    expect(h.audio.seeks.last, greaterThan(0));

    await tester.tap(find.text('1×'));
    await tester.pumpAndSettle();
    expect(find.text('Vitesse de lecture'), findsOneWidget);
    await tester.tap(find.text('1,5×'));
    await tester.pumpAndSettle();
    expect(h.audio.speed, 1.5);
    expect(find.text('1,5×'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('fin du livre : pause, une sauvegarde, « Livre terminé » ; '
      'le moteur revient au début sans changer la position', (tester) async {
    final h = await open(tester);
    await tester.tap(find.byTooltip('Lecture'));
    await tester.pump();

    h.audio
      ..emit(8040)
      ..finish();
    await tester.pumpAndSettle();
    expect(find.text('Livre terminé !'), findsOneWidget);
    expect(find.text('pages'), findsOneWidget);
    expect(h.positions.position?.audioMs, 8000, reason: 'fin enregistrée');
    expect(h.audio.seeks.last, 0, reason: '▶ de la notification relance');
    // Le moteur, revenu au début, émet 0 : ni l'écran ni la position ne
    // bougent tant qu'on n'écoute pas.
    h.audio.emit(0);
    final saves = h.player.saved.length;
    await tester.pump(positionSaveEvery * 2);
    expect(h.player.saved, hasLength(saves), reason: 'plus d’envoi en boucle');

    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();
    expect(find.text('0:08'), findsOneWidget);
    expect(find.byTooltip('Lecture'), findsOneWidget);

    await tester.tap(find.byTooltip('Lecture'));
    await tester.pump();
    expect(h.audio.seeks.last, 0);
    expect(find.byTooltip('Pause'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('fin du livre : ▶ de la notification relance du début', (
    tester,
  ) async {
    final h = await open(tester);
    await tester.tap(find.byTooltip('Lecture'));
    await tester.pump();
    h.audio
      ..emit(8040)
      ..finish();
    await tester.pumpAndSettle();

    // La notification joue le moteur directement.
    await h.audio.play();
    h.audio.emit(1500);
    await tester.pumpAndSettle();
    expect(find.text('Livre terminé !'), findsNothing);
    expect(find.text('0:01'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('« Revenir au début » et « Choisir mon prochain livre »', (
    tester,
  ) async {
    final h = await open(tester);
    await tester.tap(find.byTooltip('Lecture'));
    await tester.pump();
    h.audio
      ..emit(8040)
      ..finish();
    await tester.pumpAndSettle();
    expect(find.textContaining('Supprimer l’audio'), findsNothing);

    await tester.tap(find.text('Revenir au début'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Pause'), findsOneWidget);
    expect(find.text('0:00'), findsOneWidget);

    h.audio
      ..emit(8040)
      ..finish();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choisir mon prochain livre'));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerScreen), findsNothing);
    expect(find.widgetWithText(AppBar, 'Bibliothèque'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('aperçu : la suite arrive, puis s’ajoute', (tester) async {
    final player = FakePlayerGateway(
      manifest: testManifest(secondReady: false),
    );
    final h = await open(tester, player: player);

    expect(find.textContaining('Aperçu : 1 partie(s) sur 2'), findsOneWidget);
    expect(h.audio.loads.single.parts, hasLength(1));
    expect(find.textContaining('règle', findRichText: true), findsNothing);

    player.current = testManifest();
    await tester.pump(manifestRefreshEvery);
    await tester.pumpAndSettle();

    expect(h.audio.appended.map((p) => p.index), [1]);
    expect(
      find.textContaining('règle les contrats.', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('Aperçu'), findsNothing);
    await leave(tester);
  });

  testWidgets('URL presque expirées : tout est rechargé à la même place', (
    tester,
  ) async {
    final player = FakePlayerGateway(
      manifest: testManifest(expiresAt: DateTime.utc(2026, 10, 13, 10, 3)),
    );
    final h = await open(tester, player: player);
    expect(h.audio.loads, hasLength(1));

    await tester.pump(manifestRefreshEvery);
    await tester.pumpAndSettle();
    expect(h.audio.loads, hasLength(2));
    await leave(tester);
  });

  testWidgets('erreurs : rien à écouter, réessayer', (tester) async {
    final player = FakePlayerGateway(
      manifest: testManifest(firstReady: false),
    );
    final h = await open(tester, player: player);

    expect(
      find.text('Rien à écouter pour l’instant : la première partie arrive.'),
      findsOneWidget,
    );
    player.current = testManifest();
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(h.audio.loads, hasLength(1));
    await leave(tester);
  });

  testWidgets('quitter le lecteur enregistre la position', (tester) async {
    final h = await open(tester);
    h.audio.emit(3000);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerScreen), findsNothing);
    expect(h.positions.position?.audioMs, 3000);
    expect(h.audio.disposed, isFalse, reason: 'faux injecté, pas libéré');
    await leave(tester);
  });

  testWidgets('la carte « Reprendre » ouvre le lecteur', (tester) async {
    tallScreen(tester);
    await pumpVoxlivre(
      tester,
      token: 'jeton',
      library: FakeLibraryRepository(
        remote: [
          book(
            'a',
            title: title,
            status: LibraryStatus.inProgress,
            progressPercent: 40,
            listenedAt: DateTime.utc(2026, 10, 15),
          ),
        ],
      ),
    );
    await tester.tap(find.text('REPRENDRE LA LECTURE'));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerScreen), findsOneWidget);
    await leave(tester);
  });

  test('messages et libellés', () {
    for (final code in ['UNSUPPORTED_MANIFEST', 'NETWORK_UNAVAILABLE']) {
      expect(playerErrorText(code), isNot(playerErrorText('X')), reason: code);
    }
    expect(speedLabel(1), '1×');
    expect(speedLabel(0.75), '0,75×');
  });
}

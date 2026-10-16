import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/features/library/domain/library_snapshot.dart';
import 'package:voxlivre/src/features/library/presentation/widgets/library_card.dart';
import 'package:voxlivre/src/features/player/application/download_book.dart';
import 'package:voxlivre/src/features/player/presentation/offline_card.dart';
import 'package:voxlivre/src/features/player/presentation/player_screen.dart';

import '../../../helpers/app_harness.dart';
import '../library/fakes.dart';
import '../library/presentation/library_screen_test.dart' show tallScreen;
import 'fakes.dart';

const title = 'Droit des obligations';

void main() {
  /// Ouvre la fiche du livre prêt « a ».
  Future<Harness> sheetOf(
    WidgetTester tester, {
    FakePlayerGateway? player,
  }) async {
    tallScreen(tester);
    final h = await pumpVoxlivre(
      tester,
      token: 'jeton',
      library: FakeLibraryRepository(remote: [book('a', title: title)]),
      documents: FakeDocumentRepository(
        remote: {'a': sheet('a', title: title)},
      ),
      player: player,
    );
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> menu(WidgetTester tester, String item) async {
    await tester.tap(find.byTooltip('Plus d’actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  Future<void> leave(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('télécharger, hors ligne dans la bibliothèque, retirer', (
    tester,
  ) async {
    final h = await sheetOf(tester);

    // « Écouter » reste l'unique bouton principal ; la carte est à côté.
    expect(find.text('Écouter sans connexion'), findsOneWidget);
    expect(find.textContaining('à télécharger'), findsOneWidget);
    expect(
      tester.getSize(find.widgetWithText(OutlinedButton, 'Télécharger')).height,
      greaterThanOrEqualTo(48),
    );
    final before = tester.getSize(find.byType(OfflineCard));
    h.player.hold = Completer<void>();

    await tester.tap(find.text('Télécharger'));
    await tester.pump();
    expect(find.text('Téléchargement…'), findsOneWidget);
    expect(
      tester.getSize(find.byType(OfflineCard)),
      before,
      reason: 'même taille pendant le téléchargement',
    );
    h.player.hold!.complete();
    await tester.pumpAndSettle();

    expect(find.text('Disponible hors ligne'), findsOneWidget);
    expect(find.textContaining('sur le téléphone'), findsOneWidget);
    expect((await h.books.read('c-a'))!.complete, isTrue);

    // La bibliothèque le marque (icône + texte).
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(find.text('Hors ligne'), findsOneWidget);
    expect(find.byIcon(Icons.offline_pin_outlined), findsOneWidget);

    // Retirer : confirmation, puis message.
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    await menu(tester, 'Supprimer l’audio du téléphone');
    expect(find.text('Supprimer l’audio du téléphone ?'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(await h.books.read('c-a'), isNotNull);

    await menu(tester, 'Supprimer l’audio du téléphone');
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Audio supprimé du téléphone'), findsOneWidget);
    expect(await h.books.read('c-a'), isNull);
    expect(find.text('Écouter sans connexion'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('coupure : « Connexion perdue », puis reprise', (tester) async {
    final player = FakePlayerGateway()
      ..failOnce['https://s.test/p1.mp3'] = 'NETWORK_UNAVAILABLE';
    await sheetOf(tester, player: player);

    await tester.tap(find.text('Télécharger'));
    await tester.pumpAndSettle();
    expect(find.text('Connexion perdue'), findsOneWidget);
    expect(find.textContaining('gardés'), findsOneWidget);

    await tester.tap(find.text('Reprendre'));
    await tester.pumpAndSettle();
    expect(find.text('Disponible hors ligne'), findsOneWidget);
    expect(
      player.downloads.where((u) => u.path == '/p0.mp3'),
      hasLength(1),
      reason: 'la partie 0 n’est pas renvoyée',
    );
    await leave(tester);
  });

  testWidgets('annuler pendant le téléchargement', (tester) async {
    final player = FakePlayerGateway()..hold = Completer<void>();
    await sheetOf(tester, player: player);

    await tester.tap(find.text('Télécharger'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Téléchargement…'), findsOneWidget);
    expect(find.textContaining('Partie 1 sur 2'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Téléchargement en pause'), findsOneWidget);
    expect(find.text('Reprendre'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('supprimer le document retire aussi son audio', (tester) async {
    final h = await sheetOf(tester);
    await tester.tap(find.text('Télécharger'));
    await tester.pumpAndSettle();

    await menu(tester, 'Supprimer le document');
    await tester.tap(find.text('Supprimer définitivement'));
    await tester.pumpAndSettle();
    expect(await h.books.read('c-a'), isNull);
    await leave(tester);
  });

  testWidgets('hors ligne : le livre téléchargé s’ouvre, les autres non', (
    tester,
  ) async {
    tallScreen(tester);
    final player = FakePlayerGateway();
    final books = MemoryBookFiles(player.disk);
    await DownloadBook(player, books)('c-a');
    final library = FakeLibraryRepository(
      cached: LibrarySnapshot(
        items: [
          book('a', title: title),
          book('b', title: 'Autre livre'),
        ],
        refreshedAt: DateTime.utc(2026, 10, 13, 9),
      ),
    )..failure = 'NETWORK_UNAVAILABLE';
    await pumpVoxlivre(
      tester,
      token: 'jeton',
      library: library,
      documents: FakeDocumentRepository(cached: sheet('a', title: title))
        ..failure = 'NETWORK_UNAVAILABLE',
      player: player,
      books: books,
    );

    expect(
      find.textContaining('vos livres téléchargés restent disponibles'),
      findsOneWidget,
    );
    expect(find.text('Nécessite une connexion'), findsOneWidget);
    final cards = tester.widgetList<LibraryCard>(find.byType(LibraryCard));
    expect(
      cards.map((c) => (c.item.documentId, c.downloaded, c.onTap != null)),
      [('a', true, true), ('b', false, false)],
    );

    // Le livre téléchargé s'écoute sans manifeste du réseau.
    player
      ..manifests = 0
      ..manifestCode = 'NETWORK_UNAVAILABLE';
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Écouter'));
    await tester.pumpAndSettle();
    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(find.text('Page 1'), findsWidgets);
    expect(player.manifests, 0);
    await leave(tester);
  });

  test('titres d’interruption', () {
    expect(offlineInterruptionTitle('TIMEOUT'), 'Connexion perdue');
    expect(offlineInterruptionTitle('DOWNLOAD_CORRUPT'), contains('abîmé'));
    expect(offlineInterruptionTitle('X'), 'Téléchargement interrompu');
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/features/player/domain/book_text.dart';
import 'package:voxlivre/src/features/player/domain/bookmark.dart';
import 'package:voxlivre/src/features/player/domain/timed_word.dart';
import 'package:voxlivre/src/features/player/presentation/bookmark_sheets.dart';
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
    await tester.tap(find.text('Écouter'));
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> leave(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  /// Au mot « règle » (page 2, 1er mot, 0:04), avec une note.
  Future<void> addAtRegle(WidgetTester tester, Harness h, String note) async {
    h.audio.emit(4500);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Ajouter un marque-page'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), note);
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
  }

  Future<void> openList(WidgetTester tester) async {
    await tester.tap(find.byTooltip(RegExp('^Marque-pages')));
    await tester.pumpAndSettle();
  }

  testWidgets('poser : page, minutage, extrait, note ; envoyé ; icône pleine', (
    tester,
  ) async {
    final h = await open(tester);
    h.audio.emit(4500);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ajouter un marque-page'));
    await tester.pumpAndSettle();
    expect(find.text('Ajouter un marque-page'), findsOneWidget);
    expect(find.text('Page 2 · 0:04'), findsOneWidget);
    expect(find.text('« règle les contrats. Fin… »'), findsOneWidget);
    expect(find.text('0/2000'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Définition clé');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Marque-page ajouté'), findsOneWidget);
    final saved = h.bookmarks.rows.values.single;
    expect((saved.pageNumber, saved.wordIndex), (2, 0));
    expect(saved.note, 'Définition clé');
    expect(saved.pending, isFalse, reason: 'envoyé tout de suite');
    expect(h.player.server, contains(saved.id));
    expect(
      find.byTooltip('Ajouter un marque-page (page déjà marquée)'),
      findsOneWidget,
    );
    await leave(tester);
  });

  testWidgets('liste : la carte place la lecture au mot', (tester) async {
    final h = await open(tester);
    await addAtRegle(tester, h, 'à revoir');
    h.audio.emit(500);
    await tester.pumpAndSettle();

    await openList(tester);
    expect(find.text('Tous (1)'), findsOneWidget);
    expect(find.text('Avec notes (1)'), findsOneWidget);
    expect(find.text('« règle les contrats. Fin… »'), findsOneWidget);
    expect(find.text('à revoir'), findsOneWidget);
    expect(find.text('p. 2 · 0:04 · Créé à l’instant'), findsOneWidget);

    await tester.tap(find.text('à revoir'));
    await tester.pumpAndSettle();
    expect(h.audio.seeks.last, 4000);
    expect(find.text('Tous (1)'), findsNothing, reason: 'feuille fermée');
    await leave(tester);
  });

  testWidgets('modifier la note, puis supprimer avec confirmation', (
    tester,
  ) async {
    final h = await open(tester);
    await addAtRegle(tester, h, 'avant');
    await openList(tester);

    await tester.tap(find.byTooltip('Actions du marque-page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier la note'));
    await tester.pumpAndSettle();
    expect(find.text('Modifier la note'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'après');
    await tester.tap(find.text('Enregistrer la note'));
    await tester.pumpAndSettle();
    expect(find.text('après'), findsOneWidget);
    expect(h.player.server.values.single.note, 'après');

    await tester.tap(find.byTooltip('Actions du marque-page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer'));
    await tester.pumpAndSettle();
    expect(find.text('Supprimer ce marque-page ?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Supprimer'));
    await tester.pumpAndSettle();

    // Dans la feuille : un SnackBar resterait caché dessous.
    expect(
      find.descendant(
        of: find.byType(BookmarksSheet),
        matching: find.text('Marque-page supprimé'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Aucun marque-page'), findsOneWidget);
    expect(h.bookmarks.rows, isEmpty, reason: 'trace envoyée puis retirée');
    expect(h.player.server.values.single.deleted, isTrue);
    await leave(tester);
  });

  testWidgets('glisser pour supprimer : annuler garde le marque-page', (
    tester,
  ) async {
    final h = await open(tester);
    await addAtRegle(tester, h, '');
    await openList(tester);

    await tester.drag(
      find.text('« règle les contrats. Fin… »'),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('« règle les contrats. Fin… »'), findsOneWidget);
    expect(h.bookmarks.rows, hasLength(1));
    await leave(tester);
  });

  testWidgets('hors ligne : posé quand même, « en attente » ; à vérifier', (
    tester,
  ) async {
    final player = FakePlayerGateway();
    final at = DateTime.utc(2026, 10, 12);
    player.server['ailleurs'] = Bookmark(
      id: 'ailleurs',
      documentId: 'd-1',
      pageNumber: 1,
      wordIndex: 1,
      excerpt: 'droit civil. Il',
      note: '',
      createdAt: at,
      updatedAt: at,
      needsReview: true,
    );
    final h = await open(tester, player: player);
    h.player.bookmarkCode = 'NETWORK_UNAVAILABLE';
    await addAtRegle(tester, h, '');
    await openList(tester);

    expect(find.text('Tous (2)'), findsOneWidget);
    expect(find.text('À vérifier (1)'), findsOneWidget);
    expect(find.text('En attente de synchronisation'), findsOneWidget);
    expect(find.text('À vérifier'), findsOneWidget);

    await tester.tap(find.text('À vérifier (1)'));
    await tester.pumpAndSettle();
    expect(find.text('« droit civil. Il… »'), findsOneWidget);
    expect(find.text('« règle les contrats. Fin… »'), findsNothing);
    await leave(tester);
  });

  testWidgets('appui long sur un mot : marque-page à cet endroit', (
    tester,
  ) async {
    await open(tester);
    await tester.longPress(
      find.textContaining('Le droit civil.', findRichText: true),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ajouter un marque-page'), findsOneWidget);
    expect(find.textContaining('Page 1 · '), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    await leave(tester);
  });

  test('mot sous un caractère de la page (mots séparés d’une espace)', () {
    final text = BookText([
      for (final (i, w) in ['Le', 'droit', 'civil.'].indexed)
        TimedWord(index: i, text: w, startMs: i, endMs: i),
    ], const []);
    // « Le droit civil. » : L=0, espace=2, d=3, espace=8, c=9.
    expect(wordAtOffset(text, 0, 2, 0), 0);
    expect(wordAtOffset(text, 0, 2, 2), 0, reason: 'espace après « Le »');
    expect(wordAtOffset(text, 0, 2, 3), 1);
    expect(wordAtOffset(text, 0, 2, 9), 2);
    expect(wordAtOffset(text, 0, 2, 99), 2, reason: 'après la fin');
  });

  testWidgets('posé hors ligne : « Créé », même si le serveur le date '
      'à son arrivée', (tester) async {
    final player = FakePlayerGateway();
    player.server['b'] = Bookmark(
      id: 'b',
      documentId: 'd-1',
      pageNumber: 1,
      wordIndex: 0,
      excerpt: 'Le droit',
      note: '',
      // Arrivé au serveur 2 min après avoir été posé.
      createdAt: DateTime.utc(2026, 10, 13, 9, 2),
      updatedAt: DateTime.utc(2026, 10, 13, 9),
    );
    await open(tester, player: player);
    await openList(tester);
    expect(find.textContaining('Créé il y a 1 h'), findsOneWidget);
    await leave(tester);
  });
}

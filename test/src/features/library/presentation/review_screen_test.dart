import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/features/library/domain/document_page.dart';
import 'package:voxlivre/src/features/library/domain/document_sheet.dart';
import 'package:voxlivre/src/features/library/presentation/document_screen.dart';
import 'package:voxlivre/src/features/library/presentation/review_screen.dart';

import '../../../../helpers/app_harness.dart';
import '../fakes.dart';
import 'library_screen_test.dart' show tallScreen;

const title = 'Droit des obligations';
const header = SetAsideLine('DROIT CIVIL — L2', SetAsideReason.header);

final List<DocumentPage> scanPages = [
  page(1, confidence: 0.95),
  page(2, confidence: 0.62, setAside: [header]),
  page(3, confidence: 0.7),
];

void main() {
  /// Ouvre la fiche de « a » (scan à relire), puis la vérification.
  Future<Harness> open(
    WidgetTester tester, {
    List<DocumentPage>? pages,
    bool reviewRequired = true,
    String? failure,
    bool viaMenu = false,
  }) async {
    tallScreen(tester);
    final documents = FakeDocumentRepository(
      remote: {
        'a': sheet(
          'a',
          title: title,
          method: ExtractionMethod.ocr,
          reviewRequired: reviewRequired,
        ),
      },
    );
    final texts = FakeDocumentTextRepository(
      remote: pages ?? scanPages,
      onReviewed: () async {
        documents.remote['a'] = sheet(
          'a',
          title: title,
          reviewRequired: true,
          reviewedAt: DateTime.utc(2026, 10, 15),
        );
        await documents.refresh('a');
      },
    )..failure = failure;
    final h = await pumpVoxlivre(
      tester,
      token: 'jeton',
      library: FakeLibraryRepository(remote: [book('a', title: title)]),
      documents: documents,
      texts: texts,
    );
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    if (viaMenu) {
      await tester.tap(find.byTooltip('Plus d’actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voir le texte'));
    } else {
      await tester.tap(find.text('Vérifier le texte'));
    }
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> leave(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('les pages à relire d’abord, confiance en icône et texte', (
    tester,
  ) async {
    await open(tester);

    expect(find.byType(ReviewScreen), findsOneWidget);
    expect(find.text('À vérifier (2)'), findsOneWidget);
    expect(find.text('Toutes (3)'), findsOneWidget);
    expect(find.text('Page 2 sur 3'), findsOneWidget);
    expect(find.text('Confiance 62 % · à relire'), findsOneWidget);
    expect(find.text('Texte de la page 2.'), findsOneWidget);
    expect(find.text('p. 1'), findsNothing, reason: 'filtre « À vérifier »');

    await tester.tap(find.text('Page 3'));
    await tester.pumpAndSettle();
    expect(find.text('Page 3 sur 3'), findsOneWidget);

    await tester.tap(find.text('Page 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toutes (3)'));
    await tester.pumpAndSettle();
    expect(find.text('Page 1 sur 3'), findsOneWidget);
    expect(find.text('Confiance 95 %'), findsOneWidget);

    await tester.tap(find.text('p. 3'));
    await tester.pumpAndSettle();
    expect(find.text('Page 3 sur 3'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('corriger une page : échec gardé, puis enregistrée', (
    tester,
  ) async {
    final h = await open(tester);
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Texte corrigé.');
    expect(
      find.text('J’ai relu le texte'),
      findsNothing,
      reason: 'barre masquée pendant l’édition (clavier)',
    );

    h.texts.failure = 'NETWORK_UNAVAILABLE';
    await tester.tap(find.text('Enregistrer la page'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pas de connexion'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Texte corrigé.'), findsOneWidget);

    h.texts.failure = null;
    await tester.tap(find.text('Enregistrer la page'));
    await tester.pumpAndSettle();
    expect(h.texts.saved, [(2, 'Texte corrigé.')]);
    expect(find.text('Page 2 enregistrée'), findsOneWidget);
    expect(find.text('Texte corrigé.'), findsOneWidget);
    expect(h.documents.refreshes, greaterThanOrEqualTo(2));

    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await leave(tester);
  });

  testWidgets('réintégrer une ligne retirée', (tester) async {
    final h = await open(tester);

    await tester.tap(find.text('Lignes retirées de la lecture (1)'));
    await tester.pumpAndSettle();
    expect(find.text('En-tête'), findsOneWidget);
    await tester.tap(find.text('Réintégrer'));
    await tester.pumpAndSettle();
    expect(
      find.widgetWithText(TextField, 'DROIT CIVIL — L2\nTexte de la page 2.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Enregistrer la page'));
    await tester.pumpAndSettle();
    expect(h.texts.saved.single.$2, startsWith('DROIT CIVIL'));
    expect(
      find.text('Lignes retirées de la lecture (1)'),
      findsNothing,
      reason: 'déjà dans le texte',
    );
    await leave(tester);
  });

  testWidgets('« J’ai relu » : retour à la fiche, conversion débloquée', (
    tester,
  ) async {
    final h = await open(tester);

    h.texts.failure = 'SERVER_ERROR';
    await tester.tap(find.text('J’ai relu le texte'));
    await tester.pumpAndSettle();
    expect(find.text('L’enregistrement a échoué. Réessayez.'), findsOneWidget);

    h.texts.failure = null;
    await tester.tap(find.text('J’ai relu le texte'));
    await tester.pumpAndSettle();
    expect(h.texts.reviews, 1);
    expect(find.byType(DocumentScreen), findsOneWidget);
    expect(
      find.text('Texte relu : vous pouvez lancer la conversion.'),
      findsOneWidget,
    );
    expect(find.text('Vérifier le texte'), findsNothing);
    expect(find.text('Après relecture'), findsNothing);
    await leave(tester);
  });

  testWidgets('PDF texte : « Voir le texte » par le menu, sans relecture', (
    tester,
  ) async {
    await open(
      tester,
      pages: [
        page(1),
        page(2, text: ''),
      ],
      reviewRequired: false,
      viaMenu: true,
    );

    expect(find.text('À vérifier (0)'), findsNothing);
    expect(find.text('Toutes (2)'), findsOneWidget);
    expect(find.textContaining('Confiance'), findsNothing);
    expect(find.text('J’ai relu le texte'), findsNothing);
    await tester.tap(find.text('Page 2'));
    await tester.pumpAndSettle();
    expect(find.text('(page vide)'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('hors ligne sans cache : le bandeau le dit', (tester) async {
    await open(tester, failure: 'NETWORK_UNAVAILABLE');

    expect(
      find.text('Hors ligne : le texte s’affichera au retour du réseau.'),
      findsOneWidget,
    );
    await leave(tester);
  });

  test('libellés et messages', () {
    expect(
      SetAsideReason.values.map(setAsideLabel).toSet(),
      hasLength(SetAsideReason.values.length),
    );
    for (final code in ['INVALID_PAGE_TEXT', 'DOCUMENT_TEXT_NOT_READY']) {
      expect(reviewErrorText(code), isNot(reviewErrorText('X')));
    }
  });
}

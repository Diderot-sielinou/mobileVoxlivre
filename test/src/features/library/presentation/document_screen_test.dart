import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/features/library/domain/document_sheet.dart';
import 'package:voxlivre/src/features/library/domain/library_item.dart';
import 'package:voxlivre/src/features/library/presentation/document_screen.dart';
import 'package:voxlivre/src/features/library/presentation/widgets/library_card.dart';
import 'package:voxlivre/src/features/library/presentation/widgets/outline_section.dart';
import 'package:voxlivre/src/shared/design/widgets/vox_cover.dart';
import 'package:voxlivre/src/shared/format/durations.dart';

import '../../../../helpers/app_harness.dart';
import '../fakes.dart';
import 'library_screen_test.dart' show tallScreen;

const title = 'Droit des obligations';

final List<OutlineEntry> outline = [
  for (var i = 1; i <= 7; i++)
    OutlineEntry(
      title: 'Chapitre $i',
      level: i.isOdd ? 1 : 2,
      pageNumber: i * 10,
    ),
];

void main() {
  /// Ouvre la fiche de « a » depuis la bibliothèque.
  Future<Harness> open(
    WidgetTester tester, {
    DocumentSheet? remote,
    DocumentSheet? cached,
    String? failure,
    LibraryStatus status = LibraryStatus.notConverted,
    bool reduceMotion = false,
  }) async {
    tallScreen(tester);
    final documents = FakeDocumentRepository(
      remote: {'a': ?remote},
      cached: cached,
    )..failure = failure;
    final h = await pumpVoxlivre(
      tester,
      token: 'jeton',
      library: FakeLibraryRepository(
        remote: [
          book(
            'a',
            title: title,
            status: status,
            partsReady: 8,
            partCount: 10,
          ),
        ],
      ),
      documents: documents,
      reduceMotion: reduceMotion,
    );
    await tester.tap(find.byType(LibraryCard));
    await tester.pumpAndSettle();
    return h;
  }

  /// Les minuteurs (10 s ici, 15 s dans la bibliothèque) tournent : on
  /// quitte l'app avant la fin du test.
  Future<void> leave(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  Future<void> menu(WidgetTester tester, String action) async {
    await tester.tap(find.byTooltip('Plus d’actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(action));
    await tester.pumpAndSettle();
  }

  testWidgets('toucher une carte ouvre la fiche : infos et table', (
    tester,
  ) async {
    final h = await open(
      tester,
      remote: sheet('a', title: title, outline: outline),
    );

    expect(find.byType(DocumentScreen), findsOneWidget);
    expect(h.documents.refreshes, 1);
    expect(find.text(title), findsOneWidget);
    expect(find.text('DO'), findsOneWidget, reason: 'initiales');
    expect(find.text('120 pages'), findsOneWidget);
    expect(find.text('214 300 caractères'), findsOneWidget);
    expect(find.text('Texte'), findsOneWidget);
    expect(find.byType(OutlineRow), findsNWidgets(OutlineSection.preview));
    final semantics = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(RegExp('Chapitre 1, page 10')),
      findsOneWidget,
    );
    semantics.dispose();
    expect(find.text('Choisir la voix et convertir'), findsOneWidget);
    expect(find.text('Disponible à l’étape conversion'), findsNothing);

    await tester.tap(find.text('Tout voir (7)'));
    await tester.pumpAndSettle();
    expect(find.byType(OutlineRow), findsNWidgets(5 + 7));

    await leave(tester);
  });

  testWidgets('un livre prêt propose d’écouter', (
    tester,
  ) async {
    await open(
      tester,
      remote: sheet('a', title: title),
      status: LibraryStatus.ready,
      reduceMotion: true,
    );

    expect(find.text('Écouter'), findsOneWidget);
    expect(find.text('Disponible avec le lecteur'), findsNothing);
    await leave(tester);
  });

  testWidgets('un scan à relire : avertissement et conversion verrouillée', (
    tester,
  ) async {
    await open(
      tester,
      remote: sheet(
        'a',
        title: title,
        method: ExtractionMethod.ocr,
        reviewRequired: true,
      ),
    );

    expect(find.text('Scan (OCR)'), findsOneWidget);
    expect(
      find.text(
        'Relecture obligatoire : certaines pages ont été mal reconnues.',
      ),
      findsOneWidget,
    );
    expect(find.text('Vérifier le texte'), findsOneWidget);
    expect(find.text('Après relecture'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('texte en préparation : progression, relu toutes les 10 s', (
    tester,
  ) async {
    final h = await open(
      tester,
      remote: sheet(
        'a',
        title: title,
        stage: DocumentStage.extracting,
        method: null,
        ocrProgress: (done: 20, total: 120),
      ),
      status: LibraryStatus.processing,
    );

    expect(find.text('Analyse en cours'), findsOneWidget);
    expect(find.text('Reconnaissance du texte'), findsOneWidget);
    expect(find.text('20/120 pages'), findsOneWidget);
    expect(find.text('Scan détecté : le texte est une image'), findsOneWidget);
    expect(find.text('Terminé'), findsNWidgets(2), reason: 'reçu, lu');
    expect(find.text('En cours'), findsOneWidget);
    expect(
      find.text('En attente'),
      findsNWidgets(2),
      reason: 'nettoyage, prêt',
    );
    expect(find.text('Pourquoi ce nettoyage ?'), findsOneWidget);
    expect(find.text('Choisir la voix et convertir'), findsNothing);

    await tester.pump(documentWorkRefresh);
    expect(h.documents.refreshes, 2);
    await leave(tester);
  });

  testWidgets('PDF texte en lecture : pas d’étape de reconnaissance', (
    tester,
  ) async {
    await open(
      tester,
      remote: sheet(
        'a',
        title: title,
        stage: DocumentStage.extracting,
        method: null,
      ),
      status: LibraryStatus.processing,
      reduceMotion: true,
    );

    expect(find.text('Lecture du PDF'), findsOneWidget);
    expect(find.text('Reconnaissance du texte'), findsNothing);
    expect(find.text('En cours'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('extraction ratée : la raison est dite', (tester) async {
    await open(
      tester,
      remote: sheet(
        'a',
        title: title,
        stage: DocumentStage.failed,
        extractionError: 'ocr_no_text',
      ),
    );

    expect(find.text('Le texte n’a pas pu être extrait'), findsOneWidget);
    expect(find.textContaining('Aucun texte reconnu'), findsOneWidget);
    await leave(tester);
  });

  group('erreurs du rafraîchissement', () {
    testWidgets('hors ligne avec la fiche en cache', (tester) async {
      await open(
        tester,
        cached: sheet('a', title: title),
        failure: 'NETWORK_UNAVAILABLE',
      );

      expect(
        find.text('Hors ligne : fiche enregistrée sur l’appareil.'),
        findsOneWidget,
      );
      expect(find.text('120 pages'), findsOneWidget);
      await leave(tester);
    });

    testWidgets('hors ligne sans cache : le titre de la bibliothèque', (
      tester,
    ) async {
      await open(tester, failure: 'TIMEOUT');

      expect(
        find.text('Hors ligne : la fiche s’affichera au retour du réseau.'),
        findsOneWidget,
      );
      expect(find.text(title), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await leave(tester);
    });

    testWidgets('document disparu, ou service en panne', (tester) async {
      final h = await open(tester, failure: 'DOCUMENT_NOT_FOUND');
      expect(find.textContaining('Ce document n’existe plus'), findsOneWidget);

      h.documents.failure = 'SERVER_ERROR';
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 500),
        1000,
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Service momentanément indisponible'),
        findsOneWidget,
      );
      await leave(tester);
    });
  });

  testWidgets('renommer : titre refusé, hors ligne, puis réussi', (
    tester,
  ) async {
    final h = await open(tester, remote: sheet('a', title: title));
    await menu(tester, 'Renommer');

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.widgetWithText(FilledButton, 'Renommer'));
    await tester.pumpAndSettle();
    expect(find.text('Entrez un titre de 1 à 200 caractères.'), findsOneWidget);

    h.documents.failure = 'NETWORK_UNAVAILABLE';
    await tester.enterText(find.byType(TextField), 'Obligations L2');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      find.text('Pas de connexion : le titre n’a pas été changé.'),
      findsOneWidget,
    );

    h.documents.failure = 'SERVER_ERROR';
    await tester.tap(find.widgetWithText(FilledButton, 'Renommer'));
    await tester.pumpAndSettle();
    expect(
      find.text('Le titre n’a pas pu être changé. Réessayez.'),
      findsOneWidget,
    );

    h.documents.failure = null;
    await tester.tap(find.widgetWithText(FilledButton, 'Renommer'));
    await tester.pumpAndSettle();
    expect(h.documents.renamed, ['Obligations L2']);
    expect(find.text('Document renommé'), findsOneWidget);
    expect(find.text('Obligations L2'), findsOneWidget);

    await menu(tester, 'Renommer');
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    await leave(tester);
  });

  group('supprimer', () {
    testWidgets('confirmé : retour à la bibliothèque', (tester) async {
      final h = await open(tester, remote: sheet('a', title: title));
      await menu(tester, 'Supprimer le document');

      expect(find.text('ACTION IRRÉVERSIBLE'), findsOneWidget);
      expect(find.text('Supprimer « $title » ?'), findsOneWidget);

      await tester.tap(find.text('Supprimer définitivement'));
      await tester.pumpAndSettle();

      expect(h.documents.deleted, ['a']);
      expect(find.byType(DocumentScreen), findsNothing);
      expect(find.text('Document supprimé'), findsOneWidget);
      await leave(tester);
    });

    testWidgets('conversion en cours : « Suppression suspendue »', (
      tester,
    ) async {
      final h = await open(
        tester,
        remote: sheet('a', title: title),
        status: LibraryStatus.processing,
      );
      h.documents.failure = 'DOCUMENT_DELETION_CONFLICT';
      await menu(tester, 'Supprimer le document');
      await tester.tap(find.text('Supprimer définitivement'));
      await tester.pumpAndSettle();

      expect(find.text('Suppression suspendue'), findsOneWidget);
      expect(find.text('Conversion · 8/10 parties'), findsWidgets);

      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      expect(find.byType(DocumentScreen), findsOneWidget);
      await leave(tester);
    });

    testWidgets('hors ligne ou en panne : rien n’est supprimé', (
      tester,
    ) async {
      final h = await open(tester, remote: sheet('a', title: title));
      h.documents.failure = 'NETWORK_UNAVAILABLE';
      await menu(tester, 'Supprimer le document');
      await tester.tap(find.text('Supprimer définitivement'));
      await tester.pumpAndSettle();
      expect(
        find.text('Pas de connexion : rien n’a été supprimé.'),
        findsOneWidget,
      );

      h.documents.failure = 'SERVER_ERROR';
      await tester.tap(find.text('Supprimer définitivement'));
      await tester.pumpAndSettle();
      expect(
        find.text('La suppression a échoué. Réessayez dans un instant.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(h.documents.deleted, isEmpty);
      expect(find.byType(DocumentScreen), findsOneWidget);
      await leave(tester);
    });
  });

  group('formats', () {
    test('nombres à la française', () {
      expect(VoxFormat.count(0), '0');
      expect(VoxFormat.count(999), '999');
      expect(VoxFormat.count(214300), '214 300');
      expect(VoxFormat.count(-1234567), '-1 234 567');
    });

    testWidgets('petite couverture : initiales sur une ligne', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: VoxCover(title: 'Essai gros envoi', width: 44, height: 56),
          ),
        ),
      );
      final text = tester.getRect(find.text('EG'));
      final cover = tester.getRect(find.byType(VoxCover));
      expect(text.height, lessThan(cover.height / 2));
      expect(tester.takeException(), isNull);
    });

    test('initiales de la couverture : mots porteurs de sens', () {
      expect(VoxCover.initialsOf('Droit des obligations — L2'), 'DO');
      expect(VoxCover.initialsOf('L’économie du Cameroun'), 'ÉC');
      expect(VoxCover.initialsOf('de la'), 'DL');
      expect(VoxCover.initialsOf(' — '), '?');
    });
  });
}

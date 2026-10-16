import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/features/conversion/domain/conversion.dart';
import 'package:voxlivre/src/features/conversion/presentation/conversion_screen.dart';
import 'package:voxlivre/src/features/conversion/presentation/convert_screen.dart';
import 'package:voxlivre/src/features/library/domain/library_item.dart';
import 'package:voxlivre/src/features/library/presentation/document_screen.dart';

import '../../../helpers/app_harness.dart';
import '../library/fakes.dart';
import '../library/presentation/library_screen_test.dart' show tallScreen;
import 'fakes.dart';

const title = 'Droit des obligations';

void main() {
  /// Ouvre la fiche de « a » (texte prêt, 214 300 caractères).
  Future<Harness> openSheet(
    WidgetTester tester, {
    FakeConversionGateway? conversions,
    LibraryItem? item,
  }) async {
    tallScreen(tester);
    final h = await pumpVoxlivre(
      tester,
      token: 'jeton',
      library: FakeLibraryRepository(
        remote: [
          item ?? book('a', title: title, status: LibraryStatus.notConverted),
        ],
      ),
      documents: FakeDocumentRepository(
        remote: {'a': sheet('a', title: title)},
      ),
      conversions: conversions,
    );
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    return h;
  }

  /// Fiche → « Choisir la voix et convertir ».
  Future<Harness> openConvert(
    WidgetTester tester, {
    FakeConversionGateway? conversions,
  }) async {
    final h = await openSheet(tester, conversions: conversions);
    await tester.tap(find.text('Choisir la voix et convertir'));
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> leave(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('voix, coûts, lancement puis suivi', (tester) async {
    final h = await openConvert(
      tester,
      conversions: FakeConversionGateway(account: unitsAccount(free: 300000)),
    );

    expect(find.byType(ConvertScreen), findsOneWidget);
    expect(find.text('214 300 caractères'), findsOneWidget);
    expect(
      find.text('Utilisable pour cette voix : 300 000 unités'),
      findsOneWidget,
    );
    expect(find.text('Standard ×1 · 214 300 unités'), findsNWidgets(2));
    expect(find.text('Naturelle ×4 · 857 200 unités'), findsOneWidget);
    expect(find.text('Unités insuffisantes'), findsOneWidget, reason: 'Léa');
    expect(
      find.text('Amina · 214 300 unités seront décomptées.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Convertir'));
    await tester.pumpAndSettle();

    expect(h.conversions.started, [('a', 'fr-f2')]);
    expect(find.byType(ConversionScreen), findsOneWidget);
    expect(find.text('Génération en cours'), findsOneWidget);
    expect(find.text('Étape 1 sur 4'), findsOneWidget);
    expect(find.text(title), findsOneWidget);
    expect(h.library.refreshes, greaterThanOrEqualTo(2));
    await leave(tester);
  });

  testWidgets('voix naturelle trop chère : le manque, et la voix standard', (
    tester,
  ) async {
    await openConvert(
      tester,
      conversions: FakeConversionGateway(account: unitsAccount(free: 300000)),
    );

    await tester.tap(find.text('Léa'));
    await tester.pumpAndSettle();
    expect(
      find.text('Il vous manque 857 200 unités pour la voix Léa.'),
      findsOneWidget,
    );
    expect(find.textContaining('(voix standard seulement)'), findsOneWidget);
    expect(find.text('Aucune unité n’a été décomptée.'), findsOneWidget);
    expect(find.text('Par Orange Money ou MTN MoMo.'), findsOneWidget);

    await tester.tap(find.text('Passer en voix standard (Amina)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Amina · '), findsOneWidget);
    expect(find.textContaining('Il vous manque'), findsNothing);
    await leave(tester);
  });

  testWidgets('le 402 du backend fait foi', (tester) async {
    final gateway = FakeConversionGateway(account: unitsAccount(free: 300000))
      ..startFailure = 'QUOTA_EXCEEDED'
      ..startDetails = {'requested': 214300, 'usable': 14300};
    await openConvert(tester, conversions: gateway);

    await tester.tap(find.text('Convertir'));
    await tester.pumpAndSettle();

    expect(
      find.text('Il vous manque 200 000 unités pour la voix Amina.'),
      findsOneWidget,
    );
    expect(find.byType(ConvertScreen), findsOneWidget);
    await leave(tester);
  });

  testWidgets('autres refus : message par code', (tester) async {
    final gateway = FakeConversionGateway(account: unitsAccount(free: 300000))
      ..startFailure = 'DOCUMENT_REVIEW_REQUIRED';
    await openConvert(tester, conversions: gateway);

    await tester.tap(find.text('Convertir'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Relisez d’abord le texte : certaines pages ont été mal reconnues.',
      ),
      findsOneWidget,
    );
    await leave(tester);
  });

  testWidgets('document trop long, et chargement raté puis repris', (
    tester,
  ) async {
    final gateway = FakeConversionGateway(account: unitsAccount(maxChars: 1000))
      ..failure = 'NETWORK_UNAVAILABLE';
    await openConvert(tester, conversions: gateway);

    expect(
      find.text('Pas de connexion. Réessayez quand le réseau revient.'),
      findsOneWidget,
    );
    gateway.failure = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.textContaining('caractères par conversion'), findsOneWidget);
    expect(find.text('Aucune unité n’a été décomptée.'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('suivi : synthèse, puis prêt ; la bibliothèque est relue', (
    tester,
  ) async {
    final gateway = FakeConversionGateway(
      account: unitsAccount(free: 300000),
      states: [
        conversion(ConversionStage.queued),
        conversion(
          ConversionStage.synthesizing,
          segmentsDone: 3,
          segmentCount: 10,
          partsReady: 1,
          partCount: 4,
        ),
        conversion(ConversionStage.ready, partsReady: 4, partCount: 4),
      ],
    );
    final h = await openConvert(tester, conversions: gateway);
    await tester.tap(find.text('Convertir'));
    await tester.pumpAndSettle();
    expect(find.text('Étape 1 sur 4'), findsOneWidget);

    await tester.pump(conversionRefresh);
    await tester.pumpAndSettle();
    expect(find.text('Étape 2 sur 4'), findsOneWidget);
    expect(find.text('Partie 2 sur 4 · 30 %'), findsOneWidget);
    expect(find.text('En cours'), findsOneWidget);
    expect(find.text('Terminé'), findsOneWidget);
    expect(find.text('Vous pouvez quitter cet écran.'), findsOneWidget);

    final before = h.library.refreshes;
    await tester.pump(conversionRefresh);
    await tester.pumpAndSettle();
    expect(find.text('Livre audio prêt'), findsNWidgets(2));
    expect(find.text('4 parties'), findsOneWidget);
    expect(find.text('Écouter'), findsOneWidget);
    expect(h.library.refreshes, before + 1);

    final fetches = gateway.fetches;
    await tester.pump(conversionRefresh);
    expect(gateway.fetches, fetches, reason: 'plus de suivi une fois prête');

    await tester.tap(find.text('Retour à la bibliothèque'));
    await tester.pumpAndSettle();
    expect(find.byType(ConversionScreen), findsNothing);
    await leave(tester);
  });

  testWidgets('échec : la raison, puis « Réessayer » revient à la fiche', (
    tester,
  ) async {
    final gateway = FakeConversionGateway(
      account: unitsAccount(free: 300000),
      states: [
        conversion(ConversionStage.failed, failureReason: 'text_changed'),
      ],
    );
    await openConvert(tester, conversions: gateway);
    await tester.tap(find.text('Convertir'));
    await tester.pumpAndSettle();

    expect(find.text('La conversion a échoué'), findsOneWidget);
    expect(find.textContaining('Le texte a été corrigé'), findsOneWidget);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.byType(DocumentScreen), findsOneWidget);
    await leave(tester);
  });

  testWidgets('fiche : une conversion en cours se suit ; hors ligne', (
    tester,
  ) async {
    final gateway = FakeConversionGateway()..failure = 'NETWORK_UNAVAILABLE';
    await openSheet(
      tester,
      conversions: gateway,
      item: LibraryItem(
        documentId: 'a',
        title: title,
        status: LibraryStatus.processing,
        importedAt: DateTime.utc(2026, 10, 2),
        conversion: const ConversionSummary(
          id: 'c-9',
          status: 'synthesizing',
          partsReady: 1,
          partCount: 4,
          playable: Duration.zero,
        ),
      ),
    );

    await tester.tap(find.text('Suivre la conversion'));
    await tester.pumpAndSettle();
    expect(find.byType(ConversionScreen), findsOneWidget);
    expect(
      find.text('Hors ligne : l’état s’affichera au retour du réseau.'),
      findsOneWidget,
    );
    await leave(tester);
  });

  test('messages par code', () {
    for (final code in [
      'DOCUMENT_TEXT_NOT_READY',
      'QUOTA_CONVERSION_LIMIT_EXCEEDED',
      'INVALID_VOICE',
      'INVALID_CONVERSION_TEXT',
    ]) {
      expect(startErrorText(code), isNot(startErrorText('X')), reason: code);
    }
    for (final reason in ['source_unavailable', 'empty_text', 'tts_rejected']) {
      expect(
        conversionFailureText(reason),
        isNot(conversionFailureText(null)),
        reason: reason,
      );
    }
  });
}

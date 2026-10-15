import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/features/library/domain/document_import.dart';
import 'package:voxlivre/src/features/library/presentation/document_screen.dart';
import 'package:voxlivre/src/features/library/presentation/import_screen.dart';

import '../../../../helpers/app_harness.dart';
import '../fakes.dart';
import 'library_screen_test.dart' show tallScreen;

void main() {
  /// Ouvre l'onglet Importer, un PDF prêt à être « choisi ».
  Future<Harness> open(
    WidgetTester tester, {
    PickedPdf? file,
    FakeUploads? uploads,
  }) async {
    tallScreen(tester);
    final h = await pumpVoxlivre(
      tester,
      token: 'jeton',
      pdfs: FakePdfSource(next: file ?? pdf()),
      uploads: uploads,
      documents: FakeDocumentRepository(
        remote: {
          'doc-1': sheet('doc-1', title: 'Droit des obligations'),
          'doc-2': sheet('doc-2', title: 'Second import'),
        },
      ),
    );
    await tester.tap(find.text('Importer').last);
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> pickAndAttest(WidgetTester tester) async {
    await tester.tap(find.text('Choisir un PDF'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
  }

  /// Les minuteurs de la bibliothèque et de la fiche tournent.
  Future<void> leave(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('choisir, attester, envoyer : la fiche s’ouvre', (tester) async {
    final h = await open(tester);

    expect(find.text('Importez un PDF'), findsOneWidget);
    expect(find.text('PDF jusqu’à 50 Mo'), findsOneWidget);
    await tester.tap(find.text('Choisir un PDF'));
    await tester.pumpAndSettle();

    expect(find.text('Droit_des_obligations.pdf'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Droit des obligations'),
      findsOneWidget,
    );
    expect(find.textContaining('6,4 Mo seront envoyés'), findsOneWidget);
    expect(find.text('Cochez l’attestation pour envoyer.'), findsOneWidget);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();

    expect(h.uploads.requests.single.title, 'Droit des obligations');
    expect(h.uploads.confirms, ['doc-1']);
    expect(h.pdfs.discarded, hasLength(1));
    expect(find.byType(DocumentScreen), findsOneWidget);
    expect(h.library.refreshes, greaterThanOrEqualTo(2));
    await leave(tester);
  });

  testWidgets('deux imports de suite : la seconde fiche est relue', (
    tester,
  ) async {
    final h = await open(tester);
    await pickAndAttest(tester);
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();
    expect(h.documents.refreshes, 1);

    // La première fiche reste dans la pile de la Bibliothèque.
    await tester.tap(find.text('Importer').last);
    await tester.pumpAndSettle();
    await pickAndAttest(tester);
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();

    expect(h.documents.refreshes, 2);
    expect(find.text('Second import'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('pendant l’envoi : étape, progression, annulation', (
    tester,
  ) async {
    final uploads = FakeUploads()..sendGate = Completer<void>();
    final h = await open(tester, uploads: uploads);
    await pickAndAttest(tester);
    await tester.tap(find.text('Envoyer'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Étape 1 sur 2'), findsOneWidget);
    expect(find.text('Envoi en cours'), findsOneWidget);
    expect(find.text('50 % · 3,2 Mo / 6,4 Mo'), findsOneWidget);
    expect(find.text('Gardez l’application ouverte.'), findsOneWidget);

    await tester.tap(find.text('Annuler l’envoi'));
    await tester.pumpAndSettle();
    expect(find.text('Envoyer'), findsOneWidget, reason: 'fichier gardé');
    expect(h.uploads.confirms, isEmpty);
    await leave(tester);
  });

  testWidgets('coupure : nouvel essai annoncé, puis vérification', (
    tester,
  ) async {
    final uploads = FakeUploads(sendCodes: ['NETWORK_UNAVAILABLE', null])
      ..confirmCodes = [];
    await open(tester, uploads: uploads);
    await pickAndAttest(tester);
    uploads.sendGate = Completer<void>();
    await tester.tap(find.text('Envoyer'));
    await tester.pump();
    // Premier essai coupé, pause de 3 s, second essai retenu.
    uploads.sendGate!.complete();
    await tester.pump();
    uploads.sendGate = Completer<void>();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.textContaining('essai 2'), findsOneWidget);
    uploads.sendGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(DocumentScreen), findsOneWidget);
    await leave(tester);
  });

  testWidgets('refus : fichier trop gros, puis un autre fichier', (
    tester,
  ) async {
    final h = await open(tester, file: pdf(sizeBytes: 60 * 1024 * 1024));
    await pickAndAttest(tester);
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();

    expect(
      find.text('Ce PDF dépasse 50 Mo. Découpez-le en plusieurs parties.'),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsOneWidget);
    expect(h.uploads.requests, isEmpty);

    h.pdfs.next = pdf(name: 'Autre.pdf');
    await tester.tap(find.text('Changer'));
    await tester.pumpAndSettle();
    expect(find.text('Autre.pdf'), findsOneWidget);
    expect(h.pdfs.discarded, hasLength(1), reason: 'ancienne copie effacée');
    expect(find.text('Envoyer'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('titre vide : l’erreur est sous le champ', (tester) async {
    await open(tester);
    await pickAndAttest(tester);
    await tester.enterText(find.byType(TextField), '  ');
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();

    expect(find.text('Entrez un titre de 1 à 200 caractères.'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('fichier vérifié et refusé par le serveur', (tester) async {
    final uploads = FakeUploads()
      ..confirmCode = 'INVALID_DOCUMENT_UPLOAD'
      ..confirmDetails = {'reason': 'not_pdf'};
    await open(tester, uploads: uploads);
    await pickAndAttest(tester);
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();

    expect(
      find.text('Le serveur n’a pas reconnu un PDF dans ce fichier.'),
      findsOneWidget,
    );
    await leave(tester);
  });

  test('messages par code', () {
    for (final code in [
      'FILE_EMPTY',
      'NOT_A_PDF',
      'RIGHTS_NOT_ATTESTED',
      'INVALID_DOCUMENT_UPLOAD',
      'NETWORK_UNAVAILABLE',
      'RATE_LIMITED',
    ]) {
      expect(
        importErrorText(code),
        isNot(importErrorText('SERVER_ERROR')),
        reason: code,
      );
    }
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/conversion/presentation/convert_screen.dart';
import 'package:voxlivre/src/features/library/domain/library_item.dart';
import 'package:voxlivre/src/features/payment/domain/payment.dart';
import 'package:voxlivre/src/features/payment/presentation/payment_controller.dart';
import 'package:voxlivre/src/features/payment/presentation/payment_screen.dart';

import '../../../helpers/app_harness.dart';
import '../conversion/fakes.dart';
import '../library/fakes.dart';
import '../library/presentation/library_screen_test.dart' show tallScreen;
import 'fakes.dart';

const title = 'Droit des obligations';

void main() {
  /// Fiche → convertir → voix Léa (trop chère) → « Recharger des unités ».
  Future<Harness> openPayment(
    WidgetTester tester, {
    FakePaymentGateway? payments,
    MemoryPaymentMemory? memory,
  }) async {
    tallScreen(tester);
    final h = await pumpVoxlivre(
      tester,
      token: 'jeton',
      library: FakeLibraryRepository(
        remote: [book('a', title: title, status: LibraryStatus.notConverted)],
      ),
      documents: FakeDocumentRepository(
        remote: {'a': sheet('a', title: title)},
      ),
      conversions: FakeConversionGateway(
        account: unitsAccount(free: 300000),
      ),
      payments: payments,
      paymentMemory: memory,
    );
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choisir la voix et convertir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Léa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Recharger des unités'));
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> leave(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  /// Offres → pass → numéro → « Payer ».
  Future<void> payPass(WidgetTester tester, {String? phone}) async {
    await tester.tap(find.text('Pass 30 jours'));
    await tester.pumpAndSettle();
    if (phone != null) await tester.enterText(find.byType(TextField), phone);
    await tester.tap(find.text('Payer 2 000 FCFA'));
    await tester.pumpAndSettle();
  }

  String onlyPayment(Harness h) => h.payments.byId.keys.single;

  testWidgets('offres, payer, valider sur le téléphone, réussi', (
    tester,
  ) async {
    final h = await openPayment(
      tester,
      memory: MemoryPaymentMemory(phone: '+237694821033'),
    );
    expect(find.byType(PaymentScreen), findsOneWidget);
    expect(find.text('Recharger des unités'), findsOneWidget, reason: 'titre');
    expect(find.text('39 200 unités'), findsOneWidget, reason: 'solde');
    // Pass d'abord, prix du serveur.
    final pass = tester.getTopLeft(find.text('Pass 30 jours'));
    final credits = tester.getTopLeft(find.text('Crédits 50 000 unités'));
    expect(pass.dy, lessThan(credits.dy));
    expect(find.text('2 000 FCFA'), findsOneWidget);

    await tester.tap(find.text('Pass 30 jours'));
    await tester.pumpAndSettle();
    expect(find.text('694821033'), findsOneWidget, reason: 'pré-rempli');
    await tester.tap(find.text('Payer 2 000 FCFA'));
    await tester.pumpAndSettle();

    expect(h.payments.starts.single.key, 'k-1');
    expect(
      find.text('Validez le paiement sur votre téléphone'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Une demande de 2 000 FCFA arrive sur le +237 6•• •• •• 33.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('*150#'), findsOneWidget);
    expect(h.paymentMemory.pending, onlyPayment(h));

    // Relu toutes les 3 s.
    final reads = h.payments.reads;
    await tester.pump(paymentCheckEvery);
    expect(h.payments.reads, reads + 1);
    h.payments.settle(onlyPayment(h), PaymentStatus.succeeded);
    await tester.pump(paymentCheckEvery);
    await tester.pumpAndSettle();

    expect(find.text('Paiement réussi !'), findsOneWidget);
    expect(find.text('+250 000 unités ajoutées'), findsOneWidget);
    expect(find.text('Valable jusqu’au 12 novembre.'), findsOneWidget);
    expect(find.text('+237 6•• •• •• 33'), findsOneWidget);
    expect(h.paymentMemory.pending, isNull);

    final readsAfter = h.payments.reads;
    await tester.pump(paymentCheckEvery * 3);
    expect(h.payments.reads, readsAfter, reason: 'plus de relecture');

    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentScreen), findsNothing);
    expect(find.byType(ConvertScreen), findsOneWidget);
    await leave(tester);
  });

  testWidgets('numéro invalide : refusé ici, rien n’est envoyé', (
    tester,
  ) async {
    final h = await openPayment(tester);
    await payPass(tester, phone: '22 12 34');
    expect(
      find.text(
        'Ce numéro n’est pas un numéro Orange Money ou MTN MoMo du Cameroun.',
      ),
      findsOneWidget,
    );
    expect(h.payments.starts, isEmpty);
    await leave(tester);
  });

  testWidgets('coupure : même clé au nouvel essai ; autre numéro : autre clé', (
    tester,
  ) async {
    final h = await openPayment(tester);
    h.payments.startCode = 'INFRASTRUCTURE_PAYMENT_UNAVAILABLE';
    await payPass(tester, phone: '694821033');
    expect(
      find.textContaining('n’est pas disponible pour le moment'),
      findsOneWidget,
    );
    expect(find.textContaining('Rien n’a été débité'), findsOneWidget);

    h.payments.startCode = 'NETWORK_UNAVAILABLE';
    await tester.tap(find.text('Payer 2 000 FCFA'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pas de connexion'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '677000011');
    await tester.tap(find.text('Payer 2 000 FCFA'));
    await tester.pumpAndSettle();
    expect([for (final s in h.payments.starts) s.key], ['k-1', 'k-1', 'k-2']);
    expect(
      find.text('Validez le paiement sur votre téléphone'),
      findsOneWidget,
    );
    await leave(tester);
  });

  testWidgets('refusé sur le téléphone : rien prélevé, réessayer (clé neuve)', (
    tester,
  ) async {
    final h = await openPayment(tester);
    await payPass(tester, phone: '694821033');
    h.payments.settle(
      onlyPayment(h),
      PaymentStatus.failed,
      failureCode: 'declined',
    );
    await tester.tap(find.text('J’ai déjà validé'));
    await tester.pumpAndSettle();

    expect(find.text('Paiement refusé ou annulé'), findsOneWidget);
    expect(
      find.textContaining('Aucun montant n’a été prélevé'),
      findsOneWidget,
    );
    await tester.tap(find.text('Réessayer le paiement'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Payer 2 000 FCFA'));
    await tester.pumpAndSettle();
    expect([for (final s in h.payments.starts) s.key], ['k-1', 'k-2']);
    await leave(tester);
  });

  testWidgets('15 min sans réponse : « toujours en attente », vérifier', (
    tester,
  ) async {
    final h = await openPayment(tester);
    await payPass(tester, phone: '694821033');
    h.clock.advance(paymentWaitLimit);
    await tester.pump(paymentCheckEvery);
    await tester.pumpAndSettle();
    expect(find.textContaining('Toujours en attente'), findsOneWidget);
    final reads = h.payments.reads;
    await tester.pump(paymentCheckEvery * 2);
    expect(h.payments.reads, reads, reason: 'relecture arrêtée');

    h.payments.settle(onlyPayment(h), PaymentStatus.expired);
    await tester.tap(find.text('Vérifier'));
    await tester.pumpAndSettle();
    expect(find.text('Demande expirée'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('retour arrière : de « Payer » aux offres, puis on quitte', (
    tester,
  ) async {
    await openPayment(tester);
    await tester.tap(find.text('Pass 30 jours'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(find.text('Choisissez une offre'), findsOneWidget);
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentScreen), findsNothing);
    await leave(tester);
  });

  testWidgets('déjà en cours (409) : on reprend le paiement connu', (
    tester,
  ) async {
    final payments = FakePaymentGateway();
    final memory = MemoryPaymentMemory();
    final h = await openPayment(tester, payments: payments, memory: memory);
    await payPass(tester, phone: '694821033');
    // Fermé pendant l'attente, puis nouvel essai.
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();
    expect(memory.pending, isNotNull);
    memory.pending = null;
    await tester.tap(find.text('Recharger des unités'));
    await tester.pumpAndSettle();
    payments.startCode = 'PAYMENT_IN_PROGRESS_CONFLICT';
    await payPass(tester, phone: '694821033');
    expect(find.textContaining('attend déjà votre validation'), findsOneWidget);

    memory.pending = onlyPayment(h);
    payments.startCode = 'PAYMENT_IN_PROGRESS_CONFLICT';
    await tester.tap(find.text('Payer 2 000 FCFA'));
    await tester.pumpAndSettle();
    expect(
      find.text('Validez le paiement sur votre téléphone'),
      findsOneWidget,
    );
    await leave(tester);
  });

  testWidgets('app rouverte pendant l’attente : le parcours reprend', (
    tester,
  ) async {
    tallScreen(tester);
    final payments = FakePaymentGateway();
    final started = await payments.start(
      offerCode: 'credits-s',
      phone: '+237694821033',
      idempotencyKey: 'avant',
    );
    final id = (started as Ok<Payment, Failure>).value.id;
    payments.settle(id, PaymentStatus.succeeded);
    final h = await pumpVoxlivre(
      tester,
      token: 'jeton',
      payments: payments,
      paymentMemory: MemoryPaymentMemory(pending: id),
    );
    expect(find.text('Paiement réussi !'), findsOneWidget);
    expect(find.text('+50 000 unités ajoutées'), findsOneWidget);
    expect(h.paymentMemory.pending, isNull);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentScreen), findsNothing);
    await leave(tester);
  });

  testWidgets('catalogue injoignable : message et « Réessayer »', (
    tester,
  ) async {
    final payments = FakePaymentGateway()..offersCode = 'NETWORK_UNAVAILABLE';
    await openPayment(tester, payments: payments);
    expect(find.textContaining('Pas de connexion'), findsOneWidget);
    payments.offersCode = null;
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();
    expect(find.text('Pass 30 jours'), findsOneWidget);
    await leave(tester);
  });
}

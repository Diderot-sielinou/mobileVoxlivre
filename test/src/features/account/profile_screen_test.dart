import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/features/auth/domain/current_user.dart';
import 'package:voxlivre/src/features/auth/presentation/widgets/account_summary.dart';
import 'package:voxlivre/src/features/payment/domain/offer.dart';
import 'package:voxlivre/src/features/payment/presentation/payment_screen.dart';
import 'package:voxlivre/src/features/payment/presentation/units_history.dart';
import 'package:voxlivre/src/features/player/presentation/storage.dart';
import 'package:voxlivre/src/shared/format/durations.dart';
import 'package:voxlivre/src/shared/network/network_kind.dart';
import 'package:voxlivre/src/shared/settings/device_settings.dart';

import '../../../helpers/app_harness.dart';
import '../library/fakes.dart';
import '../library/presentation/library_screen_test.dart' show tallScreen;
import '../payment/fakes.dart';

const title = 'Droit des obligations';

void main() {
  Future<Harness> openProfile(
    WidgetTester tester, {
    FakePaymentGateway? payments,
    DeviceSettings settings = const DeviceSettings(),
  }) async {
    tallScreen(tester);
    final h = await pumpVoxlivre(
      tester,
      token: 'jeton',
      library: FakeLibraryRepository(remote: [book('a', title: title)]),
      documents: FakeDocumentRepository(
        remote: {'a': sheet('a', title: title)},
      ),
      payments: payments,
      deviceSettings: settings,
    );
    h.session.attachUser(
      const CurrentUser(id: 'u1', email: 'lecteur@mail.com', name: 'Awa Ngo'),
    );
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    return h;
  }

  Future<void> leave(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  testWidgets('en-tête, unités, réglages, légal, version', (tester) async {
    final payments = FakePaymentGateway()
      ..account = Balance(
        freeRemaining: 38000,
        passRemaining: 210000,
        credits: 50000,
        passEndsAt: DateTime.utc(2026, 11, 9, 12),
      );
    final h = await openProfile(tester, payments: payments);

    expect(find.text('Awa Ngo'), findsOneWidget);
    expect(find.text('AN'), findsOneWidget, reason: 'initiales');
    expect(find.text('l••••@mail.com'), findsOneWidget);
    expect(find.text('298 000 unités restantes'), findsOneWidget);
    expect(find.text('Pass actif jusqu’au 9 novembre'), findsOneWidget);
    expect(find.text('Amina'), findsOneWidget, reason: 'voix du serveur');
    expect(find.text('1×'), findsOneWidget);
    expect(find.text('Aucun livre sur le téléphone'), findsOneWidget);
    expect(find.text('Voxlivre 0.1.0 (1)'), findsOneWidget);

    await tester.tap(find.text('Conditions d’utilisation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confidentialité et données'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aide et contact'));
    await tester.pumpAndSettle();
    expect(h.links.opened.map((u) => u.toString()), [
      'https://site.test/conditions',
      'https://site.test/confidentialite',
      'mailto:aide@site.test?subject=Aide%20Voxlivre',
    ]);

    h.links.works = false;
    await tester.tap(find.text('Conditions d’utilisation'));
    await tester.pumpAndSettle();
    expect(
      find.text('Aucune application pour ouvrir ce lien.'),
      findsOneWidget,
    );
    await leave(tester);
  });

  testWidgets('voix par défaut : gardée, puis préchoisie à la conversion', (
    tester,
  ) async {
    final h = await openProfile(tester);
    await tester.tap(find.text('Voix par défaut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marc'));
    await tester.pumpAndSettle();
    expect(h.settings.read().defaultVoiceId, 'fr-m2');
    expect(find.text('Marc'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('vitesse : gardée, appliquée à l’ouverture du lecteur', (
    tester,
  ) async {
    final h = await openProfile(tester);
    await tester.tap(find.text('Vitesse de lecture'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1,5×'));
    await tester.pumpAndSettle();
    expect(h.settings.read().speed, 1.5);
    expect(find.text('1,5×'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('recharger depuis le Profil ouvre le paiement', (tester) async {
    await openProfile(tester);
    await tester.tap(find.text('Recharger'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Fermer'));
    await tester.pumpAndSettle();
    expect(find.byType(PaymentScreen), findsNothing);
    await leave(tester);
  });

  testWidgets('historique : par mois, titres, filtres, pages suivantes', (
    tester,
  ) async {
    final payments = FakePaymentGateway()
      ..pageSize = 2
      ..wallet = [
        WalletEntry(
          id: 'e1',
          kind: WalletEntryKind.consumption,
          units: -536,
          createdAt: DateTime.utc(2026, 10, 16, 10),
          conversionId: 'c-a',
        ),
        WalletEntry(
          id: 'e2',
          kind: WalletEntryKind.purchase,
          units: 50000,
          createdAt: DateTime.utc(2026, 10, 16, 9),
          offerCode: 'credits-s',
        ),
        WalletEntry(
          id: 'e3',
          kind: WalletEntryKind.refund,
          units: 120,
          createdAt: DateTime.utc(2026, 9, 2, 9),
          conversionId: 'inconnue',
        ),
      ];
    await openProfile(tester, payments: payments);
    await tester.tap(find.text('Unités et offres'));
    await tester.pumpAndSettle();

    expect(find.byType(UnitsHistoryScreen), findsOneWidget);
    expect(find.text('OCTOBRE 2026'), findsOneWidget);
    expect(find.text('SEPTEMBRE 2026'), findsOneWidget, reason: '2e page');
    expect(find.text('Conversion « $title »'), findsOneWidget);
    expect(find.text('−536 unités'), findsOneWidget);
    expect(find.text('Crédits 50 000 unités'), findsOneWidget);
    expect(find.text('+50 000 unités'), findsOneWidget);
    expect(find.text('Remboursement'), findsOneWidget, reason: 'titre inconnu');
    expect(payments.walletCursors, [null, '2']);

    await tester.tap(find.text('Achats'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Conversion'), findsNothing);
    await tester.tap(find.text('Consommation'));
    await tester.pumpAndSettle();
    expect(find.text('Crédits 50 000 unités'), findsNothing);
    expect(find.text('Remboursement'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('historique injoignable : message', (tester) async {
    final payments = FakePaymentGateway()..walletCode = 'NETWORK_UNAVAILABLE';
    await openProfile(tester, payments: payments);
    await tester.tap(find.text('Unités et offres'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Pas de connexion'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('stockage : livre téléchargé, Wi-Fi seulement, tout supprimer', (
    tester,
  ) async {
    final h = await openProfile(tester);
    // Télécharger le livre depuis sa fiche.
    await tester.tap(find.text('Livres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Télécharger'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profil').last);
    await tester.pumpAndSettle();
    expect(find.text('1 livre sur le téléphone'), findsOneWidget);

    await tester.tap(find.text('Stockage hors ligne'));
    await tester.pumpAndSettle();
    expect(find.byType(StorageScreen), findsOneWidget);
    expect(
      find.text(title),
      findsOneWidget,
      reason: 'titre de la bibliothèque',
    );
    expect(find.text('Prêt pour l’écoute hors ligne'), findsOneWidget);

    await tester.tap(find.text('Télécharger seulement en Wi-Fi'));
    await tester.pumpAndSettle();
    expect(h.settings.read().wifiOnly, isFalse);

    await tester.tap(find.text('Supprimer l’audio du téléphone'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Supprimer'));
    await tester.pumpAndSettle();
    expect(await h.books.read('c-a'), isNull);
    expect(find.textContaining('Aucun livre téléchargé'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('données mobiles : on demande avant de télécharger', (
    tester,
  ) async {
    final h = await openProfile(tester);
    h.network.kind = NetworkKind.mobile;
    await tester.tap(find.text('Livres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Télécharger'));
    await tester.pumpAndSettle();
    expect(find.text('Télécharger en données mobiles ?'), findsOneWidget);
    expect(
      find.textContaining('seront pris sur votre forfait'),
      findsOneWidget,
    );
    await tester.tap(find.text('Attendre le Wi-Fi'));
    await tester.pumpAndSettle();
    expect(h.player.downloads, isEmpty);

    await tester.tap(find.text('Télécharger'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Télécharger'));
    await tester.pumpAndSettle();
    expect(h.player.downloads, isNotEmpty);
    expect(find.text('Disponible hors ligne'), findsOneWidget);
    await leave(tester);
  });

  test('masques, initiales, mois', () {
    expect(maskEmail('lecteur@mail.com'), 'l••••@mail.com');
    expect(maskEmail('sansarobase'), 'sansarobase');
    expect(maskPhone('+237694821011'), '+237 6•• •• •• 11');
    expect(maskPhone('+33612345678'), '••• 78');
    expect(initialsOf('Awa Ngo', null), 'AN');
    expect(initialsOf('Awa', null), 'A');
    expect(initialsOf(null, 'lecteur@mail.com'), 'L');
    expect(initialsOf('', '+237'), '?');
    expect(VoxFormat.month(DateTime(2026, 10, 3)), 'octobre 2026');
    expect(VoxFormat.day(DateTime(2026, 11)), '1er novembre');
    expect(totalBytes(const []), 0);
  });
}

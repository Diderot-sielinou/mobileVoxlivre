import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/payment/application/check_payment.dart';
import 'package:voxlivre/src/features/payment/application/clear_payment_memory.dart';
import 'package:voxlivre/src/features/payment/application/load_offers.dart';
import 'package:voxlivre/src/features/payment/application/pending_payment.dart';
import 'package:voxlivre/src/features/payment/application/start_payment.dart';
import 'package:voxlivre/src/features/payment/domain/offer.dart';
import 'package:voxlivre/src/features/payment/domain/payment.dart';
import 'package:voxlivre/src/features/payment/infrastructure/api_payment_gateway.dart';
import 'package:voxlivre/src/features/payment/infrastructure/secure_payment_memory.dart';
import 'package:voxlivre/src/features/payment/infrastructure/uuid_keys.dart';
import 'package:voxlivre/src/features/payment/presentation/payment_texts.dart';

import '../../../helpers/fake_http.dart';
import 'fakes.dart';

String? codeOf(Result<Object?, Failure> result) => switch (result) {
  Ok() => null,
  Err(:final error) => error.code,
};

void main() {
  group('numéro Mobile Money', () {
    test('formes acceptées, normalisées en +2376…', () {
      for (final raw in [
        '694821033',
        '6 94 82 10 33',
        '237694821033',
        '+237 694 82 10 33',
        '00237694821033',
        '694-82-10-33',
      ]) {
        expect(normalizeCameroonMobile(raw), '+237694821033', reason: raw);
      }
    });

    test('refusés : fixe, trop court, étranger, lettres', () {
      for (final raw in [
        '',
        '222123456',
        '69482103',
        '6948210333',
        '+33612345678',
        '69482103a',
        '+2372694821033',
      ]) {
        expect(normalizeCameroonMobile(raw), isNull, reason: raw);
      }
    });
  });

  group('cas d’usage', () {
    late FakePaymentGateway gateway;
    late MemoryPaymentMemory memory;

    setUp(() {
      gateway = FakePaymentGateway();
      memory = MemoryPaymentMemory();
    });

    test('offres : pass d’abord, puis crédits du moins cher', () async {
      gateway.catalog = [
        const Offer(
          code: 'credits-l',
          kind: OfferKind.credits,
          priceXaf: 2500,
          units: 300000,
        ),
        creditsS,
        passOffer,
      ];
      final result = await LoadOffers(gateway)();
      final value =
          (result as Ok).value as ({List<Offer> offers, Balance balance});
      expect(
        [for (final o in value.offers) o.code],
        [
          'pass-30d',
          'credits-s',
          'credits-l',
        ],
      );
      expect(value.balance.total, 39200);

      gateway.offersCode = 'NETWORK_UNAVAILABLE';
      expect(codeOf(await LoadOffers(gateway)()), 'NETWORK_UNAVAILABLE');
    });

    test(
      'lancer : numéro vérifié d’abord, puis gardé avec le paiement',
      () async {
        final start = StartPayment(gateway, memory);
        expect(
          codeOf(
            await start(
              offerCode: 'pass-30d',
              phone: '22',
              idempotencyKey: 'k',
            ),
          ),
          'INVALID_PAYMENT_PHONE',
        );
        expect(gateway.starts, isEmpty, reason: 'rien n’est parti');

        final result = await start(
          offerCode: 'pass-30d',
          phone: '6 94 82 10 33',
          idempotencyKey: 'k-1',
        );
        expect(codeOf(result), isNull);
        expect(gateway.starts.single.phone, '+237694821033');
        expect(memory.phone, '+237694821033');
        expect(memory.pending, (result as Ok<Payment, Failure>).value.id);
      },
    );

    test('lancer : un refus ne garde rien', () async {
      gateway.startCode = 'RATE_LIMIT_PAYMENT_ATTEMPTS';
      final result = await StartPayment(gateway, memory)(
        offerCode: 'pass-30d',
        phone: '694821033',
        idempotencyKey: 'k-1',
      );
      expect(codeOf(result), 'RATE_LIMIT_PAYMENT_ATTEMPTS');
      expect(memory.phone, isNull);
      expect(memory.pending, isNull);
    });

    test('relire : conclu ou inconnu, il n’est plus à reprendre', () async {
      final started = await StartPayment(gateway, memory)(
        offerCode: 'credits-s',
        phone: '694821033',
        idempotencyKey: 'k-1',
      );
      final id = (started as Ok<Payment, Failure>).value.id;
      final check = CheckPayment(gateway, memory);

      await check(id);
      expect(memory.pending, id, reason: 'toujours en attente');
      gateway.readCode = 'NETWORK_UNAVAILABLE';
      await check(id);
      expect(memory.pending, id, reason: 'réseau absent : on garde');
      gateway
        ..readCode = null
        ..settle(id, PaymentStatus.succeeded);
      final done = await check(id) as Ok<Payment, Failure>;
      expect(done.value.status, PaymentStatus.succeeded);
      expect(memory.pending, isNull);

      memory.pending = 'disparu';
      expect(codeOf(await check('disparu')), 'PAYMENT_NOT_FOUND');
      expect(memory.pending, isNull);
    });

    test('en attente, dernier numéro, fin de session', () async {
      memory
        ..pending = 'p-1'
        ..phone = '+237694821033';
      final pending = PendingPayment(memory);
      expect(await pending(), 'p-1');
      expect(await pending.lastPhone(), '+237694821033');
      await ClearPaymentMemory(memory)();
      expect(await pending(), isNull);
      expect(await pending.lastPhone(), isNull);
    });
  });

  group('ApiPaymentGateway', () {
    Map<String, Object?> wirePayment({String status = 'pending'}) => {
      'id': '01a1b2c3-d4e5-7f00-8000-000000000001',
      'status': status,
      'offerCode': 'pass-30d',
      'amountXaf': 2000,
      'phoneSuffix': '33',
      'failureCode': status == 'failed' ? 'declined' : null,
      'createdAt': '2026-10-16T09:00:00.000Z',
      'completedAt': status == 'pending' ? null : '2026-10-16T09:01:00.000Z',
    };

    test('offres, solde, lancer (en-tête), relire', () async {
      final http = FakeHttp(
        (r) => switch (r.path) {
          '/v1/billing/offers' => reply(200, {
            'items': [
              {
                'code': 'pass-30d',
                'kind': 'pass',
                'priceXaf': 2000,
                'units': 250000,
                'durationDays': 30,
              },
              {
                'code': 'credits-s',
                'kind': 'credits',
                'priceXaf': 500,
                'units': 50000,
                'durationDays': null,
              },
            ],
            'voiceTierWeights': {'standard': 1, 'natural': 4},
          }),
          '/v1/billing/account' => reply(200, {
            'period': '2026-10',
            'free': {'limit': 50000, 'used': 12000, 'remaining': 38000},
            'pass': {
              'endsAt': '2026-11-09T12:00:00.000Z',
              'includedUnits': 250000,
              'usedUnits': 40000,
              'remainingUnits': 210000,
            },
            'nextPassStartsAt': null,
            'credits': 50000,
            'maxCharsPerConversion': 1000000,
          }),
          '/v1/payments' => reply(202, wirePayment()),
          _ => reply(200, wirePayment(status: 'failed')),
        },
      );
      final gateway = ApiPaymentGateway(http.client());

      final offers = (await gateway.offers() as Ok).value as List<Offer>;
      expect(offers.first.kind, OfferKind.pass);
      expect(offers.last.durationDays, isNull);

      final balance = (await gateway.balance() as Ok).value as Balance;
      expect(balance.total, 38000 + 210000 + 50000);
      expect(balance.passEndsAt, DateTime.utc(2026, 11, 9, 12));

      final started =
          (await gateway.start(
                        offerCode: 'pass-30d',
                        phone: '+237694821033',
                        idempotencyKey: 'k-1',
                      )
                      as Ok)
                  .value
              as Payment;
      final post = http.requests.last;
      expect(post.method, 'POST');
      expect(post.headers['Idempotency-Key'], 'k-1');
      expect(post.data, {
        'offerCode': 'pass-30d',
        'phoneNumber': '+237694821033',
      });
      expect(started.status, PaymentStatus.pending);
      expect(started.completedAt, isNull);

      final read = (await gateway.payment(started.id) as Ok).value as Payment;
      expect(http.requests.last.path, '/v1/payments/${started.id}');
      expect(read.status, PaymentStatus.failed);
      expect(read.failureCode, 'declined');
      expect(
        PaymentStatus.fromWire('amount_mismatch'),
        PaymentStatus.amountMismatch,
      );
      expect(PaymentStatus.fromWire('expired').isFinal, isTrue);
    });
  });

  group('sur l’appareil', () {
    test('numéro et paiement en attente, puis tout efface', () async {
      FlutterSecureStorage.setMockInitialValues({});
      const memory = SecurePaymentMemory();
      expect(await memory.lastPhone(), isNull);
      await memory.rememberPhone('+237694821033');
      await memory.rememberPending('p-1');
      expect(await memory.lastPhone(), '+237694821033');
      expect(await memory.pendingPayment(), 'p-1');
      await memory.forgetPending();
      expect(await memory.pendingPayment(), isNull);
      await memory.clear();
      expect(await memory.lastPhone(), isNull);
    });

    test('Keystore illisible : on oublie sans planter', () async {
      final memory = SecurePaymentMemory(_BrokenStorage());
      expect(await memory.lastPhone(), isNull);
      expect(await memory.pendingPayment(), isNull);
      await memory.clear();
    });

    test('clés d’idempotence : UUID v4 différents', () {
      const keys = UuidKeys();
      expect(keys.newKey(), matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(keys.newKey(), isNot(keys.newKey()));
    });
  });

  test('textes', () {
    expect(offerTitle(passOffer), 'Pass 30 jours');
    expect(offerTitle(creditsS), 'Crédits 50 000 unités');
    expect(maskedPhone('47'), '+237 6•• •• •• 47');
    for (final code in [
      'INVALID_PAYMENT_PHONE',
      'PAYMENT_IN_PROGRESS_CONFLICT',
      'RATE_LIMIT_PAYMENT_ATTEMPTS',
      'OFFER_NOT_FOUND',
      'INFRASTRUCTURE_PAYMENT_UNAVAILABLE',
      'NETWORK_UNAVAILABLE',
      'AUTRE',
    ]) {
      expect(startErrorText(code), isNotEmpty);
    }
    Payment paid(PaymentStatus status, [String? failure]) => Payment(
      id: '01a1b2c3-d4e5-7f00-8000-000000000001',
      status: status,
      offerCode: 'pass-30d',
      amountXaf: 2000,
      phoneSuffix: '33',
      failureCode: failure,
      createdAt: DateTime.utc(2026),
    );
    expect(failureText(paid(PaymentStatus.expired)).title, 'Demande expirée');
    expect(
      failureText(paid(PaymentStatus.failed, 'invalid_phone')).title,
      'Numéro refusé',
    );
    expect(
      failureText(paid(PaymentStatus.failed, 'declined')).detail,
      contains('Aucun montant'),
    );
    expect(
      failureText(paid(PaymentStatus.amountMismatch)).title,
      'Paiement à vérifier',
    );
    expect(paymentReference(paid(PaymentStatus.failed)), '01A1B2C3D4');
  });
}

/// Keystore dont la clé est perdue : toute lecture échoue.
class _BrokenStorage implements FlutterSecureStorage {
  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => throw PlatformException(code: 'BAD_DECRYPT');

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) => throw PlatformException(code: 'BAD_DECRYPT');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

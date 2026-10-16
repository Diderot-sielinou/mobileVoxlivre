import 'dart:async';

import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/payment/domain/offer.dart';
import 'package:voxlivre/src/features/payment/domain/payment.dart';
import 'package:voxlivre/src/features/payment/domain/payment_ports.dart';

import '../auth/fakes.dart';

const passOffer = Offer(
  code: 'pass-30d',
  kind: OfferKind.pass,
  priceXaf: 2000,
  units: 250000,
  durationDays: 30,
);
const creditsS = Offer(
  code: 'credits-s',
  kind: OfferKind.credits,
  priceXaf: 500,
  units: 50000,
);

/// Backend du paiement en mémoire : chaque clé d'idempotence donne un
/// paiement ; [settle] le conclut comme le ferait Campay.
final class FakePaymentGateway implements PaymentGateway {
  FakePaymentGateway({DateTime? now})
    : now = now ?? DateTime.utc(2026, 10, 13, 10);

  final DateTime now;
  List<Offer> catalog = [creditsS, passOffer];
  Balance account = const Balance(
    freeRemaining: 38000,
    passRemaining: 0,
    credits: 1200,
  );

  /// Échec du prochain lancement (une fois).
  String? startCode;

  /// Échec des relectures, tant qu'il est posé.
  String? readCode;
  String? offersCode;

  final byKey = <String, Payment>{};
  final byId = <String, Payment>{};
  final starts = <({String offer, String phone, String key})>[];
  int reads = 0;

  @override
  Future<Result<List<Offer>, Failure>> offers() async {
    if (offersCode case final code?) return Result.err(FakeFailure(code));
    return Result.ok(catalog);
  }

  @override
  Future<Result<Balance, Failure>> balance() async => Result.ok(account);

  @override
  Future<Result<Payment, Failure>> start({
    required String offerCode,
    required String phone,
    required String idempotencyKey,
  }) async {
    starts.add((offer: offerCode, phone: phone, key: idempotencyKey));
    if (startCode case final code?) {
      startCode = null;
      return Result.err(FakeFailure(code));
    }
    final known = byKey[idempotencyKey];
    if (known != null) return Result.ok(known);
    final offer = catalog.firstWhere((o) => o.code == offerCode);
    final payment = Payment(
      id: '01a1-pay-${byKey.length + 1}-0000',
      status: PaymentStatus.pending,
      offerCode: offerCode,
      amountXaf: offer.priceXaf,
      phoneSuffix: phone.substring(phone.length - 2),
      createdAt: now,
    );
    byKey[idempotencyKey] = payment;
    byId[payment.id] = payment;
    return Result.ok(payment);
  }

  @override
  Future<Result<Payment, Failure>> payment(String id) async {
    reads++;
    if (readCode case final code?) return Result.err(FakeFailure(code));
    final payment = byId[id];
    if (payment == null) {
      return const Result.err(FakeFailure('PAYMENT_NOT_FOUND'));
    }
    return Result.ok(payment);
  }

  /// Conclut le paiement [id] (`succeeded` accorde l'offre au solde).
  void settle(String id, PaymentStatus status, {String? failureCode}) {
    final old = byId[id]!;
    byId[id] = Payment(
      id: old.id,
      status: status,
      offerCode: old.offerCode,
      amountXaf: old.amountXaf,
      phoneSuffix: old.phoneSuffix,
      failureCode: failureCode,
      createdAt: old.createdAt,
      completedAt: now.add(const Duration(minutes: 1)),
    );
    if (status == PaymentStatus.succeeded) {
      final offer = catalog.firstWhere((o) => o.code == old.offerCode);
      account = Balance(
        freeRemaining: account.freeRemaining,
        passRemaining: offer.kind == OfferKind.pass
            ? account.passRemaining + offer.units
            : account.passRemaining,
        credits: offer.kind == OfferKind.credits
            ? account.credits + offer.units
            : account.credits,
        passEndsAt: offer.kind == OfferKind.pass
            ? DateTime.utc(2026, 11, 12, 10)
            : account.passEndsAt,
      );
    }
  }
}

final class MemoryPaymentMemory implements PaymentMemory {
  MemoryPaymentMemory({this.phone, this.pending});

  String? phone;
  String? pending;
  int clears = 0;

  @override
  Future<String?> lastPhone() async => phone;

  @override
  Future<void> rememberPhone(String value) async => phone = value;

  @override
  Future<String?> pendingPayment() async => pending;

  @override
  Future<void> rememberPending(String paymentId) async => pending = paymentId;

  @override
  Future<void> forgetPending() async => pending = null;

  @override
  Future<void> clear() async {
    clears++;
    phone = null;
    pending = null;
  }
}

/// Clés prévisibles : k-1, k-2…
final class SequenceKeys implements KeyGenerator {
  int count = 0;

  @override
  String newKey() => 'k-${++count}';
}

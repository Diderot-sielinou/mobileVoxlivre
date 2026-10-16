import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/payment/domain/offer.dart';
import 'package:voxlivre/src/features/payment/domain/payment.dart';
import 'package:voxlivre/src/features/payment/domain/payment_ports.dart';
import 'package:voxlivre/src/shared/http/api_client.dart';

typedef _Json = Map<String, Object?>;

/// [PaymentGateway] sur `voxlivre-api` (ADR-0013). Le numéro part dans le
/// corps, jamais dans l'URL ; le client HTTP ne journalise ni corps ni
/// en-têtes.
final class ApiPaymentGateway implements PaymentGateway {
  const ApiPaymentGateway(this._api);

  final ApiClient _api;

  @override
  Future<Result<List<Offer>, Failure>> offers() => _api.get(
    '/v1/billing/offers',
    decode: (r) => [
      for (final o
          in ((r.json! as _Json)['items']! as List<Object?>).cast<_Json>())
        Offer(
          code: o['code']! as String,
          kind: OfferKind.fromWire(o['kind']! as String),
          priceXaf: o['priceXaf']! as int,
          units: o['units']! as int,
          durationDays: o['durationDays'] as int?,
        ),
    ],
  );

  @override
  Future<Result<Balance, Failure>> balance() => _api.get(
    '/v1/billing/account',
    decode: (r) {
      final json = r.json! as _Json;
      final pass = json['pass'] as _Json?;
      return Balance(
        freeRemaining: (json['free']! as _Json)['remaining']! as int,
        passRemaining: (pass?['remainingUnits'] as int?) ?? 0,
        credits: json['credits']! as int,
        passEndsAt: _date(pass?['endsAt']),
        nextPassStartsAt: _date(json['nextPassStartsAt']),
      );
    },
  );

  @override
  Future<Result<Payment, Failure>> start({
    required String offerCode,
    required String phone,
    required String idempotencyKey,
  }) => _api.post(
    '/v1/payments',
    body: {'offerCode': offerCode, 'phoneNumber': phone},
    headers: {'Idempotency-Key': idempotencyKey},
    decode: (r) => _payment(r.json! as _Json),
  );

  @override
  Future<Result<Payment, Failure>> payment(String id) => _api.get(
    '/v1/payments/$id',
    decode: (r) => _payment(r.json! as _Json),
  );

  @override
  Future<Result<WalletPage, Failure>> walletEntries({String? cursor}) =>
      _api.get(
        '/v1/billing/wallet/entries',
        query: {'limit': 30, 'cursor': ?cursor},
        decode: (r) {
          final json = r.json! as _Json;
          return WalletPage(
            entries: [
              for (final e in (json['items']! as List<Object?>).cast<_Json>())
                WalletEntry(
                  id: e['id']! as String,
                  kind: WalletEntryKind.fromWire(e['kind']! as String),
                  units: e['units']! as int,
                  createdAt: _date(e['createdAt'])!,
                  offerCode: e['offerCode'] as String?,
                  conversionId: e['conversionId'] as String?,
                ),
            ],
            nextCursor: json['nextCursor'] as String?,
          );
        },
      );

  static Payment _payment(_Json json) => Payment(
    id: json['id']! as String,
    status: PaymentStatus.fromWire(json['status']! as String),
    offerCode: json['offerCode']! as String,
    amountXaf: json['amountXaf']! as int,
    phoneSuffix: json['phoneSuffix']! as String,
    failureCode: json['failureCode'] as String?,
    createdAt: _date(json['createdAt'])!,
    completedAt: _date(json['completedAt']),
  );

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.parse(value).toUtc() : null;
}

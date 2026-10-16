import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/payment/domain/payment.dart';
import 'package:voxlivre/src/features/payment/domain/payment_ports.dart';

/// Le numéro saisi n'est pas un mobile camerounais.
final class InvalidPaymentPhone extends Failure {
  const InvalidPaymentPhone() : super('INVALID_PAYMENT_PHONE');
}

/// Lance un paiement (ADR-0013) : numéro vérifié ici d'abord, puis
/// demande au serveur avec la clé de la tentative ; le numéro et le
/// paiement en attente sont gardés sur l'appareil.
final class StartPayment {
  const StartPayment(this._gateway, this._memory);

  final PaymentGateway _gateway;
  final PaymentMemory _memory;

  Future<Result<Payment, Failure>> call({
    required String offerCode,
    required String phone,
    required String idempotencyKey,
  }) async {
    final normalized = normalizeCameroonMobile(phone);
    if (normalized == null) return const Result.err(InvalidPaymentPhone());
    final result = await _gateway.start(
      offerCode: offerCode,
      phone: normalized,
      idempotencyKey: idempotencyKey,
    );
    if (result case Ok(value: final payment)) {
      await _memory.rememberPhone(normalized);
      if (!payment.status.isFinal) await _memory.rememberPending(payment.id);
    }
    return result;
  }
}

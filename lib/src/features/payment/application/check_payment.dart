import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/payment/domain/payment.dart';
import 'package:voxlivre/src/features/payment/domain/payment_ports.dart';

/// Relit un paiement ; conclu, il n'est plus « à reprendre ».
final class CheckPayment {
  const CheckPayment(this._gateway, this._memory);

  final PaymentGateway _gateway;
  final PaymentMemory _memory;

  Future<Result<Payment, Failure>> call(String paymentId) async {
    final result = await _gateway.payment(paymentId);
    switch (result) {
      case Ok(value: final payment) when payment.status.isFinal:
        await _memory.forgetPending();
      // Inconnu du serveur (compte changé, paiement supprimé) : oublié.
      case Err(:final error) when error.code == 'PAYMENT_NOT_FOUND':
        await _memory.forgetPending();
      case _:
    }
    return result;
  }
}

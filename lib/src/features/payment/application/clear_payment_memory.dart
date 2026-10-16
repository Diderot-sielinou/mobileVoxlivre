import 'package:voxlivre/src/features/payment/domain/payment_ports.dart';

/// Fin de session : numéro et paiement en attente quittent l'appareil.
final class ClearPaymentMemory {
  const ClearPaymentMemory(this._memory);

  final PaymentMemory _memory;

  Future<void> call() => _memory.clear();
}

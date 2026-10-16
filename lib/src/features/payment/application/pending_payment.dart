import 'package:voxlivre/src/features/payment/domain/payment_ports.dart';

/// Le paiement en attente laissé par une session précédente (app fermée
/// pendant l'attente), et le dernier numéro qui a payé.
final class PendingPayment {
  const PendingPayment(this._memory);

  final PaymentMemory _memory;

  Future<String?> call() => _memory.pendingPayment();

  Future<String?> lastPhone() => _memory.lastPhone();
}

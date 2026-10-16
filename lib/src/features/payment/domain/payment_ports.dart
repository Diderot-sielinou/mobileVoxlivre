import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/payment/domain/offer.dart';
import 'package:voxlivre/src/features/payment/domain/payment.dart';

/// Ce que le paiement demande au backend (ADR-0013).
abstract interface class PaymentGateway {
  /// Catalogue actif.
  Future<Result<List<Offer>, Failure>> offers();

  Future<Result<Balance, Failure>> balance();

  /// Lance l'encaissement de [offerCode] sur [phone] (`+2376…`). Même
  /// [idempotencyKey] = même paiement, sans nouvelle demande au téléphone.
  Future<Result<Payment, Failure>> start({
    required String offerCode,
    required String phone,
    required String idempotencyKey,
  });

  /// Relit un paiement (lecture en base côté serveur).
  Future<Result<Payment, Failure>> payment(String id);
}

/// Ce que le paiement garde sur l'appareil (stockage sécurisé).
abstract interface class PaymentMemory {
  /// Dernier numéro qui a payé, pour le pré-remplir.
  Future<String?> lastPhone();

  Future<void> rememberPhone(String phone);

  /// Paiement en attente de confirmation, à reprendre.
  Future<String?> pendingPayment();

  Future<void> rememberPending(String paymentId);

  Future<void> forgetPending();

  /// Fin de session : tout part.
  Future<void> clear();
}

/// Clés d'idempotence (UUID v4).
abstract interface class KeyGenerator {
  String newKey();
}

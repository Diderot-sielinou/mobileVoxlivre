import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voxlivre/src/features/payment/application/check_payment.dart';
import 'package:voxlivre/src/features/payment/application/clear_payment_memory.dart';
import 'package:voxlivre/src/features/payment/application/load_offers.dart';
import 'package:voxlivre/src/features/payment/application/pending_payment.dart';
import 'package:voxlivre/src/features/payment/application/start_payment.dart';
import 'package:voxlivre/src/features/payment/domain/payment_ports.dart';
import 'package:voxlivre/src/features/payment/infrastructure/api_payment_gateway.dart';
import 'package:voxlivre/src/features/payment/infrastructure/secure_payment_memory.dart';
import 'package:voxlivre/src/features/payment/infrastructure/uuid_keys.dart';
import 'package:voxlivre/src/shared/http/http_providers.dart';

/// Composition du paiement (ADR-0002, ADR-0013).

final paymentGatewayProvider = Provider<PaymentGateway>(
  (ref) => ApiPaymentGateway(ref.watch(apiClientProvider)),
);

final paymentMemoryProvider = Provider<PaymentMemory>(
  (ref) => const SecurePaymentMemory(),
);

final keyGeneratorProvider = Provider<KeyGenerator>((ref) => const UuidKeys());

final loadOffersProvider = Provider<LoadOffers>(
  (ref) => LoadOffers(ref.watch(paymentGatewayProvider)),
);

final startPaymentProvider = Provider<StartPayment>(
  (ref) => StartPayment(
    ref.watch(paymentGatewayProvider),
    ref.watch(paymentMemoryProvider),
  ),
);

final checkPaymentProvider = Provider<CheckPayment>(
  (ref) => CheckPayment(
    ref.watch(paymentGatewayProvider),
    ref.watch(paymentMemoryProvider),
  ),
);

final pendingPaymentProvider = Provider<PendingPayment>(
  (ref) => PendingPayment(ref.watch(paymentMemoryProvider)),
);

final clearPaymentMemoryProvider = Provider<ClearPaymentMemory>(
  (ref) => ClearPaymentMemory(ref.watch(paymentMemoryProvider)),
);

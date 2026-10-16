import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/payment/domain/offer.dart';
import 'package:voxlivre/src/features/payment/domain/payment_ports.dart';

/// Le catalogue et le solde, ensemble (écran « Offres »).
final class LoadOffers {
  const LoadOffers(this._gateway);

  final PaymentGateway _gateway;

  Future<Result<({List<Offer> offers, Balance balance}), Failure>>
  call() async {
    final (offers, balance) = await (
      _gateway.offers(),
      _gateway.balance(),
    ).wait;
    return switch ((offers, balance)) {
      (Err(:final error), _) || (_, Err(:final error)) => Result.err(error),
      (Ok(value: final o), Ok(value: final b)) => Result.ok((
        // Pass d'abord, puis crédits du moins cher au plus cher.
        offers: [...o]
          ..sort(
            (a, b) => a.kind != b.kind
                ? a.kind.index.compareTo(b.kind.index)
                : a.priceXaf.compareTo(b.priceXaf),
          ),
        balance: b,
      )),
    };
  }
}

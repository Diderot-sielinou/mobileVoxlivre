import 'package:voxlivre/src/core/failure.dart';
import 'package:voxlivre/src/core/result.dart';
import 'package:voxlivre/src/features/payment/domain/offer.dart';
import 'package:voxlivre/src/features/payment/domain/payment_ports.dart';

/// Une page de l'historique des unités (écran « Historique »).
final class LoadWalletPage {
  const LoadWalletPage(this._gateway);

  final PaymentGateway _gateway;

  Future<Result<WalletPage, Failure>> call({String? cursor}) =>
      _gateway.walletEntries(cursor: cursor);
}

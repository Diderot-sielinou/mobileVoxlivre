import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:voxlivre/src/features/payment/domain/payment_ports.dart';

/// [PaymentMemory] dans le Keystore Android : le numéro est une donnée
/// personnelle, jamais en clair ailleurs ni dans les journaux.
final class SecurePaymentMemory implements PaymentMemory {
  const SecurePaymentMemory([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const _phone = 'payment_last_phone';
  static const _pending = 'payment_pending_id';

  /// Un Keystore illisible n'empêche pas de payer : on oublie.
  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException {
      return null;
    }
  }

  Future<void> _delete(String key) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException {
      // Rien de lisible à effacer.
    }
  }

  @override
  Future<String?> lastPhone() => _read(_phone);

  @override
  Future<void> rememberPhone(String phone) =>
      _storage.write(key: _phone, value: phone);

  @override
  Future<String?> pendingPayment() => _read(_pending);

  @override
  Future<void> rememberPending(String paymentId) =>
      _storage.write(key: _pending, value: paymentId);

  @override
  Future<void> forgetPending() => _delete(_pending);

  @override
  Future<void> clear() async {
    await _delete(_phone);
    await _delete(_pending);
  }
}

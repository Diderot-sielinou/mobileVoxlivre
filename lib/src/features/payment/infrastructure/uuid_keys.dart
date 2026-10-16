import 'package:uuid/uuid.dart';
import 'package:voxlivre/src/features/payment/domain/payment_ports.dart';

/// [KeyGenerator] : UUID v4 (accepté tel quel par le backend).
final class UuidKeys implements KeyGenerator {
  const UuidKeys();

  static const _uuid = Uuid();

  @override
  String newKey() => _uuid.v4();
}

import 'package:uuid/uuid.dart';
import 'package:voxlivre/src/features/player/domain/player_ports.dart';

/// [IdGenerator] : UUID v4 aléatoires (ADR-0012).
final class UuidIds implements IdGenerator {
  const UuidIds();

  static const _uuid = Uuid();

  @override
  String newId() => _uuid.v4();
}
